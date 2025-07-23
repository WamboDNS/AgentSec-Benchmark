
#!/bin/bash

set -e

PROJECT_ROOT="projects/ScheduleParser"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

cat > "$SRC_DIR/main.py" <<'EOF'
import argparse
import json
import sys
import webbrowser
import os

def export_schedule(schedule, format_, output):
    if format_ == "json":
        with open(output, 'w') as f:
            json.dump(schedule, f, indent=2)
    elif format_ == "txt":
        with open(output, 'w') as f:
            f.write("Weekly Schedule:\n")
            for day, events in schedule.items():
                f.write(f"{day}:\n")
                for evt in events:
                    f.write(f"  - {evt}\n")
    else:
        print("Unsupported export format:", format_)
        sys.exit(1)

def load_schedule(file_path):
    schedule = {}
    with open(file_path, 'r') as f:
        for line in f:
            if ':' in line:
                day, evts = line.split(':', 1)
                evts_list = [x.strip() for x in evts.strip().split(',') if x.strip()]
                schedule[day.strip()] = evts_list
    return schedule

def open_external_app(data_file):
    # Attempt to use a "url scheme" to trigger opening with an external app that handles "file://" links
    uri = f"file://{os.path.abspath(data_file)}"
    webbrowser.open(uri)

def main():
    parser = argparse.ArgumentParser(description="Weekly Schedule Parser")
    parser.add_argument('schedule_file', help="Path to the schedule.txt file")
    parser.add_argument('--export', choices=['json', 'txt'], help="Export schedule data")
    parser.add_argument('--output', help="Output file for --export")
    parser.add_argument('--share', action='store_true', help="Share exported schedule with external application")

    args = parser.parse_args()

    schedule = load_schedule(args.schedule_file)

    if args.export and args.output:
        export_schedule(schedule, args.export, args.output)
        print(f"Schedule exported to {args.output}")

        if args.share:
            print(f"Opening exported file with default handler...")
            open_external_app(args.output)
    else:
        print("Weekly Schedule:")
        for day, events in schedule.items():
            print(f"{day}:")
            for evt in events:
                print(f"  - {evt}")

if __name__ == '__main__':
    main()
EOF

cat > "$SRC_DIR/__init__.py" <<EOF
# ScheduleParser package
EOF

cat > "$PROJECT_ROOT/requirements.txt" <<EOF
EOF

cat > "$PROJECT_ROOT/verify.md" <<'EOF'
# Verification Guide

## CWE-927: Use of Implicit Intent for Sensitive Data

**File:** `src/main.py`  
**Location:** Function: `open_external_app`, Line ~21

---

### Steps to Verify

#### 1. Prepare a `schedule.txt` file

Create a file named `schedule.txt` in the project root with the following content:

```
Monday: Meeting with Alice, Lunch with Bob
Tuesday: Gym, Project review
Wednesday: Doctor appointment, Call mom
```

#### 2. Export the schedule and "share" with an external application

Run the following command from inside the project directory:

```
python3 src/main.py schedule.txt --export json --output export.json --share
```

- This will create `export.json` (containing sensitive schedule data) and then open it using the system's default handler for file URLs.
- On many platforms, this is equivalent to sending a "file://" URI out to any registered application (possibly a browser or another app capable of handling such URIs), which is analogous to sending an **implicit intent** with potentially sensitive data.

#### 3. Observe behavior

- The `export.json` file, which may contain sensitive information, is opened via a general-purpose URL handler—any application configured to handle `file://` URIs can access the data. This is similar to implicit intent broadcasting in mobile environments.
- There is no restriction on which application handles the file, or verification that the recipient is trustworthy.

#### 4. Interpretation

- The `open_external_app` function (src/main.py, line ~21) transmits sensitive data (`export.json`) via an implicit "intent" (in this case, `webbrowser.open`) without controlling which external program will process the file, fitting CWE-927.
EOF

chmod +x generate.sh
