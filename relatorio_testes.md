# Relatório de Testes Unitários de Rotas da Clínica (Incluindo PUT e DELETE)

## Teste: GET /usuarios
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 200
- Body:
```json
[
  {
    "email": "teste.unitario@clinica.com",
    "id": 1,
    "nome": "Teste Usuário",
    "tipo": "MEDICO"
  }
]
```

## Teste: POST /usuarios
**Input:**
```json
{
  "nome": "Novo Usuario",
  "email": "teste.novo@clinica.com",
  "senha": "password123",
  "senha_repeat": "password123",
  "tipo": "PACIENTE"
}
```
**Response:**
- Status: 201
- Body:
```json
{
  "message": "Usuário criado com sucesso!"
}
```

## Teste: GET /usuarios/1
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 200
- Body:
```json
{
  "email": "teste.unitario@clinica.com",
  "id": 1,
  "nome": "Teste Usuário",
  "tipo": "MEDICO"
}
```

## Teste: PUT /usuarios/1
**Input:**
```json
{
  "nome": "Teste Usuário Atualizado",
  "email": "teste.unitario@clinica.com",
  "senha": "newpassword123",
  "senha_repeat": "newpassword123",
  "tipo": "MEDICO"
}
```
**Response:**
- Status: 200
- Body:
```json
{
  "message": "Usuário 1 atualizado com sucesso!"
}
```

## Teste: DELETE /usuarios/9999
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 404
- Body:
```json
{
  "error": "Usuário não encontrado!"
}
```

## Teste: GET /pacientes
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 200
- Body:
```json
[
  {
    "bairro": "Sé",
    "cep": "01001000",
    "cidade": "São Paulo",
    "cpf": "12345678901",
    "data_nascimento": "Mon, 01 Jan 1990 00:00:00 GMT",
    "estado": "SP",
    "id": 1,
    "logradouro": "Praça da Sé",
    "nome": "João Paciente",
    "numero_casa": "1",
    "telefone": "11999999999"
  }
]
```

## Teste: POST /pacientes
**Input:**
```json
{
  "nome": "Novo Paciente",
  "data_nascimento": "1995-05-05",
  "cpf": "09876543210",
  "telefone": "11888888888",
  "cep": "02002000",
  "logradouro": "Rua X",
  "numero_casa": "2",
  "bairro": "Centro",
  "cidade": "São Paulo",
  "estado": "SP"
}
```
**Response:**
- Status: 201
- Body:
```json
{
  "message": "Paciente criado com sucesso!"
}
```

## Teste: GET /pacientes/1
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 200
- Body:
```json
{
  "bairro": "Sé",
  "cep": "01001000",
  "cidade": "São Paulo",
  "cpf": "12345678901",
  "data_nascimento": "Mon, 01 Jan 1990 00:00:00 GMT",
  "estado": "SP",
  "id": 1,
  "logradouro": "Praça da Sé",
  "nome": "João Paciente",
  "numero_casa": "1",
  "telefone": "11999999999"
}
```

## Teste: PUT /pacientes/1
**Input:**
```json
{
  "nome": "João Paciente Atualizado",
  "data_nascimento": "1990-01-01",
  "cpf": "12345678901",
  "telefone": "11999999998",
  "cep": "01001000",
  "logradouro": "Praça da Sé",
  "numero_casa": "10",
  "bairro": "Sé",
  "cidade": "São Paulo",
  "estado": "SP"
}
```
**Response:**
- Status: 200
- Body:
```json
{
  "message": "Paciente 1 atualizado com sucesso!"
}
```

## Teste: DELETE /pacientes/9999
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 404
- Body:
```json
{
  "error": "Paciente não encontrado!"
}
```

## Teste: GET /medicos
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 200
- Body:
```json
[
  {
    "crm": "CRM-RJ 278964",
    "especialidade": "Cardiologia",
    "id": 3,
    "nome": "Dr. Carlos Moreira",
    "salario": "18000.00"
  },
  {
    "crm": "CRM-RJ 264573",
    "especialidade": "Cardiologia",
    "id": 4,
    "nome": "Dra. Daniela Costa",
    "salario": "18500.00"
  },
  {
    "crm": "CRM-SP 154233",
    "especialidade": "Clínica Médica",
    "id": 1,
    "nome": "Dr. Alberto Fontes",
    "salario": "12000.00"
  },
  {
    "crm": "123456",
    "especialidade": "Clínica Médica",
    "id": 13,
    "nome": "Dr. House",
    "salario": "15000.00"
  },
  {
    "crm": "CRM-SP 157896",
    "especialidade": "Clínica Médica",
    "id": 2,
    "nome": "Dra. Beatriz Lemos",
    "salario": "12000.00"
  },
  {
    "crm": "CRM-MG 325697",
    "especialidade": "Pediatria",
    "id": 5,
    "nome": "Dr. Eduardo Nunes",
    "salario": "14000.00"
  },
  {
    "crm": "CRM-MG 347890",
    "especialidade": "Pediatria",
    "id": 6,
    "nome": "Dra. Fernanda Silva",
    "salario": "15000.00"
  }
]
```

## Teste: POST /medicos
**Input:**
```json
{
  "nome": "Dra. Teste",
  "crm": "112233",
  "salario": 14000.0,
  "id_especialidade": 2,
  "id_usuario": 2
}
```
**Response:**
- Status: 201
- Body:
```json
{
  "message": "Médico criado com sucesso!"
}
```

