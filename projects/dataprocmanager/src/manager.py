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
