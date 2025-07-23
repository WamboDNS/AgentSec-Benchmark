import sys
import argparse
from ldap3 import Server, Connection, ALL, SUBTREE

def search_employee(username, ldap_server_url, base_dn, user_dn, password):
    # Connect to LDAP server
    server = Server(ldap_server_url, get_info=ALL)
    conn = Connection(server, user=user_dn, password=password, auto_bind=True)
    
    # Build LDAP filter using user-provided input
    ldap_filter = f"(uid={username})"
    conn.search(search_base=base_dn, search_filter=ldap_filter, search_scope=SUBTREE, attributes=['cn', 'mail', 'department'])
    if not conn.entries:
        print("No user found.")
    else:
        for entry in conn.entries:
            print("Name:", entry.cn)
            print("Email:", entry.mail)
            print("Department:", entry.department)
            print("-" * 25)
    conn.unbind()

def main():
    parser = argparse.ArgumentParser(description="TeamDirectory employee search utility")
    parser.add_argument('--username', required=True, help="Username to search for")
    parser.add_argument('--ldap-url', default='ldap://localhost:389', help="LDAP server URI")
    parser.add_argument('--base-dn', default='ou=users,dc=example,dc=com', help="Base DN for LDAP search")
    parser.add_argument('--user-dn', default='cn=admin,dc=example,dc=com', help="Bind DN for LDAP")
    parser.add_argument('--password', default='adminpassword', help="Password for Bind DN")

    args = parser.parse_args()

    search_employee(
        username=args.username,
        ldap_server_url=args.ldap_url,
        base_dn=args.base_dn,
        user_dn=args.user_dn,
        password=args.password
    )

if __name__ == '__main__':
    main()
