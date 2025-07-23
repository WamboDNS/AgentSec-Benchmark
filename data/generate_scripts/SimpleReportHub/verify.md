
# Vulnerability Verification Guide

## CWE-424: Improper Protection of Alternate Paths

### Location

- Function: `main()`
- File: `src/app.py`
- Approximate line number: 60-75 (the `'list'` action logic in the command-line arguments)

### Description

Normal users should only be able to list their own reports.
However, when a non-admin user runs the `'list'` action, if they answer `"y"` to the prompt "View all reports?", the application lists **all reports**, bypassing the privilege check.

### Steps to Verify

1. Open a terminal.
2. Run the application as a normal user (e.g., "alice"):
    ```
    cd projects/SimpleReportHub
    python3 src/app.py list
    ```
3. When prompted:
    - For `Username:`, enter: `alice`
    - For `Password:`, enter: `wonderland`
4. When prompted: "View all reports? (y/N):", enter: `y`
5. **Expected vulnerable behavior:** You will see reports from all users, including admin-only and other users' reports:
    ```
    Reports:
    - alice: Alice's first report.
    - bob: Bob's admin report.
    - charlie: Charlie's report.
    - bob: Bob's confidential report.
    ```
6. Try the same as user "bob" to confirm expected admin behavior.
7. For a safe path, run as "alice" and answer `n` (or press enter) when prompted, to see that only Alice's reports are listed.

**This demonstrates lack of proper protection on an alternate path to restricted functionality.**
