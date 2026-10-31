
from risk_prediction import predict_risk

scenarios = [
    {
        "name": "LOW RISK SCENARIO",
        "rainfall": 10,
        "slope": 5,
        "elevation": 500,
        "soil": "Rocky"
    },
    {
        "name": "MEDIUM RISK SCENARIO",
        "rainfall": 150,
        "slope": 30,
        "elevation": 1800,
        "soil": "Loamy"
    },
    {
        "name": "HIGH RISK SCENARIO",
        "rainfall": 300,
        "slope": 50,
        "elevation": 1800,
        "soil": "Clay"
    }
]

print("\nFIRE EYE - MULTIPLE RISK SCENARIOS")
print("=" * 50)

for scenario in scenarios:

    result = predict_risk(
        rainfall_mm=scenario["rainfall"],
        slope_degrees=scenario["slope"],
        elevation_m=scenario["elevation"],
        soil_type=scenario["soil"]
    )

    print("\n", scenario["name"])
    print("Rainfall:", scenario["rainfall"])
    print("Slope:", scenario["slope"])
    print("Elevation:", scenario["elevation"])
    print("Soil:", scenario["soil"])
    print("Predicted Risk:", result["risk_level"])
    print("Probabilities:", result["class_probabilities"])
