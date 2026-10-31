
import numpy as np
import pandas as pd
from pathlib import Path

# Reproducible synthetic dataset
np.random.seed(42)

SAMPLES = 2000

# Generate environmental features
rainfall = np.random.gamma(
    shape=2.2, scale=65, size=SAMPLES
).clip(0, 350).round(2)

slope = np.random.uniform(
    2, 60, SAMPLES
).round(2)

elevation = np.random.uniform(
    200, 4000, SAMPLES
).round(2)

soil_types = np.random.choice(
    ["Clay", "Silty", "Loamy", "Sandy", "Rocky"],
    size=SAMPLES,
    p=[0.25, 0.20, 0.25, 0.20, 0.10]
)

# Illustrative synthetic soil susceptibility factors
soil_factor_map = {
    "Clay": 0.12,
    "Silty": 0.10,
    "Loamy": 0.08,
    "Sandy": 0.06,
    "Rocky": 0.02
}

soil_factor = np.array([
    soil_factor_map[soil] for soil in soil_types
])

# Illustrative elevation context assumption
elevation_factor = np.where(
    (elevation >= 1200) & (elevation <= 2800),
    0.04,
    0.0
)

# Synthetic risk score
risk_score = (
    (rainfall / 350) * 0.48
    + (slope / 60) * 0.38
    + soil_factor
    + elevation_factor
    + np.random.normal(0, 0.045, SAMPLES)
)

# Assign risk categories
risk_level = np.where(
    risk_score < 0.38,
    "LOW",
    np.where(risk_score < 0.68, "MEDIUM", "HIGH")
)

# Create dataset
df = pd.DataFrame({
    "rainfall_mm": rainfall,
    "slope_degrees": slope,
    "elevation_m": elevation,
    "soil_type": soil_types,
    "risk_level": risk_level
})

# Save CSV
output_dir = Path("data")
output_dir.mkdir(exist_ok=True)

file_path = output_dir / "synthetic_landslide_data.csv"
df.to_csv(file_path, index=False)

# Dataset verification
print("\nFIRE EYE - SYNTHETIC DATASET")
print("=" * 45)

print("Total samples:", len(df))
print("Total features:", 4)
print("Target column: risk_level")
print("Saved at:", file_path)

print("\nRisk category distribution:")
print(df["risk_level"].value_counts())

print("\nSample records:")
print(df.head())

print("\nMissing values:")
print(df.isnull().sum())
