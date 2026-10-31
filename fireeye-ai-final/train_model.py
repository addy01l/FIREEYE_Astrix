
import pandas as pd
import joblib

from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    balanced_accuracy_score,
    classification_report,
    confusion_matrix
)

# Load dataset
df = pd.read_csv("data/synthetic_landslide_data.csv")

# Separate features and target
X = df.drop("risk_level", axis=1)
y = df["risk_level"]

numeric_features = [
    "rainfall_mm",
    "slope_degrees",
    "elevation_m"
]

categorical_features = ["soil_type"]

# Encode categorical soil data
preprocessor = ColumnTransformer(
    transformers=[
        ("soil", OneHotEncoder(handle_unknown="ignore"),
         categorical_features)
    ],
    remainder="passthrough"
)

# Random Forest classifier
rf = RandomForestClassifier(
    n_estimators=200,
    random_state=42,
    class_weight="balanced_subsample",
    min_samples_leaf=2,
    n_jobs=-1
)

# Complete ML pipeline
model = Pipeline([
    ("preprocessor", preprocessor),
    ("classifier", rf)
])

# Split dataset
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.20,
    random_state=42,
    stratify=y
)

# Train model
print("\nTraining Random Forest...")
model.fit(X_train, y_train)

# Predictions
y_pred = model.predict(X_test)

# Evaluation
print("\nFIRE EYE - MODEL EVALUATION")
print("=" * 50)

print("Training samples:", len(X_train))
print("Testing samples:", len(X_test))

print("\nAccuracy:", round(accuracy_score(y_test, y_pred), 4))
print("Balanced Accuracy:", round(
    balanced_accuracy_score(y_test, y_pred), 4
))

print("\nClassification Report:")
print(classification_report(y_test, y_pred, zero_division=0))

labels = ["HIGH", "LOW", "MEDIUM"]

print("Confusion Matrix:")
print(confusion_matrix(y_test, y_pred, labels=labels))

# Save model
Path("models").mkdir(exist_ok=True)

joblib.dump(model, "models/risk_model.joblib")

print("\nModel saved successfully!")
print("Location: models/risk_model.joblib")
