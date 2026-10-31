"""
FIRE-EYE WebSocket Connection Manager v2.0
Production-grade: heartbeat, Redis Pub/Sub fan-out, graceful disconnect.
"""

import asyncio
import json
import logging
from datetime import datetime

from fastapi import WebSocket

logger = logging.getLogger("fire-eye.ws")


class ConnectionManager:
    """Manages WebSocket connections with heartbeat and Redis Pub/Sub bridging."""

    def __init__(self):
        self.active_connections: list[WebSocket] = []
        self._heartbeat_task = None
        self._pubsub_task = None

    async def connect(self, websocket: WebSocket):
        """Accept and register a new WebSocket client."""
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"WS client connected. Total: {len(self.active_connections)}")

        # Send initial handshake
        await websocket.send_text(
            json.dumps(
                {
                    "event": "CONNECTED",
                    "data": {
                        "server_time": datetime.utcnow().isoformat(),
                        "total_clients": len(self.active_connections),
                    },
                }
            )
        )

    def disconnect(self, websocket: WebSocket):
        """Remove a disconnected client."""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        logger.info(f"WS client disconnected. Total: {len(self.active_connections)}")

    async def broadcast(self, event_type: str, payload: dict):
        """Push an event to all connected clients. Prunes dead connections."""
        if not self.active_connections:
            return

        message = json.dumps(
            {
                "event": event_type,
                "data": payload,
                "timestamp": datetime.utcnow().isoformat(),
            }
        )

        stale = []
        for conn in self.active_connections:
            try:
                await conn.send_text(message)
            except Exception:
                stale.append(conn)

        # Clean up dead connections
        for dead in stale:
            self.disconnect(dead)

        if stale:
            logger.info(f"Pruned {len(stale)} stale WS connections.")

    async def send_to_client(
        self, websocket: WebSocket, event_type: str, payload: dict
    ):
        """Send a message to a single client."""
        try:
            await websocket.send_text(
                json.dumps(
                    {
                        "event": event_type,
                        "data": payload,
                        "timestamp": datetime.utcnow().isoformat(),
                    }
                )
            )
        except Exception:
            self.disconnect(websocket)

    async def start_heartbeat(self, interval_seconds: int = 30):
        """Background task: sends PING to all clients periodically."""
        while True:
            await asyncio.sleep(interval_seconds)
            if self.active_connections:
                await self.broadcast(
                    "HEARTBEAT",
                    {
                        "server_time": datetime.utcnow().isoformat(),
                        "clients": len(self.active_connections),
                    },
                )

    async def start_redis_subscriber(self):
        """
        Background task: subscribes to the Redis 'fire_eye_events' channel
        and relays messages to all connected WebSocket clients.
        """
        try:
            from app.redis_client import redis_client

            pubsub = redis_client.pubsub()
            pubsub.subscribe("fire_eye_events")
            logger.info("Redis Pub/Sub subscriber started on 'fire_eye_events'.")

            while True:
                message = pubsub.get_message(
                    ignore_subscribe_messages=True, timeout=1.0
                )
                if message and message.get("type") == "message":
                    try:
                        data = json.loads(message["data"])
                        event_type = data.get("event", "UNKNOWN")
                        payload = data.get("data", {})
                        await self.broadcast(event_type, payload)
                    except json.JSONDecodeError:
                        logger.warning("Malformed Redis Pub/Sub message.")
                await asyncio.sleep(0.1)
        except Exception as e:
            logger.warning(
                f"Redis Pub/Sub not available: {e}. WS direct-broadcast only."
            )

    @property
    def client_count(self) -> int:
        return len(self.active_connections)


# ── Publish helper (fire-and-forget from sync code) ──────────────────────────
def publish_event(event_type: str, payload: dict):
    """
    Publish an event to Redis Pub/Sub channel for fan-out.
    Safe to call from synchronous code.
    Fallback to direct broadcast if Redis is unavailable.
    """
    try:
        from app.redis_client import redis_client

        redis_client.publish(
            "fire_eye_events", json.dumps({"event": event_type, "data": payload})
        )
    except Exception as e:
        import asyncio
        try:
            loop = asyncio.get_running_loop()
            loop.create_task(ws_manager.broadcast(event_type, payload))
        except RuntimeError:
            pass


# ── Singleton ────────────────────────────────────────────────────────────────
ws_manager = ConnectionManager()
