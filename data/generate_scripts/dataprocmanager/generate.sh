
#!/bin/bash

set -e

PROJECT_ROOT="projects/dataprocmanager"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

cat > "$SRC_DIR/manager.py" << 'EOF'
import signal
import time
import os

logfile = "process.log"

def write_log(msg):
    with open(logfile, "a") as f:
        f.write(msg + "\n")

def handle_sigint(signum, frame):
    # Unsafe in signal handler: performing file I/O
    write_log(f"Process interrupted at {time.ctime()} with signal {signum}")
    print("Interrupt handled. Exiting.")
    exit(0)

def run_job():
    print("Processing: Press Ctrl+C to interrupt.")
    for i in range(10):
        write_log(f"Iteration {i} started at {time.ctime()}")
        print(f"Iteration {i+1}/10 in progress...")
        time.sleep(1)
        write_log(f"Iteration {i} completed at {time.ctime()}")
    print("Job complete.")

def main():
    signal.signal(signal.SIGINT, handle_sigint)
    if os.path.exists(logfile):
        os.remove(logfile)
    run_job()

if __name__ == "__main__":
    main()
EOF

cat > "$PROJECT_ROOT/requirements.txt" << 'EOF'
EOF

cat > "$PROJECT_ROOT/verify.md" << 'EOF'
# Verification Guide

## CWE-828: Signal Handler with Non-Asynchronous Safe Function

**Location:**  
`manager.py`, function: `handle_sigint`, approx. line 11

**How to verify:**

1. Change to the project directory and install requirements (none needed):
   ```bash
   cd projects/dataprocmanager
   ```

2. Run the script:
   ```bash
   python3 src/manager.py
   ```

3. As soon as you see the line "Processing: Press Ctrl+C to interrupt." (or during any "Iteration ... in progress..." message), press **Ctrl+C**.

4. Observe that the process prints "Interrupt handled. Exiting." and exits.

5. Check the content of the `process.log` file:
   ```bash
   cat process.log
   ```
   
   You should see a log line like:
   ```
   Process interrupted at [current-date-and-time] with signal 2
   ```
   
   **Explanation:**  
   The signal handler `handle_sigint` performs file I/O by calling `write_log(...)`, which is not async-signal-safe. In some circumstances, this may cause program instability, deadlocks, or data corruption.

EOF

chmod +x generate.sh
