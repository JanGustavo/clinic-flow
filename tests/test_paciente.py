import unittest
import json
from app import app
from database import get_db_connection

class TestPaciente(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
                # Limpar registros anteriores de teste
                cursor.execute("DELETE FROM PACIENTE WHERE cpf LIKE '999%'")
                cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
                db.commit()
        finally:
            db.close()

    def tearDown(self):
        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
                cursor.execute("DELETE FROM PACIENTE WHERE cpf LIKE '999%'")
                cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
                db.commit()
        finally:
            db.close()

    def test_create_paciente_without_address(self):
        # 1. Test creation without address fields (only nome, data_nascimento, cpf, telefone)
        payload = {
            "nome": "Paciente Teste Sem Endereco",
            "data_nascimento": "1995-10-25",
            "cpf": "99911122233",
            "telefone": "11999998888"
        }
        response = self.app.post('/pacientes', 
                                 data=json.dumps(payload),
                                 content_type='application/json')
        
        self.assertEqual(response.status_code, 201)
        res_json = response.get_json()
        self.assertTrue(res_json['success'])
        self.assertIn("Paciente criado com sucesso", res_json['data']['message'])
        self.assertIn("id", res_json['data'])
        self.assertIsNotNone(res_json['data']['id'])

        # Verify in DB that it is stored and address fields are NULL
        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("SELECT * FROM PACIENTE WHERE cpf = %s", ("99911122233",))
                paciente = cursor.fetchone()
                self.assertIsNotNone(paciente)
                self.assertEqual(paciente['nome'], "Paciente Teste Sem Endereco")
                self.assertIsNone(paciente['cep'])
                self.assertIsNone(paciente['logradouro'])
        finally:
            db.close()

    def test_update_paciente_preserves_existing_address(self):
        # 1. Create a patient WITH address fields manually in DB
        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO PACIENTE (nome, data_nascimento, cpf, telefone, cep, logradouro, numero_casa, bairro, cidade, estado)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    "Paciente Teste Com Endereco",
                    "1990-05-15",
                    "99944455566",
                    "11988887777",
                    "01001-000",
                    "Praca da Se",
                    "100",
                    "Se",
                    "Sao Paulo",
                    "SP"
                ))
                paciente_id = cursor.lastrowid
                db.commit()
        finally:
            db.close()

        # 2. Call UPDATE/PUT route with only the 4 fields (no address) to update the name
        update_payload = {
            "nome": "Paciente Teste Nome Atualizado",
            "data_nascimento": "1990-05-15",
            "cpf": "99944455566",
            "telefone": "11988887777"
        }
        response = self.app.put(f'/pacientes/{paciente_id}',
                                data=json.dumps(update_payload),
                                content_type='application/json')
        
        self.assertEqual(response.status_code, 200)
        res_json = response.get_json()
        self.assertTrue(res_json['success'])

        # 3. Query DB to verify the name updated but address details are PRESERVED (not overwritten with NULL/empty)
        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("SELECT * FROM PACIENTE WHERE id = %s", (paciente_id,))
                paciente = cursor.fetchone()
                self.assertIsNotNone(paciente)
                self.assertEqual(paciente['nome'], "Paciente Teste Nome Atualizado")
                self.assertEqual(paciente['cep'], "01001-000")
                self.assertEqual(paciente['logradouro'], "Praca da Se")
                self.assertEqual(paciente['numero_casa'], "100")
                self.assertEqual(paciente['bairro'], "Se")
                self.assertEqual(paciente['cidade'], "Sao Paulo")
                self.assertEqual(paciente['estado'], "SP")
        finally:
            db.close()

if __name__ == '__main__':
    unittest.main()
