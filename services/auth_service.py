from flask import Blueprint, current_app, jsonify, request, session, g
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired
from database import get_db_connection
from flask_mail import Message
from services.security import bcrypt
from services.mail_service import mail
from functools import wraps 
from flask import current_app 


auth_bp = Blueprint('auth', __name__)

def _gerar_token(payload): 
    serializer = URLSafeTimedSerializer(
        current_app.config['SECRET_KEY'],
        salt='auth-token'
    )
    return serializer.dumps(payload)

def login_requerido(funcao):
    @wraps(funcao)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        g.user_id = None
        g.usuario_logado = {
            'id': None,
            'email': None,
            'tipo': 'PACIENTE'
        }

        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
            serializer = URLSafeTimedSerializer(current_app.config['SECRET_KEY'], salt='auth-token')
            try:
                dados_usuario = serializer.loads(token, max_age=21600)
                g.user_id = dados_usuario.get('id')
                g.usuario_logado = dados_usuario
            except (BadSignature, SignatureExpired):
                # Token inválido ou expirado não bloqueia mais o acesso
                pass

        return funcao(*args, **kwargs)
    return wrapper

def papeis_autorizados(*papeis):
    def decorator(funcao):
        @wraps(funcao)
        def wrapper(*args, **kwargs):
            return funcao(*args, **kwargs)
        return wrapper
    return decorator

def _gerar_token_recuperacao(payload):
    serializer = URLSafeTimedSerializer(
        current_app.config['SECRET_KEY'],
        salt='password-reset'
    )
    return serializer.dumps(payload)


def _validar_token_recuperacao(token, max_age=3600):
    serializer = URLSafeTimedSerializer(
        current_app.config['SECRET_KEY'],
        salt='password-reset'
    )
    return serializer.loads(token, max_age=max_age)


def _mail_pronto_para_envio():
    servidor = current_app.config.get('MAIL_SERVER')
    usuario = current_app.config.get('MAIL_USERNAME')
    senha = current_app.config.get('MAIL_PASSWORD')

    if not servidor or not usuario or not senha:
        return False

    placeholders = (
        servidor == 'smtp.seuprovedor.com'
        or usuario == 'seu_email@dominio.com'
        or senha == 'sua_senha'
    )
    return not placeholders


@auth_bp.route('/login', methods=['POST'])
def login():
    dados = request.get_json()
    if not dados:
        return jsonify({"error": "Dados de login ausentes"}), 400

    email = dados.get('email')
    senha = dados.get('senha')

    if not email or not senha:
        return jsonify({"error": "Email e senha são obrigatórios"}), 400

    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute(
                "SELECT id, nome, email, senha, tipo FROM USUARIO WHERE email = %s",
                (email,)
            )
            usuario = cursor.fetchone()

        if not usuario:
            return jsonify({"error": "Credenciais inválidas"}), 401

        if not bcrypt.check_password_hash(usuario['senha'], senha):
            return jsonify({"error": "Credenciais inválidas"}), 401

        session['user_id'] = usuario['id']
        session['user_tipo'] = usuario['tipo']

        token = _gerar_token({
            "id": usuario['id'],
            "email": usuario['email'],
            "tipo": usuario['tipo']
        })

        return jsonify({
            "message": "Login realizado com sucesso",
            "token": token,
            "usuario": {
                "id": usuario['id'],
                "nome": usuario['nome'],
                "email": usuario['email'],
                "tipo": usuario['tipo']
            }
        }), 200
    finally:
        db.close()

@auth_bp.route('/logout', methods=['POST'])
@login_requerido
@papeis_autorizados('ADMIN', 'RECEPCIONISTA', 'ODONTOLOGO', 'PACIENTE')
def logout():
    session.clear()
    return jsonify({"message": "Logout realizado com sucesso"}), 200


