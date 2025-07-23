from flask import Flask, request, render_template_string
import threading

# Desktop popup in server-side context (bad pattern)
try:
    import tkinter as tk
    from tkinter import messagebox
except:
    tk = None
    messagebox = None

app = Flask(__name__)

tasks = []

def notify_admin(task):
    # Use Tkinter to show a system message box when a new task is added
    # Not suitable for server-side usage, but code does it anyway
    if tk and messagebox:
        def popup():
            root = tk.Tk()
            root.withdraw()
            messagebox.showinfo("New Task", f"A new task has been added: {task['title']}")
            root.quit()
            root.destroy()
        # Run in thread to not block Flask
        threading.Thread(target=popup).start()

@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        title = request.form.get("title", "").strip()
        desc = request.form.get("desc", "").strip()
        if title:
            task = {"title": title, "desc": desc}
            tasks.append(task)
            notify_admin(task)
    return render_template_string(
        '''
        <h1>TaskPad</h1>
        <form method="post">
          Title: <input name="title"/><br/>
          Description: <input name="desc"/><br/>
          <input type="submit" value="Add Task"/>
        </form>
        <h2>Tasks:</h2>
        <ul>
        {% for t in tasks %}
          <li><b>{{t.title}}</b>: {{t.desc}}</li>
        {% endfor %}
        </ul>
        ''',
        tasks=tasks
    )

if __name__ == "__main__":
    app.run(port=5000)
