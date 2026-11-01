
from pathlib import Path
import joblib
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent
model = joblib.load(BASE_DIR / "models" / "risk_model.joblib")

classifier = model.named_steps["classifier"]
preprocessor = model.named_steps["preprocessor"]

feature_names = preprocessor.get_feature_names_out()
importance = classifier.feature_importances_

results = pd.DataFrame({
    "Feature": feature_names,
    "Importance": importance
})

results = results.sort_values(
    by="Importance",
    ascending=False
)

print("\nFIRE EYE - FEATURE IMPORTANCE")
print("=" * 45)

for _, row in results.iterrows():
    print(f"{row['Feature']}: {row['Importance']:.4f}")
