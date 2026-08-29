from pydantic import BaseModel


class ModelVersionOut(BaseModel):
    id: int
    model_name: str
    version: str
    file_url: str
    metrics: dict | None = None
