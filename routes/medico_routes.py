from flask import Blueprint, jsonify, request
from database import get_db_connection

medico_bp = Blueprint('medico', __name__)

# --- CONSTANTES ---

DIAS_VALIDOS = {
    "SEGUNDA",
    "TERCA",
    "QUARTA",
    "QUINTA",
    "SEXTA",
    "SABADO",
    "DOMINGO"
}

TURNOS_VALIDOS = {
    "MANHA",
    "TARDE",
    "NOITE"
}


# --- FUNÇÕES AUXILIARES DE BANCO ---

def crm_existe(crm, id_excluido=None):
    """Verifica se o CRM já existe."""
    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            sql = "SELECT id FROM MEDICO WHERE crm = %s"
            params = [crm]

            if id_excluido is not None:
                sql += " AND id <> %s"
                params.append(id_excluido)

            cursor.execute(sql, tuple(params))

            return cursor.fetchone() is not None

    finally:
        db.close()


def especialidade_existe(id_especialidade):
    """Verifica se a especialidade existe."""
    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute(
                "SELECT id FROM ESPECIALIDADE WHERE id = %s",
                (id_especialidade,)
            )

            return cursor.fetchone() is not None

    finally:
        db.close()


def especialidade_nome_existe(nome):
    """Valida especialidade pelo nome."""
    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute(
                """
                SELECT nome AS especialidade
                FROM ESPECIALIDADE
                WHERE UPPER(nome) = %s
                """,
                (nome.upper(),)
            )

            return cursor.fetchone() is not None

    finally:
        db.close()


# --- VALIDAÇÕES ---

def verificar_nome(nome):
    if (
        not nome
        or nome.isspace()
        or len(nome) < 3
        or len(nome) > 100
    ):
        return "Nome do médico inválido"

    return True


def verificar_crm(crm):
    if (
        not crm
        or crm.isspace()
        or len(crm) < 4
        or len(crm) > 20
    ):
        return "CRM inválido"

    return True


def verificar_salario(salario):
    try:
        salario = float(salario)

        if salario < 0:
            return "Salário inválido"

    except (TypeError, ValueError):
        return "Salário inválido"

    return True


def verificar_especialidade(id_especialidade):
    if not id_especialidade:
        return "Especialidade inválida"

    if not especialidade_existe(id_especialidade):
        return "Especialidade não encontrada"

    return True


def validar_medico(nome, crm, salario, id_especialidade):
    validacoes = [
        verificar_nome(nome),
        verificar_crm(crm),
        verificar_salario(salario),
        verificar_especialidade(id_especialidade)
    ]

    for validacao in validacoes:
        if validacao is not True:
            return validacao

    return True


# --- ROTAS ---

@medico_bp.route('/medicos', methods=['GET'])
def list_medicos():
    """Lista todos os médicos."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    m.id,
                    m.nome,
                    e.nome AS especialidade,
                    m.crm,
                    m.salario
                FROM MEDICO m
                INNER JOIN ESPECIALIDADE e
                    ON m.id_especialidade = e.id
                ORDER BY e.nome, m.nome
            """)

            return jsonify(cursor.fetchall()), 200

    finally:
        db.close()


@medico_bp.route('/medicos/<int:id>', methods=['GET'])
def get_medico(id):
    """Obtém um médico específico."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    m.id,
                    m.nome,
                    e.nome AS especialidade,
                    m.crm,
                    m.salario
                FROM MEDICO m
                INNER JOIN ESPECIALIDADE e
                    ON m.id_especialidade = e.id
                WHERE m.id = %s
            """, (id,))

            medico = cursor.fetchone()

            if not medico:
                return jsonify({
                    "error": "Médico não encontrado!"
                }), 404

            return jsonify(medico), 200

    finally:
        db.close()


@medico_bp.route('/medicos', methods=['POST'])
def create_medico():
    """Cria um médico."""

    db = get_db_connection()

    try:
        dados = request.get_json()

        if not dados:
            return jsonify({
                "error": "Dados do médico ausentes!"
            }), 400

        nome = dados.get('nome')
        crm = dados.get('crm')
        salario = dados.get('salario')
        id_especialidade = dados.get('id_especialidade')
        id_usuario = dados.get('id_usuario')

        validacao = validar_medico(
            nome,
            crm,
            salario,
            id_especialidade
        )

        if validacao is not True:
            return jsonify({
                "error": validacao
            }), 400

        if crm_existe(crm):
            return jsonify({
                "error": "CRM já cadastrado"
            }), 409

        with db.cursor() as cursor:
            cursor.execute("""
                INSERT INTO MEDICO (
                    id_usuario,
                    nome,
                    id_especialidade,
                    crm,
                    salario
                )
                VALUES (%s, %s, %s, %s, %s)
            """, (
                id_usuario,
                nome,
                id_especialidade,
                crm,
                salario
            ))

            db.commit()

            return jsonify({
                "message": "Médico criado com sucesso!"
            }), 201

    finally:
        db.close()


