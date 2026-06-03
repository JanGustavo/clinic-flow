from flask import Blueprint, jsonify, request
from database import get_db_connection
from services.auth_service import login_requerido, papeis_autorizados

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


def procedimento_ja_vinculado(id_consulta, id_procedimento):
    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute(
                """
                SELECT id_consulta
                FROM CONSULTA_PROCEDIMENTO
                WHERE id_consulta = %s
                AND id_procedimento = %s
                """,
                (id_consulta, id_procedimento)
            )

            return cursor.fetchone() is not None
    finally:
        db.close()


def validar_consulta(
    id_paciente,
    id_odontologo,
    id_usuario_responsavel,
    data_hora,
    motivo,
    valor,
    prioridade
):
    if not id_paciente:
        return "Paciente inválido"

    if not id_odontologo:
        return "Odontólogo inválido"

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
@login_requerido
@papeis_autorizados('ADMIN', 'RECEPCIONISTA', 'ODONTOLOGO', 'PACIENTE')
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
                    c.status,
                    p.nome AS paciente,
                    o.nome AS odontologo,
                    u.nome AS usuario_responsavel
                FROM CONSULTA c
                INNER JOIN PACIENTE p
                    ON c.id_paciente = p.id
                INNER JOIN ODONTOLOGO o
                    ON c.id_odontologo = o.id
                INNER JOIN USUARIO u
                    ON c.id_usuario_responsavel = u.id
                ORDER BY c.data_hora DESC
            """)

            return jsonify(cursor.fetchall()), 200

    finally:
        db.close()


@consulta_bp.route('/consultas/<int:id>', methods=['GET'])
@login_requerido
@papeis_autorizados('ADMIN', 'RECEPCIONISTA', 'ODONTOLOGO', 'PACIENTE')
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
                    c.status,
                    p.nome AS paciente,
                    o.nome AS odontologo,
                    u.nome AS usuario_responsavel
                FROM CONSULTA c
                INNER JOIN PACIENTE p
                    ON c.id_paciente = p.id
                INNER JOIN ODONTOLOGO o
                    ON c.id_odontologo = o.id
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
@login_requerido
@papeis_autorizados('ADMIN', 'RECEPCIONISTA', 'PACIENTE')
def create_consulta():
    db = get_db_connection()

    try:
        dados = request.get_json()

        if not dados:
            return jsonify({
                "error": "Dados da consulta ausentes"
            }), 400

        id_paciente = dados.get('id_paciente')
        id_odontologo = dados.get('id_odontologo')
        id_usuario = dados.get('id_usuario_responsavel')
        data_hora = dados.get('data_hora')
        motivo = dados.get('motivo')
        valor = dados.get('valor')
        prioridade = dados.get('prioridade', 'MEDIA').upper()

        # Validação de formato
        validacao = validar_consulta(
            id_paciente,
            id_odontologo,
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

        if not entidade_existe("ODONTOLOGO", id_odontologo):
            return jsonify({
                "error": "Odontólogo não encontrado"
            }), 404

        if not entidade_existe("USUARIO", id_usuario):
            return jsonify({
                "error": "Usuário responsável não encontrado"
            }), 404

        with db.cursor() as cursor:
            cursor.execute("""
                INSERT INTO CONSULTA (
                    id_paciente,
                    id_odontologo,
                    id_usuario_responsavel,
                    data_hora,
                    motivo,
                    valor,
                    prioridade
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                id_paciente,
                id_odontologo,
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
@login_requerido
@papeis_autorizados('ADMIN', 'RECEPCIONISTA', 'ODONTOLOGO', 'PACIENTE')
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
        id_odontologo = dados.get('id_odontologo')
        id_usuario = dados.get('id_usuario_responsavel')
        data_hora = dados.get('data_hora')
        motivo = dados.get('motivo')
        valor = dados.get('valor')
        prioridade = dados.get('prioridade', 'MEDIA').upper()

        validacao = validar_consulta(
            id_paciente,
            id_odontologo,
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
                    id_odontologo = %s,
                    id_usuario_responsavel = %s,
                    data_hora = %s,
                    motivo = %s,
                    valor = %s,
                    prioridade = %s
                WHERE id = %s
            """, (
                id_paciente,
                id_odontologo,
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
@login_requerido
@papeis_autorizados('ADMIN', 'RECEPCIONISTA', 'PACIENTE','ODONTOLOGO')
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
# PROCEDIMENTOS DA CONSULTA
# ==========================================================

# Rotas para listar e adicionar procedimentos vinculados a uma consulta
@consulta_bp.route('/consultas/<int:id_consulta>/procedimentos', methods=['GET'])
@login_requerido
@papeis_autorizados('ADMIN', 'RECEPCIONISTA', 'ODONTOLOGO', 'PACIENTE')
def list_procedimentos_consulta(id_consulta):

    if not entidade_existe("CONSULTA", id_consulta):
        return jsonify({
            "error": "Consulta não encontrada"
        }), 404

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    p.id,
                    p.nome,
                    p.valor
                FROM CONSULTA_PROCEDIMENTO cp
                INNER JOIN PROCEDIMENTO p
                    ON cp.id_procedimento = p.id
                WHERE cp.id_consulta = %s
            """, (id_consulta,))

            return jsonify(cursor.fetchall()), 200

    finally:
        db.close()


@consulta_bp.route('/consultas/<int:id_consulta>/procedimentos', methods=['POST'])
@login_requerido
@papeis_autorizados('ADMIN', 'ODONTOLOGO')
def add_procedimento_consulta(id_consulta):

    if not entidade_existe("CONSULTA", id_consulta):
        return jsonify({
            "error": "Consulta não encontrada"
        }), 404

    dados = request.get_json()

    if not dados:
        return jsonify({
            "error": "Dados ausentes"
        }), 400

    id_procedimento = dados.get('id_procedimento')

    if not id_procedimento:
        return jsonify({
            "error": "ID do procedimento inválido"
        }), 400

    if not entidade_existe("PROCEDIMENTO", id_procedimento):
        return jsonify({
            "error": "Procedimento não encontrado"
        }), 404

    if procedimento_ja_vinculado(id_consulta, id_procedimento):
        return jsonify({
            "error": "Procedimento já vinculado à consulta"
        }), 409

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                INSERT INTO CONSULTA_PROCEDIMENTO (
                    id_consulta,
                    id_procedimento
                )
                VALUES (%s, %s)
            """, (
                id_consulta,
                id_procedimento
            ))

            db.commit()

            return jsonify({
                "message": "Procedimento adicionado com sucesso"
            }), 201

    finally:
        db.close()
        