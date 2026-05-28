# Guia de Integração da API - Sorriso Perfeito (Clinic Flow)

Este guia prático foi criado para auxiliar a equipe de desenvolvimento Frontend no consumo de todos os recursos oferecidos pela API.

---

## 🔑 Padrões Globais da API

### 1. URL Base

**Local / Desenvolvimento:** `http://localhost:5000`

### 2. Formato das Respostas (Response Envelopes)

Todas as respostas da API seguem um padrão consistente de encapsulamento configurado no servidor:

#### Resposta de Sucesso (Status `200` a `299`)

```json
{
  "success": true,
  "data": {
    // Dados retornados pela rota (objeto, lista, etc.)
  }
}
```

#### Resposta de Erro (Status `400` a `599`)

```json
{
  "success": false,
  "error": "Descrição clara do erro ocorrido"
}
```

### 3. Mecanismo de Autenticação

**Tipo:** JWT (JSON Web Token)

**Envio:** Cabeçalho HTTP `Authorization` usando o esquema `Bearer`

**Exemplo de Header:**

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Validade do Token:** 6 horas

---

## 🏷️ Tabela de Rotas e Permissões (RBAC)

Abaixo está o catálogo completo de caminhos agrupados por módulos de negócio.

---

### 🔑 Módulo: Autenticação

#### 1. Realizar Login

**Endpoint:** `POST /auth/login`

**Autenticação:** Não requer token (Público)

**Payload de Envio:**

```json
{
  "email": "test_unique@example.com",
  "senha": "password123"
}
```

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": {
    "message": "Login realizado com sucesso",
    "token": "eyJhbGciOiJIUzI1Ni...",
    "usuario": {
      "id": 10,
      "nome": "Dr. Fernando Dentista",
      "email": "fernando@example.com",
      "tipo": "ODONTOLOGO"
    }
  }
}
```

#### 2. Encerrar Sessão

**Endpoint:** `POST /auth/logout`

**Autenticação:** **Requer JWT** (Qualquer usuário logado)

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": {
    "message": "Logout realizado com sucesso"
  }
}
```

#### 3. Solicitar Recuperação de Senha

**Endpoint:** `POST /auth/recuperar-senha`

**Autenticação:** Não requer token (Público)

**Payload de Envio:**

```json
{
  "email": "fernando@example.com"
}
```

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": {
    "message": "Se o email existir, você receberá instruções para redefinir a senha"
  }
}
```

#### 4. Redefinir Senha

**Endpoint:** `POST /auth/redefinir-senha`

**Autenticação:** Não requer token (Usa o token temporário do e-mail no corpo)

**Payload de Envio:**

```json
{
  "token": "token_recebido_por_email",
  "senha": "novaSenhaSegura123",
  "senha_repeat": "novaSenhaSegura123"
}
```

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": {
    "message": "Senha redefinida com sucesso"
  }
}
```

---

### 👥 Módulo: Usuários (Colaboradores)

> [!NOTE]
> Este módulo gerencia os logins de acesso ao sistema (ADMIN, RECEPCIONISTA, ODONTOLOGO, PACIENTE).

#### 1. Listar Usuários

**Endpoint:** `GET /usuarios`

**Autenticação:** **Requer JWT** (Apenas `ADMIN`)

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": [
    { "id": 1, "nome": "Maria Admin", "email": "admin@clinica.com", "tipo": "ADMIN" },
    { "id": 2, "nome": "Ana Recepção", "email": "ana@clinica.com", "tipo": "RECEPCIONISTA" }
  ]
}
```

#### 2. Obter Detalhes do Usuário

**Endpoint:** `GET /usuarios/{id}`

**Autenticação:** **Requer JWT** (Apenas `ADMIN` ou o Próprio Usuário dono do ID)

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": {
    "id": 2,
    "nome": "Ana Recepção",
    "email": "ana@clinica.com",
    "tipo": "RECEPCIONISTA"
  }
}
```

#### 3. Criar Novo Usuário

**Endpoint:** `POST /usuarios`

**Autenticação:** **Requer JWT** (Apenas `ADMIN`)

