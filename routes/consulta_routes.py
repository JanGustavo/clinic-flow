from flask import Blueprint, jsonify, request
from database import get_db_connection

consulta_bp = Blueprint('consulta', __name__)

@consulta_bp.route('/consultas', methods=['GET', 'POST'])
def handle_consultas():
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            if request.method == 'POST':
                data = request.json
                sql = """INSERT INTO CONSULTA (id_paciente, id_medico, id_usuario_responsavel, data_hora, motivo, valor, prioridade) 
                         VALUES (%s, %s, %s, %s, %s, %s, %s)"""
                cursor.execute(sql, (
                    data['id_paciente'], data['id_medico'], data['id_usuario_responsavel'],
                    data['data_hora'], data['motivo'], data['valor'], data.get('prioridade', 'MEDIA')
                ))
                db.commit()
                return jsonify({"message": "Consulta agendada", "id": cursor.lastrowid}), 201
            else:
                sql = """SELECT c.*, p.nome as paciente_nome, m.nome as medico_nome 
                         FROM CONSULTA c 
                         JOIN PACIENTE p ON c.id_paciente = p.id 
                         JOIN MEDICO m ON c.id_medico = m.id"""
                cursor.execute(sql)
                return jsonify(cursor.fetchall()), 200
    finally:
        db.close()

@consulta_bp.route('/consultas/<int:id_consulta>/exames', methods=['POST'])
def add_exame_consulta(id_consulta):
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            data = request.json
            sql = "INSERT INTO CONSULTA_EXAME (id_consulta, id_exame) VALUES (%s, %s)"
            cursor.execute(sql, (id_consulta, data['id_exame']))
            db.commit()
            return jsonify({"message": "Exame solicitado com sucesso"}), 201
    finally:
        db.close()
