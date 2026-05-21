import unittest
import json
from app import app
from database import get_db_connection

class TestUsuario(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True
        
        # Limpar ou preparar dados de teste
        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                # CUIDADO: Isso remove dados! Em um ambiente real, use um banco de teste separado.
                cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
                cursor.execute("DELETE FROM USUARIO WHERE email LIKE 'test_%'")
                cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
                db.commit()
        finally:
            db.close()

    def test_create_usuario_success(self):
        payload = {
            "nome": "Test User",
            "email": "test_unique@example.com",
            "senha": "password123",
            "senha_repeat": "password123",
            "tipo": "PACIENTE"
        }
        response = self.app.post('/usuarios', 
                                 data=json.dumps(payload),
                                 content_type='application/json')
        
        self.assertEqual(response.status_code, 201)
        res_json = response.get_json()
        self.assertTrue(res_json['success'])
        self.assertIn("Usuário criado com sucesso", res_json['data']['message'])

    def test_create_usuario_duplicate_email(self):
        payload = {
            "nome": "Test User",
            "email": "test_duplicate@example.com",
            "senha": "password123",
            "senha_repeat": "password123",
            "tipo": "PACIENTE"
        }
        # Primeiro insert
        self.app.post('/usuarios', 
                      data=json.dumps(payload),
                      content_type='application/json')
        
        # Segundo insert (duplicado)
        response = self.app.post('/usuarios', 
                                 data=json.dumps(payload),
                                 content_type='application/json')
        
        self.assertEqual(response.status_code, 409)
        res_json = response.get_json()
        self.assertFalse(res_json['success'])
        self.assertEqual(res_json['error'], "Email já cadastrado")

    def test_create_usuario_invalid_data(self):
        payload = {
            "nome": "T", # Muito curto
            "email": "invalid-email",
            "senha": "123", # Muito curta
            "senha_repeat": "321", # Diferente
            "tipo": "INVALIDO"
        }
        response = self.app.post('/usuarios', 
                                 data=json.dumps(payload),
                                 content_type='application/json')
        
        self.assertEqual(response.status_code, 400)
        res_json = response.get_json()
        self.assertFalse(res_json['success'])
        self.assertIn("error", res_json)

if __name__ == '__main__':
    unittest.main()
