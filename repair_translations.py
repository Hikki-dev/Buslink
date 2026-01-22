import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 1. Handle multi-line `languageProvider.translate('key')`
    # Pattern: languageProvider .translate ('key') (with optional whitespace/newlines)
    # We strip it to just 'key'
    content = re.sub(r"languageProvider\s*\.translate\s*\(\s*(['\"])(.*?)\1\s*\)", r"\1\2\1", content, flags=re.DOTALL)

    # 2. Handle multi-line `Provider.of<LanguageProvider>(context).translate('key')`
    content = re.sub(r"Provider\.of<LanguageProvider>\s*\(.*?\)\s*\.translate\s*\(\s*(['\"])(.*?)\1\s*\)", r"\1\2\1", content, flags=re.DOTALL)

    # 3. Handle `lp.translate('key')` multi-line
    content = re.sub(r"\blp\s*\.translate\s*\(\s*(['\"])(.*?)\1\s*\)", r"\1\2\1", content, flags=re.DOTALL)

    # 4. Handle broken commented out blocks in revenue_analytics_screen.dart
    # Pattern: // child: Text(Provider.of<LanguageProvider>(context)
    #          .translate('key')))
    # Becomes: child: Text('key'),
    # This regex looks for the comment line followed by the .translate line
    content = re.sub(
        r"//\s*child:\s*Text\(Provider\.of<LanguageProvider>\(context\)\s*[\r\n]+\s*\.translate\((['\"])(.*?)\1\)\)\),?",
        r"child: Text('\2'),",
        content,
        flags=re.IGNORECASE
    )

    # 5. Handle `child: Text(Provider.of<LanguageProvider>(context).translate('key'))` (if not commented but split)
    content = re.sub(
        r"child:\s*Text\(Provider\.of<LanguageProvider>\(context\)\s*[\r\n]+\s*\.translate\((['\"])(.*?)\1\)\)",
        r"child: Text('\2')",
        content,
        flags=re.IGNORECASE
    )

    # 6. Clean up any remaining `Provider.of<LanguageProvider>(context)` imports or usages that might be standalone?
    # No, risky.

    # 7. Specific fix for PopupMenuItem child in revenue analytics if pattern differs slightly
    # // child: Text(Provider.of<LanguageProvider>(context)
    # .translate('last_7_days'))),
    # The regex #4 should catch it if formatting is consistent.
    
    # 8. Handle `Consumer<LanguageProvider>` wrappers
    # Pattern:
    # Consumer<LanguageProvider>(
    #   builder: (context, lp, _) {
    #     return ...;
    #   }
    # )
    # Replace with just the child? Hard to do with regex reliably.
    # But if `lp` is used inside, our other regexes replace `lp.translate`.
    # So we just need to change Consumer<LanguageProvider> to Consumer<Object> or something to stop type errors,
    # or just leave it if LanguageProvider class still exists?
    # User said they removed `LanguageProvider`. usage.
    # If the class is gone, `Consumer<LanguageProvider>` is a compile error.
    # We should replace `Consumer<LanguageProvider>` with `Builder`.
    # `Consumer<LanguageProvider>(builder: (context, lp, child) => ...)`
    # -> `Builder(builder: (context) { final lp = null; ... })`? Messy.
    # Maybe `Consumer<Object>` is safer for now? Or `Consumer<dynamic>`?
    # `content = re.sub(r"Consumer<LanguageProvider>", "Consumer<dynamic>", content)`
    
    
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
