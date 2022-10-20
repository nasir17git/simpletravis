from flask import Flask

app = Flask(__name__)
qweqwewqeeqwe

@app.route("/")
def hello_world():
    return "<p>Hello, World! test19</p>"


@app.route("/health_check")
def health_check():
    return "OK"
