import os
from flask import Flask, render_template, request, jsonify

try:
    from dotenv import load_dotenv
except ImportError:
    load_dotenv = None

if load_dotenv is not None:
    load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

app.config['MAIL_SERVER'] = os.getenv('MAIL_SERVER', '')
app.config['MAIL_PORT'] = int(os.getenv('MAIL_PORT', '587'))
app.config['MAIL_USE_TLS'] = os.getenv('MAIL_USE_TLS', 'True').lower() in ('1', 'true', 'yes', 'on')
app.config['MAIL_USE_SSL'] = os.getenv('MAIL_USE_SSL', 'False').lower() in ('1', 'true', 'yes', 'on')
app.config['MAIL_USERNAME'] = os.getenv('MAIL_USERNAME', '')
app.config['MAIL_PASSWORD'] = os.getenv('MAIL_PASSWORD', '')
app.config['MAIL_DEFAULT_SENDER'] = os.getenv('MAIL_DEFAULT_SENDER', '')

from services.security import bcrypt
from services.mail_service import mail
from flask_cors import CORS
CORS(app)
bcrypt.init_app(app)
mail.init_app(app)

from routes.usuario_routes import usuario_bp
from routes.paciente_routes import paciente_bp
from routes.odontologo_routes import odontologo_bp
from routes.consulta_routes import consulta_bp
from routes.procedimentos_routes import procedimento_bp
from routes.anamnese_routes import anamnese_bp
from services.auth_service import auth_bp

# Configurações para JSON
app.config['JSON_SORT_KEYS'] = False
app.config['JSON_AS_ASCII'] = False
app.json.ensure_ascii = False


from werkzeug.exceptions import HTTPException

# Registrar Blueprints
app.register_blueprint(usuario_bp)
app.register_blueprint(paciente_bp)
app.register_blueprint(odontologo_bp)
app.register_blueprint(consulta_bp)
app.register_blueprint(procedimento_bp)
app.register_blueprint(anamnese_bp)
app.register_blueprint(auth_bp, url_prefix='/auth')

@app.after_request
def padronizar_respostas(response):
    if response.is_json:
        try:
            dados = response.get_json()
        except Exception:
            return response

        # Se já estiver no novo padrão, não altera nada
        if isinstance(dados, dict) and "success" in dados and ("data" in dados or "error" in dados):
            return response

        status = response.status_code
        sucesso = 200 <= status < 300

        novo_corpo = {}
        if sucesso:
            novo_corpo["success"] = True
            novo_corpo["data"] = dados
        else:
            novo_corpo["success"] = False
            if isinstance(dados, dict):
                if "error" in dados:
                    novo_corpo["error"] = dados["error"]
                elif "message" in dados:
                    novo_corpo["error"] = dados["message"]
                else:
                    novo_corpo["error"] = dados
            else:
                novo_corpo["error"] = str(dados)

        dados_serializados = app.json.dumps(novo_corpo)
        response.set_data(dados_serializados)
        response.headers['Content-Length'] = str(len(response.data))
        response.content_type = "application/json"
    return response

@app.errorhandler(HTTPException)
def tratar_erro_http(e):
    response = e.get_response()
    dados_serializados = app.json.dumps({
        "success": False,
        "error": e.description
    })
    response.set_data(dados_serializados)
    response.headers['Content-Length'] = str(len(response.data))
    response.content_type = "application/json"
    return response

@app.errorhandler(Exception)
def tratar_erro_generico(e):
    if isinstance(e, HTTPException):
        return e

    if app.debug:
        raise e

    response = jsonify({
        "success": False,
        "error": "Erro interno do servidor"
    })
    return response, 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"}), 200



if __name__ == '__main__':
    app.run(debug=True)
