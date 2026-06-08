-- MySQL dump 10.13  Distrib 8.0.45, for Linux (x86_64)
--
-- Host: localhost    Database: clinica
-- ------------------------------------------------------
-- Server version	8.0.45-0ubuntu0.24.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `ANAMNESE`
--

DROP TABLE IF EXISTS `ANAMNESE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ANAMNESE` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_paciente` int NOT NULL,
  `alergia` tinyint(1) DEFAULT '0',
  `descricao_alergia` text,
  `diabetes` tinyint(1) DEFAULT '0',
  `hipertensao` tinyint(1) DEFAULT '0',
  `cardiopatia` tinyint(1) DEFAULT '0',
  `gestante` tinyint(1) DEFAULT NULL,
  `usa_medicacao` tinyint(1) DEFAULT '0',
  `descricao_medicacao` text,
  `observacoes` text,
  `criado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_paciente` (`id_paciente`),
  CONSTRAINT `fk_anamnese_paciente` FOREIGN KEY (`id_paciente`) REFERENCES `PACIENTE` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ANAMNESE`
--

LOCK TABLES `ANAMNESE` WRITE;
/*!40000 ALTER TABLE `ANAMNESE` DISABLE KEYS */;
/*!40000 ALTER TABLE `ANAMNESE` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CONSULTA`
--

DROP TABLE IF EXISTS `CONSULTA`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CONSULTA` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_paciente` int NOT NULL,
  `id_odontologo` int NOT NULL,
  `id_usuario_responsavel` int NOT NULL,
  `data_hora` datetime NOT NULL,
  `motivo` varchar(255) DEFAULT NULL,
  `sintomas` text,
  `observacoes_odontologicas` text,
  `diagnostico_preliminar` text,
  `valor` decimal(10,2) NOT NULL,
  `prioridade` enum('BAIXA','MEDIA','ALTA') NOT NULL DEFAULT 'MEDIA',
  `status` enum('AGENDADA','EM_ANDAMENTO','CANCELADA','FINALIZADA') NOT NULL DEFAULT 'AGENDADA',
  `criado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_consulta_paciente` (`id_paciente`),
  KEY `fk_consulta_odontologo` (`id_odontologo`),
  KEY `fk_consulta_usuario_responsavel` (`id_usuario_responsavel`),
  CONSTRAINT `fk_consulta_odontologo` FOREIGN KEY (`id_odontologo`) REFERENCES `ODONTOLOGO` (`id`),
  CONSTRAINT `fk_consulta_paciente` FOREIGN KEY (`id_paciente`) REFERENCES `PACIENTE` (`id`),
  CONSTRAINT `fk_consulta_usuario_responsavel` FOREIGN KEY (`id_usuario_responsavel`) REFERENCES `USUARIO` (`id`),
  CONSTRAINT `CONSULTA_chk_1` CHECK ((`valor` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CONSULTA`
--

LOCK TABLES `CONSULTA` WRITE;
/*!40000 ALTER TABLE `CONSULTA` DISABLE KEYS */;
/*!40000 ALTER TABLE `CONSULTA` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CONSULTA_EXAME`
--

DROP TABLE IF EXISTS `CONSULTA_EXAME`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CONSULTA_EXAME` (
  `id_consulta` int NOT NULL,
  `id_exame` int NOT NULL,
  `resultado` text,
  `status` enum('SOLICITADO','EM_ANALISE','CONCLUIDO','CANCELADO') NOT NULL DEFAULT 'SOLICITADO',
  PRIMARY KEY (`id_consulta`,`id_exame`),
  KEY `fk_consulta_exame_exame` (`id_exame`),
  CONSTRAINT `fk_consulta_exame_consulta` FOREIGN KEY (`id_consulta`) REFERENCES `CONSULTA` (`id`),
  CONSTRAINT `fk_consulta_exame_exame` FOREIGN KEY (`id_exame`) REFERENCES `EXAME` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CONSULTA_EXAME`
--

LOCK TABLES `CONSULTA_EXAME` WRITE;
/*!40000 ALTER TABLE `CONSULTA_EXAME` DISABLE KEYS */;
/*!40000 ALTER TABLE `CONSULTA_EXAME` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CONSULTA_PROCEDIMENTO`
--

DROP TABLE IF EXISTS `CONSULTA_PROCEDIMENTO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CONSULTA_PROCEDIMENTO` (
  `id_consulta` int NOT NULL,
  `id_procedimento` int NOT NULL,
  `dente` varchar(10) DEFAULT NULL,
  `quantidade` int DEFAULT '1',
  `observacoes` text,
  `resultado` text,
  `status` enum('SOLICITADO','EM_ANALISE','CONCLUIDO','CANCELADO') NOT NULL DEFAULT 'SOLICITADO',
  PRIMARY KEY (`id_consulta`,`id_procedimento`),
  KEY `fk_consulta_procedimento_procedimento` (`id_procedimento`),
  CONSTRAINT `fk_consulta_procedimento_consulta` FOREIGN KEY (`id_consulta`) REFERENCES `CONSULTA` (`id`),
  CONSTRAINT `fk_consulta_procedimento_procedimento` FOREIGN KEY (`id_procedimento`) REFERENCES `PROCEDIMENTO` (`id`),
  CONSTRAINT `CONSULTA_PROCEDIMENTO_chk_1` CHECK ((`quantidade` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CONSULTA_PROCEDIMENTO`
--

LOCK TABLES `CONSULTA_PROCEDIMENTO` WRITE;
/*!40000 ALTER TABLE `CONSULTA_PROCEDIMENTO` DISABLE KEYS */;
/*!40000 ALTER TABLE `CONSULTA_PROCEDIMENTO` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `DISPONIBILIDADE_ODONTOLOGO`
--

DROP TABLE IF EXISTS `DISPONIBILIDADE_ODONTOLOGO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DISPONIBILIDADE_ODONTOLOGO` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_odontologo` int NOT NULL,
  `dia_semana` enum('SEGUNDA','TERCA','QUARTA','QUINTA','SEXTA','SABADO','DOMINGO') NOT NULL,
  `turno` enum('MANHA','TARDE','NOITE') NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_odontologo_dia_turno` (`id_odontologo`,`dia_semana`,`turno`),
  CONSTRAINT `fk_disponibilidade_odontologo` FOREIGN KEY (`id_odontologo`) REFERENCES `ODONTOLOGO` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `DISPONIBILIDADE_ODONTOLOGO`
--

LOCK TABLES `DISPONIBILIDADE_ODONTOLOGO` WRITE;
/*!40000 ALTER TABLE `DISPONIBILIDADE_ODONTOLOGO` DISABLE KEYS */;
INSERT INTO `DISPONIBILIDADE_ODONTOLOGO` VALUES (1,1,'SEGUNDA','MANHA'),(2,1,'SEGUNDA','TARDE'),(3,1,'QUARTA','MANHA'),(4,1,'QUARTA','TARDE'),(5,2,'TERCA','TARDE'),(6,2,'TERCA','NOITE'),(7,2,'QUINTA','TARDE'),(8,2,'QUINTA','NOITE'),(9,3,'SEGUNDA','NOITE'),(10,3,'SEXTA','MANHA'),(11,3,'SEXTA','TARDE'),(12,4,'QUINTA','MANHA'),(13,4,'SABADO','MANHA'),(14,5,'QUARTA','TARDE'),(15,5,'SEXTA','TARDE');
/*!40000 ALTER TABLE `DISPONIBILIDADE_ODONTOLOGO` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ESPECIALIDADE`
--

DROP TABLE IF EXISTS `ESPECIALIDADE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ESPECIALIDADE` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nome` (`nome`)
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ESPECIALIDADE`
--

LOCK TABLES `ESPECIALIDADE` WRITE;
/*!40000 ALTER TABLE `ESPECIALIDADE` DISABLE KEYS */;
INSERT INTO `ESPECIALIDADE` VALUES (1,'Clínica Geral'),(3,'Endodontia (Canal)'),(5,'Implantodontia'),(4,'Odontopediatria'),(2,'Ortodontia'),(73,'TEST-ESPECIALIDADE');
/*!40000 ALTER TABLE `ESPECIALIDADE` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ODONTOLOGO`
--

DROP TABLE IF EXISTS `ODONTOLOGO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ODONTOLOGO` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_usuario` int DEFAULT NULL,
  `nome` varchar(100) NOT NULL,
  `id_especialidade` int NOT NULL,
  `cro` varchar(20) NOT NULL,
  `salario` decimal(10,2) NOT NULL,
  `criado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cro` (`cro`),
  UNIQUE KEY `id_usuario` (`id_usuario`),
  KEY `fk_odontologo_especialidade` (`id_especialidade`),
  CONSTRAINT `fk_odontologo_especialidade` FOREIGN KEY (`id_especialidade`) REFERENCES `ESPECIALIDADE` (`id`),
  CONSTRAINT `fk_odontologo_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `USUARIO` (`id`),
  CONSTRAINT `ODONTOLOGO_chk_1` CHECK ((`salario` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ODONTOLOGO`
--

LOCK TABLES `ODONTOLOGO` WRITE;
/*!40000 ALTER TABLE `ODONTOLOGO` DISABLE KEYS */;
INSERT INTO `ODONTOLOGO` VALUES (1,3,'Dra. Camila Alencar',2,'CRO-SP12345',12500.00,'2026-05-21 19:00:53','2026-05-21 19:00:53'),(2,4,'Dr. Marcos Silveira',3,'CRO-SP67890',14000.00,'2026-05-21 19:00:53','2026-05-21 19:00:53'),(3,NULL,'Dra. Patrícia Lima',1,'CRO-SP54321',8500.00,'2026-05-21 19:00:53','2026-05-21 19:00:53'),(4,NULL,'Dr. Renato Souza',5,'CRO-SP98765',16500.00,'2026-05-21 19:00:53','2026-05-21 19:00:53'),(5,NULL,'Dra. Aline Santos',4,'CRO-SP11223',9800.00,'2026-05-21 19:00:53','2026-05-21 19:00:53');
/*!40000 ALTER TABLE `ODONTOLOGO` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `PACIENTE`
--

DROP TABLE IF EXISTS `PACIENTE`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `PACIENTE` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `data_nascimento` date NOT NULL,
  `cpf` char(11) NOT NULL,
  `telefone` varchar(20) DEFAULT NULL,
  `cep` varchar(9) NOT NULL,
  `logradouro` varchar(100) NOT NULL,
  `numero_casa` varchar(10) NOT NULL,
  `bairro` varchar(50) NOT NULL,
  `cidade` varchar(50) NOT NULL,
  `estado` varchar(2) NOT NULL,
  `possui_plano_saude` tinyint(1) NOT NULL DEFAULT '0',
  `debito` decimal(10,2) NOT NULL DEFAULT '0.00',
  `criado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cpf` (`cpf`)
) ENGINE=InnoDB AUTO_INCREMENT=68 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `PACIENTE`
--

LOCK TABLES `PACIENTE` WRITE;
/*!40000 ALTER TABLE `PACIENTE` DISABLE KEYS */;
INSERT INTO `PACIENTE` VALUES (1,'Ricardo Gomes','1990-07-22','11122233344','(11) 99999-1111','04101-000','Rua Vergueiro','1200','Vila Mariana','São Paulo','SP',0,0.00,'2026-05-21 19:03:27','2026-05-21 19:03:27'),(2,'Fernanda Ribeiro','1988-03-15','22233344455','(11) 99999-2222','01311-200','Avenida Paulista','500','Bela Vista','São Paulo','SP',1,0.00,'2026-05-21 19:03:27','2026-05-21 19:03:27'),(3,'Lucas Souza (Criança)','2018-11-05','33344455566','(11) 99999-3333','03102-010','Rua Mooca','45','Mooca','São Paulo','SP',0,0.00,'2026-05-21 19:03:27','2026-05-21 19:03:27'),(4,'Maria do Carmo','1955-01-30','44455566677','(11) 99999-4444','02001-000','Voluntários da Pátria','210','Santana','São Paulo','SP',1,150.00,'2026-05-21 19:03:27','2026-05-21 19:03:27'),(67,'TEST Patient','1990-01-01','12345678901','11999999999','01001000','TEST St','10','TEST Bairro','TEST City','SP',0,0.00,'2026-06-08 19:34:38','2026-06-08 19:34:38');
/*!40000 ALTER TABLE `PACIENTE` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `PROCEDIMENTO`
--

DROP TABLE IF EXISTS `PROCEDIMENTO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `PROCEDIMENTO` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `valor` decimal(10,2) NOT NULL,
  `criado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `PROCEDIMENTO_chk_1` CHECK ((`valor` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `PROCEDIMENTO`
--

LOCK TABLES `PROCEDIMENTO` WRITE;
/*!40000 ALTER TABLE `PROCEDIMENTO` DISABLE KEYS */;
INSERT INTO `PROCEDIMENTO` VALUES (1,'Consulta Inicial + Avaliação Clínica',100.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(2,'Profilaxia Completa (Limpeza e Raspagem)',180.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(3,'Aplicação Tópica de Flúor',90.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(4,'Restauração em Resina (1 Face)',150.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(5,'Restauração em Resina (Multi-faces)',220.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(6,'Tratamento de Canal (Endodontia) - Incisivo',450.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(7,'Tratamento de Canal (Endodontia) - Molar',750.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(8,'Extração Dentária Simples (Exodontia)',250.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(9,'Cirurgia de Remoção de Siso (Incluso)',500.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(10,'Implante Dentário de Titânio (Pino)',1800.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(11,'Prótese Dentária Sobre Implante',1400.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(12,'Manutenção Mensal de Aparelho Ortodôntico',130.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(13,'Clareamento Dental Caseiro (Kit + Moldeiras)',400.00,'2026-05-21 19:03:44','2026-05-21 19:03:44'),(14,'Clareamento Dental de Consultório (Sessão)',600.00,'2026-05-21 19:03:44','2026-05-21 19:03:44');
/*!40000 ALTER TABLE `PROCEDIMENTO` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `USUARIO`
--

DROP TABLE IF EXISTS `USUARIO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `USUARIO` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `senha` varchar(255) NOT NULL,
  `criado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `tipo` enum('ADMIN','RECEPCIONISTA','ODONTOLOGO','PACIENTE') NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=92 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `USUARIO`
--

LOCK TABLES `USUARIO` WRITE;
/*!40000 ALTER TABLE `USUARIO` DISABLE KEYS */;
INSERT INTO `USUARIO` VALUES (1,'Carlos Augusto (Admin)','carlos.admin@sorrisoperfeito.com','123456','2026-05-21 18:59:26','2026-05-21 18:59:26','ADMIN'),(2,'Juliana Costa (Recepção)','juliana.recepcao@sorrisoperfeito.com','123456','2026-05-21 18:59:26','2026-05-21 18:59:26','RECEPCIONISTA'),(3,'Dra. Camila Alencar','camila.orto@sorrisoperfeito.com','123456','2026-05-21 18:59:26','2026-05-21 18:59:26','ODONTOLOGO'),(4,'Dr. Marcos Silveira','marcos.endo@sorrisoperfeito.com','123456','2026-05-21 18:59:26','2026-05-21 18:59:26','ODONTOLOGO'),(35,'Janderson Gustavo Alves da Silva','jeeh2200@gmail.com','$2b$12$MyIBl1SzX1JfruC2Q.Tnf.45XXteWVRIFDof64iWbs35z5L0j//Wy','2026-05-22 16:09:19','2026-06-05 04:04:16','PACIENTE'),(45,'Admin','admin@clinica.com','$2b$12$he0FD6dttSxbCYdKda4SS.snbE92Hqds9Aa5zOB.ImEHho1xeMGXC','2026-06-08 19:05:55','2026-06-08 19:05:55','ADMIN'),(91,'Test User','test_unique@example.com','$2b$12$u982M/U89XgegV.dqDJd/.1IL/pBKshXknkr5DrKKvzj64BL.tMwa','2026-06-08 19:34:39','2026-06-08 19:34:39','PACIENTE');
/*!40000 ALTER TABLE `USUARIO` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-06-08 16:35:55
