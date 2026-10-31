"""
FIRE-EYE Unified Intelligence Pipeline Service
Directly incorporates fireeye-ai-final/intelligence_pipeline.py into FastAPI backend.
Orchestrates:
1. Environmental Landslide Prediction (Random Forest Pipeline)
2. Continuous Risk Index Mapping
3. Priority Engine Queue Triage Evaluation
4. Graph Shortest Route Optimization with Blocked Road Hazards
"""

from typing import Any
from app.services.ml_service import calculate_risk_score, get_landslide_prediction
from app.services.priority_engine import rank_requests
from app.services.routing_engine import shortest_route


def run_intelligence_pipeline(
    environmental_data: dict[str, Any],
    sos_requests: list[dict[str, Any]],
    road_network: dict[str, dict[str, float]],
    rescue_base: str,
    destination: str,
    blocked_roads: list[tuple[str, str]] | None = None
) -> dict[str, Any]:
    """
    Executes the 4-step FIRE-EYE Unified Intelligence Pipeline.
    """
    # STEP 1: Predict environmental risk
    risk_assessment = get_landslide_prediction(
        rainfall_mm=environmental_data.get("rainfall_mm"),
        slope_degrees=environmental_data.get("slope_degrees"),
        elevation_m=environmental_data.get("elevation_m"),
        soil_type=environmental_data.get("soil_type"),
        rainfall_24h=environmental_data.get("rainfall_24h"),
        slope=environmental_data.get("slope"),
        elevation=environmental_data.get("elevation"),
    )

    # Convert model probabilities into continuous risk index (0-100 scale for priority engine)
    risk_score_normalized = calculate_risk_score(risk_assessment)
    risk_score_100 = round(risk_score_normalized * 100.0, 2)

    # STEP 2: Apply dynamic environmental risk to SOS requests
    updated_requests = []
    for request in sos_requests:
        updated = request.copy()
        if "risk" not in updated or updated["risk"] is None:
            updated["risk"] = risk_score_100
        updated_requests.append(updated)

    # Rank SOS requests with priority weights
    ranked_requests = rank_requests(updated_requests)

    # STEP 3: Find rescue evacuation route
    route_plan = shortest_route(
        graph=road_network,
        start=rescue_base,
        destination=destination,
        blocked_roads=blocked_roads,
    )

    # STEP 4: Return full intelligence output
    return {
        "risk_assessment": risk_assessment,
        "risk_score_used_for_priority": risk_score_100,
        "ranked_rescue_requests": ranked_requests,
        "route_plan": route_plan,
    }

