"""
FIRE-EYE ML Prediction Service
Loads pre-trained Random Forest joblib model at application startup and keeps it in memory.
Ensures 100% feature order parity with training pipeline (rainfall_24h, cumulative_rainfall_7d, slope, elevation, historical_landslides).
Falls back cleanly to calibrated hydrological heuristic engine if model file is not found or fails.
"""

import logging
import os
from typing import Any
import pandas as pd

logger = logging.getLogger("fire-eye.ml")

# ── Model Singleton ──────────────────────────────────────────────────────────
_model = None
_model_features = None
_model_classes = None
_model_loaded = False


def load_model_at_startup():
    """Call once from FastAPI lifespan/startup to warm the model into RAM."""
    global _model, _model_features, _model_classes, _model_loaded

    candidate_paths = [
        os.getenv("ML_MODEL_PATH", ""),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "ml", "models", "landslide_model.joblib")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "ml", "models", "landslide_model.joblib")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "ml", "landslide_model.joblib")),
    ]

    model_path = next((p for p in candidate_paths if p and os.path.exists(p)), None)

    if model_path:
        try:
            import joblib

            payload = joblib.load(model_path)
            if isinstance(payload, dict) and "model" in payload:
                _model = payload["model"]
                _model_features = payload.get("features", [
                    "rainfall_24h", "cumulative_rainfall_7d", "slope", "elevation", "historical_landslides"
                ])
                _model_classes = payload.get("classes", getattr(_model, "classes_", ["LOW", "MEDIUM", "HIGH"]))
            else:
                _model = payload
                _model_features = [
                    "rainfall_24h", "cumulative_rainfall_7d", "slope", "elevation", "historical_landslides"
                ]
                _model_classes = getattr(_model, "classes_", ["LOW", "MEDIUM", "HIGH"])

            _model_loaded = True
            logger.info(f"ML model successfully loaded from {model_path} with features: {_model_features}")
        except Exception as e:
            logger.warning(f"Failed to load ML model: {e}. Using calibrated heuristic fallback.")
            _model_loaded = False
    else:
        logger.info(f"No ML model artifact found at inspected paths. Using calibrated hydrological heuristic.")
        _model_loaded = False


def predict_risk_at_location(
    lat: float,
    lon: float,
    rainfall_24h: float = 100.0,
    cumulative_rainfall_7d: float = 0.0,
    slope: float = 35.0,
    elevation: float = 1200.0,
    historical_landslides: int = 1
) -> float:
    """
    Internal service function used by Priority Engine.
    Returns calibrated 0.0 to 1.0 probability of hazard at given location.
    """
    if cumulative_rainfall_7d <= 0.0:
        cumulative_rainfall_7d = rainfall_24h * 2.2

    if _model_loaded and _model is not None:
        try:
            features_df = pd.DataFrame([{
                "rainfall_24h": rainfall_24h,
                "cumulative_rainfall_7d": cumulative_rainfall_7d,
                "slope": slope,
                "elevation": elevation,
                "historical_landslides": historical_landslides,
            }])[list(_model_features)]
            probs = _model.predict_proba(features_df)[0]
            classes = list(_model_classes)
            if "HIGH" in classes:
                high_idx = classes.index("HIGH")
                return round(float(probs[high_idx]), 3)
            return round(float(max(probs)), 3)
        except Exception:
            pass

    # Heuristic fallback based on geographical and rainfall hazards
    base_risk = min(rainfall_24h / 200.0, 1.0) * 0.6
    # Chamoli / Rudraprayag / Wayanad danger zones
    if (30.0 <= lat <= 31.0 and 78.0 <= lon <= 80.0) or (11.4 <= lat <= 11.8 and 75.8 <= lon <= 76.4):
        base_risk += 0.25
    return round(min(base_risk, 0.99), 3)


def get_landslide_prediction(
    rainfall_24h: float,
    cumulative_rainfall_7d: float = 0.0,
    slope: float = 35.0,
    elevation: float = 1200.0,
    historical_landslides: int = 1,
) -> dict[str, Any]:
    """
    Full prediction endpoint service used by /disaster/predict/landslide.
    Uses Random Forest joblib model when loaded, otherwise hydrological heuristic.
    """
    if cumulative_rainfall_7d <= 0.0:
        cumulative_rainfall_7d = rainfall_24h * 2.2

    if _model_loaded and _model is not None:
        try:
            features_df = pd.DataFrame([{
                "rainfall_24h": rainfall_24h,
                "cumulative_rainfall_7d": cumulative_rainfall_7d,
                "slope": slope,
                "elevation": elevation,
                "historical_landslides": historical_landslides,
            }])[list(_model_features)]
            pred_label = _model.predict(features_df)[0]
            probs = _model.predict_proba(features_df)[0]
            classes = list(_model_classes)

            if "HIGH" in classes:
                high_idx = classes.index("HIGH")
                high_prob = float(probs[high_idx])
            else:
                high_prob = float(max(probs))

            prob = min(max(high_prob, 0.01), 0.99)
            level = str(pred_label).upper()

            return {
                "risk_level": level,
                "risk_score": round(prob, 2),
                "landslide_probability": round(prob, 4),
                "risk_category": level,
                "model_used": "RandomForest_Landslide_v1",
                "features_used": {
                    "rainfall_24h": rainfall_24h,
                    "slope": slope,
                    "elevation": elevation,
                    "cumulative_rainfall_7d": cumulative_rainfall_7d,
                    "historical_landslides": historical_landslides,
                },
                "disclaimer": "Operational advisory only; verify with local meteorological and disaster authorities."
            }
        except Exception as e:
            logger.warning(f"Model inference failed: {e}. Falling back to heuristic.")

    # ── Calibrated Hydrological Heuristic Engine ──────────────────────────
    slope_factor = min(max((slope - 15.0) / 30.0, 0.0), 1.0)
    rain_factor = min(rainfall_24h / 200.0, 1.0)
    cumulative_factor = min(cumulative_rainfall_7d / 500.0, 1.0) * 0.15
    elevation_factor = min(max((elevation - 800) / 1500.0, 0.0), 1.0) * 0.10
    history_factor = min(historical_landslides * 0.12, 0.25)

    raw_score = (
        (rain_factor * 0.45)
        + (slope_factor * 0.30)
        + cumulative_factor
        + elevation_factor
        + history_factor
    )
    score = min(max(raw_score, 0.05), 0.99)

    if score >= 0.70 or rainfall_24h >= 140:
        level = "HIGH"
    elif score >= 0.40 or rainfall_24h >= 75:
        level = "MEDIUM"
    else:
        level = "LOW"

    return {
        "risk_level": level,
        "risk_score": round(score, 2),
        "landslide_probability": round(score, 4),
        "risk_category": level,
        "model_used": "Hydrological_Heuristic_Engine_v2",
        "features_used": {
            "rainfall_24h": rainfall_24h,
            "slope": slope,
            "elevation": elevation,
            "cumulative_rainfall_7d": cumulative_rainfall_7d,
            "historical_landslides": historical_landslides,
        },
        "disclaimer": "Operational advisory only; verify with local meteorological and disaster authorities."
    }