**Payload de Envio:**

```json
{
  "nome": "Dr. Fernando Dentista",
  "email": "fernando@example.com",
  "senha": "secret123",
  "senha_repeat": "secret123",
  "tipo": "ODONTOLOGO"
}
```

**Resposta de Sucesso (`201 Created`):**

```json
{
  "success": true,
  "data": {
    "message": "Usuário criado com sucesso!"
  }
}
```

#### 4. Atualizar Cadastro de Usuário

**Endpoint:** `PUT /usuarios/{id}`

**Autenticação:** **Requer JWT** (Apenas `ADMIN` ou o Próprio Usuário dono do ID)

**Payload de Envio:** (A senha é opcional para atualizações cadastrais)

```json
{
  "nome": "Dr. Fernando Dentista Silva",
  "email": "fernando.novo@example.com",
  "tipo": "ODONTOLOGO",
  "senha": "novaSenhaOpcional",
  "senha_repeat": "novaSenhaOpcional"
}
```

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": {
    "message": "Usuário 2 atualizado com sucesso!"
  }
}
```

#### 5. Excluir Usuário

**Endpoint:** `DELETE /usuarios/{id}`

**Autenticação:** **Requer JWT** (Apenas `ADMIN`)

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": {
    "message": "Usuário removido com sucesso!"
  }
}
```

---

### 🏥 Módulo: Pacientes

#### 1. Listar Pacientes

**Endpoint:** `GET /pacientes`

**Autenticação:** **Requer JWT** (`ADMIN`, `RECEPCIONISTA`, `ODONTOLOGO`)

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nome": "Ana Santos",
      "data_nascimento": "1992-07-20",
      "cpf": "98765432109",
      "telefone": "11988887777",
      "cep": "01001000",
      "logradouro": "Praça da Sé",
      "numero_casa": "100",
      "bairro": "Sé",
      "cidade": "São Paulo",
      "estado": "SP"
    }
  ]
}
```

#### 2. Obter Detalhes do Paciente

**Endpoint:** `GET /pacientes/{id}`

**Autenticação:** **Requer JWT** (`ADMIN`, `RECEPCIONISTA`, `ODONTOLOGO` ou o próprio `PACIENTE`)

#### 3. Cadastrar Paciente

**Endpoint:** `POST /pacientes`

**Autenticação:** **Requer JWT** (`ADMIN`, `RECEPCIONISTA`)

**Payload de Envio:**

```json
{
  "nome": "Ana Santos",
  "data_nascimento": "1992-07-20",
  "cpf": "98765432109",
  "telefone": "11988887777",
  "cep": "01001000",
  "logradouro": "Praça da Sé",
  "numero_casa": "100",
  "bairro": "Sé",
  "cidade": "São Paulo",
  "estado": "SP"
}
```

**Resposta de Sucesso (`201 Created`):**

```json
{
  "success": true,
  "data": {
    "message": "Paciente cadastrado com sucesso!"
  }
}
```

#### 4. Atualizar Dados do Paciente

**Endpoint:** `PUT /pacientes/{id}`

**Autenticação:** **Requer JWT** (`ADMIN`, `RECEPCIONISTA`, `ODONTOLOGO` ou o próprio `PACIENTE`)

#### 5. Excluir Paciente

**Endpoint:** `DELETE /pacientes/{id}`

**Autenticação:** **Requer JWT** (Apenas `ADMIN`)

---

### 📝 Módulo: Anamnese (Histórico Clínico)

> [!WARNING]
> Dado clínico altamente confidencial. Acesso restrito para proteção do paciente.

#### 1. Buscar Anamnese por ID

**Endpoint:** `GET /anamneses/{id}`

**Autenticação:** **Requer JWT** (Apenas `ADMIN`, `ODONTOLOGO` ou o próprio `PACIENTE` dono do histórico)

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "id_paciente": 5,
    "alergia": true,
    "descricao_alergia": "Penicilina",
    "diabetes": false,
    "hipertensao": true,
    "cardiopatia": false,
    "gestante": false,
    "usa_medicacao": true,
    "descricao_medicacao": "Aspirina",
    "observacoes": "Paciente ansioso",
    "criado_em": "2026-05-21T14:49:00",
    "atualizado_em": "2026-05-21T14:49:00"
  }
}
```

