import os
import re
from pathlib import Path

import pymysql
from dotenv import load_dotenv


def load_env():
    env_path = Path(__file__).resolve().parent.parent / ".env"
    if env_path.exists():
        load_dotenv(env_path)
    else:
        load_dotenv()  # fallback to environment variables


def get_db_config():
    return {
        "host": os.getenv("db_host", "localhost").strip("'\""),
        "user": os.getenv("db_user", "root").strip("'\""),
        "password": os.getenv("db_password", "").strip("'\""),
        "db_name": os.getenv("db_name", "clinica").strip("'\""),
    }


def normalize_sql(sql_text: str) -> str:
    # Remove SQL comments and normalize whitespace.
    lines = []
    for line in sql_text.splitlines():
        line = re.sub(r"--.*", "", line)
        if line.strip():
            lines.append(line)
    return "\n".join(lines)


def split_statements(sql_text: str):
    normalized = normalize_sql(sql_text)
    statements = [stmt.strip() for stmt in re.split(r";\s*(?=\n|$)", normalized) if stmt.strip()]
    return statements


def execute_schema(cursor, schema_path: Path):
    with schema_path.open("r", encoding="utf-8") as f:
        schema_sql = f.read()

    statements = split_statements(schema_sql)
    for statement in statements:
        if statement:
            cursor.execute(statement)


def main():
    load_env()
    config = get_db_config()
    schema_path = Path(__file__).resolve().parent.parent / "database" / "schema.sql"

    if not schema_path.exists():
        raise FileNotFoundError(f"Schema file not found: {schema_path}")

    print("Initializing MariaDB/MySQL schema for ClinicFlow...")
    connection = pymysql.connect(
        host=config["host"],
        user=config["user"],
        password=config["password"],
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )

    try:
        with connection.cursor() as cursor:
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{config['db_name']}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
            cursor.execute(f"USE `{config['db_name']}`;")
            execute_schema(cursor, schema_path)

        print("Database schema initialized successfully.")
    finally:
        connection.close()


if __name__ == "__main__":
    main()
