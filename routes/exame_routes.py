from flask import Blueprint, jsonify
from database import get_db_connection

exame_bp = Blueprint('exame', __name__)

@exame_bp.route('/exames', methods=['GET'])
def list_exames():
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    nome,
                    valor
                FROM EXAME
                ORDER BY nome
            """)
            return jsonify(cursor.fetchall()), 200
    finally:
        db.close()

@exame_bp.route('/exames/<int:id>', methods=['GET'])
def get_exame(id):
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute("""
            SELECT
                id,
                nome,
                valor
            FROM EXAME
            WHERE id = %s
        """, (id,))
            exame = cursor.fetchone()
            if exame:
                return jsonify(exame), 200
            else:
                return jsonify(
                    {
                    'error': 'Exame não encontrado'
                    }), 404
    finally:
        db.close()