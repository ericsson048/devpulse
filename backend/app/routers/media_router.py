import os
import uuid
import mimetypes
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from fastapi.responses import FileResponse, RedirectResponse

from app.auth import get_admin_user
from app.models import User
from app.services.b2_service import B2Service

# ── Config ────────────────────────────────────────────────────────
MEDIA_ROOT = Path(__file__).resolve().parent.parent / "Medias"

ALLOWED_TYPES = {
    "video":    {"video/mp4", "video/webm", "video/ogg"},
    "image":    {"image/jpeg", "image/png", "image/gif", "image/webp", "image/svg+xml"},
    "resource": {
        "application/pdf",
        "text/plain",
        "application/zip",
        "application/x-zip-compressed",
    },
}

SUBFOLDERS = {
    "video": "videos",
    "image": "images",
    "resource": "resources",
}

MAX_SIZES = {
    "video":    200 * 1024 * 1024,
    "image":    10  * 1024 * 1024,
    "resource": 50  * 1024 * 1024,
}

router = APIRouter(prefix="/media", tags=["Media"])


def _media_type(mime: str) -> str | None:
    for category, mimes in ALLOWED_TYPES.items():
        if mime in mimes:
            return category
    return None


def _safe_ext(filename: str, mime: str) -> str:
    ext = Path(filename).suffix.lower()
    if not ext:
        ext = mimetypes.guess_extension(mime) or ""
    ext = ext.replace("/", "").replace("\\", "")
    return ext[:10]


# ── Upload ────────────────────────────────────────────────────────
@router.post("/upload")
async def upload_media(
    file: UploadFile = File(...),
    admin: User = Depends(get_admin_user),
):
    mime = file.content_type or ""
    category = _media_type(mime)
    if not category:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported media type '{mime}'. "
                   f"Allowed: videos (mp4/webm), images (jpeg/png/gif/webp), "
                   f"resources (pdf/zip/txt).",
        )

    content = await file.read()
    if len(content) > MAX_SIZES[category]:
        max_mb = MAX_SIZES[category] // (1024 * 1024)
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum size for {category} is {max_mb} MB.",
        )

    ext = _safe_ext(file.filename or "", mime)
    unique_name = f"{uuid.uuid4().hex}{ext}"
    subfolder = SUBFOLDERS[category]
    b2_key = f"{subfolder}/{unique_name}"

    # Upload to B2
    ok = B2Service.upload_fileobj(content, b2_key)
    if not ok:
        raise HTTPException(status_code=500, detail="Failed to upload file to storage")

    # Also save locally as fallback
    dest_dir = MEDIA_ROOT / subfolder
    dest_dir.mkdir(parents=True, exist_ok=True)
    with open(dest_dir / unique_name, "wb") as f:
        f.write(content)

    public_url = f"/api/media/{subfolder}/{unique_name}"

    return {
        "url": public_url,
        "filename": unique_name,
        "original_name": file.filename,
        "type": category,
        "mime": mime,
        "size_bytes": len(content),
    }


# ── Serve static media ────────────────────────────────────────────
@router.get("/{subfolder}/{filename}")
async def serve_media(subfolder: str, filename: str):
    if ".." in subfolder or ".." in filename or "/" in filename or "\\" in filename:
        raise HTTPException(status_code=400, detail="Invalid path")

    allowed_subfolders = {"videos", "images", "resources"}
    if subfolder not in allowed_subfolders:
        raise HTTPException(status_code=404, detail="Not found")

    # Try local disk first (backward compat)
    local_path = MEDIA_ROOT / subfolder / filename
    if local_path.exists() and local_path.is_file():
        return FileResponse(
            path=str(local_path),
            filename=filename,
            media_type=mimetypes.guess_type(filename)[0] or "application/octet-stream",
        )

    # Fallback to B2 redirect
    b2_key = f"{subfolder}/{filename}"
    if B2Service.file_exists(b2_key):
        return RedirectResponse(url=B2Service.public_url(b2_key))

    raise HTTPException(status_code=404, detail="Media not found")


# ── List media (admin only) ───────────────────────────────────────
@router.get("/list")
async def list_media(
    media_type: str = Query("all", description="Filter: video | image | resource | all"),
    admin: User = Depends(get_admin_user),
):
    results = []

    folders_to_scan: list[tuple[str, str]] = []
    if media_type == "all":
        folders_to_scan = [
            ("video", "videos"),
            ("image", "images"),
            ("resource", "resources"),
        ]
    elif media_type in SUBFOLDERS:
        folders_to_scan = [(media_type, SUBFOLDERS[media_type])]
    else:
        raise HTTPException(status_code=400, detail="Invalid media_type")

    # List local files
    for category, subfolder in folders_to_scan:
        folder = MEDIA_ROOT / subfolder
        if not folder.exists():
            continue
        for f in sorted(folder.iterdir()):
            if f.is_file():
                results.append({
                    "url": f"/api/media/{subfolder}/{f.name}",
                    "filename": f.name,
                    "type": category,
                    "size_bytes": f.stat().st_size,
                    "mime": mimetypes.guess_type(f.name)[0] or "application/octet-stream",
                })

    # List B2 files (merge, avoid dupes)
    seen = {r["filename"] for r in results}
    for category, subfolder in folders_to_scan:
        for obj in B2Service.list_files(prefix=f"{subfolder}/"):
            fname = obj["key"].split("/")[-1]
            if fname in seen:
                continue
            seen.add(fname)
            results.append({
                "url": f"/api/media/{subfolder}/{fname}",
                "filename": fname,
                "type": category,
                "size_bytes": obj["size_bytes"],
                "mime": mimetypes.guess_type(fname)[0] or "application/octet-stream",
            })

    return results


# ── Delete media (admin only) ─────────────────────────────────────
@router.delete("/{subfolder}/{filename}")
async def delete_media(
    subfolder: str,
    filename: str,
    admin: User = Depends(get_admin_user),
):
    if ".." in subfolder or ".." in filename or "/" in filename or "\\" in filename:
        raise HTTPException(status_code=400, detail="Invalid path")

    allowed_subfolders = {"videos", "images", "resources"}
    if subfolder not in allowed_subfolders:
        raise HTTPException(status_code=404, detail="Not found")

    # Delete from local disk
    local_path = MEDIA_ROOT / subfolder / filename
    if local_path.exists():
        os.remove(local_path)

    # Delete from B2
    b2_key = f"{subfolder}/{filename}"
    B2Service.delete_file(b2_key)

    return {"ok": True, "deleted": filename}
