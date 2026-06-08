from flask import Blueprint, jsonify, request, g
from database import get_db_connection
from services.security import bcrypt
from services.auth_service import login_requerido, papeis_autorizados

# --- CONSTANTES ---
TIPOS_VALIDOS = {
    "ADMIN",
    "RECEPCIONISTA",
    "ODONTOLOGO",
    "PACIENTE"
} 

# --- CONFIGURAÇÃO ---
usuario_bp = Blueprint('usuario', __name__)

# --- FUNÇÕES AUXILIARES DE BANCO DE DADOS ---
def email_existe(email, id_excluido=None):
    """Verifica se um email já está cadastrado no banco de dados."""
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            sql = "SELECT id FROM USUARIO WHERE email = %s"
            params = [email]
            
            if id_excluido is not None:
                sql += " AND id <> %s"
                params.append(id_excluido)
                
            cursor.execute(sql, tuple(params))
            return cursor.fetchone() is not None
    finally:
        db.close()

# --- FUNÇÕES DE VALIDAÇÃO ---
def verificar_nome(nome_usuario):
    """Valida o nome do usuário."""
    if (
        not nome_usuario
        or nome_usuario.isspace()
        or len(nome_usuario) > 100
        or len(nome_usuario) < 3
        or not all(parte.isalpha() for parte in nome_usuario.split())
    ):
        return "Nome do usuário inválido"
    return True

def verificar_email(email_usuario):
    """Valida o formato do email."""
    if (
        not email_usuario
        or email_usuario.isspace()
        or len(email_usuario) > 100
        or len(email_usuario) < 5
        or '@' not in email_usuario
        or '.' not in email_usuario
    ):
        return "Email do usuário inválido"    
    return True

def verificar_senha(senha_usuario, senha_repeat_usuario):
    """Valida a senha e sua confirmação."""
    if (
        not senha_repeat_usuario 
        or not senha_usuario
        or senha_repeat_usuario != senha_usuario
        or senha_usuario.isspace()
        or len(senha_usuario) > 100
        or len(senha_usuario) < 6
    ):
        return "Senha do usuário inválida"
    return True

def verificar_tipo(tipo_usuario):
    """Valida o tipo de acesso do usuário."""
    if (
        not tipo_usuario
        or tipo_usuario.isspace()
        or tipo_usuario not in TIPOS_VALIDOS
    ):
        return "Tipo do usuário inválido"
    return True

def validar_usuario(nome, email, senha, senha_repeat, tipo):
    """Executa todas as validações de um usuário."""
    validacoes = [
        verificar_nome(nome),
        verificar_email(email),
        verificar_senha(senha, senha_repeat),
        verificar_tipo(tipo)
    ]
    for validacao in validacoes:
        if validacao is not True:
            return validacao
    return True

# --- ROTAS (BLUEPRINT) ---

@usuario_bp.route('/usuarios/perfil', methods=['GET'])
@login_requerido
def get_perfil_usuario():
    """Obtém o perfil do usuário logado ou o primeiro usuário disponível."""
    user_id = g.usuario_logado.get('id')

    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            if user_id:
                cursor.execute(
                    "SELECT id, nome, email, tipo FROM USUARIO WHERE id = %s", 
                    (user_id,)
                )
            else:
                cursor.execute(
                    "SELECT id, nome, email, tipo FROM USUARIO ORDER BY id LIMIT 1"
                )
            usuario = cursor.fetchone()
            if usuario:
                return jsonify(usuario), 200
            else:
                return jsonify({"error": "Usuário não encontrado!"}), 404
    finally:
        db.close()

@usuario_bp.route('/usuarios', methods=['GET'])
@login_requerido
@papeis_autorizados('ADMIN')
def list_usuarios():
    """Lista todos os usuários cadastrados."""
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute("SELECT id, nome, email, tipo FROM USUARIO")
            return jsonify(cursor.fetchall()), 200
    finally:
        db.close()

@usuario_bp.route('/usuarios/<int:id>', methods=['GET'])
@login_requerido
def get_usuario(id):
    """Obtém os detalhes de um usuário específico."""
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute("SELECT id, nome, email, tipo FROM USUARIO WHERE id = %s", (id,))
            usuario = cursor.fetchone()
            if usuario:
                return jsonify(usuario), 200
            else:
                return jsonify({"error": "Usuário não encontrado!"}), 404
    finally:
        db.close()

@usuario_bp.route('/usuarios/registrar', methods=['POST'])
def registrar_paciente():
    """Permite que novos pacientes se registrem sem autenticação."""
    db = get_db_connection()
    try:
        dados_usuario = request.get_json()
        if not dados_usuario:
            return jsonify({"error": "Dados de usuário ausentes!"}), 400

        nome = dados_usuario.get('nome')
        email = dados_usuario.get('email')
        senha = dados_usuario.get('senha')
        senha_repeat = dados_usuario.get('senha_repeat')
        tipo = "PACIENTE"  # Força PACIENTE para registro público

        # 1. Validação de formato
        validacao = validar_usuario(nome, email, senha, senha_repeat, tipo)
        if validacao is not True:
            return jsonify({"error": validacao}), 400

        # 2. Verificação de unicidade
        if email_existe(email):
            return jsonify({"error": "Email já cadastrado"}), 409

        # 3. Hash de senha e persistência
        senha_hash = bcrypt.generate_password_hash(senha).decode('utf-8')
        with db.cursor() as cursor:
            cursor.execute(
                "INSERT INTO USUARIO (nome, email, senha, tipo) VALUES (%s, %s, %s, %s)", 
                (nome, email, senha_hash, tipo)
            )
            db.commit()
            return jsonify({"message": "Paciente registrado com sucesso!"}), 201
    finally:
        db.close()

