"""
Rutas de autenticación
======================

Endpoints para registro, login, logout, y gestión de usuarios.
Comunica con AuthService para operaciones con Firebase Auth.
"""

from flask import Blueprint, request, jsonify
from services.firebase_service import FirebaseService
from services.resend_service import ResendService

auth_bp = Blueprint('auth', __name__)
firebase_service = FirebaseService()
resend_service = ResendService()

@auth_bp.route('/register', methods=['POST'])
def register():
    """
    Registra un nuevo usuario
    
    Body:
        - email: string
        - password: string
        - name: string (opcional)
        - isSingle: boolean (opcional)
    
    Returns:
        - user: objeto con datos del usuario
        - token: token de autenticación
    """
    try:
        data = request.get_json()
        # TODO: Validar datos
        # TODO: Crear usuario con FirebaseService
        # TODO: Enviar email de bienvenida con ResendService
        return jsonify({'message': 'Registro exitoso'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@auth_bp.route('/login', methods=['POST'])
def login():
    """
    Inicia sesión con email y contraseña
    
    Body:
        - email: string
        - password: string
    
    Returns:
        - user: objeto con datos del usuario
        - token: token de autenticación
    """
    try:
        data = request.get_json()
        # TODO: Validar datos
        # TODO: Autenticar con FirebaseService
        return jsonify({'message': 'Login exitoso'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 401

@auth_bp.route('/logout', methods=['POST'])
def logout():
    """
    Cierra sesión del usuario actual
    
    Headers:
        - Authorization: Bearer token
    """
    try:
        # TODO: Validar token
        # TODO: Invalidar token si es necesario
        return jsonify({'message': 'Logout exitoso'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@auth_bp.route('/me', methods=['GET'])
def get_current_user():
    """
    Obtiene los datos del usuario actual
    
    Headers:
        - Authorization: Bearer token
    """
    try:
        # TODO: Validar token
        # TODO: Obtener datos del usuario desde Firestore
        return jsonify({'user': {}}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 401

@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    """
    Envía email para resetear contraseña
    
    Body:
        - email: string
    """
    try:
        data = request.get_json()
        # TODO: Generar link de reset con FirebaseService
        # TODO: Enviar email con ResendService
        return jsonify({'message': 'Email de reset enviado'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400
