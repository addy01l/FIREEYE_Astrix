import os
import sys

_CACHED_MODEL = None
_CACHED_FEATURES = None

def _load_model_once():
    global _CACHED_MODEL, _CACHED_FEATURES
    if _CACHED_MODEL is not None:
        return True
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(base_dir, "models", "landslide_model.joblib")
    
    if os.path.exists(model_path):
        try:
            import joblib
            payload = joblib.load(model_path)
            _CACHED_MODEL = payload["model"]
            _CACHED_FEATURES = payload["features"]
            return True
        except Exception:
            pass
    return False

def predict_landslide_risk(
    rainfall_24h: float,
    cumulative_rainfall_7d: float = 0.0,
    slope: float = 30.0,
    elevation: float = 1000.0,
    historical_landslides: int = 1
) -> dict:
    # If cumulative rainfall not provided, approximate from 24h
    if cumulative_rainfall_7d <= 0.0:
        cumulative_rainfall_7d = rainfall_24h * 2.2

    # Attempt to use trained ML model if available
    if _load_model_once():
        try:
            import pandas as pd
            model = _CACHED_MODEL
            features = _CACHED_FEATURES

            df_input = pd.DataFrame([{
                "rainfall_24h": rainfall_24h,
                "cumulative_rainfall_7d": cumulative_rainfall_7d,
                "slope": slope,
                "elevation": elevation,
                "historical_landslides": historical_landslides
            }])[features]

            pred_label = model.predict(df_input)[0]
            probs = model.predict_proba(df_input)[0]
            class_idx = list(model.classes_).index(pred_label)
            prob_score = float(probs[class_idx])

            # Compute standardized continuous hazard score (0.0 to 1.0)
            if "HIGH" in model.classes_:
                high_idx = list(model.classes_).index("HIGH")
                hazard_score = float(probs[high_idx])
            else:
                hazard_score = prob_score

            return {
                "risk_level": pred_label,
                "risk_score": round(max(hazard_score, 0.05), 2),
                "model_used": "RandomForest_joblib"
            }
        except Exception as e:
            pass

    # Heuristic algorithm matching physical hydrological landslide threshold
    # Formula: Intensity-Duration rainfall threshold + slope factor
    slope_factor = min(max((slope - 15.0) / 30.0, 0.0), 1.0)
    rain_factor = min(rainfall_24h / 200.0, 1.0)
    history_factor = min(historical_landslides * 0.15, 0.3)
    
    raw_score = (rain_factor * 0.55) + (slope_factor * 0.35) + history_factor
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
        "model_used": "Hydrological_Heuristic_Engine"
    }

if __name__ == "__main__":
    rain = float(sys.argv[1]) if len(sys.argv) > 1 else 185.0
    slope_val = float(sys.argv[2]) if len(sys.argv) > 2 else 38.0
    result = predict_landslide_risk(rainfall_24h=rain, slope=slope_val)
    print("Inference Result:", result)
