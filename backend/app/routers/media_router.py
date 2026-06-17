import os
import uuid
import mimetypes
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from fastapi.responses import FileResponse

from app.auth import get_admin_user
from app.models import User

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

# sub-folder per media type
SUBFOLDERS = {
    "video": "videos",
    "image": "images",
    "resource": "resources",
}

MAX_SIZES = {
    "video":    200 * 1024 * 1024,   # 200 MB
    "image":    10  * 1024 * 1024,   # 10 MB
    "resource": 50  * 1024 * 1024,   # 50 MB
}

router = APIRouter(prefix="/media", tags=["Media"])


def _media_type(mime: str) -> str | None:
    """Return category key (video / image / resource) or None if not allowed."""
    for category, mimes in ALLOWED_TYPES.items():
        if mime in mimes:
            return category
    return None


def _safe_ext(filename: str, mime: str) -> str:
    """Return a safe file extension from the original name or mime type."""
    ext = Path(filename).suffix.lower()
    if not ext:
        ext = mimetypes.guess_extension(mime) or ""
    # guard against path traversal
    ext = ext.replace("/", "").replace("\\", "")
    return ext[:10]


# ── Upload ────────────────────────────────────────────────────────
@router.post("/upload")
async def upload_media(
    file: UploadFile = File(...),
    admin: User = Depends(get_admin_user),
):
    """
    Upload a media file (video, image, or resource/PDF).
    Returns the public URL path that can be stored in the DB.
    """
    mime = file.content_type or ""
    category = _media_type(mime)
    if not category:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported media type '{mime}'. "
                   f"Allowed: videos (mp4/webm), images (jpeg/png/gif/webp), "
                   f"resources (pdf/zip/txt).",
        )

    # Read and check size
    content = await file.read()
    if len(content) > MAX_SIZES[category]:
        max_mb = MAX_SIZES[category] // (1024 * 1024)
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum size for {category} is {max_mb} MB.",
        )

    # Build unique filename
    ext = _safe_ext(file.filename or "", mime)
    unique_name = f"{uuid.uuid4().hex}{ext}"
    subfolder = SUBFOLDERS[category]
    dest_dir = MEDIA_ROOT / subfolder
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest_path = dest_dir / unique_name

    # Write to disk
    with open(dest_path, "wb") as f:
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
    """
    Serve a media file by its path.
    No authentication required — URLs are unguessable (UUID-based).
    """
    # Prevent path traversal
    if ".." in subfolder or ".." in filename or "/" in filename or "\\" in filename:
        raise HTTPException(status_code=400, detail="Invalid path")

    allowed_subfolders = {"videos", "images", "resources"}
    if subfolder not in allowed_subfolders:
        raise HTTPException(status_code=404, detail="Not found")

    file_path = MEDIA_ROOT / subfolder / filename
    if not file_path.exists() or not file_path.is_file():
        raise HTTPException(status_code=404, detail="Media not found")

    return FileResponse(
        path=str(file_path),
        filename=filename,
        media_type=mimetypes.guess_type(filename)[0] or "application/octet-stream",
    )


# ── List media (admin only) ───────────────────────────────────────
@router.get("/list")
async def list_media(
    media_type: str = Query("all", description="Filter: video | image | resource | all"),
    admin: User = Depends(get_admin_user),
):
    """List all uploaded media files (admin only)."""
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

    return results


# ── Delete media (admin only) ─────────────────────────────────────
@router.delete("/{subfolder}/{filename}")
async def delete_media(
    subfolder: str,
    filename: str,
    admin: User = Depends(get_admin_user),
):
    """Delete a media file."""
    if ".." in subfolder or ".." in filename or "/" in filename or "\\" in filename:
        raise HTTPException(status_code=400, detail="Invalid path")

    allowed_subfolders = {"videos", "images", "resources"}
    if subfolder not in allowed_subfolders:
        raise HTTPException(status_code=404, detail="Not found")

    file_path = MEDIA_ROOT / subfolder / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Media not found")

    os.remove(file_path)
    return {"ok": True, "deleted": filename}
