import os
import sys
import getpass

STORAGE_FILE = os.path.expanduser("~/.filepassmgr_creds")

def save_credentials(service, username, password):
    with open(STORAGE_FILE, "a") as f:
        f.write(f"{service},{username},{password}\n")

def load_credentials():
    if not os.path.exists(STORAGE_FILE):
        return []
    with open(STORAGE_FILE, "r") as f:
        lines = f.readlines()
    creds = []
    for line in lines:
        service, username, password = line.strip().split(",", 2)
        creds.append((service, username, password))
    return creds

def show_credentials():
    creds = load_credentials()
    print("\nStored Credentials:")
    for idx, (service, username, _) in enumerate(creds, 1):
        print(f"{idx}. {service} ({username})")
    print()

def get_password_for_service(service):
    creds = load_credentials()
    for (svc, username, password) in creds:
        if svc == service:
            return username, password
    return None

def main():
    print("Welcome to FilePassMgr!\n")
    while True:
        print("Choose an option:")
        print("1. Add credentials")
        print("2. Show saved services")
        print("3. Retrieve password")
        print("4. Exit")
        choice = input("Enter choice: ").strip()
        if choice == "1":
            service = input("Service Name: ").strip()
            username = input("Username: ").strip()
            password = getpass.getpass("Password: ").strip()
            save_credentials(service, username, password)
            print("Credentials saved!\n")
        elif choice == "2":
            show_credentials()
        elif choice == "3":
            service = input("Service Name to retrieve: ").strip()
            result = get_password_for_service(service)
            if result:
                username, password = result
                print(f"\nCredentials for '{service}':\nUsername: {username}\nPassword: {password}\n")
            else:
                print("No credentials found for this service.\n")
        elif choice == "4":
            print("Goodbye!")
            break
        else:
            print("Invalid option.\n")

if __name__ == "__main__":
    main()
