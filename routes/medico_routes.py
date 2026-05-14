from flask import Blueprint, jsonify
from database import get_db_connection

medico_bp = Blueprint('medico', __name__)

@medico_bp.route('/medicos', methods=['GET'])
def list_medicos():
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute("SELECT m.id, m.nome, e.nome as especialidade FROM MEDICO m JOIN ESPECIALIDADE e ON m.id_especialidade = e.id")
            return jsonify(cursor.fetchall()), 200
    finally:
        db.close()
