import unittest
from app import app

class TestSwagger(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

    def test_swagger_ui_html(self):
        """Testa se a rota /docs serve a interface Swagger UI em HTML."""
        response = self.app.get('/docs')
        self.assertEqual(response.status_code, 200)
        html_content = response.get_data(as_text=True)
        self.assertIn("<!doctype html>", html_content.lower())
        self.assertIn("Clinic Flow - Documentação da API", html_content)
        self.assertIn("swagger-ui", html_content)

    def test_swagger_json_spec(self):
        """Testa se a rota /swagger.json retorna a especificação OpenAPI correta e não-embrulhada."""
        response = self.app.get('/swagger.json')
        self.assertEqual(response.status_code, 200)
        
        # O middleware global não deve embrulhar o swagger.json em {"success": true, "data": ...}
        # Ele deve retornar o dicionário OpenAPI puro diretamente.
        res_json = response.get_json()
        self.assertIsNotNone(res_json)
        self.assertEqual(res_json.get("openapi"), "3.0.3")
        self.assertIn("info", res_json)
        self.assertIn("paths", res_json)
        self.assertIn("components", res_json)
        self.assertNotIn("success", res_json)
        self.assertNotIn("data", res_json)

if __name__ == '__main__':
    unittest.main()