---

### 🦷 Módulo: Odontólogos (Dentistas)

#### 1. Listar Odontólogos

**Endpoint:** `GET /odontologos`

**Autenticação:** **Requer JWT** (`ADMIN`, `RECEPCIONISTA`, `ODONTOLOGO`)

#### 2. Criar Cadastro de Odontólogo

**Endpoint:** `POST /odontologos`

**Autenticação:** **Requer JWT** (Apenas `ADMIN`)

**Payload de Envio:**

```json
{
  "nome": "Dr. Fernando Dentista",
  "cro": "TEST-1234",
  "salario": 12000.00,
  "id_especialidade": 1,
  "id_usuario": 10
}
```

#### 3. Buscar Dentistas Disponíveis por Escala

**Endpoint:** `GET /odontologos/disponiveis/{dia_semana}/{turno}`

**Autenticação:** **Requer JWT** (Todos os perfis)

**Parâmetros da Rota:**

* `dia_semana`: `SEGUNDA`, `TERCA`, `QUARTA`, `QUINTA`, `SEXTA`, `SABADO` ou `DOMINGO`.
* `turno`: `MANHA`, `TARDE` ou `NOITE`.

**Query Params Opcionais:** `?especialidade=ORTODONTIA`

---

### 📅 Módulo: Consultas

#### 1. Listar Consultas

**Endpoint:** `GET /consultas`

**Autenticação:** **Requer JWT** (Todos os perfis. `PACIENTE` visualiza somente as suas).

#### 2. Agendar Nova Consulta

**Endpoint:** `POST /consultas`

**Autenticação:** **Requer JWT** (`ADMIN`, `RECEPCIONISTA`, `PACIENTE`)

**Payload de Envio:**

```json
{
  "id_paciente": 5,
  "id_odontologo": 2,
  "id_usuario_responsavel": 1,
  "data_hora": "2026-05-25 10:00:00",
  "motivo": "Extração de Siso",
  "valor": 300.00,
  "prioridade": "MEDIA"
}
```

#### 3. Vincular Procedimento à Consulta

**Endpoint:** `POST /consultas/{id_consulta}/procedimentos`

**Autenticação:** **Requer JWT** (`ADMIN`, `ODONTOLOGO` apenas)

**Payload de Envio:**

```json
{
  "id_procedimento": 1,
  "dente": "38",
  "quantidade": 1,
  "observacoes": "Extração tranquila",
  "status": "CONCLUIDO"
}
```

---

### 📖 Módulo: Catálogo de Procedimentos (Público)

#### 1. Listar Procedimentos

**Endpoint:** `GET /procedimentos`

**Autenticação:** Não requer token (Público - ideal para marketing do portal)

**Resposta de Sucesso (`200 OK`):**

```json
{
  "success": true,
  "data": [
    { "id": 1, "nome": "Limpeza Dental", "valor": 150.00 },
    { "id": 2, "nome": "Canal", "valor": 600.00 }
  ]
}
```

---

## 💡 Dicas de Integração no Front-end (React / Vue / Angular / Vanilla)

### 1. Interceptor de Requisições no Axios (Header de Autorização)

Configure o Axios para incluir automaticamente o token recuperado do seu gerenciador de estado (`localStorage` ou `sessionStorage`) em cada requisição protegida:

```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:5000',
});

// Adiciona o cabeçalho Authorization com o Token JWT em cada requisição
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token_clinica');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
}, (error) => {
  return Promise.reject(error);
});
```

### 2. Lidando com Sessão Expirada (`401 Unauthorized`)

Implemente um interceptor de resposta para redirecionar o usuário à tela de `/login` quando o token expirar:

```javascript
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Limpa dados expirados locais
      localStorage.removeItem('token_clinica');
      localStorage.removeItem('usuario_clinica');
      
      // Redireciona o usuário para a página de login
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
```
