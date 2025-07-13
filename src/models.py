from pydantic import BaseModel

class CWEEntry(BaseModel):
    """Pydantic model for CWE entry containing ID and description."""
    id: str
    description: str