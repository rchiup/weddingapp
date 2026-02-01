"""
Rutas de chat
=============

Endpoints para mensajería en tiempo real:
crear chats, enviar mensajes, obtener conversaciones.
"""

from flask import Blueprint, request, jsonify
from services.firebase_service import FirebaseService

chat_bp = Blueprint('chat', __name__)
firebase_service = FirebaseService()

@chat_bp.route('/conversations', methods=['GET'])
def get_conversations():
    """
    Obtiene las conversaciones del usuario
    
    Headers:
        - Authorization: Bearer token
    """
    try:
        # TODO: Validar token y obtener userId
        # TODO: Consultar conversaciones desde Firestore
        return jsonify({'conversations': []}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@chat_bp.route('/<chat_id>/messages', methods=['GET'])
def get_messages(chat_id):
    """
    Obtiene los mensajes de un chat
    
    Headers:
        - Authorization: Bearer token
    
    Query params:
        - limit: number (opcional, default 50)
        - before: timestamp (opcional, para paginación)
    """
    try:
        # TODO: Validar token y permisos del chat
        # TODO: Consultar mensajes desde Firestore
        return jsonify({'messages': []}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@chat_bp.route('/<chat_id>/messages', methods=['POST'])
def send_message(chat_id):
    """
    Envía un mensaje en un chat
    
    Headers:
        - Authorization: Bearer token
    
    Body:
        - text: string
    """
    try:
        data = request.get_json()
        # TODO: Validar token y permisos del chat
        # TODO: Crear mensaje en Firestore
        # TODO: Actualizar último mensaje del chat
        return jsonify({'messageId': '', 'message': 'Mensaje enviado'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@chat_bp.route('/create', methods=['POST'])
def create_chat():
    """
    Crea o obtiene un chat entre dos usuarios
    
    Headers:
        - Authorization: Bearer token
    
    Body:
        - userId2: string
        - eventId: string
    """
    try:
        data = request.get_json()
        # TODO: Validar token y obtener userId
        # TODO: Buscar chat existente o crear nuevo
        return jsonify({'chatId': '', 'message': 'Chat creado/obtenido'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@chat_bp.route('/<chat_id>/read', methods=['POST'])
def mark_as_read(chat_id):
    """
    Marca los mensajes de un chat como leídos
    
    Headers:
        - Authorization: Bearer token
    """
    try:
        # TODO: Validar token y permisos del chat
        # TODO: Actualizar estado de lectura en Firestore
        return jsonify({'message': 'Mensajes marcados como leídos'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400
