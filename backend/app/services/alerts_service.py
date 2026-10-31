import asyncio
import logging

import httpx
from app.config import settings

logger = logging.getLogger("fire-eye.alerts")


async def send_discord_webhook(message: str):
    if not settings.DISCORD_WEBHOOK_URL:
        return
    try:
        async with httpx.AsyncClient() as client:
            await client.post(
                settings.DISCORD_WEBHOOK_URL,
                json={"content": message, "username": "Fire-Eye Alert Bot"},
            )
    except Exception as e:
        logger.error(f"Failed to send Discord alert: {e}")


async def send_telegram_alert(message: str):
    if not settings.TELEGRAM_BOT_TOKEN or not settings.TELEGRAM_CHAT_ID:
        return
    try:
        url = f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/sendMessage"
        async with httpx.AsyncClient() as client:
            await client.post(
                url, json={"chat_id": settings.TELEGRAM_CHAT_ID, "text": message}
            )
    except Exception as e:
        logger.error(f"Failed to send Telegram alert: {e}")


async def send_fcm_push(title: str, body: str):
    if not settings.FCM_SERVER_KEY:
        return
    try:
        url = "https://fcm.googleapis.com/fcm/send"
        headers = {
            "Authorization": f"key={settings.FCM_SERVER_KEY}",
            "Content-Type": "application/json",
        }
        # To global 'alerts' topic
        payload = {
            "to": "/topics/alerts",
            "notification": {"title": title, "body": body},
        }
        async with httpx.AsyncClient() as client:
            await client.post(url, json=payload, headers=headers)
    except Exception as e:
        logger.error(f"Failed to send FCM push: {e}")


async def dispatch_emergency_alerts(
    sos_code: str, severity: str, location_str: str, message: str
):
    """Dispatches alerts to all configured channels concurrently."""
    alert_text = f"🚨 **EMERGENCY: {severity}** 🚨\nSOS Code: `{sos_code}`\nLocation: {location_str}\nDetails: {message}"

    tasks = [
        send_discord_webhook(alert_text),
        send_telegram_alert(alert_text),
        send_fcm_push(f"EMERGENCY: {severity}", f"SOS {sos_code} from {location_str}"),
    ]

    await asyncio.gather(*tasks, return_exceptions=True)
