from flask import Blueprint, jsonify, request
from database import get_db_connection

consulta_bp = Blueprint('consulta', __name__)

PRIORIDADES_VALIDAS = {
    "BAIXA",
    "MEDIA",
    "ALTA",
    "URGENTE"
}


# ==========================================================
# FUNÇÕES AUXILIARES
# ==========================================================

def entidade_existe(tabela, id):
    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            sql = f"SELECT id FROM {tabela} WHERE id = %s"
            cursor.execute(sql, (id,))
            return cursor.fetchone() is not None
    finally:
        db.close()


def exame_ja_vinculado(id_consulta, id_exame):
    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute(
                """
                SELECT id_consulta
                FROM CONSULTA_EXAME
                WHERE id_consulta = %s
                AND id_exame = %s
                """,
                (id_consulta, id_exame)
            )

            return cursor.fetchone() is not None
    finally:
        db.close()


def validar_consulta(
    id_paciente,
    id_medico,
    id_usuario_responsavel,
    data_hora,
    motivo,
    valor,
    prioridade
):
    if not id_paciente:
        return "Paciente inválido"

    if not id_medico:
        return "Médico inválido"

    if not id_usuario_responsavel:
        return "Usuário responsável inválido"

    if not data_hora:
        return "Data e hora inválidas"

    if not motivo or motivo.isspace() or len(motivo) > 255:
        return "Motivo inválido"

    if valor is None or float(valor) < 0:
        return "Valor inválido"

    if prioridade not in PRIORIDADES_VALIDAS:
        return "Prioridade inválida"

    return True


# ==========================================================
# ROTAS
# ==========================================================

@consulta_bp.route('/consultas', methods=['GET'])
def list_consultas():
    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    c.id,
                    c.data_hora,
                    c.motivo,
                    c.valor,
                    c.prioridade,
                    p.nome AS paciente,
                    m.nome AS medico,
                    u.nome AS usuario_responsavel
                FROM CONSULTA c
                INNER JOIN PACIENTE p
                    ON c.id_paciente = p.id
                INNER JOIN MEDICO m
                    ON c.id_medico = m.id
                INNER JOIN USUARIO u
                    ON c.id_usuario_responsavel = u.id
                ORDER BY c.data_hora DESC
            """)

            return jsonify(cursor.fetchall()), 200

    finally:
        db.close()


@consulta_bp.route('/consultas/<int:id>', methods=['GET'])
def get_consulta(id):
    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    c.id,
                    c.data_hora,
                    c.motivo,
                    c.valor,
                    c.prioridade,
                    p.nome AS paciente,
                    m.nome AS medico,
                    u.nome AS usuario_responsavel
                FROM CONSULTA c
                INNER JOIN PACIENTE p
                    ON c.id_paciente = p.id
                INNER JOIN MEDICO m
                    ON c.id_medico = m.id
                INNER JOIN USUARIO u
                    ON c.id_usuario_responsavel = u.id
                WHERE c.id = %s
            """, (id,))

            consulta = cursor.fetchone()

            if not consulta:
                return jsonify({
                    "error": "Consulta não encontrada"
                }), 404

            return jsonify(consulta), 200

    finally:
        db.close()


