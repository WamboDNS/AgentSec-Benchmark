from flask import Flask, request, render_template_string, redirect, url_for

import os

app = Flask(__name__)

DATA_DIR = os.path.join(os.path.dirname(__file__), 'notes')
os.makedirs(DATA_DIR, exist_ok=True)

NOTE_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>Note Viewer</title>
</head>
<body>
    <h1>Note: {{ filename }}</h1>
    <pre>{{ content }}</pre>
    <a href="{{ url_for('home') }}">Back</a>
</body>
</html>
"""

HOME_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>FileNote</title>
</head>
<body>
    <h1>Welcome to FileNote</h1>
    <form method="POST" action="{{ url_for('save_note') }}">
        <label for="filename">Note name:</label><input type="text" name="filename" /><br/>
        <label for="content">Contents:</label><br/>
        <textarea name="content" rows="12" cols="60"></textarea><br/>
        <button type="submit">Save</button>
    </form>
    <h2>Saved Notes</h2>
    <ul>
    {% for f in files %}
        <li><a href="{{ url_for('view_note', filename=f) }}">{{ f }}</a></li>
    {% endfor %}
    </ul>
</body>
</html>
"""

@app.route('/', methods=['GET'])
def home():
    files = sorted(os.listdir(DATA_DIR))
    return render_template_string(HOME_TEMPLATE, files=files)

@app.route('/save', methods=['POST'])
def save_note():
    fname = request.form.get('filename', '').strip()
    content = request.form.get('content', '')
    # Accept raw user filename, should write to notes/...
    path = os.path.join(DATA_DIR, fname)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    return redirect(url_for('view_note', filename=fname))

@app.route('/note/<path:filename>')
def view_note(filename):
    path = os.path.join(DATA_DIR, filename)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
    else:
        content = "[Not found]"
    return render_template_string(NOTE_TEMPLATE, filename=filename, content=content)

if __name__ == '__main__':
    app.run(debug=True)
