import os
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
import joblib

def train_model():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    data_path = os.path.join(base_dir, "dataset", "landslide_data.csv")
    models_dir = os.path.join(base_dir, "models")
    os.makedirs(models_dir, exist_ok=True)
    model_output_path = os.path.join(models_dir, "landslide_model.joblib")

    print(f"Loading training data from: {data_path}")
    df = pd.read_csv(data_path)

    features = ["rainfall_24h", "cumulative_rainfall_7d", "slope", "elevation", "historical_landslides"]
    X = df[features]
    y = df["risk_label"]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.25, random_state=42)

    print("Training Random Forest Classifier for Landslide Hazard Prediction...")
    clf = RandomForestClassifier(n_estimators=50, max_depth=5, random_state=42)
    clf.fit(X_train, y_train)

    train_acc = accuracy_score(y_train, clf.predict(X_train))
    test_acc = accuracy_score(y_test, clf.predict(X_test))
    print(f"Train Accuracy: {train_acc * 100:.2f}% | Test Accuracy: {test_acc * 100:.2f}%")

    model_payload = {
        "model": clf,
        "features": features,
        "classes": clf.classes_.tolist()
    }

    joblib.dump(model_payload, model_output_path)
    print(f"Model successfully saved to {model_output_path}")

if __name__ == "__main__":
    train_model()
