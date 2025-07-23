
# verify.md

## CWE-575: The product violates the Enterprise JavaBeans (EJB) specification by using AWT/Swing.

**Location:**  
Function: `notify_admin` in `src/app.py`, lines ~14-24.

**Verification Steps:**
1. Install dependencies and run the Flask app:
    ```bash
    cd projects/taskpad
    pip install -r requirements.txt
    python src/app.py
    ```
2. Open a browser and visit: [http://127.0.0.1:5000/](http://127.0.0.1:5000/)
3. Add a new task by filling in the Title and Description fields, then submit.
4. **Expected Result:**  
   On the server machine (NOT the browser), a desktop popup appears indicating a new task was added. This is caused by `tkinter.messagebox.showinfo` being called in a server-side process—a desktop GUI dependency/frame used in a web server context.
5. **Why is this a violation?**  
   This mimics the violation described in CWE-575 (mixing desktop GUI with enterprise/server logic). Here, a headless server running a Flask app improperly attempts to use a desktop GUI API (Tkinter), which is not appropriate and may cause the server to hang or error, especially when deployed in environments without a display. This maps closely to the spirit of CWE-575 within the context of a Python project.
