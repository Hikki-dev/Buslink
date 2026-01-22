import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 1. Uncomment `// child: Text(...)`
    # Pattern: // whitespace child: Text(
    content = re.sub(r"//\s*(child:\s*Text\()", r"\1", content)
    
    # 2. Uncomment `// hint: Text(...)`
    content = re.sub(r"//\s*(hint:\s*Text\()", r"\1", content)

    # 3. Uncomment `// label: Text(...)`
    content = re.sub(r"//\s*(label:\s*Text\()", r"\1", content)

    # 4. Uncomment `// 'string'` inside Text( or similar
    # This specifically addresses the broken Text widget in admin_booking_list.dart
    # Pattern: child: Text( \n // 'status_$s' \n .toUpperCase()
    # matches: Text\(\s*//\s*(['"].*?['"])\s*(\.[a-zA-Z]+\(\))?
    # Replace with: Text(\1\2
    content = re.sub(r"Text\(\s*//\s*(['\"].*?['\"])\s*(\.[a-zA-Z]+\(\),?)", r"Text(\1\2", content, flags=re.DOTALL)

    # 5. Generic uncomment of `// child: Text(...)` spanning multiple lines if any
    # (Regex #1 parses line by line if defaults used, but we want to be safe)
    
    # 6. Check for `// : 'travel_date_hint',`
    # In admin_booking_list.dart:
    # 191:                                           .format(_selectedDate!)
    # 192: //                                       : 'travel_date_hint',
    # This is part of ternary operator: condition ? val : val
    # We need to uncomment this too.
    # Pattern: // : '...'
    content = re.sub(r"//\s*(:\s*['\"].*?['\"],?)", r"\1", content)

    # 7. Check for `// .translate(...)` that might still exist?
    # No, hopefully previous script fixed that.
    
    # 8. Late Departures Screen: `Text('some_string'.translate(...))`
    # If regex #3 in repair_translations didn't catch it.
    # But let's assume repair_translations did its job on .translate replacement.
    
    if content != original_content:
        print(f"Repaired comments in {filepath}")
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

def main():
    root_dir = 'lib'
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith(".dart"):
                fix_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
