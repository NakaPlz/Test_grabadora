from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from pydantic import EmailStr
from .config import settings

conf = ConnectionConfig(
    MAIL_USERNAME=settings.MAIL_USERNAME,
    MAIL_PASSWORD=settings.MAIL_PASSWORD,
    MAIL_FROM=settings.MAIL_FROM,
    MAIL_PORT=settings.MAIL_PORT,
    MAIL_SERVER=settings.MAIL_SERVER,
    MAIL_FROM_NAME=settings.MAIL_FROM_NAME,
    MAIL_STARTTLS=settings.MAIL_STARTTLS,
    MAIL_SSL_TLS=settings.MAIL_SSL_TLS,
    USE_CREDENTIALS=settings.USE_CREDENTIALS,
    VALIDATE_CERTS=settings.VALIDATE_CERTS
)

async def send_verification_email(email: EmailStr, token: str):
    verification_link = f"{settings.APP_DOMAIN}/auth/verify?token={token}"
    
    html = f"""
    <html>
        <body>
            <h1>Verifica tu cuenta</h1>
            <p>Gracias por registrarte en Grabadora IA.</p>
            <p>Por favor, haz clic en el siguiente enlace para verificar tu cuenta:</p>
            <a href="{verification_link}">Verificar Email</a>
            <p>Si no fuiste tú, ignora este mensaje.</p>
        </body>
    </html>
    """

    message = MessageSchema(
        subject="Verifica tu cuenta - Grabadora IA",
        recipients=[email],
        body=html,
        subtype=MessageType.html
    )

    fm = FastMail(conf)
    await fm.send_message(message)
