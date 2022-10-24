from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, World!, Port is 5001</p>"

@app.route("/health_check")
def health_check():
    return "OK"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
