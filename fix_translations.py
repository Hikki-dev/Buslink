import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 1. Remove Imports
    content = re.sub(r"import\s+['\"].*?language_provider\.dart['\"];\n?", "", content)
    content = re.sub(r"import\s+['\"].*?app_localizations\.dart['\"];\n?", "", content)

    # 2. Remove Provider.of<LanguageProvider> definitions
    # Matches: final lp = Provider.of<LanguageProvider>(context);
    # Matches: final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    content = re.sub(r"(final|var)\s+\w+\s*=\s*Provider\.of<LanguageProvider>.*?;", "", content)
    
    # 3. Remove Consumer<LanguageProvider> wrapper (simplified - just removing the line might break structure, so usually we replace usage)
    # This is hard to regex safely. We'll skip stripping Consumer wrappers for now and rely on fixing the USAGE inside.
    # If Consumer is used, 'builder' provides the variable. We might need to handle that manually or via improved regex.
    # For now, let's focus on the calls.

    # 4. Replace .translate('key') or .translate("key") with "key" or 'key'
    # Usage: lp.translate('hello') -> 'hello'
    # Usage: languageProvider.translate("hello") -> "hello"
    content = re.sub(r"\w+\.translate\((['\"])(.*?)\1\)", r"\1\2\1", content)

    # 5. Replace .translate(variable) with variable
    # Usage: lp.translate(cityKey) -> cityKey
    content = re.sub(r"\w+\.translate\(([^'\"]+?)\)", r"\1", content)

    # 6. Replace `Provider.of<LanguageProvider>(context).translate(...)` type calls
    # Usage: Provider.of<LanguageProvider>(context).translate('key') -> 'key'
    content = re.sub(r"Provider\.of<LanguageProvider>\(.*?\)\.translate\((['\"])(.*?)\1\)", r"\1\2\1", content)
    
    # 7. Replace `Provider.of<LanguageProvider>(context).currentLanguage` with 'en'
    content = re.sub(r"Provider\.of<LanguageProvider>\(.*?\)\.currentLanguage", "'en'", content)

    # 8. Clean up "LanguageProvider lp" in method signatures
    # Widget foo(LanguageProvider lp) -> Widget foo()  (This might break call sites, careful. Maybe just Type dynamic?)
    # Safer: Widget foo(dynamic lp)
    content = re.sub(r"LanguageProvider\s+(\w+)", r"dynamic \1", content)

    # 9. Clean up Provider<LanguageProvider> in generics if any (e.g. Consumer<LanguageProvider>)
    # Consumer<LanguageProvider> -> Consumer<Object> (placeholder to avoid build error, though behavior changes)
    content = re.sub(r"Consumer<LanguageProvider>", "Consumer<Object>", content)

    # 10. Fix previously commented out lines from sed that might be lingering if we run this on top
    # The sed was: // final lp = ...
    # We want to remove those lines entirely if they are just clutter now, or leave them.
    # The main issue is usages.
    
    # 11. Type 'LanguageProvider' not found -> dynamic
    content = re.sub(r":\s*LanguageProvider", ": dynamic", content)


    if content != original_content:
        print(f"Fixing {filepath}")
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
