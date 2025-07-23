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
