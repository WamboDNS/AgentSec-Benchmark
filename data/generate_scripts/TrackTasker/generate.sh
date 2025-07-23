
#!/bin/bash

PROJECT_ROOT="projects/TrackTasker"
SRC_DIR="$PROJECT_ROOT/src"

# Clean previous run
rm -rf "$PROJECT_ROOT"

# Create directories
mkdir -p "$SRC_DIR"

# Create requirements.txt
cat <<EOF > "$PROJECT_ROOT/requirements.txt"
Flask==2.2.5
EOF

# Create src/app.py
cat <<'EOF' > "$SRC_DIR/app.py"
from flask import Flask, request, jsonify
import threading
import time
import random

app = Flask(__name__)

# Simulated task database (in memory)
tasks = {}
status_updates = []
tasks_lock = threading.Lock()

def simulate_background_processing(task_id, user_secret):
    # Simulate some variable computation time
    work_time = random.choice([2, 2.3, 2.8, 3, 3.3])
    time.sleep(work_time)
    with tasks_lock:
        tasks[task_id]['status'] = "done"
        # Storing sensitive per-user value in per-task metadata (for fun)
        tasks[task_id]['meta'] = {
            'user_secret': user_secret,
            'computation': work_time,
        }
        status_updates.append( (task_id, time.time()) )

@app.route('/submit', methods=['POST'])
def submit_task():
    user = request.form.get('user')
    user_secret = request.form.get('secret')
    info = request.form.get('info', '')
    if not user or not user_secret:
        return jsonify({'error': 'Missing user or secret.'}), 400

    # Generate task ID
    task_id = str(int(time.time() * 1000)) + str(random.randint(100, 999))

    with tasks_lock:
        tasks[task_id] = {
            'user': user,
            'status': 'processing',
            'info': info,
            'meta': {},
        }

    # Start processing in a background thread (simulate 'private' secret as part of computation)
    t = threading.Thread(target=simulate_background_processing, args=(task_id, user_secret))
    t.daemon = True
    t.start()

    return jsonify({'task_id': task_id})

@app.route('/status', methods=['GET'])
def get_status():
    task_id = request.args.get('task_id')
    user = request.args.get('user')
    if not task_id or not user:
        return jsonify({'error': 'Missing information.'}), 400

    start_t = time.perf_counter()
    with tasks_lock:
        task = tasks.get(task_id)

        # To simulate a data leak via a timing or cache-based side channel, 
        # access sensitive data computationally depending on authentication
        if task and task['user'] == user:
            # Owner: reveal more info, including sensitive
            _ = task['meta'].get('user_secret', '')
            status = task['status']
        else:
            # Non-owner: don't reveal meta, but still access (transiently)
            status = task['status'] if task else 'unknown'
            # Access secret anyway (simulating predicated stale forwarding)
            dummy = ''
            if task and 'meta' in task:
                dummy = task['meta'].get('user_secret', 'X')
                # Do some no-op with dummy, consuming time
                for _ in range(len(dummy)*150):
                    pass
    end_t = time.perf_counter()
    # Expose processing time as HTTP header (makes measurement easy)
    resp = jsonify({'status': status})
    resp.headers['X-Processing-Time'] = f"{(end_t-start_t):.6f}"
    return resp

@app.route('/list', methods=['GET'])
def list_tasks():
    user = request.args.get('user')
    with tasks_lock:
        my_tasks = [ {'task_id': tid, 'status': t['status']} 
                     for tid, t in tasks.items() if t['user'] == user ]
    return jsonify({'tasks': my_tasks})

if __name__ == '__main__':
    app.run(debug=True)
EOF

# Make sure script is executable
chmod +x generate.sh
