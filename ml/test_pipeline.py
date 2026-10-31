
from intelligence_pipeline import run_intelligence_pipeline


environment = {
    "rainfall_mm": 300,
    "slope_degrees": 50,
    "elevation_m": 1800,
    "soil_type": "Clay"
}

sos_requests = [
    {
        "id": "SOS-201",
        "severity": 90,
        "vulnerability": 100,
        "isolation": 80
    },
    {
        "id": "SOS-202",
        "severity": 60,
        "vulnerability": 50,
        "isolation": 40
    }
]

graph = {
    "Base": {"Village": 5},
    "Village": {"Base": 5, "Hospital": 4},
    "Hospital": {"Village": 4}
}


print("\nFIRE EYE - INTEGRATION EDGE TESTS")
print("=" * 50)


# TEST 1: Invalid environmental input

try:
    invalid_environment = environment.copy()
    invalid_environment["rainfall_mm"] = -50

    run_intelligence_pipeline(
        invalid_environment,
        sos_requests,
        graph,
        "Base",
        "Hospital"
    )

except ValueError:
    print("\nTEST 1 - Invalid Environment: PASSED")


# TEST 2: Duplicate SOS IDs

try:
    duplicate_requests = [
        sos_requests[0],
        sos_requests[0].copy()
    ]

    run_intelligence_pipeline(
        environment,
        duplicate_requests,
        graph,
        "Base",
        "Hospital"
    )

except ValueError:
    print("\nTEST 2 - Duplicate SOS: PASSED")


# TEST 3: No available rescue route

result = run_intelligence_pipeline(
    environment,
    sos_requests,
    graph,
    "Base",
    "Hospital",
    blocked_roads=[("Base", "Village")]
)

if not result["route_plan"]["success"]:
    print("\nTEST 3 - No Available Route: PASSED")


print("\nINTEGRATION EDGE TESTING COMPLETED")
