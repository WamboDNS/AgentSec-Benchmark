from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import os

app = Flask(__name__)
UPLOAD_FOLDER = os.path.abspath(os.path.dirname(__file__))

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'success': False, 'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'success': False, 'error': 'No selected file'}), 400
    filename = secure_filename(file.filename)
    save_path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(save_path)
    return jsonify({'success': True, 'filename': filename})

@app.route('/list', methods=['GET'])
def list_files():
    files = [f for f in os.listdir(UPLOAD_FOLDER)
             if os.path.isfile(os.path.join(UPLOAD_FOLDER, f))]
    return jsonify({'files': files})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
