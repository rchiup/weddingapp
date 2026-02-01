"""
Servicio de Resend (Email)
===========================

Encapsula toda la lógica de envío de emails usando Resend.
Incluye templates para invitaciones, notificaciones, etc.
"""

import os
from resend import Resend

class ResendService:
    """Servicio para envío de emails con Resend"""
    
    def __init__(self):
        """Inicializa el cliente de Resend"""
        api_key = os.environ.get('RESEND_API_KEY')
        if not api_key:
            raise Exception('RESEND_API_KEY no configurada')
        
        self.resend = Resend(api_key=api_key)
        self.from_email = os.environ.get('RESEND_FROM_EMAIL', 'noreply@weddingapp.com')

    def send_email(self, to: str, subject: str, html: str, text: str = None) -> dict:
        """
        Envía un email
        
        Args:
            to: Email del destinatario
            subject: Asunto del email
            html: Contenido HTML del email
            text: Contenido de texto plano (opcional)
        
        Returns:
            Respuesta de Resend
        """
        try:
            # TODO: Implementar envío de email
            params = {
                'from': self.from_email,
                'to': to,
                'subject': subject,
                'html': html,
            }
            
            if text:
                params['text'] = text
            
            response = self.resend.emails.send(params)
            return response
        except Exception as e:
            raise Exception(f'Error enviando email: {e}')

    def send_invitation_email(self, to: str, event_name: str, invitation_link: str) -> dict:
        """
        Envía email de invitación a un evento
        
        Args:
            to: Email del invitado
            event_name: Nombre del evento
            invitation_link: Link de invitación
        
        Returns:
            Respuesta de Resend
        """
        try:
            # TODO: Crear template HTML para invitación
            html = f"""
            <html>
                <body>
                    <h1>Invitación a {event_name}</h1>
                    <p>Has sido invitado a un evento de matrimonio.</p>
                    <a href="{invitation_link}">Aceptar invitación</a>
                </body>
            </html>
            """
            
            return self.send_email(
                to=to,
                subject=f'Invitación a {event_name}',
                html=html,
            )
        except Exception as e:
            raise Exception(f'Error enviando email de invitación: {e}')

    def send_welcome_email(self, to: str, name: str) -> dict:
        """
        Envía email de bienvenida a un nuevo usuario
        
        Args:
            to: Email del usuario
            name: Nombre del usuario
        
        Returns:
            Respuesta de Resend
        """
        try:
            # TODO: Crear template HTML para bienvenida
            html = f"""
            <html>
                <body>
                    <h1>Bienvenido a Wedding App, {name}!</h1>
                    <p>Tu cuenta ha sido creada exitosamente.</p>
                </body>
            </html>
            """
            
            return self.send_email(
                to=to,
                subject='Bienvenido a Wedding App',
                html=html,
            )
        except Exception as e:
            raise Exception(f'Error enviando email de bienvenida: {e}')

    def send_password_reset_email(self, to: str, reset_link: str) -> dict:
        """
        Envía email para resetear contraseña
        
        Args:
            to: Email del usuario
            reset_link: Link para resetear contraseña
        
        Returns:
            Respuesta de Resend
        """
        try:
            # TODO: Crear template HTML para reset de contraseña
            html = f"""
            <html>
                <body>
                    <h1>Reset de Contraseña</h1>
                    <p>Haz clic en el siguiente link para resetear tu contraseña:</p>
                    <a href="{reset_link}">Resetear contraseña</a>
                </body>
            </html>
            """
            
            return self.send_email(
                to=to,
                subject='Reset de Contraseña - Wedding App',
                html=html,
            )
        except Exception as e:
            raise Exception(f'Error enviando email de reset: {e}')
