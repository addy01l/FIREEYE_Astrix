from pydantic import BaseModel


class MeshPayload(BaseModel):
    vulnerabilities: list[str] | None = []
    people_count: int | None = 1
    battery_level: int | None = 100


class MeshPacket(BaseModel):
    message_id: str
    sender_id: str
    type: str = "SOS"
    household_id: str | None = None
    latitude: float
    longitude: float
    severity: str = "CRITICAL"
    timestamp: int
    ttl: int = 8
    hops: list[str] = []
    payload: MeshPayload | None = None


class MeshPacketAck(BaseModel):
    status: str
    message_id: str
    action_taken: str
    associated_sos_code: str | None = None
