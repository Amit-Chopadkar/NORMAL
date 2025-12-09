from functools import lru_cache
from pathlib import Path
from typing import Optional

from pydantic import Field
from pydantic_settings import BaseSettings


BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    """Service configuration populated from env vars or defaults."""

    data_dir: Path = Field(default=BASE_DIR / "data")
    model_dir: Path = Field(default=BASE_DIR / "models")
    historical_dataset: Path = Field(
        default=BASE_DIR / "data" / "historical_observations.csv"
    )
    danger_zones_path: Path = Field(default=BASE_DIR / "data" / "danger_zones.geojson")

    route_deviation_threshold_m: float = Field(default=120.0)
    inactivity_threshold_minutes: int = Field(default=15)
    alert_buffer_minutes: int = Field(default=5)

    model_filename: str = Field(default="anomaly_iforest.joblib")
    random_state: Optional[int] = Field(default=42)

    # LLM Configuration
    ollama_host: str = Field(default="http://localhost:11434")
    ollama_model: str = Field(default="phi3:mini")
    llm_enabled: bool = Field(default=True)
    llm_timeout: int = Field(default=30)
    llm_max_tokens: int = Field(default=500)

    class Config:
        env_prefix = "ML_ENGINE_"
        case_sensitive = False


@lru_cache
def get_settings() -> Settings:
    return Settings()

