"""
Script para inserir dados iniciais (seed) no banco de dados para teste.
Execute depois de executar init_db.py
"""

import os
from pathlib import Path
from dotenv import load_dotenv
import pymysql
from pymysql.cursors import DictCursor


def load_env():
    env_path = Path(__file__).resolve().parent.parent / ".env"
    if env_path.exists():
        load_dotenv(env_path)
    else:
        load_dotenv()


def get_db_config():
    return {
        "host": os.getenv("db_host", "localhost").strip("'\""),
        "user": os.getenv("db_user", "root").strip("'\""),
        "password": os.getenv("db_password", "").strip("'\""),
        "db_name": os.getenv("db_name", "clinica").strip("'\""),
    }


def seed_data():
    load_env()
    config = get_db_config()

    print("Inserindo dados iniciais no banco de dados...")
    connection = pymysql.connect(
        host=config["host"],
        user=config["user"],
        password=config["password"],
        database=config["db_name"],
        charset="utf8mb4",
        cursorclass=DictCursor,
        autocommit=True,
    )

    try:
        with connection.cursor() as cursor:
            # Inserir especialidades
            especialidades = [
                ("Odontologia Geral",),
                ("Implantodontia",),
                ("Ortodontia",),
                ("Endodontia",),
                ("Periodontia",),
                ("Pediatria Dentária",),
            ]
            for especialidade in especialidades:
                try:
                    cursor.execute(
                        "INSERT IGNORE INTO ESPECIALIDADE (nome) VALUES (%s)",
                        especialidade,
                    )
                except Exception as e:
                    print(f"  ⚠ Especialidade '{especialidade[0]}' já existe: {e}")

            # Inserir procedimentos
            procedimentos = [
                ("Limpeza e Polimento", 100.00),
                ("Restauração em Resina", 150.00),
                ("Extração Dentária", 200.00),
                ("Tratamento de Canal", 500.00),
                ("Implante Dentário", 2000.00),
                ("Clareamento Dentário", 300.00),
                ("Aplicação de Flúor", 50.00),
                ("Raspagem Subgengival", 200.00),
            ]
            for nome, valor in procedimentos:
                try:
                    cursor.execute(
                        "INSERT IGNORE INTO PROCEDIMENTO (nome, valor) VALUES (%s, %s)",
                        (nome, valor),
                    )
                except Exception as e:
                    print(f"  ⚠ Procedimento '{nome}' já existe: {e}")

            print("✓ Dados iniciais inseridos com sucesso!")

    finally:
        connection.close()


if __name__ == "__main__":
    seed_data()
