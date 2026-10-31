import logging
import os
from pathlib import Path
from dotenv import load_dotenv
import redis

# Explicitly ensure backend .env is loaded
env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

logger = logging.getLogger("fireeye.redis")

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")


def _sanitize_url(url: str) -> str:
    """Mask credentials for safe logging."""
    if "@" in url:
        prefix = url.split("://")[0]
        host = url.split("@")[-1]
        return f"{prefix}://***@{host}"
    return url


def create_resilient_redis():
    """Connect to Redis with automatic TLS support for Upstash."""
    global REDIS_URL
    url = REDIS_URL.strip()
    if not url:
        return None

    # Automatically handle Upstash TLS requirements
    if "upstash.io" in url and url.startswith("redis://"):
        url = url.replace("redis://", "rediss://", 1)

    connect_args = {
        "decode_responses": True,
        "socket_connect_timeout": 5,
        "socket_timeout": 5,
        "retry_on_timeout": True,
    }

    if url.startswith("rediss://") or "upstash.io" in url:
        connect_args["ssl_cert_reqs"] = None

    try:
        client = redis.Redis.from_url(url, **connect_args)
        client.ping()
        logger.info(f"[FIRE-EYE REDIS] Connected to Redis at {_sanitize_url(url)}")
        print(f"[FIRE-EYE REDIS] Connected to Redis at {_sanitize_url(url)}")
        return client
    except Exception as exc:
        logger.warning(
            f"[FIRE-EYE REDIS WARNING] Redis connection to {_sanitize_url(url)} failed: {exc}. "
            f"Operating with resilient in-memory fallback."
        )
        print(
            f"[FIRE-EYE REDIS WARNING] Redis connection to {_sanitize_url(url)} failed: {exc}. "
            f"Operating with resilient in-memory fallback."
        )
        return None


redis_client = create_resilient_redis()