@consulta_bp.route('/consultas', methods=['POST'])
def create_consulta():
    db = get_db_connection()

    try:
        dados = request.get_json()

        if not dados:
            return jsonify({
                "error": "Dados da consulta ausentes"
            }), 400

        id_paciente = dados.get('id_paciente')
        id_medico = dados.get('id_medico')
        id_usuario = dados.get('id_usuario_responsavel')
        data_hora = dados.get('data_hora')
        motivo = dados.get('motivo')
        valor = dados.get('valor')
        prioridade = dados.get('prioridade', 'MEDIA').upper()

        # Validação de formato
        validacao = validar_consulta(
            id_paciente,
            id_medico,
            id_usuario,
            data_hora,
            motivo,
            valor,
            prioridade
        )

        if validacao is not True:
            return jsonify({
                "error": validacao
            }), 400

        # Verificação de existência
        if not entidade_existe("PACIENTE", id_paciente):
            return jsonify({
                "error": "Paciente não encontrado"
            }), 404

        if not entidade_existe("MEDICO", id_medico):
            return jsonify({
                "error": "Médico não encontrado"
            }), 404

        if not entidade_existe("USUARIO", id_usuario):
            return jsonify({
                "error": "Usuário responsável não encontrado"
            }), 404

        with db.cursor() as cursor:
            cursor.execute("""
                INSERT INTO CONSULTA (
                    id_paciente,
                    id_medico,
                    id_usuario_responsavel,
                    data_hora,
                    motivo,
                    valor,
                    prioridade
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                id_paciente,
                id_medico,
                id_usuario,
                data_hora,
                motivo,
                valor,
                prioridade
            ))

            db.commit()

            return jsonify({
                "message": "Consulta criada com sucesso",
                "id": cursor.lastrowid
            }), 201

    finally:
        db.close()


@consulta_bp.route('/consultas/<int:id>', methods=['PUT'])
def update_consulta(id):
    db = get_db_connection()

    try:
        if not entidade_existe("CONSULTA", id):
            return jsonify({
                "error": "Consulta não encontrada"
            }), 404

        dados = request.get_json()

        if not dados:
            return jsonify({
                "error": "Dados da consulta ausentes"
            }), 400

        id_paciente = dados.get('id_paciente')
        id_medico = dados.get('id_medico')
        id_usuario = dados.get('id_usuario_responsavel')
        data_hora = dados.get('data_hora')
        motivo = dados.get('motivo')
        valor = dados.get('valor')
        prioridade = dados.get('prioridade', 'MEDIA').upper()

        validacao = validar_consulta(
            id_paciente,
            id_medico,
            id_usuario,
            data_hora,
            motivo,
            valor,
            prioridade
        )

        if validacao is not True:
            return jsonify({
                "error": validacao
            }), 400

        with db.cursor() as cursor:
            cursor.execute("""
                UPDATE CONSULTA
                SET
                    id_paciente = %s,
                    id_medico = %s,
                    id_usuario_responsavel = %s,
                    data_hora = %s,
                    motivo = %s,
                    valor = %s,
                    prioridade = %s
                WHERE id = %s
            """, (
                id_paciente,
                id_medico,
                id_usuario,
                data_hora,
                motivo,
                valor,
                prioridade,
                id
            ))

            db.commit()

            return jsonify({
                "message": f"Consulta {id} atualizada com sucesso"
            }), 200

    finally:
        db.close()


@consulta_bp.route('/consultas/<int:id>', methods=['DELETE'])
def delete_consulta(id):
    db = get_db_connection()

    try:
        with db.cursor() as cursor:

            cursor.execute(
                "SELECT id FROM CONSULTA WHERE id = %s",
                (id,)
            )

            if not cursor.fetchone():
                return jsonify({
                    "error": "Consulta não encontrada"
                }), 404

            cursor.execute(
                "DELETE FROM CONSULTA WHERE id = %s",
                (id,)
            )

            db.commit()

            return jsonify({
                "message": f"Consulta {id} excluída com sucesso"
            }), 200

    finally:
        db.close()


# ==========================================================
# EXAMES DA CONSULTA
# ==========================================================

@consulta_bp.route('/consultas/<int:id_consulta>/exames', methods=['GET'])
def list_exames_consulta(id_consulta):

    if not entidade_existe("CONSULTA", id_consulta):
        return jsonify({
            "error": "Consulta não encontrada"
        }), 404

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    e.id,
                    e.nome,
                    e.valor
                FROM CONSULTA_EXAME ce
                INNER JOIN EXAME e
                    ON ce.id_exame = e.id
                WHERE ce.id_consulta = %s
            """, (id_consulta,))

            return jsonify(cursor.fetchall()), 200

    finally:
        db.close()


@consulta_bp.route('/consultas/<int:id_consulta>/exames', methods=['POST'])
def add_exame_consulta(id_consulta):

    if not entidade_existe("CONSULTA", id_consulta):
        return jsonify({
            "error": "Consulta não encontrada"
        }), 404

    dados = request.get_json()

    if not dados:
        return jsonify({
            "error": "Dados ausentes"
        }), 400

    id_exame = dados.get('id_exame')

    if not id_exame:
        return jsonify({
            "error": "ID do exame inválido"
        }), 400

    if not entidade_existe("EXAME", id_exame):
        return jsonify({
            "error": "Exame não encontrado"
        }), 404

    if exame_ja_vinculado(id_consulta, id_exame):
        return jsonify({
            "error": "Exame já vinculado à consulta"
        }), 409

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                INSERT INTO CONSULTA_EXAME (
                    id_consulta,
                    id_exame
                )
                VALUES (%s, %s)
            """, (
                id_consulta,
                id_exame
            ))

            db.commit()

            return jsonify({
                "message": "Exame adicionado com sucesso"
            }), 201

    finally:
        db.close()
        