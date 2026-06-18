import smtplib
from email.mime.text import MIMEText
from app.config import get_settings

settings = get_settings()


async def send_reset_email(to_email: str, token: str):
    reset_url = f"{settings.APP_URL}/reset-password?token={token}"
    subject = "DevPulse — Password Reset"
    body = f"""
Hello,

You requested a password reset for your DevPulse account.

Click the link below to reset your password (valid for 1 hour):
{reset_url}

If you did not request this, please ignore this email.

— The DevPulse Team
"""
    msg = MIMEText(body, "plain", "utf-8")
    msg["Subject"] = subject
    msg["From"] = settings.SMTP_FROM
    msg["To"] = to_email

    if settings.SMTP_USERNAME and settings.SMTP_PASSWORD:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
            server.starttls()
            server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            server.send_message(msg)
