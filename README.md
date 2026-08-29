# Protocol Synapsix

AI/ML intelligent **dead-reckoning** navigation for **SIH26168**.

This repository is a **demo skeleton**. Sensor fusion, EKF, TFLite inference,
HMM map-matching, and agentic orchestration are **intentionally fake** and
marked `PLACEHOLDER` / `TODO(agentic-workflow)` so they can be replaced one
narrow slice at a time.

## Layout

| Path | Stack |
| --- | --- |
| `mobile/` | Flutter, feature-based Clean Architecture, OSM via `flutter_map` |
| `backend/` | FastAPI, in-memory trip points |
| `dashboard/` | React + Vite + TypeScript, Leaflet OSM, Recharts |
| `ml/` | Training scripts later |
| `docs/` | Schema + progress |

## Quick start

**Mobile**

```bash
cd mobile
flutter pub get
flutter run
```

Home/Map runs the tunnel demo automatically (no backend, no real IMU).

**Backend**

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

`POST /trips/{trip_id}/points` with `Authorization: Bearer demo`.

**Dashboard**

```bash
cd dashboard
npm install
npm run dev
```

Open `/replay` for the judge-facing mock trip.

## Secrets

Copy `*/.env.example` locally. Never commit real `.env`, `.tflite`, or `.onnx`.
Mapbox is optional; OSM tiles are the hackathon default.
