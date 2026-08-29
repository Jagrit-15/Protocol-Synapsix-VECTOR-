from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.schemas.models import ModelVersionOut

router = APIRouter(prefix="/models", tags=["models"])

_MOCK = [
    ModelVersionOut(
        id=1,
        model_name="motion_classifier",
        version="0.0.0-placeholder",
        file_url="PLACEHOLDER",
        metrics={"note": "no real model yet"},
    )
]


@router.get("", response_model=list[ModelVersionOut])
async def list_models(user: dict = Depends(get_current_user)) -> list[ModelVersionOut]:
    return _MOCK
