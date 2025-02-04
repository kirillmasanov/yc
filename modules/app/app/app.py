import os
import pymysql
import socket
from flask import Flask, jsonify, request

app = Flask(__name__)

# Читаем переменные окружения
DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")
SSL_CA_PATH = os.getenv("SSL_CA_PATH", "/certs/root.crt")  # По умолчанию путь внутри контейнера

# Получаем IP пода
POD_IP = socket.gethostbyname(socket.gethostname())

# Получаем IP ноды из переменной окружения
NODE_IP = os.getenv("NODE_IP", "unknown")

# Подключение к БД
db_conn = pymysql.connect(
    host=DB_HOST,
    user=DB_USER,
    password=DB_PASSWORD,
    database=DB_NAME,
    ssl={"ca": SSL_CA_PATH},
    cursorclass=pymysql.cursors.DictCursor
)

@app.after_request
def add_cache_control_headers(response):
    """Отключаем кэширование на уровне Flask"""
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

@app.route("/")
def index():
    """Заглушка для проверки"""
    return "Flask app is running on port 8080!\n"

@app.route("/write/<data>")
def write_data(data):
    """Записывает данные в таблицу my_app_logs"""
    try:
        with db_conn.cursor() as cursor:
            sql = "INSERT INTO my_app_logs (message) VALUES (%s)"
            cursor.execute(sql, (data,))
            db_conn.commit()
        return f"Saved: {data}\n"
    except Exception as e:
        return f"Error: {str(e)}\n", 500

@app.route("/logs")
def get_logs():
    """Выводит все записи из таблицы my_app_logs"""
    try:
        with db_conn.cursor() as cursor:
            cursor.execute("SELECT * FROM my_app_logs")
            logs = cursor.fetchall()
        return jsonify({"logs": logs})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/page1.html")
def page1():
    """Выводит страницу 1 с IP-адресом пода и ноды"""
    return f"Страница 1\npod_ip: {POD_IP}\nnode_ip: {NODE_IP}\n", 200, {"Content-Type": "text/plain; charset=utf-8"}

@app.route("/page2.html")
def page2():
    """Выводит страницу 2 с IP-адресом пода и ноды"""
    return f"Страница 2\npod_ip: {POD_IP}\nnode_ip: {NODE_IP}\n", 200, {"Content-Type": "text/plain; charset=utf-8"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
