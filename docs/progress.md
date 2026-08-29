# Progress — Protocol Synapsix (SIH26168)

## 2026-08-29 — mono-repo skeleton

Generated a working **demo/placeholder** tree. Nothing below is production
sensor fusion.

### Real (wired enough to demo)

- Flutter app shell: onboarding, home map (OSM/`flutter_map` + moving dot +
  covariance circle), turn-by-turn GNSS badge, trip history/summary, settings,
  hidden debug `fl_chart` covariance plot (tap Settings title ×7).
- `DemoScenarioController` tunnel cycle: GNSS on (~12s) → drop (~20s,
  Dead-Reckoning Active, ellipse grows) → reacquire (ellipse shrinks).
- FastAPI `POST /trips/{trip_id}/points` with in-memory store (201 with any
  Bearer token, 401 without).
- Dashboard `/replay` hardcoded GPS vs fused polylines + scrubber (Leaflet OSM).
- Unit test stubs: coordinate transforms, fusion covariance grow/shrink,
  sensor passthrough; backend trip ingest tests.
- `docs/schema.sql` as specified.

### PLACEHOLDER (swap one slice at a time)

| Slice | Location | Demo behavior |
| --- | --- | --- |
| SensorIngestionAgent | `mobile/lib/features/sensors` | Pass-through / mockOverride |
| MotionClassifierAgent | `fusion/motion_classifier` | Scripted label cycle |
| LearnedOdometryAgent | `fusion/odometry_model` | Bounded random deltas |
| FusionAgent / EKF | `fusion/ekf` | Linear blend, fake covariance |
| MapMatchingAgent | `map_matching/hmm_matcher` | Identity snap |
| TFLite wrappers | `tflite_*.dart` | No interpreter load |
| Auth / JWT | mobile + `backend/app/core/security.py` | Any bearer accepted |
| Supabase / sqflite | services + trip repo | Hardcoded lists |
| Background service | `services/background_service.dart` | Not started |
| Analytics engine | `backend/app/services/analytics_engine.py` | Max of mock cov |
| ML training | `ml/` | Empty |

Each agent file starts with
`// TODO(agentic-workflow): replace with real implementation — see [agent name] spec`.