@usuario_bp.route('/usuarios', methods=['POST'])
@login_requerido
@papeis_autorizados('ADMIN')
def create_usuario():
    """Cria um novo usuário no sistema (apenas ADMIN)."""
    db = get_db_connection()
    try:
        dados_usuario = request.get_json()
        if not dados_usuario:
            return jsonify({"error": "Dados de usuário ausentes!"}), 400

        nome = dados_usuario.get('nome')
        email = dados_usuario.get('email')
        senha = dados_usuario.get('senha')
        senha_repeat = dados_usuario.get('senha_repeat')
        tipo = dados_usuario.get('tipo')

        # 1. Validação de formato
        validacao = validar_usuario(nome, email, senha, senha_repeat, tipo)
        if validacao is not True:
            return jsonify({"error": validacao}), 400

        # 2. Verificação de unicidade
        if email_existe(email):
            return jsonify({"error": "Email já cadastrado"}), 409

        # 3. Hash de senha e persistência
        senha_hash = bcrypt.generate_password_hash(senha).decode('utf-8')
        with db.cursor() as cursor:
            cursor.execute(
                "INSERT INTO USUARIO (nome, email, senha, tipo) VALUES (%s, %s, %s, %s)", 
                (nome, email, senha_hash, tipo)
            )
            db.commit()
            return jsonify({"message": "Usuário criado com sucesso!"}), 201
    finally:
        db.close()

@usuario_bp.route('/usuarios/<int:id>', methods=['PUT'])
@login_requerido
def update_usuario(id):
    """Atualiza um usuário existente (senha é opcional)."""
    db = get_db_connection()
    try: 
        with db.cursor() as cursor:
            # 1. Verificar existência e obter tipo atual
            cursor.execute("SELECT id, tipo FROM USUARIO WHERE id = %s", (id,))
            usuario_existente = cursor.fetchone()
            if not usuario_existente:
                return jsonify({"error": "Usuário não encontrado!"}), 404

            # Autenticação e Autorização
            if not g.get('user_id'):
                return jsonify({"error": "Autenticação requerida!"}), 401
            
            logged_in_user_id = g.user_id
            logged_in_user_role = g.usuario_logado.get('tipo', 'PACIENTE').upper()
            
            if logged_in_user_role != 'ADMIN' and logged_in_user_id != id:
                return jsonify({"error": "Não autorizado!"}), 403

            dados_usuario = request.get_json()
            if not dados_usuario:
                return jsonify({"error": "Dados de usuário ausentes!"}), 400
            
            nome = dados_usuario.get('nome')
            email = dados_usuario.get('email')
            tipo = dados_usuario.get('tipo')   
            senha = dados_usuario.get('senha')
            senha_repeat = dados_usuario.get('senha_repeat')
            
            # Impedir alteração de tipo (role) por não-admins
            if logged_in_user_role != 'ADMIN' or tipo is None:
                tipo = usuario_existente['tipo']
            
            # 2. Validações básicas (nome, email, tipo)
            if verificar_nome(nome) is not True:
                return jsonify({"error": "Nome inválido"}), 400
            if verificar_email(email) is not True:
                return jsonify({"error": "Email inválido"}), 400
            if verificar_tipo(tipo) is not True:
                return jsonify({"error": "Tipo inválido"}), 400
            
            # 3. Verificação de unicidade de email
            if email_existe(email, id):
                return jsonify({"error": "Email já cadastrado por outro usuário"}), 409
            
            # 4. Montar a query dinamicamente baseada na presença da senha
            if senha or senha_repeat:
                if verificar_senha(senha, senha_repeat) is not True:
                    return jsonify({"error": "Senha inválida ou divergente"}), 400
                
                senha_hash = bcrypt.generate_password_hash(senha).decode('utf-8')
                sql = "UPDATE USUARIO SET nome = %s, email = %s, tipo = %s, senha = %s WHERE id = %s"
                params = (nome, email, tipo, senha_hash, id)
            else:
                # Atualiza tudo, exceto a senha
                sql = "UPDATE USUARIO SET nome = %s, email = %s, tipo = %s WHERE id = %s"
                params = (nome, email, tipo, id)

            cursor.execute(sql, params)
            db.commit()
            return jsonify({"message": f"Usuário {id} atualizado com sucesso!"}), 200
    finally:        
        db.close()

@usuario_bp.route('/usuarios/<int:id>', methods=['DELETE'])
@login_requerido
def delete_usuario(id):
    """Deleta um usuário, tratando restrições de integridade."""
    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            # 1. Verificar se o usuário existe
            cursor.execute("SELECT id FROM USUARIO WHERE id = %s", (id,))
            if not cursor.fetchone():
                return jsonify({"error": "Usuário não encontrado!"}), 404

            # 2. Tentar deletar
            try:
                cursor.execute("DELETE FROM USUARIO WHERE id = %s", (id,))
                db.commit()
                return jsonify({"message": "Usuário removido com sucesso!"}), 200
            except Exception as e:
                # Captura erro de integridade (ex: usuário vinculado a médico ou consulta)
                return jsonify({
                    "error": "Não é possível excluir: o usuário possui vínculos no sistema (consultas, registros médicos, etc)."
                }), 400
    finally:
        db.close()
