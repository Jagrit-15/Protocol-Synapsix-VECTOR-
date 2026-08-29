from pydantic import BaseModel


class DriftSummary(BaseModel):
    trip_id: str
    max_drift_m: float
    pct_time_dr: float
    point_count: int
