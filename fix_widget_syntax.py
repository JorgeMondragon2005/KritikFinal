import os
import re

lib_path = r"c:\Users\jorge\Downloads\Kiosko_IA-main\Kiosko_IA-main\frontend_flutter\lib"

for root, _, files in os.walk(lib_path):
    for f in files:
        if f.endswith('.dart'):
            filepath = os.path.join(root, f)
            with open(filepath, 'r', encoding='utf-8') as file:
                content = file.read()
            
            original = content
            # Fix widget.(role.toLowerCase() == 'evaluator' || role.toLowerCase() == 'profesor')
            content = content.replace("widget.(role.toLowerCase() == 'evaluator' || role.toLowerCase() == 'profesor')", "(widget.role.toLowerCase() == 'evaluator' || widget.role.toLowerCase() == 'profesor')")
            
            # Fix widget.(role.toLowerCase() == 'teacher' || role.toLowerCase() == 'profesor')
            content = content.replace("widget.(role.toLowerCase() == 'teacher' || role.toLowerCase() == 'profesor')", "(widget.role.toLowerCase() == 'teacher' || widget.role.toLowerCase() == 'profesor')")
            
            if content != original:
                with open(filepath, 'w', encoding='utf-8') as file:
                    file.write(content)
                print(f"Fixed: {filepath}")

print("Fixes applied.")
