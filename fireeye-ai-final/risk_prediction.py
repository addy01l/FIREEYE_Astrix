from pathlib import Path
import joblib
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "models" / "risk_model.joblib"

model = joblib.load(MODEL_PATH)

VALID_SOILS = ["Clay", "Silty", "Loamy", "Sandy", "Rocky"]


def predict_risk(rainfall_mm, slope_degrees, elevation_m, soil_type):

    values = [rainfall_mm, slope_degrees, elevation_m]

    if any(
        isinstance(v, bool) or not isinstance(v, (int, float))
        for v in values
    ):
        raise ValueError("Environmental inputs must be numeric")

    if not 0 <= rainfall_mm <= 350:
        raise ValueError("Rainfall must be between 0 and 350 mm")

    if not 2 <= slope_degrees <= 60:
        raise ValueError("Slope must be between 2 and 60 degrees")

    if not 200 <= elevation_m <= 4000:
        raise ValueError("Elevation must be between 200 and 4000 metres")

    if soil_type not in VALID_SOILS:
        raise ValueError("Invalid soil type")

    input_data = pd.DataFrame([{
        "rainfall_mm": rainfall_mm,
        "slope_degrees": slope_degrees,
        "elevation_m": elevation_m,
        "soil_type": soil_type
    }])

    prediction = model.predict(input_data)[0]

    probabilities = model.predict_proba(input_data)[0]

    class_probabilities = {
        str(label): round(float(prob) * 100, 2)
        for label, prob in zip(model.classes_, probabilities)
    }

    return {
        "risk_level": str(prediction),
        "class_probabilities": class_probabilities
    }


if __name__ == "__main__":

    result = predict_risk(
        rainfall_mm=300,
        slope_degrees=50,
        elevation_m=1800,
        soil_type="Clay"
    )

    print("\nFIRE EYE - LANDSLIDE RISK PREDICTION")
    print("=" * 45)

    print("Input: 300 mm rainfall, 50 degree slope")
    print("Elevation: 1800 metres")
    print("Soil: Clay")

    print("\nPredicted Risk:", result["risk_level"])
    print("Class probabilities:", result["class_probabilities"])
