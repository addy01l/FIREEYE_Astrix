
from risk_prediction import predict_risk


print("\nFIRE EYE - RISK MODEL EDGE TESTS")
print("=" * 50)


# TEST 1: Negative rainfall

try:
    predict_risk(-20, 30, 1800, "Clay")
except ValueError as error:
    print("\nTEST 1 - Negative Rainfall: PASSED")
    print(error)


# TEST 2: Invalid slope

try:
    predict_risk(100, 90, 1800, "Clay")
except ValueError as error:
    print("\nTEST 2 - Invalid Slope: PASSED")
    print(error)


# TEST 3: Invalid soil type

try:
    predict_risk(100, 30, 1800, "Unknown")
except ValueError as error:
    print("\nTEST 3 - Invalid Soil: PASSED")
    print(error)


# TEST 4: Valid boundary values

try:
    result = predict_risk(0, 2, 200, "Rocky")

    print("\nTEST 4 - Valid Boundary Input: PASSED")
    print("Prediction:", result["risk_level"])

except ValueError as error:
    print("\nTEST 4 - FAILED")
    print(error)


print("\nRISK MODEL EDGE TESTING COMPLETED")
