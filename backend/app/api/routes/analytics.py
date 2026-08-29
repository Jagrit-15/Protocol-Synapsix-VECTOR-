from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.api.routes.trips import get_points
from app.schemas.analytics import DriftSummary
from app.services.analytics_engine import summarize_trip

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/trips/{trip_id}", response_model=DriftSummary)
async def trip_analytics(
    trip_id: str,
    user: dict = Depends(get_current_user),
) -> DriftSummary:
    return summarize_trip(trip_id, get_points(trip_id))
