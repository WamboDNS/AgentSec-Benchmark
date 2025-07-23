
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

