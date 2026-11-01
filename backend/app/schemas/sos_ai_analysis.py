from datetime import datetime
import json
from pydantic import BaseModel, ConfigDict, field_validator


class SOSAIAnalysisResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    sos_code: str
    incident_summary: str
    identified_risk_factors: list[str]
    recommended_rescue_actions: list[str]
    required_rescue_resources: list[str]
    suggested_urgency_level: str
    model_used: str = "groq-openai/gpt-oss-120b"
    reviewed_by_human: bool = False
    created_at: datetime | None = None

    @field_validator(
        "identified_risk_factors",
        "recommended_rescue_actions",
        "required_rescue_resources",
        mode="before",
    )
    @classmethod
    def parse_json_lists(cls, v):
        if isinstance(v, str):
            try:
                parsed = json.loads(v)
                if isinstance(parsed, list):
                    return [str(item) for item in parsed]
                return [str(parsed)]
            except Exception:
                return [v] if v else []
        elif isinstance(v, list):
            return [str(item) for item in v]
        return []


