from flask import Blueprint, jsonify, request
from database import get_db_connection

paciente_bp = Blueprint('paciente', __name__)

@paciente_bp.route('/pacientes', methods=['GET', 'POST'])
def handle_pacientes():
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            if request.method == 'POST':
                data = request.json
                sql = """INSERT INTO PACIENTE (nome, data_nascimento, cpf, telefone, cep, logradouro, numero_casa, bairro, cidade, estado) 
                         VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""
                cursor.execute(sql, (
                    data['nome'], data['data_nascimento'], data['cpf'], data['telefone'], 
                    data['cep'], data['logradouro'], data['numero_casa'], data['bairro'], 
                    data['cidade'], data['estado']
                ))
                db.commit()
                return jsonify({"message": "Paciente criado com sucesso"}), 201
            else:
                cursor.execute("SELECT * FROM PACIENTE")
                return jsonify(cursor.fetchall()), 200
    finally:
        db.close()
