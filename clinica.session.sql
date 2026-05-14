-- MARIADB -- NOMES DE TABELAS MAIUSCULAS E NOMES DE COLUNAS MINUSCULAS
DROP TABLE IF EXISTS CONSULTA_EXAME;
DROP TABLE IF EXISTS EXAME;
DROP TABLE IF EXISTS CONSULTA;
DROP TABLE IF EXISTS MEDICO;
DROP TABLE IF EXISTS PACIENTE;
DROP TABLE IF EXISTS ESPECIALIDADE;
DROP TABLE IF EXISTS USUARIO;
-- 1. USUARIO: Quem usa o sistema (Autenticação)
CREATE TABLE USUARIO (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    tipo ENUM('ADMIN', 'RECEPCIONISTA', 'MEDICO', 'PACIENTE') NOT NULL
);
CREATE TABLE ESPECIALIDADE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE
);
-- 2. MEDICO: Profissional que atende (Pode ter login associado)
CREATE TABLE MEDICO (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NULL UNIQUE,
    -- Permitir NULL caso o médico não acesse o sistema
    nome VARCHAR(100) NOT NULL,
    id_especialidade INT NOT NULL,
    crm VARCHAR(20) NOT NULL UNIQUE,
    salario DECIMAL(10, 2) NOT NULL CHECK (salario >= 0),
    plantao BOOLEAN NOT NULL DEFAULT FALSE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- 3. PACIENTE: Pessoa atendida (Apenas existe, sem login obrigatório)
CREATE TABLE PACIENTE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    data_nascimento DATE NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    cep VARCHAR(9) NOT NULL,
    logradouro VARCHAR(100) NOT NULL,
    numero_casa VARCHAR(10) NOT NULL,
    bairro VARCHAR(50) NOT NULL,
    cidade VARCHAR(50) NOT NULL,
    estado VARCHAR(2) NOT NULL,
    possui_plano_saude BOOLEAN NOT NULL DEFAULT FALSE,
    debito DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- 4. CONSULTA: Relaciona Paciente, Médico e o Usuário que criou/agendou
CREATE TABLE CONSULTA (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_medico INT NOT NULL,
    id_usuario_responsavel INT NOT NULL,
    -- Quem marcou a consulta (Recepcionista, o próprio Paciente, etc.)
    data_hora DATETIME NOT NULL,
    motivo VARCHAR(255),
    sintomas TEXT,
    observacoes_medicas TEXT,
    diagnostico_preliminar TEXT,
    valor DECIMAL(10, 2) NOT NULL CHECK (valor >= 0),
    prioridade ENUM('BAIXA', 'MEDIA', 'ALTA') NOT NULL DEFAULT 'MEDIA',
    status ENUM(
        'AGENDADA',
        'EM_ANDAMENTO',
        'CANCELADA',
        'FINALIZADA'
    ) NOT NULL DEFAULT 'AGENDADA',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- 5. EXAME: Catálogo de exames disponíveis (O Produto)
CREATE TABLE EXAME (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    valor DECIMAL(10, 2) NOT NULL CHECK (valor >= 0),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- 6. CONSULTA_EXAME: Exame efetivamente realizado na consulta (A Instância)
CREATE TABLE CONSULTA_EXAME (
    id_consulta INT NOT NULL,
    id_exame INT NOT NULL,
    resultado TEXT,
    -- O resultado vem para cá, pois pertence à realização do exame
    status ENUM(
        'SOLICITADO',
        'EM_ANALISE',
        'CONCLUIDO',
        'CANCELADO'
    ) NOT NULL DEFAULT 'SOLICITADO',
    PRIMARY KEY (id_consulta, id_exame)
);
-- ADIÇÃO DAS CHAVES ESTRANGEIRAS (FOREIGN KEYS)
-- Consulta_Exame (Relacionamento N:M)
ALTER TABLE CONSULTA_EXAME
ADD CONSTRAINT fk_consulta_exame_consulta FOREIGN KEY (id_consulta) REFERENCES CONSULTA(id),
    ADD CONSTRAINT fk_consulta_exame_exame FOREIGN KEY (id_exame) REFERENCES EXAME(id);
-- Consulta
ALTER TABLE CONSULTA
ADD CONSTRAINT fk_consulta_paciente FOREIGN KEY (id_paciente) REFERENCES PACIENTE(id),
    ADD CONSTRAINT fk_consulta_medico FOREIGN KEY (id_medico) REFERENCES MEDICO(id),
    ADD CONSTRAINT fk_consulta_usuario_responsavel FOREIGN KEY (id_usuario_responsavel) REFERENCES USUARIO(id);
-- Médico
ALTER TABLE MEDICO
ADD CONSTRAINT fk_medico_especialidade FOREIGN KEY (id_especialidade) REFERENCES ESPECIALIDADE(id),
    ADD CONSTRAINT fk_medico_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id);