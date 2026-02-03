"""
Utilidades generales
=====================

Funciones auxiliares reutilizables:
validación, formateo, helpers, etc.
"""

import os
import re
from datetime import datetime
from functools import wraps
from flask import request, jsonify

def validate_email(email: str) -> bool:
    """
    Valida formato de email
    
    Args:
        email: Email a validar
    
    Returns:
        True si es válido, False si no
    """
    pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'
    return bool(re.match(pattern, email))

def validate_required_fields(data: dict, required_fields: list) -> tuple[bool, str]:
    """
    Valida que los campos requeridos estén presentes
    
    Args:
        data: Diccionario con los datos
        required_fields: Lista de campos requeridos
    
    Returns:
        Tupla (es_válido, mensaje_error)
    """
    missing_fields = [field for field in required_fields if field not in data or not data[field]]
    
    if missing_fields:
        return False, f'Campos requeridos faltantes: {", ".join(missing_fields)}'
    
    return True, ''

def format_datetime(dt: datetime) -> str:
    """
    Formatea datetime a string ISO
    
    Args:
        dt: Datetime a formatear
    
    Returns:
        String en formato ISO
    """
    return dt.isoformat()

def parse_datetime(date_string: str) -> datetime:
    """
    Parsea string ISO a datetime
    
    Args:
        date_string: String en formato ISO
    
    Returns:
        Datetime parseado
    """
    try:
        return datetime.fromisoformat(date_string.replace('Z', '+00:00'))
    except Exception:
        raise ValueError(f'Formato de fecha inválido: {date_string}')

def require_auth(f):
    """
    Decorator para requerir autenticación en endpoints
    
    Args:
        f: Función a decorar
    
    Returns:
        Función decorada
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # TODO: enable auth in production
        if os.environ.get('QA_MODE', 'false').lower() == 'true':
            return f(*args, **kwargs)
        token = request.headers.get('Authorization')
        
        if not token:
            return jsonify({'error': 'Token de autenticación requerido'}), 401
        
        # TODO: Verificar y decodificar token
        # TODO: Agregar user_id al request para uso en la función
        
        return f(*args, **kwargs)
    
    return decorated_function

def require_admin(f):
    """
    Decorator para requerir permisos de administrador
    
    Args:
        f: Función a decorar
    
    Returns:
        Función decorada
    """
    @wraps(f)
    @require_auth
    def decorated_function(*args, **kwargs):
        # TODO: enable auth in production
        if os.environ.get('QA_MODE', 'false').lower() == 'true':
            return f(*args, **kwargs)
        # TODO: Esto requiere validar el rol del usuario en el evento
        
        return f(*args, **kwargs)
    
    return decorated_function
