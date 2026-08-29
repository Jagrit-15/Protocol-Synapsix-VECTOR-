"""PLACEHOLDER analytics. No real drift math yet."""

from app.schemas.analytics import DriftSummary


def summarize_trip(trip_id: str, points: list[dict]) -> DriftSummary:
    covs = [
        p.get("covariance_major_m") or 0.0
        for p in points
    ]
    dr_count = sum(1 for p in points if p.get("source") == "dr_only")
    n = max(len(points), 1)
    return DriftSummary(
        trip_id=trip_id,
        max_drift_m=max(covs) if covs else 0.0,
        pct_time_dr=dr_count / n,
        point_count=len(points),
    )
