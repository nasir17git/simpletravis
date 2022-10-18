from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, World! test5</p>"

@app.route("/health_check")
def health_check():
    return "OK"
