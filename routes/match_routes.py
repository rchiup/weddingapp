"""
Rutas de matches/conexiones
============================

Endpoints para la funcionalidad tipo Tinder:
likes, passes, matches, y lista de conexiones.
"""

from flask import Blueprint, request, jsonify
from services.firebase_service import FirebaseService

match_bp = Blueprint('matches', __name__)
firebase_service = FirebaseService()

@match_bp.route('/<event_id>/potential', methods=['GET'])
def get_potential_matches(event_id):
    """
    Obtiene usuarios potenciales para hacer match
    
    Headers:
        - Authorization: Bearer token
    
    Query params:
        - limit: number (opcional, default 10)
    """
    try:
        # TODO: Validar token y obtener userId
        # TODO: Consultar usuarios solteros del evento
        # TODO: Excluir usuarios ya vistos
        return jsonify({'users': []}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@match_bp.route('/<event_id>/like', methods=['POST'])
def like_user(event_id):
    """
    Da like a un usuario
    
    Headers:
        - Authorization: Bearer token
    
    Body:
        - targetUserId: string
    """
    try:
        data = request.get_json()
        # TODO: Validar token y obtener userId
        # TODO: Guardar like en Firestore
        # TODO: Verificar si hay match recíproco
        return jsonify({'matched': False, 'message': 'Like registrado'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@match_bp.route('/<event_id>/pass', methods=['POST'])
def pass_user(event_id):
    """
    Rechaza a un usuario (pass)
    
    Headers:
        - Authorization: Bearer token
    
    Body:
        - targetUserId: string
    """
    try:
        data = request.get_json()
        # TODO: Validar token y obtener userId
        # TODO: Guardar pass en Firestore
        return jsonify({'message': 'Pass registrado'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@match_bp.route('/<event_id>', methods=['GET'])
def get_matches(event_id):
    """
    Obtiene los matches del usuario en un evento
    
    Headers:
        - Authorization: Bearer token
    """
    try:
        # TODO: Validar token y obtener userId
        # TODO: Consultar matches desde Firestore
        return jsonify({'matches': []}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400
