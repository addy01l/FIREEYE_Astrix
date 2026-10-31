
import json

from risk_prediction import predict_risk
from priority_engine import rank_requests
from route_optimizer import shortest_route


RISK_VALUES = {
    "LOW": 20,
    "MEDIUM": 60,
    "HIGH": 90
}


def calculate_risk_score(risk_assessment):

    probabilities = risk_assessment["class_probabilities"]

    score = sum(
        probabilities[level] * RISK_VALUES[level]
        for level in RISK_VALUES
    ) / 100

    return round(score, 2)


def run_intelligence_pipeline(
    environmental_data,
    sos_requests,
    road_network,
    rescue_base,
    destination,
    blocked_roads=None
):

    # STEP 1: Predict environmental risk

    risk_assessment = predict_risk(
        rainfall_mm=environmental_data["rainfall_mm"],
        slope_degrees=environmental_data["slope_degrees"],
        elevation_m=environmental_data["elevation_m"],
        soil_type=environmental_data["soil_type"]
    )

    # Convert model probabilities into a risk index

    risk_score = calculate_risk_score(risk_assessment)

    # STEP 2: Apply area risk to SOS requests

    updated_requests = []

    for request in sos_requests:

        updated_request = request.copy()
        updated_request["risk"] = risk_score

        updated_requests.append(updated_request)

    # Rank SOS requests

    ranked_requests = rank_requests(updated_requests)

    # STEP 3: Find rescue route

    route_plan = shortest_route(
        graph=road_network,
        start=rescue_base,
        destination=destination,
        blocked_roads=blocked_roads
    )

    # STEP 4: Prepare final output

    return {
        "risk_assessment": risk_assessment,
        "risk_score_used_for_priority": risk_score,
        "ranked_rescue_requests": ranked_requests,
        "route_plan": route_plan
    }


if __name__ == "__main__":

    environmental_data = {
        "rainfall_mm": 300,
        "slope_degrees": 50,
        "elevation_m": 1800,
        "soil_type": "Clay"
    }

    sos_requests = [
        {
            "id": "SOS-001",
            "severity": 90,
            "vulnerability": 100,
            "isolation": 80
        },
        {
            "id": "SOS-002",
            "severity": 60,
            "vulnerability": 50,
            "isolation": 40
        },
        {
            "id": "SOS-003",
            "severity": 20,
            "vulnerability": 30,
            "isolation": 20
        }
    ]

    road_network = {
        "Rescue_Base": {
            "Village_A": 4,
            "Village_B": 2
        },
        "Village_A": {
            "Rescue_Base": 4,
            "Village_B": 1,
            "Village_C": 5
        },
        "Village_B": {
            "Rescue_Base": 2,
            "Village_A": 1,
            "Village_C": 8,
            "Village_D": 10
        },
        "Village_C": {
            "Village_A": 5,
            "Village_B": 8,
            "Village_D": 2,
            "Hospital": 9
        },
        "Village_D": {
            "Village_B": 10,
            "Village_C": 2,
            "Hospital": 3
        },
        "Hospital": {
            "Village_C": 9,
            "Village_D": 3
        }
    }

    result = run_intelligence_pipeline(
        environmental_data=environmental_data,
        sos_requests=sos_requests,
        road_network=road_network,
        rescue_base="Rescue_Base",
        destination="Hospital",
        blocked_roads=[("Village_C", "Village_D")]
    )

    print("\nFIRE EYE - COMPLETE INTELLIGENCE PIPELINE")
    print("=" * 55)

    print(json.dumps(result, indent=4))
