from flask import Flask, request, send_file
import datetime
import os

app = Flask(__name__)

REPORT_FILE = "report.csv"

def log_submission(data):
    date_str = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    row = "%s,%s,%s\n" % (date_str, data.get('username', ''), data.get('feedback', ''))
    # Appends unescaped values, raw
    with open(REPORT_FILE, "a", encoding="utf-8") as f:
        f.write(row)

@app.route('/submit', methods=['POST'])
def submit():
    username = request.form.get('username', '')
    feedback = request.form.get('feedback', '')
    log_submission({'username': username, 'feedback': feedback})
    return "Submission received", 200

@app.route('/report', methods=['GET'])
def report():
    if not os.path.exists(REPORT_FILE):
        return "No report yet.", 404
    return send_file(REPORT_FILE, mimetype='text/csv', as_attachment=True, download_name='report.csv')

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
