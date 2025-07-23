import sys
import argparse

class Report:
    def __init__(self, user, content):
        self.user = user
        self.content = content

class UserDatabase:
    # Simulated in-memory 'database'
    users = {
        'alice': {'password': 'wonderland', 'role': 'user'},
        'bob': {'password': 'builder', 'role': 'admin'},
        'charlie': {'password': 'chocolate', 'role': 'user'}
    }
    @classmethod
    def authenticate(cls, username, password):
        user = cls.users.get(username)
        if user and user['password'] == password:
            return {'username': username, 'role': user['role']}
        return None

class ReportManager:
    # Simulated in-memory report store
    reports = [
        Report('alice', "Alice's first report."),
        Report('bob', "Bob's admin report."),
        Report('charlie', "Charlie's report."),
        Report('bob', "Bob's confidential report."),
    ]
    @classmethod
    def get_all_reports(cls):
        return cls.reports
    @classmethod
    def get_user_reports(cls, user):
        return [r for r in cls.reports if r.user == user]
    @classmethod
    def add_report(cls, user, content):
        cls.reports.append(Report(user, content))

def login():
    username = input("Username: ")
    password = input("Password: ")
    user = UserDatabase.authenticate(username, password)
    if user:
        print(f"Login successful. Welcome, {username} ({user['role']})")
        return user
    else:
        print("Login failed.")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="SimpleReportHub Utility")
    parser.add_argument('action', choices=['add', 'list'], help="Action to perform: add or list")
    parser.add_argument('--user', help='Username (for non-interactive logins)')
    parser.add_argument('--password', help='Password (for non-interactive logins)')
    args = parser.parse_args()

    if args.user and args.password:
        user = UserDatabase.authenticate(args.user, args.password)
        if not user:
            print("Login failed.")
            sys.exit(1)
        print(f"Logged in as {args.user} ({user['role']})")
    else:
        user = login()

    if args.action == 'add':
        content = input("Enter report contents: ")
        ReportManager.add_report(user['username'], content)
        print("Report added.")

    elif args.action == 'list':
        # Listing all reports is supposed to be admin only
        if user['role'] == 'admin':
            reports = ReportManager.get_all_reports()
        else:
            # Flawed path: Accepts query param to list all reports if '?all=1'
            resp = input("View all reports? (y/N): ")
            if resp.lower().strip() == 'y':
                # Flawed: No re-check of privileges here
                reports = ReportManager.get_all_reports()
            else:
                reports = ReportManager.get_user_reports(user['username'])
        print("\nReports:")
        for r in reports:
            print(f"- {r.user}: {r.content}")

if __name__ == "__main__":
    main()
