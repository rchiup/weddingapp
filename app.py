"""
Aplicación principal Flask
===========================

Punto de entrada del backend. Configura Flask, CORS, y registra
todas las rutas de los diferentes módulos.
"""

from flask import Flask
from flask_cors import CORS
import os

from routes.auth_routes import auth_bp
from routes.event_routes import event_bp
from routes.match_routes import match_bp
from routes.chat_routes import chat_bp
from routes.gallery_routes import gallery_bp

def create_app():
    """Factory function para crear la aplicación Flask"""
    app = Flask(__name__)
    
    # Configuración
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    app.config['DEBUG'] = os.environ.get('FLASK_ENV') == 'development'
    
    # CORS - Permitir requests desde el frontend
    CORS(app, origins=os.environ.get('ALLOWED_ORIGINS', '*').split(','))
    
    # Registrar blueprints (rutas modulares)
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(event_bp, url_prefix='/api/events')
    app.register_blueprint(match_bp, url_prefix='/api/matches')
    app.register_blueprint(chat_bp, url_prefix='/api/chat')
    app.register_blueprint(gallery_bp, url_prefix='/api/gallery')
    
    return app

app = create_app()

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
