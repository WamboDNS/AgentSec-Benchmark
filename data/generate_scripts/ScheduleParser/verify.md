
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
