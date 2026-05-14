from flask import Blueprint, jsonify
from database import get_db_connection

usuario_bp = Blueprint('usuario', __name__)

@usuario_bp.route('/usuarios', methods=['GET'])
def list_usuarios():
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute("SELECT id, nome, email, tipo FROM USUARIO")
            return jsonify(cursor.fetchall()), 200
    finally:
        db.close()
