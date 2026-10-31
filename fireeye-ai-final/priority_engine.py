
import json
import math


WEIGHTS = {
    "severity": 0.40,
    "vulnerability": 0.30,
    "risk": 0.20,
    "isolation": 0.10
}


def validate_sos(sos):

    if not isinstance(sos, dict):
        raise ValueError("Each SOS request must be a dictionary")

    required_fields = [
        "id",
        "severity",
        "vulnerability",
        "risk",
        "isolation"
    ]

    for field in required_fields:
        if field not in sos:
            raise ValueError(f"Missing required field: {field}")

    if not isinstance(sos["id"], str) or not sos["id"].strip():
        raise ValueError("SOS ID must be a non-empty string")

    for field in ["severity", "vulnerability", "risk", "isolation"]:

        value = sos[field]

        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError(f"{field} must be numeric")

        if not math.isfinite(value) or not 0 <= value <= 100:
            raise ValueError(f"{field} must be between 0 and 100")


def calculate_priority(sos):

    validate_sos(sos)

    breakdown = {}

    for factor, weight in WEIGHTS.items():
        breakdown[factor] = round(sos[factor] * weight, 2)

    score = round(sum(breakdown.values()), 2)

    if score >= 75:
        level = "HIGH"
    elif score >= 40:
        level = "MEDIUM"
    else:
        level = "LOW"

    return {
        "id": sos["id"],
        "priority_score": score,
        "priority_level": level,
        "breakdown": breakdown
    }


def rank_requests(requests):

    if not isinstance(requests, list) or not requests:
        raise ValueError("SOS requests must be a non-empty list")

    results = []
    seen_ids = set()

    for sos in requests:

        result = calculate_priority(sos)

        if result["id"] in seen_ids:
            raise ValueError(f"Duplicate SOS ID: {result['id']}")

        seen_ids.add(result["id"])
        results.append(result)

    results.sort(
        key=lambda item: (-item["priority_score"], item["id"])
    )

    for rank, result in enumerate(results, start=1):
        result["rank"] = rank

    return results


def process_priority_json(payload):

    try:
        requests = json.loads(payload)

        results = rank_requests(requests)

        return json.dumps({
            "success": True,
            "total_requests": len(results),
            "ranked_requests": results
        }, indent=4)

    except (ValueError, TypeError, json.JSONDecodeError) as error:

        return json.dumps({
            "success": False,
            "error": str(error)
        }, indent=4)


if __name__ == "__main__":

    sample_requests = [
        {
            "id": "SOS-001",
            "severity": 90,
            "vulnerability": 100,
            "risk": 90,
            "isolation": 80
        },
        {
            "id": "SOS-002",
            "severity": 60,
            "vulnerability": 50,
            "risk": 70,
            "isolation": 40
        },
        {
            "id": "SOS-003",
            "severity": 20,
            "vulnerability": 30,
            "risk": 10,
            "isolation": 20
        }
    ]

    print("\nFIRE EYE - RESCUE PRIORITY ENGINE")
    print("=" * 45)

    output = rank_requests(sample_requests)

    print(json.dumps(output, indent=4))
