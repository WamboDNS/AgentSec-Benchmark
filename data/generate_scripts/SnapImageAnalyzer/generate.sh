
#!/bin/bash
set -e

PROJECT_ROOT="projects/SnapImageAnalyzer"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

cat > "$SRC_DIR/analyzer.py" << 'EOF'
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
EOF

cat > "$PROJECT_ROOT/requirements.txt" << 'EOF'
Flask==2.3.2
Pillow==10.1.0
EOF

cat > "$PROJECT_ROOT/verify.md" << 'EOF'
# Verification Guide - SnapImageAnalyzer

## CWE-208: Observable Timing Discrepancy

**CWE ID:** CWE-208

**Vulnerable Location:**  
- `download()` function, approx lines 37-48 in `src/analyzer.py`.

**Description:**  
The download route uses a password check for image "downloads" with varying response times depending on validity. A wrong password path (`else`) takes noticeably longer to respond than a correct password path, leaking timing information to an observer.

**Verification Steps:**

1. **Set up the project:**
    ```bash
    pip install -r requirements.txt
    python src/analyzer.py
    ```

2. **Test valid password (should be faster):**
    ```bash
    # This should download the "beach" image quickly (~0.1s)
    time curl -s -o /dev/null -F "password=sunnyday" http://127.0.0.1:5001/download/beach
    ```

3. **Test invalid password (should be slower):**
    ```bash
    # This will get a JSON error and take noticeably longer (~0.4s)
    time curl -s -o /dev/null -F "password=badpass" http://127.0.0.1:5001/download/beach
    ```

4. **Observe and compare the `real` time printed for both commands. The invalid password case will consistently take nearly 0.3s longer.**

**Conclusion:**  
Timing difference allows an attacker to guess correct/incorrect passwords based on response time.
EOF

chmod +x generate.sh
