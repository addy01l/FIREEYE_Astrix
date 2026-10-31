
from priority_engine import calculate_priority, rank_requests


print("\nFIRE EYE - PRIORITY ENGINE EDGE TESTS")
print("=" * 50)


# TEST 1: Missing SOS field

try:
    calculate_priority({
        "id": "SOS-101",
        "severity": 90,
        "vulnerability": 80,
        "risk": 70
    })
except ValueError as error:
    print("\nTEST 1 - Missing Field: PASSED")
    print(error)


# TEST 2: Invalid severity value

try:
    calculate_priority({
        "id": "SOS-102",
        "severity": 150,
        "vulnerability": 80,
        "risk": 70,
        "isolation": 50
    })
except ValueError as error:
    print("\nTEST 2 - Invalid Score: PASSED")
    print(error)


# TEST 3: Duplicate SOS IDs

try:
    rank_requests([
        {
            "id": "SOS-103",
            "severity": 90,
            "vulnerability": 80,
            "risk": 70,
            "isolation": 50
        },
        {
            "id": "SOS-103",
            "severity": 60,
            "vulnerability": 50,
            "risk": 40,
            "isolation": 30
        }
    ])
except ValueError as error:
    print("\nTEST 3 - Duplicate ID: PASSED")
    print(error)


# TEST 4: Equal priority scores

result = rank_requests([
    {
        "id": "SOS-105",
        "severity": 80,
        "vulnerability": 80,
        "risk": 80,
        "isolation": 80
    },
    {
        "id": "SOS-104",
        "severity": 80,
        "vulnerability": 80,
        "risk": 80,
        "isolation": 80
    }
])

print("\nTEST 4 - Equal Scores:")

for request in result:
    print(request["id"], request["priority_score"], "Rank:", request["rank"])


print("\nPRIORITY EDGE TESTING COMPLETED")
