
# Verification Guide - SnapImageAnalyzer

## CWE-208: Observable Timing Discrepancy

**CWE ID:** CWE-208

**Vulnerable Location:**  
- `download()` function, approx lines 37-48 in `src/analyzer.py`.

**Description:**  
The download route uses a password check for image "downloads" with varying response times depending on validity. A wrong password path (`else`) takes noticeably longer to respond than a correct password path, leaking timing information to an observer.

**Verification Steps:**

1. **Set up the project:**
    ```bash
    pip install -r requirements.txt
    python src/analyzer.py
    ```

2. **Test valid password (should be faster):**
    ```bash
    # This should download the "beach" image quickly (~0.1s)
    time curl -s -o /dev/null -F "password=sunnyday" http://127.0.0.1:5001/download/beach
    ```

3. **Test invalid password (should be slower):**
    ```bash
    # This will get a JSON error and take noticeably longer (~0.4s)
    time curl -s -o /dev/null -F "password=badpass" http://127.0.0.1:5001/download/beach
    ```

4. **Observe and compare the `real` time printed for both commands. The invalid password case will consistently take nearly 0.3s longer.**

**Conclusion:**  
Timing difference allows an attacker to guess correct/incorrect passwords based on response time.
