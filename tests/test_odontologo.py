import unittest
import json
from app import app
from database import get_db_connection

class TestOdontologo(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
                # Limpar registros anteriores
                cursor.execute("DELETE FROM ODONTOLOGO WHERE cro LIKE 'TEST-%'")
                cursor.execute("DELETE FROM USUARIO WHERE email = 'test_odontologo@example.com'")
                cursor.execute("DELETE FROM ESPECIALIDADE WHERE nome = 'TEST-ESPECIALIDADE'")
                
                # Inserir Especialidade de teste
                cursor.execute("INSERT INTO ESPECIALIDADE (nome) VALUES ('TEST-ESPECIALIDADE')")
                self.especialidade_id = cursor.lastrowid

                # Inserir Usuário de teste
                cursor.execute(
                    "INSERT INTO USUARIO (nome, email, senha, tipo) VALUES (%s, %s, %s, %s)",
                    ("Test Dentista", "test_odontologo@example.com", "password123", "ODONTOLOGO")
                )
                self.usuario_id = cursor.lastrowid
                
                cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
                db.commit()
        finally:
            db.close()

    def tearDown(self):
        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
                cursor.execute("DELETE FROM ODONTOLOGO WHERE cro LIKE 'TEST-%'")
                cursor.execute("DELETE FROM USUARIO WHERE email = 'test_odontologo@example.com'")
                cursor.execute("DELETE FROM ESPECIALIDADE WHERE nome = 'TEST-ESPECIALIDADE'")
                cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
                db.commit()
        finally:
            db.close()

    def test_create_odontologo_success(self):
        payload = {
            "nome": "Dr. Test Dentista",
            "cro": "TEST-1234",
            "salario": 12000.00,
            "id_especialidade": self.especialidade_id,
            "id_usuario": self.usuario_id
        }
        response = self.app.post('/odontologos', 
                                 data=json.dumps(payload),
                                 content_type='application/json')
        
        self.assertEqual(response.status_code, 201)
        res_json = response.get_json()
        self.assertTrue(res_json['success'])
        self.assertIn("Odontólogo criado com sucesso", res_json['data']['message'])

    def test_create_odontologo_duplicate_cro(self):
        payload = {
            "nome": "Dr. Test Dentista",
            "cro": "TEST-5678",
            "salario": 12000.00,
            "id_especialidade": self.especialidade_id,
            "id_usuario": self.usuario_id
        }
        # Primeiro insert
        self.app.post('/odontologos', 
                      data=json.dumps(payload),
                      content_type='application/json')
        
        # Segundo insert (CRO duplicado)
        response = self.app.post('/odontologos', 
                                 data=json.dumps(payload),
                                 content_type='application/json')
        
        self.assertEqual(response.status_code, 409)
        res_json = response.get_json()
        self.assertFalse(res_json['success'])
        self.assertEqual(res_json['error'], "CRO já cadastrado")

    def test_list_odontologos(self):
        response = self.app.get('/odontologos')
        self.assertEqual(response.status_code, 200)
        res_json = response.get_json()
        self.assertTrue(res_json['success'])
        self.assertIsInstance(res_json['data'], list)

if __name__ == '__main__':
    unittest.main()
