from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, World! 221024v2</p>"

@app.route("/health_check")
def health_check():
    return "OK"
