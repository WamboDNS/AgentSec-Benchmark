import xml.etree.ElementTree as ET
from typing import List, Optional
import json
import requests
import zipfile
import tempfile
import os
from models import CWEEntry

class CWEExtractor:
    def __init__(self, xml_url: str = "https://cwe.mitre.org/data/xml/cwec_latest.xml.zip"):
        self.xml_url = xml_url
        self.namespace = {
            'cwe': 'http://cwe.mitre.org/cwe-7',
            'xhtml': 'http://www.w3.org/1999/xhtml'
        }
        self._xml_content = None
        self._cwe_entries = None
    
    def download_and_extract_xml(self) -> str:
        if self._xml_content is not None:
            return self._xml_content
            
        print(f"Downloading CWE data from {self.xml_url}...")
        
        response = requests.get(self.xml_url)
        response.raise_for_status()
        
        with tempfile.NamedTemporaryFile(delete=False, suffix='.zip') as temp_zip:
            temp_zip.write(response.content)
            temp_zip_path = temp_zip.name
        
        try:
            with zipfile.ZipFile(temp_zip_path, 'r') as zip_ref:
                file_list = zip_ref.namelist()
                
                xml_file = None
                for file in file_list:
                    if file.endswith('.xml'):
                        xml_file = file
                        break
                
                if not xml_file:
                    raise ValueError("No XML file found in the downloaded ZIP")
                
                print(f"Extracting {xml_file} from ZIP...")
                
                with tempfile.TemporaryDirectory() as temp_dir:
                    zip_ref.extract(xml_file, temp_dir)
                    xml_path = os.path.join(temp_dir, xml_file)
                    
                    with open(xml_path, 'r', encoding='utf-8') as f:
                        self._xml_content = f.read()
                    
                    return self._xml_content
        
        finally:
            os.unlink(temp_zip_path)
    
    def extract_cwes(self) -> List[CWEEntry]:
        if self._cwe_entries is not None:
            return self._cwe_entries
            
        xml_content = self.download_and_extract_xml()
        root = ET.fromstring(xml_content)
        
        cwe_entries = []
        
        for weakness in root.findall('.//cwe:Weakness', self.namespace):
            cwe_id = weakness.get('ID')
            cwe_name = weakness.get('Name')
            
            if cwe_id and cwe_name:
                description = self._extract_description(weakness) or cwe_name
                
                cwe_entry = CWEEntry(
                    id=f"CWE-{cwe_id}",
                    description=description
                )
                cwe_entries.append(cwe_entry)
        
        self._cwe_entries = cwe_entries
        return cwe_entries
    
    def _extract_description(self, weakness_element) -> Optional[str]:
        description_elem = weakness_element.find('.//cwe:Description', self.namespace)
        if description_elem is not None:
            return self._clean_text(description_elem.text)
        
        extended_desc_elem = weakness_element.find('.//cwe:Extended_Description', self.namespace)
        if extended_desc_elem is not None:
            return self._clean_text(extended_desc_elem.text)
        
        return None
    
    def _clean_text(self, text: str) -> str:
        if not text:
            return ""
        return ' '.join(text.strip().split())
    
    def save_to_json(self, output_file: str) -> None:
        cwe_entries = self.extract_cwes()
        data = [entry.model_dump() for entry in cwe_entries]
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f"Extracted {len(cwe_entries)} CWE entries to {output_file}")

def main():
    output_file = "data/extracted_cwes.json"
    
    extractor = CWEExtractor()
    cwe_entries = extractor.extract_cwes()
    
    print(f"Found {len(cwe_entries)} CWE entries")
    print("\nFirst 5 entries:")
    for i, entry in enumerate(cwe_entries[:5]):
        print(f"{i+1}. {entry.id}: {entry.description}")
    
    extractor.save_to_json(output_file)

if __name__ == "__main__":
    main()
