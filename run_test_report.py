import json
from app import app
from database import get_db_connection

client = app.test_client()
app.testing = True

report_lines = ["# Relatório de Testes Unitários de Rotas da Clínica (Incluindo PUT e DELETE)\n"]

def run_test(method, url, payload=None):
    report_lines.append(f"## Teste: {method} {url}")
    if payload:
        report_lines.append(f"**Input:**\n```json\n{json.dumps(payload, indent=2, ensure_ascii=False)}\n```")
    else:
        report_lines.append(f"**Input:** Nenhum (ou parâmetros na URL)")

    try:
        if method == "GET":
            response = client.get(url)
        elif method == "POST":
            response = client.post(url, json=payload)
        elif method == "PUT":
            response = client.put(url, json=payload)
        elif method == "DELETE":
            response = client.delete(url)
        
        status = response.status_code
        try:
            data = response.get_json()
            if data is None:
                data_str = str(response.data.decode('utf-8'))
            else:
                data_str = json.dumps(data, indent=2, ensure_ascii=False)
        except:
            data_str = response.data.decode('utf-8')
            
        report_lines.append(f"**Response:**\n- Status: {status}\n- Body:\n```json\n{data_str}\n```\n")
        return data
    except Exception as e:
        report_lines.append(f"**Erro:** {str(e)}\n")
        return None

# Usuarios
run_test("GET", "/usuarios")
run_test("POST", "/usuarios", {"nome": "Novo Usuario", "email": "teste.novo@clinica.com", "senha": "password123", "senha_repeat": "password123", "tipo": "PACIENTE"})
run_test("GET", "/usuarios/1")
run_test("PUT", "/usuarios/1", {"nome": "Teste Usuário Atualizado", "email": "teste.unitario@clinica.com", "senha": "newpassword123", "senha_repeat": "newpassword123", "tipo": "MEDICO"})
run_test("DELETE", "/usuarios/9999") # Tentando deletar um ID que provavelmente não existe

# Pacientes
run_test("GET", "/pacientes")
run_test("POST", "/pacientes", {"nome": "Novo Paciente", "data_nascimento": "1995-05-05", "cpf": "09876543210", "telefone": "11888888888", "cep": "02002000", "logradouro": "Rua X", "numero_casa": "2", "bairro": "Centro", "cidade": "São Paulo", "estado": "SP"})
run_test("GET", "/pacientes/1")
run_test("PUT", "/pacientes/1", {"nome": "João Paciente Atualizado", "data_nascimento": "1990-01-01", "cpf": "12345678901", "telefone": "11999999998", "cep": "01001000", "logradouro": "Praça da Sé", "numero_casa": "10", "bairro": "Sé", "cidade": "São Paulo", "estado": "SP"})
run_test("DELETE", "/pacientes/9999")

# Medicos
run_test("GET", "/medicos")
run_test("POST", "/medicos", {"nome": "Dra. Teste", "crm": "112233", "salario": 14000.0, "id_especialidade": 2, "id_usuario": 2})
run_test("GET", "/medicos/1")
run_test("PUT", "/medicos/1", {"nome": "Dr. Alberto Fontes Atualizado", "crm": "154233", "salario": 12500.0, "id_especialidade": 1, "id_usuario": 1})
run_test("DELETE", "/medicos/9999")

# Consultas
run_test("GET", "/consultas")
run_test("POST", "/consultas", {"id_paciente": 1, "id_medico": 1, "id_usuario_responsavel": 1, "data_hora": "2026-08-01 14:00:00", "motivo": "Retorno", "valor": 100.0, "prioridade": "BAIXA"})
run_test("GET", "/consultas/1")
run_test("PUT", "/consultas/1", {"id_paciente": 1, "id_medico": 1, "id_usuario_responsavel": 1, "data_hora": "2026-06-01 11:00:00", "motivo": "Rotina Atualizada", "valor": 180.0, "prioridade": "ALTA"})
run_test("DELETE", "/consultas/9999")

# Exames
run_test("GET", "/exames")
run_test("GET", "/exames/1")

with open("relatorio_testes.md", "w", encoding="utf-8") as f:
    f.write("\n".join(report_lines))

print("Relatório atualizado com PUT e DELETE!")
