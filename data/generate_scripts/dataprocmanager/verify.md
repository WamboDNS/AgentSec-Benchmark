
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