## Teste: GET /medicos/1
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 200
- Body:
```json
{
  "crm": "CRM-SP 154233",
  "especialidade": "Clínica Médica",
  "id": 1,
  "nome": "Dr. Alberto Fontes",
  "salario": "12000.00"
}
```

## Teste: PUT /medicos/1
**Input:**
```json
{
  "nome": "Dr. Alberto Fontes Atualizado",
  "crm": "154233",
  "salario": 12500.0,
  "id_especialidade": 1,
  "id_usuario": 1
}
```
**Erro:** (1062, "Duplicate entry '1' for key 'MEDICO.id_usuario'")

## Teste: DELETE /medicos/9999
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 404
- Body:
```json
{
  "error": "Médico não encontrado!"
}
```

## Teste: GET /consultas
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 200
- Body:
```json
[
  {
    "data_hora": "Mon, 01 Jun 2026 10:00:00 GMT",
    "id": 1,
    "medico": "Dr. Alberto Fontes",
    "motivo": "Rotina",
    "paciente": "João Paciente Atualizado",
    "prioridade": "ALTA",
    "usuario_responsavel": "Teste Usuário Atualizado",
    "valor": "150.00"
  }
]
```

## Teste: POST /consultas
**Input:**
```json
{
  "id_paciente": 1,
  "id_medico": 1,
  "id_usuario_responsavel": 1,
  "data_hora": "2026-08-01 14:00:00",
  "motivo": "Retorno",
  "valor": 100.0,
  "prioridade": "BAIXA"
}
```
**Response:**
- Status: 201
- Body:
```json
{
  "id": 2,
  "message": "Consulta criada com sucesso"
}
```

## Teste: GET /consultas/1
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 200
- Body:
```json
{
  "data_hora": "Mon, 01 Jun 2026 10:00:00 GMT",
  "id": 1,
  "medico": "Dr. Alberto Fontes",
  "motivo": "Rotina",
  "paciente": "João Paciente Atualizado",
  "prioridade": "ALTA",
  "usuario_responsavel": "Teste Usuário Atualizado",
  "valor": "150.00"
}
```

## Teste: PUT /consultas/1
**Input:**
```json
{
  "id_paciente": 1,
  "id_medico": 1,
  "id_usuario_responsavel": 1,
  "data_hora": "2026-06-01 11:00:00",
  "motivo": "Rotina Atualizada",
  "valor": 180.0,
  "prioridade": "ALTA"
}
```
**Response:**
- Status: 200
- Body:
```json
{
  "message": "Consulta 1 atualizada com sucesso"
}
```

## Teste: DELETE /consultas/9999
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 404
- Body:
```json
{
  "error": "Consulta não encontrada"
}
```

## Teste: GET /exames
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 200
- Body:
```json
[
  {
    "id": 3,
    "nome": "Colesterol Total e Frações",
    "valor": "30.00"
  },
  {
    "id": 19,
    "nome": "Densitometria Óssea",
    "valor": "200.00"
  },
  {
    "id": 10,
    "nome": "Ecocardiograma Transtorácico",
    "valor": "220.00"
  },
  {
    "id": 7,
    "nome": "Eletrocardiograma (ECG)",
    "valor": "80.00"
  },
  {
    "id": 11,
    "nome": "Endoscopia Digestiva Alta",
    "valor": "350.00"
  },
  {
    "id": 2,
    "nome": "Glicemia em Jejum",
    "valor": "15.00"
  },
  {
    "id": 17,
    "nome": "Hemoglobina Glicada (HbA1c)",
    "valor": "45.00"
  },
  {
    "id": 1,
    "nome": "Hemograma Completo",
    "valor": "35.00"
  },
  {
    "id": 15,
    "nome": "PCR - Proteína C Reativa",
    "valor": "35.00"
  },
  {
    "id": 13,
    "nome": "Pressão Arterial",
    "valor": "10.00"
  },
  {
    "id": 8,
    "nome": "Raio-X de Tórax",
    "valor": "90.00"
  },
  {
    "id": 12,
    "nome": "Ressonância Magnética de Crânio",
    "valor": "750.00"
  },
  {
    "id": 14,
    "nome": "Teste de COVID/Influenza",
    "valor": "45.00"
  },
  {
    "id": 20,
    "nome": "Teste de Gravidez",
    "valor": "25.00"
  },
  {
    "id": 4,
    "nome": "Triglicerídeos",
    "valor": "20.00"
  },
  {
    "id": 5,
    "nome": "TSH - Hormônio Tireoestimulante",
    "valor": "45.00"
  },
  {
    "id": 9,
    "nome": "Ultrassonografia Abdominal Total",
    "valor": "150.00"
  },
  {
    "id": 18,
    "nome": "Ultrassonografia Obstétrica",
    "valor": "180.00"
  },
  {
    "id": 6,
    "nome": "Urina Tipo I",
    "valor": "18.00"
  },
  {
    "id": 16,
    "nome": "Vitamina D",
    "valor": "60.00"
  }
]
```

## Teste: GET /exames/1
**Input:** Nenhum (ou parâmetros na URL)
**Response:**
- Status: 200
- Body:
```json
{
  "id": 1,
  "nome": "Hemograma Completo",
  "valor": "35.00"
}
```
