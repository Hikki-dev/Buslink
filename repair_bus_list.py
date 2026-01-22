import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Fix toLowerCase(.replaceAll -> toLowerCase().replaceAll
    content = re.sub(r"\.toLowerCase\(\s*\.replaceAll", ".toLowerCase().replaceAll", content)

    if content != original_content:
        print(f"Repaired {filepath}")
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
