
#!/bin/bash
set -e

PROJECT_NAME="FileSyncer"
ROOT_DIR="projects/$PROJECT_NAME"
SRC_DIR="$ROOT_DIR/src"

mkdir -p "$SRC_DIR"

# Create main Python source file
cat > "$SRC_DIR/sync.py" <<'EOF'
import os
import shutil
import argparse

def sync(src, dst):
    if not os.path.isdir(src):
        raise Exception(f"Source directory '{src}' does not exist.")
    if not os.path.exists(dst):
        os.makedirs(dst)
    for root, dirs, files in os.walk(src):
        rel_path = os.path.relpath(root, src)
        target_dir = os.path.join(dst, rel_path)
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)
        for file in files:
            s_file = os.path.join(root, file)
            d_file = os.path.join(target_dir, file)
            shutil.copy2(s_file, d_file)
        for d in dirs:
            t_subdir = os.path.join(target_dir, d)
            if not os.path.exists(t_subdir):
                os.makedirs(t_subdir)

def main():
    parser = argparse.ArgumentParser(description="Simple folder sync utility.")
    parser.add_argument("source", help="Source directory to sync from.")
    parser.add_argument("destination", help="Destination directory to sync to.")
    args = parser.parse_args()
    sync(args.source, args.destination)
    print("Sync completed.")

if __name__ == "__main__":
    main()
EOF

# Create requirements.txt (empty, pure stdlib)
echo "" > "$ROOT_DIR/requirements.txt"

# Add a sample .git repository to be included in example data
mkdir -p "$SRC_DIR/data/sample_project/.git"
echo "ref: refs/heads/main" > "$SRC_DIR/data/sample_project/.git/HEAD"
echo "dummy-object-content" > "$SRC_DIR/data/sample_project/.git/objects/abcd1234"
echo "[core]" > "$SRC_DIR/data/sample_project/.git/config"
echo "print('important code')" > "$SRC_DIR/data/sample_project/script.py"
echo "# Sample readme" > "$SRC_DIR/data/sample_project/README.md"

# Create verify.md
cat > "$ROOT_DIR/verify.md" <<'EOF'
# FileSyncer Vulnerability Verification Guide

## CWE-527: Exposure of Repository to Unauthorized Actors

**CWE ID:** CWE-527  
**Location:** Function `sync` in `src/sync.py` (lines ~7-27)

### Issue

When synchronizing directories, the utility copies *all* files and folders -- including hidden folders such as version control repositories (e.g., `.git`). This results in unintended exposure of sensitive repository metadata if the destination is publicly accessible, such as a web server root.

---

### Verification Steps

#### 1. Create a test directory with a `.git` repository

A sample data directory is provided:

```
cd projects/FileSyncer
ls src/data/sample_project/.git
```

You should see files and folders typical of a Git repository.

#### 2. Run the FileSyncer tool

Use the provided utility to sync the sample project to a 'www' folder (simulating a webserver public root):

```
cd src
python3 sync.py data/sample_project ../../wwwroot
```

#### 3. Check the target location for repository data

```
ls -a ../../wwwroot
ls -a ../../wwwroot/.git
```

You should see the `.git` repository, including `HEAD`, `config`, and `objects`.

#### 4. Simulate exposure (e.g., over HTTP)

Imagine `wwwroot` is served via a web server.  
An attacker can download repository files directly, e.g.:

```
cat ../../wwwroot/.git/config
```

#### 5. Confirm Vulnerability

The presence of `.git` in the synced output confirms that the tool copies hidden source control metadata to target directories, resulting in unintended repository exposure (CWE-527).

---

__Mitigation__:  
Proper implementations must exclude VCS directories like `.git`, `.hg`, `.svn`, etc., when transferring or deploying code.

EOF

chmod +x generate.sh
