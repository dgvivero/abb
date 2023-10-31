from os import environ

from flask import Flask, request, render_template, make_response, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import Integer, String, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Mapped, mapped_column

# create the app
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = environ.get('DB_URL') or "sqlite://"
db = SQLAlchemy(app)
app.config["version"] = "0.0.1"


class Visitor(db.Model):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    remote_addr: Mapped[str] = mapped_column(String, unique=True, nullable=False)
    user_agent: Mapped[str] = mapped_column(String)


with app.app_context():
    db.create_all()


def create_visitor(req):
    try:
        visitor = Visitor()
        visitor.user_agent = req.user_agent.string
        visitor.remote_addr = req.remote_addr
        exist_visitor = db.session.query(Visitor).filter(Visitor.remote_addr == req.remote_addr).filter(
            Visitor.user_agent == req.user_agent.string).count()
        if not exist_visitor:
            db.session.add(visitor)
            db.session.commit()
    except Exception as err:
        print(err)
        db.session.rollback()


# create default route
@app.route('/', methods=['GET'])
def list_visitors():
    create_visitor(request)
    visitors = db.session.query(Visitor).all()
    return render_template('visitors.html', title='ABB', visitors=visitors)


@app.route('/version', methods=['GET'])
def get_version():
    create_visitor(request)
    return make_response(jsonify({"version": app.config["version"]}), 200)


if __name__ == '__main__':
    app.run()
