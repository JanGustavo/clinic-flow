import os
import json
from flask import Blueprint, jsonify, render_template

swagger_bp = Blueprint('swagger', __name__)

@swagger_bp.route('/docs')
def serve_docs():
    """Serve a página interativa do Swagger UI."""
    return render_template('swagger.html')


@swagger_bp.route('/swagger.json')
def serve_swagger_json():
    """Retorna o arquivo de especificação OpenAPI 3.0."""
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    file_path = os.path.join(base_dir, 'static', 'swagger.json')
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return jsonify(data), 200
    except Exception as e:
        return jsonify({"error": f"Erro ao ler documentação: {str(e)}"}), 500
