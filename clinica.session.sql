-- MARIADB -- NOMES DE TABELAS MAIUSCULAS E NOMES DE COLUNAS MINUSCULAS
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS CONSULTA_PROCEDIMENTO;
DROP TABLE IF EXISTS PROCEDIMENTO;
DROP TABLE IF EXISTS EXAME;
DROP TABLE IF EXISTS ANAMNESE;
DROP TABLE IF EXISTS CONSULTA;
DROP TABLE IF EXISTS DISPONIBILIDADE_ODONTOLOGO;
DROP TABLE IF EXISTS ODONTOLOGO;
DROP TABLE IF EXISTS PACIENTE;
DROP TABLE IF EXISTS ESPECIALIDADE;
DROP TABLE IF EXISTS USUARIO;
-- Também removemos as tabelas antigas de médicos se ainda existirem
DROP TABLE IF EXISTS DISPONIBILIDADE_MEDICO;
DROP TABLE IF EXISTS MEDICO;
SET FOREIGN_KEY_CHECKS = 1;
-- 1. USUARIO: Quem usa o sistema (Autenticação)
CREATE TABLE USUARIO (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    tipo ENUM(
        'ADMIN',
        'RECEPCIONISTA',
        'ODONTOLOGO',
        'PACIENTE'
    ) NOT NULL
);
-- Especialidade dos profissionais
CREATE TABLE ESPECIALIDADE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE
);
-- 2. ODONTOLOGO (Dentista)
CREATE TABLE ODONTOLOGO (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    id_especialidade INT NOT NULL,
    cro VARCHAR(20) NOT NULL UNIQUE,
    salario DECIMAL(10, 2) NOT NULL CHECK (salario >= 0),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- 2.1 DISPONIBILIDADE_ODONTOLOGO (Escala de plantão do odontólogo)
CREATE TABLE DISPONIBILIDADE_ODONTOLOGO (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_odontologo INT NOT NULL,
    dia_semana ENUM(
        'SEGUNDA',
        'TERCA',
        'QUARTA',
        'QUINTA',
        'SEXTA',
        'SABADO',
        'DOMINGO'
    ) NOT NULL,
    turno ENUM('MANHA', 'TARDE', 'NOITE') NOT NULL,
    -- Garante que não teremos o mesmo turno repetido no mesmo dia para o mesmo odontólogo
    CONSTRAINT uk_odontologo_dia_turno UNIQUE (id_odontologo, dia_semana, turno)
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
-- 3.1 ANAMNESE: Histórico do paciente (Relaciona-se com o paciente, mas não é obrigatório)
CREATE TABLE ANAMNESE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente INT NOT NULL UNIQUE,
    -- Um paciente tem no máximo uma anamnese
    alergia BOOLEAN DEFAULT FALSE,
    descricao_alergia TEXT,
    diabetes BOOLEAN DEFAULT FALSE,
    hipertensao BOOLEAN DEFAULT FALSE,
    cardiopatia BOOLEAN DEFAULT FALSE,
    gestante BOOLEAN NULL,
    usa_medicacao BOOLEAN DEFAULT FALSE,
    descricao_medicacao TEXT,
    observacoes TEXT,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- 4. CONSULTA: Relaciona Paciente, Odontólogo e o Usuário que criou/agendou
CREATE TABLE CONSULTA (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_paciente INT NOT NULL,
    id_odontologo INT NOT NULL,
    id_usuario_responsavel INT NOT NULL,
    -- Quem marcou a consulta (Recepcionista, o próprio Paciente, etc.)
    data_hora DATETIME NOT NULL,
    motivo VARCHAR(255),
    sintomas TEXT,
    observacoes_odontologicas TEXT,
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
-- 5. PROCEDIMENTO: Catálogo de exames disponíveis (O Produto)
CREATE TABLE PROCEDIMENTO (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    valor DECIMAL(10, 2) NOT NULL CHECK (valor >= 0),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- 6. CONSULTA_PROCEDIMENTO: Procedimento efetivamente realizado na consulta (A Instância)
CREATE TABLE CONSULTA_PROCEDIMENTO (
    id_consulta INT NOT NULL,
    id_procedimento INT NOT NULL,
    dente VARCHAR(10),
    quantidade INT DEFAULT 1 CHECK (quantidade > 0),
    observacoes TEXT,
    resultado TEXT,
    -- O resultado vem para cá, pois pertence à realização do procedimento
    status ENUM(
        'SOLICITADO',
        'EM_ANALISE',
        'CONCLUIDO',
        'CANCELADO'
    ) NOT NULL DEFAULT 'SOLICITADO',
    PRIMARY KEY (id_consulta, id_procedimento)
);
-- ADIÇÃO DAS CHAVES ESTRANGEIRAS (FOREIGN KEYS)
-- Consulta_Procedimento (Relacionamento N:M)
ALTER TABLE CONSULTA_PROCEDIMENTO
ADD CONSTRAINT fk_consulta_procedimento_consulta FOREIGN KEY (id_consulta) REFERENCES CONSULTA(id),
    ADD CONSTRAINT fk_consulta_procedimento_procedimento FOREIGN KEY (id_procedimento) REFERENCES PROCEDIMENTO(id);
-- Consulta
ALTER TABLE CONSULTA
ADD CONSTRAINT fk_consulta_paciente FOREIGN KEY (id_paciente) REFERENCES PACIENTE(id),
    ADD CONSTRAINT fk_consulta_odontologo FOREIGN KEY (id_odontologo) REFERENCES ODONTOLOGO(id),
    ADD CONSTRAINT fk_consulta_usuario_responsavel FOREIGN KEY (id_usuario_responsavel) REFERENCES USUARIO(id);
-- Odontólogo
ALTER TABLE ODONTOLOGO
ADD CONSTRAINT fk_odontologo_especialidade FOREIGN KEY (id_especialidade) REFERENCES ESPECIALIDADE(id),
    ADD CONSTRAINT fk_odontologo_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id);
-- Disponibilidade Odontólogo
ALTER TABLE DISPONIBILIDADE_ODONTOLOGO
ADD CONSTRAINT fk_disponibilidade_odontologo FOREIGN KEY (id_odontologo) REFERENCES ODONTOLOGO(id) ON DELETE CASCADE;
ALTER TABLE ANAMNESE
ADD CONSTRAINT fk_anamnese_paciente FOREIGN KEY (id_paciente) REFERENCES PACIENTE(id) ON DELETE CASCADE;