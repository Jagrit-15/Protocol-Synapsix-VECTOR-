from collections import defaultdict

from fastapi import APIRouter, Depends, status

from app.api.deps import get_current_user
from app.schemas.trip import TrajectoryPointIn

router = APIRouter(prefix="/trips", tags=["trips"])

# PLACEHOLDER in-memory store. No real DB yet.
_POINTS: dict[str, list[dict]] = defaultdict(list)


@router.post("/{trip_id}/points", status_code=status.HTTP_201_CREATED)
async def ingest_points(
    trip_id: str,
    body: list[TrajectoryPointIn],
    user: dict = Depends(get_current_user),
) -> dict:
    stored = [p.model_dump(mode="json") for p in body]
    _POINTS[trip_id].extend(stored)
    return {
        "trip_id": trip_id,
        "accepted": len(stored),
        "total": len(_POINTS[trip_id]),
        "user": user.get("sub"),
    }


def get_points(trip_id: str) -> list[dict]:
    return list(_POINTS[trip_id])
