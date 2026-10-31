import logging
import sys
from typing import Any
from datetime import datetime


def setup_logging():
    """Configure structured logging for FIRE-EYE."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        handlers=[
            logging.StreamHandler(sys.stdout),
        ],
    )


logger = logging.getLogger("fire-eye")

