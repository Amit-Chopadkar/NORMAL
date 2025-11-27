from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest

from .config import get_settings
from .schemas import TrainResponse
from .storage import store


settings = get_settings()


@dataclass
class ModelBundle:
    model: IsolationForest
    path: Optional[Path]


def load_or_train_model(force_retrain: bool = False) -> ModelBundle:
    model_path = settings.model_dir / settings.model_filename
    if model_path.exists() and not force_retrain:
        model = joblib.load(model_path)
        return ModelBundle(model=model, path=model_path)

    return train_model(persist=True)


def train_model(persist: bool) -> ModelBundle:
    df = store.load_dataframe()
    if df.empty:
        # fabricate minimal frame with neutral rows to keep model shape valid
        df = pd.DataFrame(
            [
                {
                    "speed_mps": 1.5,
                    "accuracy_m": 5.0,
                    "battery_pct": 80.0,
                }
            ]
        )

    features = df[["speed_mps", "accuracy_m", "battery_pct"]].fillna(50.0).to_numpy()
    model = IsolationForest(
        n_estimators=200,
        contamination=0.05,
        random_state=settings.random_state,
    )
    model.fit(features)

    model_path = settings.model_dir / settings.model_filename if persist else None
    if persist:
        settings.model_dir.mkdir(parents=True, exist_ok=True)
        joblib.dump(model, model_path)

    return ModelBundle(model=model, path=model_path)


def handle_training_request(retrain_with_new_data: bool, persist_model: bool) -> TrainResponse:
    bundle = train_model(persist=persist_model) if retrain_with_new_data else load_or_train_model()
    df = store.load_dataframe()
    trained_rows = len(df.index)

    response = TrainResponse(
        trained_on_rows=trained_rows,
        model_path=str(bundle.path) if bundle.path else None,
        feature_importances=None,
    )
    return response






