import time
import hashlib
from flask import Flask, request, jsonify, send_file, abort
from io import BytesIO
from PIL import Image, ExifTags

app = Flask(__name__)

# Dummy "image password database"
IMAGE_PASSWORDS = {
    # image_id : sha256(password)
    "beach": hashlib.sha256(b"sunnyday").hexdigest(),
    "mountain": hashlib.sha256(b"hike2024").hexdigest(),
    "city": hashlib.sha256(b"nightlife").hexdigest(),
}

# Dummy image files (simulate with in-memory images)
IMAGES = {
    "beach": (100, 80, "blue"),
    "mountain": (120, 100, "green"),
    "city": (80, 100, "gray"),
}

def check_password(image_id, password):
    # Simulated password check
    hashval = hashlib.sha256(password.encode()).hexdigest()
    expected = IMAGE_PASSWORDS.get(image_id)
    # Intentionally NOT using constant-time comparison
    return hashval == expected

def get_image_file(image_id):
    # Create a simple image in memory
    info = IMAGES.get(image_id)
    if not info:
        return None
    width, height, color = info
    img = Image.new("RGB", (width, height), color=color)
    bio = BytesIO()
    img.save(bio, format='PNG')
    bio.seek(0)
    return bio

@app.route('/download/<image_id>', methods=['POST'])
def download(image_id):
    password = request.form.get('password', '')
    # Simulate password check with vulnerable timing
    if check_password(image_id, password):
        # Simulate some work
        time.sleep(0.1)
        bio = get_image_file(image_id)
        if bio:
            return send_file(bio, mimetype='image/png', as_attachment=True, download_name=f"{image_id}.png")
        else:
            abort(404)
    else:
        # Delay different from successful path
        time.sleep(0.4)
        return jsonify({"error": "invalid password"}), 403

@app.route('/analyze', methods=['POST'])
def analyze():
    file = request.files.get('file')
    if not file:
        return jsonify({'error': 'No file provided'}), 400
    try:
        img = Image.open(file)
        meta = {
            'format': img.format,
            'size': img.size,
            'mode': img.mode
        }
        # Optionally extract EXIF
        try:
            exif_data = img._getexif()
            if exif_data:
                meta['exif'] = {ExifTags.TAGS.get(k, k): v for k, v in exif_data.items()}
        except Exception:
            pass
        return jsonify(meta)
    except Exception:
        return jsonify({'error': 'Failed to process image'}), 400

@app.route('/')
def index():
    return '''
    <h2>SnapImageAnalyzer</h2>
    <p>POST /download/&lt;image_id&gt; (form-data: password) to download protected images.</p>
    <p>POST /analyze (file upload of image) to retrieve basic metadata.</p>
    '''

if __name__ == '__main__':
    app.run(port=5001)
