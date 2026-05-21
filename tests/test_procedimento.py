import unittest
import json
from app import app
from database import get_db_connection

class TestProcedimento(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
                
                # Cleanup existing test data
                cursor.execute("DELETE FROM CONSULTA_PROCEDIMENTO")
                cursor.execute("DELETE FROM PROCEDIMENTO WHERE nome LIKE 'TEST-%'")
                cursor.execute("DELETE FROM CONSULTA")
                cursor.execute("DELETE FROM PACIENTE WHERE nome LIKE 'TEST-%' OR cpf = '12345678901'")
                cursor.execute("DELETE FROM ODONTOLOGO WHERE cro LIKE 'TEST-%' OR cro = 'TEST-9999'")
                cursor.execute("DELETE FROM USUARIO WHERE email LIKE 'test_%' OR email = 'test_user_proc@example.com'")

                # Insert test Procedure
                cursor.execute(
                    "INSERT INTO PROCEDIMENTO (nome, valor) VALUES (%s, %s)",
                    ("TEST-DENTAL-CLEANING", 120.50)
                )
                self.procedimento_id = cursor.lastrowid

                # Insert test User (for receptionist/admin/dentist reference)
                cursor.execute(
                    "INSERT INTO USUARIO (nome, email, senha, tipo) VALUES (%s, %s, %s, %s)",
                    ("TEST User", "test_user_proc@example.com", "password123", "ADMIN")
                )
                self.usuario_id = cursor.lastrowid

                # Insert test Specialty
                cursor.execute("INSERT IGNORE INTO ESPECIALIDADE (nome) VALUES ('TEST-ESPECIALIDADE')")
                cursor.execute("SELECT id FROM ESPECIALIDADE WHERE nome = 'TEST-ESPECIALIDADE'")
                self.especialidade_id = cursor.fetchone()['id']

                # Insert test Dentist
                cursor.execute(
                    "INSERT INTO ODONTOLOGO (nome, cro, salario, id_especialidade, id_usuario) VALUES (%s, %s, %s, %s, %s)",
                    ("TEST Dentist", "TEST-9999", 5000.00, self.especialidade_id, self.usuario_id)
                )
                self.odontologo_id = cursor.lastrowid

                # Insert test Patient
                cursor.execute(
                    """
                    INSERT INTO PACIENTE (nome, data_nascimento, cpf, telefone, cep, logradouro, numero_casa, bairro, cidade, estado)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    ("TEST Patient", "1990-01-01", "12345678901", "11999999999", "01001000", "TEST St", "10", "TEST Bairro", "TEST City", "SP")
                )
                self.paciente_id = cursor.lastrowid

                # Insert test Consultation
                cursor.execute(
                    """
                    INSERT INTO CONSULTA (id_paciente, id_odontologo, id_usuario_responsavel, data_hora, motivo, valor, prioridade)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (self.paciente_id, self.odontologo_id, self.usuario_id, "2026-05-25 10:00:00", "Routine checkup", 150.00, "MEDIA")
                )
                self.consulta_id = cursor.lastrowid

                cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
                db.commit()
        finally:
            db.close()

    def tearDown(self):
        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
                cursor.execute("DELETE FROM CONSULTA_PROCEDIMENTO")
                cursor.execute("DELETE FROM PROCEDIMENTO WHERE nome LIKE 'TEST-%'")
                cursor.execute("DELETE FROM CONSULTA")
                cursor.execute("DELETE FROM PACIENTE WHERE nome LIKE 'TEST-%'")
                cursor.execute("DELETE FROM ODONTOLOGO WHERE cro LIKE 'TEST-%'")
                cursor.execute("DELETE FROM USUARIO WHERE email LIKE 'test_%'")
                cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
                db.commit()
        finally:
            db.close()

    def test_list_procedimentos(self):
        response = self.app.get('/procedimentos')
        self.assertEqual(response.status_code, 200)
        res_json = response.get_json()
        self.assertTrue(res_json['success'])
        self.assertIsInstance(res_json['data'], list)
        
        # Verify the list contains our test procedure
        found = False
        for p in res_json['data']:
            if p['nome'] == "TEST-DENTAL-CLEANING":
                found = True
                self.assertEqual(float(p['valor']), 120.50)
                break
        self.assertTrue(found)

    def test_get_procedimento_success(self):
        response = self.app.get(f'/procedimentos/{self.procedimento_id}')
        self.assertEqual(response.status_code, 200)
        res_json = response.get_json()
        self.assertTrue(res_json['success'])
        self.assertEqual(res_json['data']['nome'], "TEST-DENTAL-CLEANING")
        self.assertEqual(float(res_json['data']['valor']), 120.50)

    def test_get_procedimento_not_found(self):
        response = self.app.get('/procedimentos/999999')
        self.assertEqual(response.status_code, 404)
        res_json = response.get_json()
        self.assertFalse(res_json['success'])
        self.assertEqual(res_json['error'], "Procedimento não encontrado")

    def test_link_procedimento_to_consulta_success(self):
        payload = {
            "id_procedimento": self.procedimento_id
        }
        # Post to link procedure
        response = self.app.post(
            f'/consultas/{self.consulta_id}/procedimentos',
            data=json.dumps(payload),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 201)
        res_json = response.get_json()
        self.assertTrue(res_json['success'])
        self.assertIn("Procedimento adicionado com sucesso", res_json['data']['message'])

        # Verify it is returned in list endpoint
        list_response = self.app.get(f'/consultas/{self.consulta_id}/procedimentos')
        self.assertEqual(list_response.status_code, 200)
        list_json = list_response.get_json()
        self.assertTrue(list_json['success'])
        self.assertEqual(len(list_json['data']), 1)
        self.assertEqual(list_json['data'][0]['nome'], "TEST-DENTAL-CLEANING")

    def test_link_procedimento_duplicate(self):
        payload = {
            "id_procedimento": self.procedimento_id
        }
        # First linkage
        self.app.post(
            f'/consultas/{self.consulta_id}/procedimentos',
            data=json.dumps(payload),
            content_type='application/json'
        )
        
        # Second linkage (duplicate)
        response = self.app.post(
            f'/consultas/{self.consulta_id}/procedimentos',
            data=json.dumps(payload),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 409)
        res_json = response.get_json()
        self.assertFalse(res_json['success'])
        self.assertEqual(res_json['error'], "Procedimento já vinculado à consulta")

if __name__ == '__main__':
    unittest.main()
