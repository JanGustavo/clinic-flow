import unittest
import json
from app import app
from database import get_db_connection

class TestAnamnese(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
                cursor.execute("DELETE FROM ANAMNESE")
                cursor.execute("DELETE FROM PACIENTE WHERE cpf = '98765432109' OR nome LIKE 'TEST-%'")
                
                # Insert a test Patient
                cursor.execute(
                    """
                    INSERT INTO PACIENTE (nome, data_nascimento, cpf, telefone, cep, logradouro, numero_casa, bairro, cidade, estado)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    ("TEST Patient Anamnese", "1995-05-15", "98765432109", "11988888888", "02002000", "TEST Ave", "20", "TEST Bairro", "TEST City", "RJ")
                )
                self.paciente_id = cursor.lastrowid

                # Insert a test Anamnese
                cursor.execute(
                    """
                    INSERT INTO ANAMNESE (
                        id_paciente, alergia, descricao_alergia, diabetes, 
                        hipertensao, cardiopatia, gestante, usa_medicacao, 
                        descricao_medicacao, observacoes
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (self.paciente_id, True, "Penicilina", False, True, False, False, True, "Aspirina", "Paciente cooperativo")
                )
                self.anamnese_id = cursor.lastrowid
                
                cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
                db.commit()
        finally:
            db.close()

    def tearDown(self):
        db = get_db_connection()
        try:
            with db.cursor() as cursor:
                cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
                cursor.execute("DELETE FROM ANAMNESE")
                cursor.execute("DELETE FROM PACIENTE WHERE cpf = '98765432109' OR nome LIKE 'TEST-%'")
                cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
                db.commit()
        finally:
            db.close()

    def test_get_anamnese_success(self):
        response = self.app.get(f'/anamneses/{self.anamnese_id}')
        self.assertEqual(response.status_code, 200)
        res_json = response.get_json()
        
        self.assertTrue(res_json['success'])
        data = res_json['data']
        self.assertEqual(data['id'], self.anamnese_id)
        self.assertEqual(data['id_paciente'], self.paciente_id)
        self.assertTrue(data['alergia'])
        self.assertEqual(data['descricao_alergia'], "Penicilina")
        self.assertFalse(data['diabetes'])
        self.assertTrue(data['hipertensao'])
        self.assertFalse(data['cardiopatia'])
        self.assertFalse(data['gestante'])
        self.assertTrue(data['usa_medicacao'])
        self.assertEqual(data['descricao_medicacao'], "Aspirina")
        self.assertEqual(data['observacoes'], "Paciente cooperativo")
        self.assertIn('criado_em', data)
        self.assertIn('atualizado_em', data)

    def test_get_anamnese_not_found(self):
        response = self.app.get('/anamneses/999999')
        self.assertEqual(response.status_code, 404)
        res_json = response.get_json()
        self.assertFalse(res_json['success'])
        self.assertEqual(res_json['error'], "Anamnese não encontrada")

if __name__ == '__main__':
    unittest.main()
