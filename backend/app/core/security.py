"""PLACEHOLDER JWT checks. Real Supabase JWKS verification is a later slice."""

from fastapi import HTTPException, status


def require_bearer(authorization: str | None) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token",
        )
    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Empty bearer token",
        )
    return token


def decode_supabase_jwt(token: str) -> dict:
    # PLACEHOLDER: accept any non-empty token as a demo user.
    return {"sub": "demo-user", "role": "authenticated", "token": token}
