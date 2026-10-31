from app.database import get_db
from app.schemas.priority import PriorityQueueResponse
from app.services.priority_engine import compute_ranked_rescue_queue
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

router = APIRouter()


@router.get("/queue", response_model=PriorityQueueResponse)
def get_priority_queue(db: Session = Depends(get_db)):
    ranked_items = compute_ranked_rescue_queue(db)
    return {"total_active_sos": len(ranked_items), "queue": ranked_items}
