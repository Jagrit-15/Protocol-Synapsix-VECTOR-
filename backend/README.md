# Protocol Synapsix — backend

```
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Auth: any non-empty `Authorization: Bearer …` header is accepted (placeholder).
Missing bearer → 401.