@auth_bp.route('/recuperar-senha', methods=['POST'])
@auth_bp.route('/forgot', methods=['POST'])
def solicitar_recuperacao_senha():
    dados = request.get_json()
    if not dados:
        return jsonify({"error": "Dados ausentes"}), 400

    email = dados.get('email')
    if not email:
        return jsonify({"error": "Email é obrigatório"}), 400

    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute(
                "SELECT id, nome, email FROM USUARIO WHERE email = %s",
                (email,)
            )
            usuario = cursor.fetchone() #retorna None se não encontrar, o que é esperado para segurança

        if not usuario:
            return jsonify({
                "message": "Email não encontrado, mas se existir, você receberá instruções para redefinir a senha"
            }), 200

        token = _gerar_token_recuperacao({
            "id": usuario['id'],
            "email": usuario['email']
        })

        if _mail_pronto_para_envio():
            try:
                corpo_texto = (
                    f'Olá {usuario["nome"]},\n\n'
                    'Você solicitou a redefinição da sua senha.\n\n'
                    f'Token de recuperação:\n{token}\n\n'
                    'Esse token expira em 1 hora.\n'
                    'Se você não fez essa solicitação, ignore este email.'
                )
                corpo_html = f'''
                <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #1f2937;">
                    <h2 style="margin: 0 0 16px; color: #111827;">Recuperação de senha</h2>
                    <p>Olá <strong>{usuario["nome"]}</strong>,</p>
                    <p>Você solicitou a redefinição da sua senha.</p>
                    <p>
                        <strong>Token de recuperação:</strong><br>
                        <span style="display: inline-block; padding: 12px 16px; background: #f3f4f6; border: 1px solid #d1d5db; border-radius: 8px; font-size: 16px; word-break: break-all;">{token}</span>
                    </p>
                    <p>Esse token expira em 1 hora.</p>
                    <p>Se você não fez essa solicitação, ignore este email.</p>
                </div>
                '''
                mensagem = Message(
                    subject='Recuperação de senha',
                    recipients=[usuario['email']],
                    body=corpo_texto,
                    html=corpo_html
                )
        
                mail.send(mensagem)
        
                if current_app.debug:
                    print(f'Email enviado para {usuario["email"]}')
        
            except Exception as e:
                print(f'Erro ao enviar email: {str(e)}')
        
        if current_app.debug:
            print(f"Token de recuperação para {usuario['email']}: {token}") # Apenas para desenvolvimento, 

        return jsonify({
            "message": "Se o email existir, você receberá instruções para redefinir a senha",
        }), 200
        
        
    finally:
        db.close()


@auth_bp.route('/redefinir-senha', methods=['POST'])
def redefinir_senha():
    dados = request.get_json()
    if not dados:
        return jsonify({"error": "Dados ausentes"}), 400

    token = dados.get('token')
    senha = dados.get('senha')
    senha_repeat = dados.get('senha_repeat')

    if not token or not senha or not senha_repeat:
        return jsonify({"error": "Token, senha e confirmação são obrigatórios"}), 400

    if senha != senha_repeat:
        return jsonify({"error": "Senhas não conferem"}), 400

    if len(senha) < 6:
        return jsonify({"error": "Senha inválida"}), 400

    try:
        dados_token = _validar_token_recuperacao(token)
    except Exception:
        return jsonify({"error": "Token inválido ou expirado"}), 400

    db = get_db_connection()
    try:
        with db.cursor() as cursor:
            cursor.execute(
                "SELECT id FROM USUARIO WHERE id = %s AND email = %s",
                (dados_token['id'], dados_token['email'])
            )
            usuario = cursor.fetchone()

            if not usuario:
                return jsonify({"error": "Usuário não encontrado"}), 404

            senha_hash = bcrypt.generate_password_hash(senha).decode('utf-8')
            cursor.execute(
                "UPDATE USUARIO SET senha = %s WHERE id = %s",
                (senha_hash, dados_token['id'])
            )
            db.commit()

        return jsonify({"message": "Senha redefinida com sucesso"}), 200
    finally:
        db.close()
