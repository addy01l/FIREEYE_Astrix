"""
FIRE-EYE ML Risk Prediction Service
Integrates the fireeye-ai-final Scikit-learn Pipeline (OneHotEncoder + RandomForestClassifier).
Evaluates categorical soil susceptibility, slope degrees, elevation, and rainfall.
Includes input range validation, calibrated risk scoring, and operational fallback.
"""

import logging
import os
from typing import Any
import pandas as pd

logger = logging.getLogger("fire-eye.ml")

# ── Model Singleton ──────────────────────────────────────────────────────────
_model = None
_model_loaded = False

VALID_SOILS = ["Clay", "Silty", "Loamy", "Sandy", "Rocky"]
DEFAULT_SOIL = "Loamy"

RISK_VALUES = {
    "LOW": 20,
    "MEDIUM": 60,
    "HIGH": 90
}


def load_model_at_startup():
    """Call once from FastAPI lifespan/startup to warm the model into RAM."""
    global _model, _model_loaded

    candidate_paths = [
        os.getenv("ML_MODEL_PATH", ""),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "fireeye-ai-final", "models", "risk_model.joblib")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "ml", "models", "risk_model.joblib")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "ml", "models", "risk_model.joblib")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "ml", "models", "landslide_model.joblib")),
    ]

    model_path = next((p for p in candidate_paths if p and os.path.exists(p)), None)

    if model_path:
        try:
            import joblib

            loaded = joblib.load(model_path)
            if isinstance(loaded, dict) and "model" in loaded:
                _model = loaded["model"]
            else:
                _model = loaded

            _model_loaded = True
            logger.info(f"FIRE-EYE ML Risk model loaded from {model_path}")
        except Exception as e:
            logger.warning(f"Failed to load ML model ({e}). Using calibrated hydrological heuristic.")
            _model_loaded = False
    else:
        logger.info("No model file found at candidate paths. Using calibrated hydrological heuristic.")
        _model_loaded = False


def calculate_risk_score(risk_assessment: dict[str, Any]) -> float:
    """
    Computes continuous risk index (0.0 to 1.0) from class probabilities:
    Score = (P(LOW)*20 + P(MEDIUM)*60 + P(HIGH)*90) / 100
    """
    probabilities = risk_assessment.get("class_probabilities", {})
    if not probabilities:
        return 0.5

    score = sum(
        probabilities.get(level, 0.0) * RISK_VALUES.get(level, 50)
        for level in RISK_VALUES
    ) / 100.0

    return round(score / 100.0, 2)  # Normalized 0.0 to 1.0


def validate_environmental_inputs(
    rainfall_mm: float,
    slope_degrees: float,
    elevation_m: float,
    soil_type: str
):
    """Validate numerical and categorical input constraints."""
    values = [rainfall_mm, slope_degrees, elevation_m]
    if any(isinstance(v, bool) or not isinstance(v, (int, float)) for v in values):
        raise ValueError("Environmental inputs must be numeric")

    if not 0 <= rainfall_mm <= 350:
        raise ValueError("Rainfall must be between 0 and 350 mm")

    if not 2 <= slope_degrees <= 60:
        raise ValueError("Slope must be between 2 and 60 degrees")

    if not 200 <= elevation_m <= 4000:
        raise ValueError("Elevation must be between 200 and 4000 metres")

    if soil_type not in VALID_SOILS:
        raise ValueError(f"Invalid soil type: '{soil_type}'. Valid: {VALID_SOILS}")


