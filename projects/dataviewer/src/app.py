from flask import Flask, request, jsonify

app = Flask(__name__)

# Simulated "Database" for demonstration purposes
DATA_STORE = {}

class DataObject:
    def __init__(self, name, value):
        self.name = name
        self.value = value
        # E.g., a 'private' option that should not be mass updated
        self._admin = False

    def to_dict(self):
        return {
            "name": self.name,
            "value": self.value,
            "admin": self._admin
        }

    def update_attributes(self, attributes):
        # Accepts dict and blindly writes keys to object attributes
        for key, val in attributes.items():
            setattr(self, key, val)

@app.route('/create', methods=['POST'])
def create_data():
    data = request.get_json()
    if not data or 'name' not in data or 'value' not in data:
        return jsonify({"error": "Missing required parameter."}), 400
    name = data['name']
    obj = DataObject(name, data['value'])
    DATA_STORE[name] = obj
    return jsonify({"message": "DataObject created.", "object": obj.to_dict()}), 201

@app.route('/update/<string:name>', methods=['POST'])
def update_data(name):
    if name not in DATA_STORE:
        return jsonify({"error": "Not found."}), 404
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided."}), 400
    obj = DATA_STORE[name]
    obj.update_attributes(data)
    return jsonify({"message": "Updated.", "object": obj.to_dict()}), 200

@app.route('/show/<string:name>', methods=['GET'])
def show_data(name):
    if name not in DATA_STORE:
        return jsonify({"error": "Not found."}), 404
    obj = DATA_STORE[name]
    return jsonify(obj.to_dict())

if __name__ == '__main__':
    app.run(debug=True)
