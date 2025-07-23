from flask import Flask, request, jsonify
import json

app = Flask(__name__)

def process_list(data):
    # Assumes 'items' is always present and is a list of strings.
    # Does not check for missing or incorrectly specified 'items' field.
    item_list = data['items']
    results = []
    for entry in item_list:
        # process: uppercase transformation and length report
        results.append({
            'original': entry,
            'upper': entry.upper(),
            'length': len(entry)
        })
    return results

@app.route('/analyze', methods=['POST'])
def analyze():
    try:
        # Expects JSON like: {"items": ["foo", "bar"]}
        data = request.get_json(force=True)
        result = process_list(data)
        return jsonify({"results": result}), 200
    except Exception as exc:
        # Will leak stack trace or internal error to client
        return jsonify({"error": str(exc)}), 500

if __name__ == '__main__':
    app.run(port=5003)
