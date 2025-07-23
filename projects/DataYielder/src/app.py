from flask import Flask, request, jsonify
import datetime

app = Flask(__name__)

def generate_report(template, data):
    # Intended: use str.format() to insert fields
    # (but no filtering of template keys)
    # e.g. template: "User {name} on {date}"
    try:
        # date value
        data["date"] = datetime.datetime.now().strftime("%Y-%m-%d")
        output = template.format(**data)
    except Exception as e:
        output = str(e)
    return output

@app.route('/report', methods=['POST'])
def report():
    incoming = request.json
    template = incoming.get("template", "")
    data = incoming.get("data", {})
    # No sanitization of keys used in format string
    report_text = generate_report(template, data)
    return jsonify({"result": report_text})

if __name__ == "__main__":
    app.run(port=5007)