@medico_bp.route('/medicos/<int:id>', methods=['PUT'])
def update_medico(id):
    """Atualiza médico."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:

            cursor.execute(
                "SELECT id FROM MEDICO WHERE id = %s",
                (id,)
            )

            if not cursor.fetchone():
                return jsonify({
                    "error": "Médico não encontrado!"
                }), 404

            dados = request.get_json()

            if not dados:
                return jsonify({
                    "error": "Dados do médico ausentes!"
                }), 400

            nome = dados.get('nome')
            crm = dados.get('crm')
            salario = dados.get('salario')
            id_especialidade = dados.get('id_especialidade')
            id_usuario = dados.get('id_usuario')

            validacao = validar_medico(
                nome,
                crm,
                salario,
                id_especialidade
            )

            if validacao is not True:
                return jsonify({
                    "error": validacao
                }), 400

            if crm_existe(crm, id):
                return jsonify({
                    "error": "CRM já cadastrado por outro médico"
                }), 409

            cursor.execute("""
                UPDATE MEDICO
                SET
                    nome = %s,
                    crm = %s,
                    salario = %s,
                    id_especialidade = %s,
                    id_usuario = %s
                WHERE id = %s
            """, (
                nome,
                crm,
                salario,
                id_especialidade,
                id_usuario,
                id
            ))

            db.commit()

            return jsonify({
                "message": f"Médico {id} atualizado com sucesso!"
            }), 200

    finally:
        db.close()


@medico_bp.route('/medicos/<int:id>', methods=['DELETE'])
def delete_medico(id):
    """Exclui médico."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:

            cursor.execute(
                "SELECT id FROM MEDICO WHERE id = %s",
                (id,)
            )

            if not cursor.fetchone():
                return jsonify({
                    "error": "Médico não encontrado!"
                }), 404

            cursor.execute(
                "DELETE FROM MEDICO WHERE id = %s",
                (id,)
            )

            db.commit()

            return jsonify({
                "message": f"Médico {id} excluído com sucesso!"
            }), 200

    finally:
        db.close()


@medico_bp.route(
    '/medicos/disponiveis/<dia_semana>/<turno>',
    methods=['GET']
)
def list_medicos_disponiveis(dia_semana, turno):
    """Lista médicos disponíveis por dia/turno."""

    dia_semana = dia_semana.upper()
    turno = turno.upper()

    especialidade = request.args.get(
        'especialidade'
    )

    if especialidade:
        especialidade = especialidade.upper()

    if dia_semana not in DIAS_VALIDOS:
        return jsonify({
            "error": "Dia da semana inválido"
        }), 400

    if turno not in TURNOS_VALIDOS:
        return jsonify({
            "error": "Turno inválido"
        }), 400

    if (
        especialidade
        and not especialidade_nome_existe(
            especialidade
        )
    ):
        return jsonify({
            "error": "Especialidade inválida"
        }), 400

    db = get_db_connection()

    try:
        with db.cursor() as cursor:

            sql = """
                SELECT
                    m.id,
                    m.nome AS medico,
                    e.nome AS especialidade
                FROM MEDICO m
                INNER JOIN ESPECIALIDADE e
                    ON m.id_especialidade = e.id
                INNER JOIN DISPONIBILIDADE_MEDICO dm
                    ON m.id = dm.id_medico
                WHERE
                    dm.dia_semana = %s
                    AND dm.turno = %s
            """

            params = [
                dia_semana,
                turno
            ]

            if especialidade:
                sql += """
                    AND UPPER(e.nome) = %s
                """

                params.append(
                    especialidade
                )

            sql += """
                ORDER BY
                    e.nome,
                    m.nome
            """

            cursor.execute(
                sql,
                tuple(params)
            )

            medicos = cursor.fetchall()

            if not medicos:
                return jsonify({
                    "message":
                    "Nenhum médico disponível encontrado."
                }), 404

            return jsonify(
                medicos
            ), 200

    finally:
        db.close()