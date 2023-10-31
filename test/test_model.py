from unittest import TestCase

from app import app, db, Visitor


class TestSuite(TestCase):

    def setUp(self):
        app.config['TESTING'] = True
        app.config['SQLALCHEMY_DATABASE_URI'] = "sqlite://"
        self.client = app.test_client()
        with app.app_context():
            # Crea las tablas de la base de datos
            db.create_all()

    def test_model(self):
        visitor = Visitor()
        visitor.remote_addr = "127.0.0.1"
        visitor.user_agent = "Mozilla"
        with app.app_context():
            db.session.add(visitor)
            db.session.commit()
            expected = db.get_or_404(Visitor, 1)
            self.assertEqual(visitor, expected)

    def test_not_duplicate(self):
        visitor = Visitor()
        visitor.remote_addr = "127.0.0.1"
        visitor.user_agent = "Mozilla"
        with app.app_context():
            # first visitor
            db.session.add(visitor)
            db.session.commit()
            # Same visitor second time
            db.session.add(visitor)
            db.session.commit()
            expected = db.session.query(Visitor).all()
            # Shoud return only one
            self.assertEqual(1, len(expected))

    def test_counter(self):
        response = self.client.get("/")
        print(response.data)
        self.assertEqual(response.status, '200 OK')

    def tearDown(self):
        with app.app_context():
            # Elimina todas las tablas de la base de datos
            db.session.remove()
            db.drop_all()
