import logging
import os
import redis

logger = logging.getLogger("fireeye.redis")

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

try:
    redis_client = redis.Redis.from_url(
        REDIS_URL,
        decode_responses=True,
        socket_connect_timeout=3,
        socket_timeout=5,
        retry_on_timeout=False,
    )
except Exception as e:
    logger.warning(f"Failed to create Redis client for {REDIS_URL}: {e}")
    redis_client = None
