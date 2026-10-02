"""Small Flask app used to test the AKS + ACR setup."""
import os
import socket

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(
        message="Hello from AKS",
        hostname=socket.gethostname(),
        version=os.environ.get("APP_VERSION", "dev"),
    )


@app.get("/healthz")
def healthz():
    return jsonify(status="ok")


if __name__ == "__main__":
    # Local run only. In the container gunicorn serves the app.
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))