def get_landslide_prediction(
    rainfall_24h: float | None = None,
    slope: float | None = None,
    elevation: float | None = None,
    soil_type: str | None = None,
    rainfall_mm: float | None = None,
    slope_degrees: float | None = None,
    elevation_m: float | None = None,
    cumulative_rainfall_7d: float | None = None,
    historical_disasters: int | None = None,
) -> dict[str, Any]:
    """
    Full prediction endpoint service matching fireeye-ai-final specification.
    Supports both new naming (rainfall_mm, slope_degrees, elevation_m, soil_type)
    and legacy aliases (rainfall_24h, slope, elevation).
    """
    rain = float(rainfall_mm if rainfall_mm is not None else (rainfall_24h if rainfall_24h is not None else 100.0))
    slp = float(slope_degrees if slope_degrees is not None else (slope if slope is not None else 35.0))
    elev = float(elevation_m if elevation_m is not None else (elevation if elevation is not None else 1200.0))
    
    # Capitalize / normalize soil type
    raw_soil = (soil_type or DEFAULT_SOIL).strip().capitalize()
    soil = raw_soil if raw_soil in VALID_SOILS else DEFAULT_SOIL

    # Input validation (clamps if slightly outside for robustness or raises)
    try:
        validate_environmental_inputs(rain, slp, elev, soil)
    except ValueError as e:
        logger.warning(f"Validation warning: {e}. Clamping to boundary limits.")
        rain = max(0.0, min(rain, 350.0))
        slp = max(2.0, min(slp, 60.0))
        elev = max(200.0, min(elev, 4000.0))

    if _model_loaded and _model is not None:
        try:
            input_df = pd.DataFrame([{
                "rainfall_mm": rain,
                "slope_degrees": slp,
                "elevation_m": elev,
                "soil_type": soil
            }])

            prediction = str(_model.predict(input_df)[0])
            probabilities = _model.predict_proba(input_df)[0]
            classes = list(_model.classes_)

            class_probabilities = {
                str(label): round(float(prob) * 100, 2)
                for label, prob in zip(classes, probabilities)
            }

            risk_assessment = {
                "risk_level": prediction,
                "class_probabilities": class_probabilities
            }
            computed_score = calculate_risk_score(risk_assessment)

            return {
                "risk_level": prediction,
                "risk_score": computed_score,
                "landslide_probability": round(float(class_probabilities.get("HIGH", 0.0) / 100.0), 4),
                "risk_category": prediction,
                "class_probabilities": class_probabilities,
                "model_used": "FIRE_EYE_RandomForest_v2",
                "features_used": {
                    "rainfall_mm": rain,
                    "slope_degrees": slp,
                    "elevation_m": elev,
                    "soil_type": soil,
                },
                "disclaimer": "Operational advisory only; verify with local meteorological and disaster authorities."
            }
        except Exception as e:
            logger.warning(f"Model prediction failed ({e}). Falling back to heuristic.")

    # ── Hydrological Heuristic Fallback ──────────────────────────────────
    soil_factor_map = {"Clay": 0.12, "Silty": 0.10, "Loamy": 0.08, "Sandy": 0.06, "Rocky": 0.02}
    soil_factor = soil_factor_map.get(soil, 0.08)
    elev_factor = 0.04 if (1200 <= elev <= 2800) else 0.0

    raw_score = ((rain / 350.0) * 0.48) + ((slp / 60.0) * 0.38) + soil_factor + elev_factor
    score = min(max(raw_score, 0.05), 0.99)

    if score >= 0.68:
        level = "HIGH"
        class_probs = {"HIGH": round(score * 100, 2), "MEDIUM": round((1 - score) * 70, 2), "LOW": round((1 - score) * 30, 2)}
    elif score >= 0.38:
        level = "MEDIUM"
        class_probs = {"HIGH": 20.0, "MEDIUM": 65.0, "LOW": 15.0}
    else:
        level = "LOW"
        class_probs = {"HIGH": 5.0, "MEDIUM": 20.0, "LOW": 75.0}

    return {
        "risk_level": level,
        "risk_score": round(score, 2),
        "landslide_probability": round(float(class_probs.get("HIGH", 0.0) / 100.0), 4),
        "risk_category": level,
        "class_probabilities": class_probs,
        "model_used": "Hydrological_Heuristic_Engine_v2",
        "features_used": {
            "rainfall_mm": rain,
            "slope_degrees": slp,
            "elevation_m": elev,
            "soil_type": soil,
        },
        "disclaimer": "Operational advisory only; verify with local meteorological and disaster authorities."
    }


def predict_risk_at_location(
    lat: float,
    lon: float,
    rainfall_24h: float = 100.0,
    slope: float = 35.0,
    elevation: float = 1200.0,
    soil_type: str = "Clay"
) -> float:
    """Convenience helper returning continuous risk score (0.0 to 1.0) for a coordinate."""
    res = get_landslide_prediction(
        rainfall_mm=rainfall_24h,
        slope_degrees=slope,
        elevation_m=elevation,
        soil_type=soil_type,
    )
    return res["risk_score"]
