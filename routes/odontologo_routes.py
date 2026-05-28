from flask import Blueprint, jsonify, request
from database import get_db_connection
from services.auth_service import login_requerido, papeis_autorizados

odontologo_bp = Blueprint('odontologo', __name__)

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

def cro_existe(cro, id_excluido=None):
    """Verifica se o CRO já existe."""
    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            sql = "SELECT id FROM ODONTOLOGO WHERE cro = %s"
            params = [cro]

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
        return "Nome do odontólogo inválido"

    return True


def verificar_cro(cro):
    if (
        not cro
        or cro.isspace()
        or len(cro) < 4
        or len(cro) > 20
    ):
        return "CRO inválido"

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


def validar_odontologo(nome, cro, salario, id_especialidade):
    validacoes = [
        verificar_nome(nome),
        verificar_cro(cro),
        verificar_salario(salario),
        verificar_especialidade(id_especialidade)
    ]

    for validacao in validacoes:
        if validacao is not True:
            return validacao

    return True


# --- ROTAS ---

@odontologo_bp.route('/odontologos', methods=['GET'])
@login_requerido
@papeis_autorizados('ADMIN', 'RECEPCIONISTA', 'ODONTOLOGO')
def list_odontologos():
    """Lista todos os odontólogos."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    o.id,
                    o.nome,
                    e.nome AS especialidade,
                    o.cro,
                    o.salario
                FROM ODONTOLOGO o
                INNER JOIN ESPECIALIDADE e
                    ON o.id_especialidade = e.id
                ORDER BY e.nome, o.nome
            """)

            return jsonify(cursor.fetchall()), 200

    finally:
        db.close()


@odontologo_bp.route('/odontologos/<int:id>', methods=['GET'])
@login_requerido
@papeis_autorizados('ADMIN', 'RECEPCIONISTA', 'ODONTOLOGO', 'PACIENTE')
def get_odontologo(id):
    """Obtém um odontólogo específico."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    o.id,
                    o.nome,
                    e.nome AS especialidade,
                    o.cro,
                    o.salario
                FROM ODONTOLOGO o
                INNER JOIN ESPECIALIDADE e
                    ON o.id_especialidade = e.id
                WHERE o.id = %s
            """, (id,))

            odontologo = cursor.fetchone()

            if not odontologo:
                return jsonify({
                    "error": "Odontólogo não encontrado!"
                }), 404

            return jsonify(odontologo), 200

    finally:
        db.close()


@odontologo_bp.route('/odontologos', methods=['POST'])
@login_requerido
@papeis_autorizados('ADMIN')
def create_odontologo():
    """Cria um odontólogo."""

    db = get_db_connection()

    try:
        dados = request.get_json()

        if not dados:
            return jsonify({
                "error": "Dados do odontólogo ausentes!"
            }), 400

        nome = dados.get('nome')
        cro = dados.get('cro')
        salario = dados.get('salario')
        id_especialidade = dados.get('id_especialidade')
        id_usuario = dados.get('id_usuario')

        validacao = validar_odontologo(
            nome,
            cro,
            salario,
            id_especialidade
        )

        if validacao is not True:
            return jsonify({
                "error": validacao
            }), 400

        if cro_existe(cro):
            return jsonify({
                "error": "CRO já cadastrado"
            }), 409

        with db.cursor() as cursor:
            cursor.execute("""
                INSERT INTO ODONTOLOGO (
                    id_usuario,
                    nome,
                    id_especialidade,
                    cro,
                    salario
                )
                VALUES (%s, %s, %s, %s, %s)
            """, (
                id_usuario,
                nome,
                id_especialidade,
                cro,
                salario
            ))

            db.commit()

            return jsonify({
                "message": "Odontólogo criado com sucesso!"
            }), 201

    finally:
        db.close()


@odontologo_bp.route('/odontologos/<int:id>', methods=['PUT'])
@login_requerido
@papeis_autorizados('ADMIN', 'ODONTOLOGO')
def update_odontologo(id):
    """Atualiza odontólogo."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:

            cursor.execute(
                "SELECT id FROM ODONTOLOGO WHERE id = %s",
                (id,)
            )

            if not cursor.fetchone():
                return jsonify({
                    "error": "Odontólogo não encontrado!"
                }), 404

            dados = request.get_json()

            if not dados:
                return jsonify({
                    "error": "Dados do odontólogo ausentes!"
                }), 400

            nome = dados.get('nome')
            cro = dados.get('cro')
            salario = dados.get('salario')
            id_especialidade = dados.get('id_especialidade')
            id_usuario = dados.get('id_usuario')

            validacao = validar_odontologo(
                nome,
                cro,
                salario,
                id_especialidade
            )

            if validacao is not True:
                return jsonify({
                    "error": validacao
                }), 400

            if cro_existe(cro, id):
                return jsonify({
                    "error": "CRO já cadastrado por outro odontólogo"
                }), 409

            cursor.execute("""
                UPDATE ODONTOLOGO
                SET
                    nome = %s,
                    cro = %s,
                    salario = %s,
                    id_especialidade = %s,
                    id_usuario = %s
                WHERE id = %s
            """, (
                nome,
                cro,
                salario,
                id_especialidade,
                id_usuario,
                id
            ))

            db.commit()

            return jsonify({
                "message": f"Odontólogo {id} atualizado com sucesso!"
            }), 200

    finally:
        db.close()


@odontologo_bp.route('/odontologos/<int:id>', methods=['DELETE'])
@login_requerido
@papeis_autorizados('ADMIN')
def delete_odontologo(id):
    """Exclui odontólogo."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:

            cursor.execute(
                "SELECT id FROM ODONTOLOGO WHERE id = %s",
                (id,)
            )

            if not cursor.fetchone():
                return jsonify({
                    "error": "Odontólogo não encontrado!"
                }), 404

            cursor.execute(
                "DELETE FROM ODONTOLOGO WHERE id = %s",
                (id,)
            )

            db.commit()

            return jsonify({
                "message": f"Odontólogo {id} excluído com sucesso!"
            }), 200

    finally:
        db.close()


@odontologo_bp.route(
    '/odontologos/disponiveis/<dia_semana>/<turno>',
    methods=['GET']
)
@login_requerido
@papeis_autorizados('ADMIN', 'RECEPCIONISTA', 'ODONTOLOGO', 'PACIENTE')
def list_odontologos_disponiveis(dia_semana, turno):
    """Lista odontólogos disponíveis por dia/turno."""

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
                    o.id,
                    o.nome AS odontologo,
                    e.nome AS especialidade
                FROM ODONTOLOGO o
                INNER JOIN ESPECIALIDADE e
                    ON o.id_especialidade = e.id
                INNER JOIN DISPONIBILIDADE_ODONTOLOGO do
                    ON o.id = do.id_odontologo
                WHERE
                    do.dia_semana = %s
                    AND do.turno = %s
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
                    o.nome
            """

            cursor.execute(
                sql,
                tuple(params)
            )

            odontologos = cursor.fetchall()

            if not odontologos:
                return jsonify({
                    "message":
                    "Nenhum odontólogo disponível encontrado."
                }), 404

            return jsonify(
                odontologos
            ), 200

    finally:
        db.close()
