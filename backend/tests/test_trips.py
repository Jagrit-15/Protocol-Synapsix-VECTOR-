from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health() -> None:
    r = client.get("/health")
    assert r.status_code == 200


def test_points_unauthorized() -> None:
    r = client.post(
        "/trips/abc/points",
        json=[
            {
                "ts": "2026-01-01T00:00:00Z",
                "lat": 28.61,
                "lon": 77.20,
                "source": "fused",
            }
        ],
    )
    assert r.status_code == 401


def test_points_created() -> None:
    r = client.post(
        "/trips/abc/points",
        headers={"Authorization": "Bearer demo"},
        json=[
            {
                "ts": "2026-01-01T00:00:00Z",
                "lat": 28.61,
                "lon": 77.20,
                "source": "gnss",
                "accuracy_m": 4.0,
                "covariance_major_m": 6.0,
                "covariance_minor_m": 3.0,
                "heading_deg": 10.0,
            }
        ],
    )
    assert r.status_code == 201
    assert r.json()["accepted"] == 1
