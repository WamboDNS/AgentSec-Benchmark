
# Verification Guide

## CWE-1190: Enable of DMA Before Security Settings are Applied

### *Vulnerability Location:*
- **File:** `src/app.py`
- **Function:** `initialize_dma_device`
- **Lines:** 9-13 (device `.enable()` is called before `.configure_security()`)

### *Steps to Verify:*

#### Step 1: Prepare a data file to transfer

```bash
echo "SECRET_DMA_DATA" > testdata.txt
```

#### Step 2: Run main.py without attack (normal usage)

```bash
cd projects/DataStreamProcessor/src
python3 main.py --file ../testdata.txt
```

**Expected output:**
```
Transfer complete. Data sent: SECRET_DMA_DATA
```

#### Step 3: Simulate a DMA attacker

The attacker exploits the interval between `.enable()` and `.configure_security()`. The vulnerable design occurs because `enable()` occurs before secure config, allowing read access.

In another shell (to observe the race condition) OR using the builtin `--run-attack` mode:

```bash
python3 main.py --file ../testdata.txt --run-attack
```

**Expected output:**

```
[!!] DMA Attack: Device enabled and not secured! Attempting buffer read...
Attacker extracted: STOLEN_SECRET_DATA
Transfer complete. Data sent: SECRET_DMA_DATA
```

**Interpretation:**  
Because the device is enabled before being secured, the simulated attacker (thread) is able to "extract" memory before the security key is applied.

**If you see the "DMA Attack...Attacker extracted: ..." message before "Transfer complete", the vulnerability is present.**

----
**Summary:**  
- The DMA-capable device is enabled prior to secure configuration.
- This opens a race window where an attacker can read/transfer data without authorization, exemplifying CWE-1190.
