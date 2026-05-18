from flask import Blueprint, jsonify, request
from database import get_db_connection
from datetime import datetime

paciente_bp = Blueprint('paciente', __name__)


# --- FUNÇÕES AUXILIARES DE BANCO ---

def cpf_existe(cpf, id_excluido=None):
    """Verifica se um CPF já está cadastrado."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            sql = """
                SELECT id
                FROM PACIENTE
                WHERE cpf = %s
            """

            params = [cpf]

            if id_excluido is not None:
                sql += " AND id <> %s"
                params.append(id_excluido)

            cursor.execute(sql, tuple(params))

            return cursor.fetchone() is not None

    finally:
        db.close()


# --- VALIDAÇÕES ---

def verificar_nome(nome):
    """Valida nome do paciente."""

    if (
        not nome
        or nome.isspace()
        or len(nome) < 3
        or len(nome) > 100
    ):
        return "Nome do paciente inválido"

    return True


def verificar_cpf(cpf):
    """Valida CPF."""

    if (
        not cpf
        or cpf.isspace()
    ):
        return "CPF inválido"

    cpf_limpo = ''.join(filter(str.isdigit, cpf))

    if len(cpf_limpo) != 11:
        return "CPF inválido"

    return True


def verificar_telefone(telefone):
    """Valida telefone."""

    if (
        not telefone
        or telefone.isspace()
    ):
        return "Telefone inválido"

    telefone_limpo = ''.join(filter(str.isdigit, telefone))

    if len(telefone_limpo) < 10:
        return "Telefone inválido"

    return True


def verificar_data_nascimento(data_nascimento):
    """Valida data nascimento."""

    if not data_nascimento:
        return "Data de nascimento inválida"

    try:
        datetime.strptime(
            data_nascimento,
            "%Y-%m-%d"
        )

    except ValueError:
        return "Data de nascimento inválida"

    return True


def validar_paciente(
    nome,
    data_nascimento,
    cpf,
    telefone
):
    validacoes = [
        verificar_nome(nome),
        verificar_data_nascimento(data_nascimento),
        verificar_cpf(cpf),
        verificar_telefone(telefone)
    ]

    for validacao in validacoes:
        if validacao is not True:
            return validacao

    return True


# --- ROTAS ---

@paciente_bp.route('/pacientes', methods=['GET'])
def list_pacientes():
    """Lista todos os pacientes."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    nome,
                    data_nascimento,
                    cpf,
                    telefone,
                    cep,
                    logradouro,
                    numero_casa,
                    bairro,
                    cidade,
                    estado
                FROM PACIENTE
                ORDER BY nome
            """)

            pacientes = cursor.fetchall()

            return jsonify(pacientes), 200

    finally:
        db.close()


@paciente_bp.route('/pacientes/<int:id>', methods=['GET'])
def get_paciente(id):
    """Obtém paciente por ID."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    nome,
                    data_nascimento,
                    cpf,
                    telefone,
                    cep,
                    logradouro,
                    numero_casa,
                    bairro,
                    cidade,
                    estado
                FROM PACIENTE
                WHERE id = %s
            """, (id,))

            paciente = cursor.fetchone()

            if not paciente:
                return jsonify({
                    "error": "Paciente não encontrado!"
                }), 404

            return jsonify(paciente), 200

    finally:
        db.close()


@paciente_bp.route('/pacientes', methods=['POST'])
def create_paciente():
    """Cria um paciente."""

    db = get_db_connection()

    try:
        dados = request.get_json()

        if not dados:
            return jsonify({
                "error": "Dados do paciente ausentes!"
            }), 400

        nome = dados.get('nome')
        data_nascimento = dados.get('data_nascimento')
        cpf = dados.get('cpf')
        telefone = dados.get('telefone')
        cep = dados.get('cep')
        logradouro = dados.get('logradouro')
        numero_casa = dados.get('numero_casa')
        bairro = dados.get('bairro')
        cidade = dados.get('cidade')
        estado = dados.get('estado')

        validacao = validar_paciente(
            nome,
            data_nascimento,
            cpf,
            telefone
        )

        if validacao is not True:
            return jsonify({
                "error": validacao
            }), 400

        if cpf_existe(cpf):
            return jsonify({
                "error": "CPF já cadastrado"
            }), 409

        with db.cursor() as cursor:
            cursor.execute("""
                INSERT INTO PACIENTE (
                    nome,
                    data_nascimento,
                    cpf,
                    telefone,
                    cep,
                    logradouro,
                    numero_casa,
                    bairro,
                    cidade,
                    estado
                )
                VALUES (
                    %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s
                )
            """, (
                nome,
                data_nascimento,
                cpf,
                telefone,
                cep,
                logradouro,
                numero_casa,
                bairro,
                cidade,
                estado
            ))

            db.commit()

            return jsonify({
                "message":
                "Paciente criado com sucesso!"
            }), 201

    finally:
        db.close()


@paciente_bp.route('/pacientes/<int:id>', methods=['PUT'])
def update_paciente(id):
    """Atualiza paciente."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:

            cursor.execute("""
                SELECT id
                FROM PACIENTE
                WHERE id = %s
            """, (id,))

            if not cursor.fetchone():
                return jsonify({
                    "error":
                    "Paciente não encontrado!"
                }), 404

            dados = request.get_json()

            if not dados:
                return jsonify({
                    "error":
                    "Dados do paciente ausentes!"
                }), 400

            nome = dados.get('nome')
            data_nascimento = dados.get(
                'data_nascimento'
            )
            cpf = dados.get('cpf')
            telefone = dados.get(
                'telefone'
            )
            cep = dados.get('cep')
            logradouro = dados.get(
                'logradouro'
            )
            numero_casa = dados.get(
                'numero_casa'
            )
            bairro = dados.get('bairro')
            cidade = dados.get('cidade')
            estado = dados.get('estado')

            validacao = validar_paciente(
                nome,
                data_nascimento,
                cpf,
                telefone
            )

            if validacao is not True:
                return jsonify({
                    "error": validacao
                }), 400

            if cpf_existe(cpf, id):
                return jsonify({
                    "error":
                    "CPF já cadastrado por outro paciente"
                }), 409

            cursor.execute("""
                UPDATE PACIENTE
                SET
                    nome = %s,
                    data_nascimento = %s,
                    cpf = %s,
                    telefone = %s,
                    cep = %s,
                    logradouro = %s,
                    numero_casa = %s,
                    bairro = %s,
                    cidade = %s,
                    estado = %s
                WHERE id = %s
            """, (
                nome,
                data_nascimento,
                cpf,
                telefone,
                cep,
                logradouro,
                numero_casa,
                bairro,
                cidade,
                estado,
                id
            ))

            db.commit()

            return jsonify({
                "message":
                f"Paciente {id} atualizado com sucesso!"
            }), 200

    finally:
        db.close()


@paciente_bp.route('/pacientes/<int:id>', methods=['DELETE'])
def delete_paciente(id):
    """Exclui paciente."""

    db = get_db_connection()

    try:
        with db.cursor() as cursor:

            cursor.execute("""
                SELECT id
                FROM PACIENTE
                WHERE id = %s
            """, (id,))

            if not cursor.fetchone():
                return jsonify({
                    "error":
                    "Paciente não encontrado!"
                }), 404

            cursor.execute("""
                DELETE FROM PACIENTE
                WHERE id = %s
            """, (id,))

            db.commit()

            return jsonify({
                "message":
                f"Paciente {id} excluído com sucesso!"
            }), 200

    finally:
        db.close()