from flask import Blueprint, jsonify
from database import get_db_connection

exame_bp = Blueprint('exame', __name__)

@exame_bp.route('/exames', methods=['GET'])
def list_exames():
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute("SELECT * FROM EXAME")
            return jsonify(cursor.fetchall()), 200
    finally:
        db.close()
