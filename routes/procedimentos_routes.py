from flask import Blueprint, jsonify
from database import get_db_connection

procedimento_bp = Blueprint('procedimento', __name__)

@procedimento_bp.route('/procedimentos', methods=['GET'])
def list_procedimentos():
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    nome,
                    valor
                FROM PROCEDIMENTO
                ORDER BY nome
            """)
            return jsonify(cursor.fetchall()), 200
    finally:
        db.close()

@procedimento_bp.route('/procedimentos/<int:id>', methods=['GET'])
def get_procedimento(id):
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute("""
            SELECT
                id,
                nome,
                valor
            FROM PROCEDIMENTO
            WHERE id = %s
        """, (id,))
            procedimento = cursor.fetchone()
            if procedimento:
                return jsonify(procedimento), 200
            else:
                return jsonify(
                    {
                    'error': 'Procedimento não encontrado'
                    }), 404
    finally:
        db.close()