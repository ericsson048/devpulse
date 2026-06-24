import logging
import os
from functools import lru_cache

import boto3
from botocore.client import Config
from botocore.exceptions import ClientError

from app.config import get_settings

logger = logging.getLogger("devpulse")


@lru_cache()
def _get_b2_client():
    """Return a cached B2 S3-compatible client."""
    settings = get_settings()
    return boto3.client(
        "s3",
        endpoint_url=settings.B2_ENDPOINT,
        aws_access_key_id=settings.B2_KEY_ID,
        aws_secret_access_key=settings.B2_APPLICATION_KEY,
        config=Config(signature_version="s3v4"),
    )


class B2Service:
    """Backblaze B2 (S3-compatible) storage service."""

    @staticmethod
    def _bucket() -> str:
        return get_settings().B2_BUCKET_NAME

    @staticmethod
    def _client():
        return _get_b2_client()

    @staticmethod
    def public_url(key: str) -> str:
        """Return the direct public URL for a given key."""
        settings = get_settings()
        return f"{settings.B2_ENDPOINT}/{settings.B2_BUCKET_NAME}/{key}"

    @staticmethod
    def presigned_url(key: str, expires_in: int = 43200) -> str:
        """Return a pre-signed URL valid for `expires_in` seconds (default 12h)."""
        client = _get_b2_client()
        try:
            return client.generate_presigned_url(
                "get_object",
                Params={"Bucket": B2Service._bucket(), "Key": key},
                ExpiresIn=expires_in,
            )
        except ClientError:
            return ""

    @staticmethod
    def upload_fileobj(data: bytes, key: str) -> bool:
        """Upload raw bytes to B2."""
        try:
            B2Service._client().put_object(
                Bucket=B2Service._bucket(),
                Key=key,
                Body=data,
            )
            return True
        except ClientError as e:
            logger.error("B2 Upload failed: %s", e)
            return False

    @staticmethod
    def delete_file(key: str) -> bool:
        """Delete a file from B2."""
        try:
            B2Service._client().delete_object(
                Bucket=B2Service._bucket(),
                Key=key,
            )
            return True
        except ClientError as e:
            logger.error("B2 Delete failed: %s", e)
            return False

    @staticmethod
    def list_files(prefix: str = "") -> list[dict]:
        """List files under a prefix. Returns list of {key, size, mime}."""
        try:
            objects = []
            paginator = B2Service._client().get_paginator("list_objects_v2")
            for page in paginator.paginate(Bucket=B2Service._bucket(), Prefix=prefix):
                for obj in page.get("Contents", []):
                    objects.append({
                        "key": obj["Key"],
                        "size_bytes": obj["Size"],
                        "last_modified": obj["LastModified"].isoformat(),
                    })
            return objects
        except ClientError as e:
            logger.error("B2 List failed: %s", e)
            return []

    @staticmethod
    def file_exists(key: str) -> bool:
        """Check if a file exists in B2."""
        try:
            B2Service._client().head_object(
                Bucket=B2Service._bucket(),
                Key=key,
            )
            return True
        except ClientError:
            return False
