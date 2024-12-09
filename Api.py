from flask import Flask, request, jsonify
import mysql.connector
from flask_cors import CORS
import os

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Load sensitive configurations from environment variables
API_KEY = os.getenv("API_KEY")
DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")
SSL_CA = os.getenv("DB_SSL_CA")
SSL_CERT = os.getenv("DB_SSL_CERT")
SSL_KEY = os.getenv("DB_SSL_KEY")

# Middleware to check API key
def require_api_key(func):
    def wrapper(*args, **kwargs):
        key = request.headers.get("X-API-KEY")
        if key != API_KEY:
            return jsonify({"message": "Invalid or missing API key"}), 403
        return func(*args, **kwargs)
    wrapper.__name__ = func.__name__
    return wrapper

# Database connection helper
def get_db_connection():
    try:
        connection = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            ssl_ca=SSL_CA,
            ssl_cert=SSL_CERT,
            ssl_key=SSL_KEY
        )
        return connection
    except mysql.connector.Error as err:
        print(f"Database connection error: {err}")
        return None

# Routes
@app.route("/add", methods=["POST"])
@require_api_key
def add_license_plate():
    data = request.get_json()
    if not data or "plate" not in data:
        return jsonify({"message": "License plate cannot be empty."}), 400

    plate = data["plate"]
    connection = get_db_connection()
    if not connection:
        return jsonify({"message": "Database connection failed."}), 500

    cursor = connection.cursor()
    try:
        # Check if the license plate already exists
        cursor.execute("SELECT plate FROM license_plates WHERE plate = %s", (plate,))
        if cursor.fetchone():
            return jsonify({"message": "License plate already exists."}), 400

        # Insert new license plate
        cursor.execute("INSERT INTO license_plates (plate) VALUES (%s)", (plate,))
        connection.commit()
        return jsonify({"message": "License plate added successfully!"}), 201
    finally:
        cursor.close()
        connection.close()

@app.route("/check/<string:plate>", methods=["GET"])
@require_api_key
def check_license_plate(plate):
    connection = get_db_connection()
    if not connection:
        return jsonify({"message": "Database connection failed."}), 500

    cursor = connection.cursor()
    try:
        cursor.execute("SELECT plate FROM license_plates WHERE plate = %s", (plate,))
        if cursor.fetchone():
            return jsonify({"message": f"License plate found: {plate}"}), 200
        return jsonify({"message": "License plate not found."}), 404
    finally:
        cursor.close()
        connection.close()

@app.route("/list", methods=["GET"])
@require_api_key
def list_license_plates():
    connection = get_db_connection()
    if not connection:
        return jsonify({"message": "Database connection failed."}), 500

    cursor = connection.cursor()
    try:
        cursor.execute("SELECT plate FROM license_plates")
        plates = [{"plate": row[0]} for row in cursor.fetchall()]
        return jsonify(plates), 200
    finally:
        cursor.close()
        connection.close()

# Run the app with HTTPS on port 8080
if __name__ == "__main__":
    app.run(ssl_context=('certificate.pem', 'key.pem'), host='0.0.0.0', port=8080)
