import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 1. Fix Text( // 'string' pattern (and variants like "string")
    # Matches: Text( \n // 'string',
    # Replacement: Text('string',
    content = re.sub(r"Text\(\s*//\s*(['\"].*?['\"])(,)?", r"Text(\1\2", content, flags=re.IGNORECASE)

    # 2. Fix _kpiCard( // 'string',
    content = re.sub(r"_kpiCard\(\s*//\s*(['\"].*?['\"])(,)?", r"_kpiCard(\1\2", content, flags=re.IGNORECASE)

    # 3. Fix label: Text( // "string"),
    content = re.sub(r"label:\s*Text\(\s*//\s*(['\"].*?['\"])(,)?", r"label: Text(\1\2", content, flags=re.IGNORECASE)

    # 4. Fix hint: Text( // "string") - rare but possible
    content = re.sub(r"hint:\s*Text\(\s*//\s*(['\"].*?['\"])(,)?", r"hint: Text(\1\2", content, flags=re.IGNORECASE)
    
    # 5. Fix home_screen.dart specific broken assignments
    # final translatedOption =
    # //                                   Provider.of<LanguageProvider>(context,
    #                                           listen: false)
    #                                       .translate(cityKey);
    # This is hard to regex perfectly, but let's try to detect the broken block.
    # We want: final translatedOption = cityKey;
    
    if 'home_screen.dart' in filepath:
        # Fix translatedOption assignment
        content = re.sub(
            r"final translatedOption =\s*//\s*Provider\.of<LanguageProvider>.*?\)\s*\.translate\(cityKey\);",
            r"final translatedOption = cityKey;",
            content,
            flags=re.DOTALL
        )
        # Fallback for slightly different formatting or if previous regex touched it
        content = re.sub(
            r"final translatedOption =\s*[\r\n]+//\s*Provider\.of.*?\)\s*[\r\n]+\s*\.translate\(cityKey\);",
            r"final translatedOption = cityKey;",
            content,
            flags=re.DOTALL
        )

        # Fix `final lp = // ...;`
        content = re.sub(
            r"final lp =\s*//\s*Provider\.of<LanguageProvider>.*?;",
            r"// final lp removed",
            content,
            flags=re.DOTALL
        )

    # 6. Fix `admin_refund_list.dart` etc.
    # Text( // 'status_$s' .toUpperCase()
    # matches: Text( \n // 'str' \n .upper()
    content = re.sub(
        r"Text\(\s*//\s*(['\"].*?['\"])\s*(\.[a-zA-Z0-9_]+\(\))",
        r"Text(\1\2",
        content,
        flags=re.DOTALL
    )

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
