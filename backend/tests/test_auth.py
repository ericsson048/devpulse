import pytest
from app.auth import hash_password, verify_password, create_access_token
from jose import jwt
from app.config import get_settings

settings = get_settings()


def test_hash_password():
    pw = "testpass123"
    hashed = hash_password(pw)
    assert hashed != pw
    assert verify_password(pw, hashed)
    assert not verify_password("wrongpass", hashed)


def test_create_access_token():
    data = {"sub": "42"}
    token = create_access_token(data)
    assert token
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    assert payload["sub"] == "42"
    assert "exp" in payload
