
"""TaskFlow API — projet fil rouge du module DevSecOps.

ATTENTION : cette application contient VOLONTAIREMENT des failles de sécurité
à des fins pédagogiques. Ne jamais la déployer sur un environnement réel.
"""
import pickle
import sqlite3
import subprocess

from flask import Flask, jsonify, request
from werkzeug.security import generate_password_hash

from app.config import DATABASE, PAYMENT_API_KEY

app = Flask(__name__)


def get_db():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_db()
    conn.execute(
        "CREATE TABLE IF NOT EXISTS tasks ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, owner TEXT, done INTEGER DEFAULT 0)"
    )
    conn.execute(
        "CREATE TABLE IF NOT EXISTS users ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, password TEXT)"
    )
    conn.commit()
    conn.close()


@app.route("/health")
def health():
    return jsonify(status="ok")


@app.route("/tasks", methods=["GET"])
def list_tasks():
    owner = request.args.get("owner", "")
    conn = get_db()
    # Correction : requête SQL paramétrée
    rows = conn.execute(
        "SELECT * FROM tasks WHERE owner = ?", (owner,)
    ).fetchall()
    conn.close()
    return jsonify([dict(r) for r in rows])


@app.route("/tasks", methods=["POST"])
def create_task():
    data = request.get_json(force=True)
    conn = get_db()
    cur = conn.execute(
        "INSERT INTO tasks (title, owner) VALUES (?, ?)",
        (data.get("title", ""), data.get("owner", "")),
    )
    conn.commit()
    task_id = cur.lastrowid
    conn.close()
    return jsonify(id=task_id), 201


@app.route("/users", methods=["POST"])
def create_user():
    data = request.get_json(force=True)
    # Correction : hachage sécurisé avec pbkdf2
    password_hash = generate_password_hash(
        data.get("password", ""), method="pbkdf2:sha256:600000"
    )
    conn = get_db()
    conn.execute(
        "INSERT INTO users (username, password) VALUES (?, ?)",
        (data.get("username", ""), password_hash),
    )
    conn.commit()
    conn.close()
    return jsonify(created=True), 201


@app.route("/export", methods=["GET"])
def export_tasks():
    fmt = request.args.get("format", "csv")
    output = subprocess.check_output("echo export " + fmt, shell=True)
    return output


@app.route("/import", methods=["POST"])
def import_tasks():
    tasks = pickle.loads(request.data)
    return jsonify(imported=len(tasks))


@app.route("/payment/status")
def payment_status():
    # Le jeton est utilisé pour appeler un prestataire de paiement (simulé)
    return jsonify(provider="paycorp", configured=bool(PAYMENT_API_KEY))


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=8085, debug=True)
