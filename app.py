from flask import Flask, render_template
from routes.usuario_routes import usuario_bp
from routes.paciente_routes import paciente_bp
from routes.medico_routes import medico_bp
from routes.consulta_routes import consulta_bp
from routes.exame_routes import exame_bp

app = Flask(__name__)

# Registrar Blueprints
app.register_blueprint(usuario_bp)
app.register_blueprint(paciente_bp)
app.register_blueprint(medico_bp)
app.register_blueprint(consulta_bp)
app.register_blueprint(exame_bp)

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True)
