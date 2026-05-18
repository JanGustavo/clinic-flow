from flask import Flask, render_template, request, jsonify
from flask_bcrypt import Bcrypt
from routes.usuario_routes import usuario_bp
from routes.paciente_routes import paciente_bp
from routes.medico_routes import medico_bp
from routes.consulta_routes import consulta_bp
from routes.exame_routes import exame_bp

app = Flask(__name__)
bcrypt = Bcrypt(app)

# Configurações para JSON
app.config['JSON_SORT_KEYS'] = False
app.config['JSON_AS_ASCII'] = False
app.json.ensure_ascii = False


# Registrar Blueprints
app.register_blueprint(usuario_bp)
app.register_blueprint(paciente_bp)
app.register_blueprint(medico_bp)
app.register_blueprint(consulta_bp)
app.register_blueprint(exame_bp)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(debug=True)
