from fastapi import Header

from app.core.security import decode_supabase_jwt, require_bearer


async def get_current_user(
    authorization: str | None = Header(default=None),
) -> dict:
    token = require_bearer(authorization)
    return decode_supabase_jwt(token)
