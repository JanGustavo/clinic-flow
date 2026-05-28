from flask import Blueprint, jsonify, request
from database import get_db_connection
from services.auth_service import login_requerido, papeis_autorizados
from datetime import datetime

anamnese_bp = Blueprint('anamnese', __name__)

@anamnese_bp.route('/anamneses/<int:anamnese_id>', methods=['GET'])
@login_requerido
@papeis_autorizados('ADMIN', 'ODONTOLOGO', 'PACIENTE')
def get_anamnese(anamnese_id):
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    id_paciente,
                    alergia,
                    descricao_alergia,
                    diabetes,
                    hipertensao,
                    cardiopatia,
                    gestante,
                    usa_medicacao,
                    descricao_medicacao,
                    observacoes,
                    criado_em,
                    atualizado_em
                FROM ANAMNESE
                WHERE id = %s
            """, (anamnese_id,))
            anamnese = cursor.fetchone()
            if anamnese:
                return jsonify(anamnese), 200
            else:
                return jsonify(
                    {
                    'error': 'Anamnese não encontrada'
                    }), 404
    finally:
        db.close()