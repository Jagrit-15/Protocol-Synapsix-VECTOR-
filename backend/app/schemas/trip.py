from datetime import datetime
from enum import Enum

from pydantic import BaseModel


class PointSource(str, Enum):
    gnss = "gnss"
    fused = "fused"
    dr_only = "dr_only"


class TrajectoryPointIn(BaseModel):
    ts: datetime
    lat: float
    lon: float
    source: PointSource
    accuracy_m: float | None = None
    covariance_major_m: float | None = None
    covariance_minor_m: float | None = None
    heading_deg: float | None = None


class TripOut(BaseModel):
    id: str
    user_id: str
    started_at: datetime
    ended_at: datetime | None = None
    distance_m: float | None = None
    max_drift_m: float | None = None
    pct_time_dr: float | None = None
