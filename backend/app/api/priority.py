from app.database import get_db
from app.schemas.priority import PriorityQueueResponse
from app.services.priority_engine import compute_ranked_rescue_queue
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.permissions import UserRole, require_roles
from app.models.user import User

router = APIRouter()


@router.get("/queue", response_model=PriorityQueueResponse)
def get_priority_queue(
    current_user: User = Depends(require_roles([UserRole.RESCUE, UserRole.ADMIN])),
    db: Session = Depends(get_db),
):
    ranked_items = compute_ranked_rescue_queue(db)
    return {"total_active_sos": len(ranked_items), "queue": ranked_items}
