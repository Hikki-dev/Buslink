import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 1. Remove import
    content = re.sub(r"import\s+['\"].*?utils/translations\.dart['\"];", "", content)

    # 2. Replace Translations.translate('key', ...) with 'key'
    # Pattern: Translations.translate('key', anything)
    # This might be multi-line
    content = re.sub(r"Translations\.translate\(\s*(['\"])(.*?)\1\s*,.*?\)", r"\1\2\1", content, flags=re.DOTALL)

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
