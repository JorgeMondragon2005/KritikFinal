import os
import re

lib_path = r"c:\Users\jorge\Downloads\Kiosko_IA-main\Kiosko_IA-main\frontend_flutter\lib"

# We want to replace role == 'teacher' with role == 'teacher' || role == 'profesor'
# and role.toLowerCase() == 'teacher' with role.toLowerCase() == 'teacher' || role.toLowerCase() == 'profesor'
# Also evaluator to evaluator || profesor in cases where it matters

replacements = [
    (r"role\.toLowerCase\(\) == 'teacher'", r"(role.toLowerCase() == 'teacher' || role.toLowerCase() == 'profesor')"),
    (r"role\.toLowerCase\(\) == 'evaluator'", r"(role.toLowerCase() == 'evaluator' || role.toLowerCase() == 'profesor')"),
    (r"userRole\?\.toLowerCase\(\) == 'teacher'", r"(userRole?.toLowerCase() == 'teacher' || userRole?.toLowerCase() == 'profesor')"),
    (r"role == 'teacher'", r"(role == 'teacher' || role == 'profesor')"),
    (r"role == 'evaluator'", r"(role == 'evaluator' || role == 'profesor')"),
]

for root, _, files in os.walk(lib_path):
    for f in files:
        if f.endswith('.dart'):
            filepath = os.path.join(root, f)
            with open(filepath, 'r', encoding='utf-8') as file:
                content = file.read()
            
            original = content
            # Quick hack to fix the specific combinations like ((role == 'teacher' || role == 'profesor') || (role == 'evaluator' || role == 'profesor'))
            # We'll just do the simple replacements
            for old, new in replacements:
                content = re.sub(old, new, content)
            
            if content != original:
                # Cleanup redundant parenthesis formatting like ((role.toLowerCase() == 'evaluator' || role.toLowerCase() == 'profesor') || (role.toLowerCase() == 'teacher' || role.toLowerCase() == 'profesor')) 
                with open(filepath, 'w', encoding='utf-8') as file:
                    file.write(content)
                print(f"Updated: {filepath}")

print("Replacement done.")
