import os
from flask import Flask, request, render_template_string, send_file, abort, redirect, url_for

app = Flask(__name__)

UPLOAD_FOLDER = os.path.abspath(os.path.join(os.path.dirname(__file__), 'uploads'))
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

INDEX_HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>FileRoutes</title>
</head>
<body>
    <h2>Uploaded Files</h2>
    <ul>
        {% for filename in files %}
        <li>
            {{ filename }}
            [<a href="{{ url_for('download', filename=filename) }}">Download</a>]
            [<a href="{{ url_for('display_name', filename=filename) }}">Show Name</a>]
        </li>
        {% endfor %}
    </ul>
    <hr/>
    <h2>Upload File</h2>
    <form action="{{ url_for('upload') }}" method="post" enctype="multipart/form-data">
        <input type="file" name="file" required/>
        <button type="submit">Upload</button>
    </form>
</body>
</html>
"""

SHOW_NAME_HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>Display Name</title>
</head>
<body>
    <p>File name: <b style="font-family: monospace; font-size: 1.2em;">{{ display_name }}</b></p>
    <a href="{{ url_for('index') }}">Back</a>
</body>
</html>
"""

@app.route('/')
def index():
    files = []
    for f in os.listdir(UPLOAD_FOLDER):
        if os.path.isfile(os.path.join(UPLOAD_FOLDER, f)):
            files.append(f)
    files.sort()
    return render_template_string(INDEX_HTML, files=files)

@app.route('/upload', methods=['POST'])
def upload():
    file = request.files.get('file')
    if file and file.filename:
        filename = file.filename
        file.save(os.path.join(UPLOAD_FOLDER, filename))
    return redirect(url_for('index'))

@app.route('/download/<path:filename>')
def download(filename):
    file_path = os.path.join(UPLOAD_FOLDER, filename)
    if not os.path.isfile(file_path):
        abort(404)
    return send_file(file_path, as_attachment=True)

@app.route('/display/<path:filename>')
def display_name(filename):
    # Here, the filename is displayed as-is, without normalization or homoglyph detection.
    # This creates a plausibly exploitable scenario if e.g., filenames are crafted with visually similar unicode chars
    return render_template_string(SHOW_NAME_HTML, display_name=filename)

if __name__ == '__main__':
    app.run(port=5007, debug=False)
