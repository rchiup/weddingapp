"""
Rutas de eventos
================

Endpoints para gestión de eventos de matrimonio:
crear, listar, obtener detalles, mesas, e invitados.
"""

from flask import Blueprint, request, jsonify
from services.firebase_service import FirebaseService

event_bp = Blueprint('events', __name__)
firebase_service = FirebaseService()

@event_bp.route('', methods=['GET'])
def get_events():
    """
    Obtiene todos los eventos del usuario
    
    Headers:
        - Authorization: Bearer token
    
    Query params:
        - userId: string (opcional, si no viene del token)
    """
    try:
        # TODO: Validar token y obtener userId
        # TODO: Consultar eventos desde Firestore
        return jsonify({'events': []}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@event_bp.route('', methods=['POST'])
def create_event():
    """
    Crea un nuevo evento
    
    Headers:
        - Authorization: Bearer token
    
    Body:
        - name: string
        - date: string (ISO format)
        - location: string (opcional)
        - description: string (opcional)
    """
    try:
        data = request.get_json()
        # TODO: Validar datos
        # TODO: Crear evento en Firestore
        return jsonify({'eventId': '', 'message': 'Evento creado'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@event_bp.route('/<event_id>', methods=['GET'])
def get_event(event_id):
    """
    Obtiene los detalles de un evento
    
    Headers:
        - Authorization: Bearer token
    """
    try:
        # TODO: Validar token
        # TODO: Obtener evento desde Firestore
        return jsonify({'event': {}}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@event_bp.route('/<event_id>/tables', methods=['GET'])
def get_tables(event_id):
    """
    Obtiene las mesas de un evento
    
    Headers:
        - Authorization: Bearer token
    """
    try:
        # TODO: Validar token y permisos
        # TODO: Consultar mesas desde Firestore
        return jsonify({'tables': []}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@event_bp.route('/<event_id>/tables', methods=['POST'])
def create_table(event_id):
    """
    Crea o actualiza una mesa
    
    Headers:
        - Authorization: Bearer token (requiere admin)
    
    Body:
        - tableNumber: string
        - capacity: number
        - guests: array de guestIds (opcional)
    """
    try:
        data = request.get_json()
        # TODO: Validar permisos de admin
        # TODO: Crear/actualizar mesa en Firestore
        return jsonify({'message': 'Mesa creada/actualizada'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@event_bp.route('/<event_id>/guests', methods=['GET'])
def get_guests(event_id):
    """
    Obtiene los invitados de un evento
    
    Headers:
        - Authorization: Bearer token
    """
    try:
        # TODO: Validar token
        # TODO: Consultar invitados desde Firestore
        return jsonify({'guests': []}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@event_bp.route('/<event_id>/guests', methods=['POST'])
def invite_guest(event_id):
    """
    Invita a un usuario al evento
    
    Headers:
        - Authorization: Bearer token (requiere admin)
    
    Body:
        - email: string
        - name: string (opcional)
    """
    try:
        data = request.get_json()
        # TODO: Validar permisos de admin
        # TODO: Crear invitación en Firestore
        # TODO: Enviar email de invitación con ResendService
        return jsonify({'message': 'Invitación enviada'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 400
