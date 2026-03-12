
import zipfile
import re
import os

files = [
    "User Research - User Persona Template 2(Alumno).docx",
    "User Research - User Persona Template 2(Profesor).docx",
    "User Research - Template User Journey.docx",
    "User Research - Modelo AEIOU.docx"
]

output_file = "temp_requirements.txt"

with open(output_file, 'w', encoding='utf-8') as outfile:
    for f in files:
        if os.path.exists(f):
            try:
                outfile.write(f"\n\n--- FILE: {f} ---\n\n")
                with zipfile.ZipFile(f) as z:
                    content = z.read('word/document.xml').decode('utf-8')
                    # Replace paragraph tags with newlines
                    text = re.sub(r'<w:p[^>]*>', '\n', content)
                    # Remove all other XML tags
                    text = re.sub(r'<[^>]+>', '', text)
                    outfile.write(text)
                print(f"Processed {f}")
            except Exception as e:
                print(f"Error processing {f}: {e}")
                outfile.write(f"Error processing {f}: {e}\n")
        else:
            print(f"File not found: {f}")
            outfile.write(f"File not found: {f}\n")
