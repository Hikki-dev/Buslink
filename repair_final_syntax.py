import os
import re

def fix_admin_analytics(content):
    # Fix Tab( // text: 'tab_revenue'),
    content = re.sub(r"Tab\(\s*//\s*text:\s*(['\"].*?['\"])\),", r"Tab(text: \1),", content)
    return content

def fix_booking_details(content):
    # Fix Text( // Provider... .translate(label...) -> Text(label...
    # Pattern: Text(\n // Provider... \n .translate(label.toLowerCase().replaceAll(' ', '_')),
    # We want: Text(label.toLowerCase().replaceAll(' ', '_'),
    
    # Regex to capture the label expression
    # Matches: .translate( (label... ) )
    content = re.sub(
        r"//\s*Provider\.of<LanguageProvider>.*?\.translate\((.*?)\),",
        r"\1,",
        content,
        flags=re.DOTALL
    )
    return content

def fix_refund_details(content):
    # 1. Fix AppBar( // title: Text(...)),
    # Matches: appBar: AppBar( \n // title: Text(...)
    # We need to ensure the closing paren '),' which was inside the comment is restored.
    # Actually, if the line is `// title: Text('...')),` then the `),` is commented out.
    # So we simply uncomment the whole line.
    content = re.sub(r"appBar: AppBar\(\s*//\s*(title: Text\(.*?\)\),)", r"appBar: AppBar(\1", content, flags=re.DOTALL)
    
    # 2. Fix // content: Text(...)
    content = re.sub(r"//\s*(content: Text\(.*?\),?)", r"\1", content)
    
    # 3. Fix _row( // 'key',
    content = re.sub(r"_row\(\s*//\s*(['\"].*?['\"],?)", r"_row(\1", content)
    
    return content

def fix_refund_list(content):
    # Fix _buildFilterItem...(..., // 'key')
    content = re.sub(r"//\s*(['\"]status_.*?['\"]\)),", r"\1,", content)
    # Also handle if paren is on next line?
    # Pattern: // 'string')
    content = re.sub(r"//\s*(['\"].*?['\"]\))", r"\1", content)
    
    # Fix Text('no_refunds_status') if it was commented?
    # View showed: child: Text('no_refunds_status')); which looks valid if child: isn't commented.
    # But let's check for // child: Text
    content = re.sub(r"//\s*(child:\s*Text\(.*?\))", r"\1", content)
    
    return content

def fix_stats_widget(content):
    # Fix _buildBox(..., // 'key',
    content = re.sub(r"//\s*(['\"]stat_.*?['\"],?)", r"\1", content)
    return content

def fix_simulated_conductor(content):
    # Fix ConductorTripManagementScreen( tripId: t.tripId) -> trip: t.trip
    # The error said 'trip' is required. And 'EnrichedTrip' t has no tripId.
    # t.trip gives the Trip object.
    content = re.sub(r"ConductorTripManagementScreen\(\s*tripId:\s*t\.tripId\)", r"ConductorTripManagementScreen(trip: t.trip)", content)
    return content

def fix_bus_list(content):
    # Fix ${controller.fromCity?.toLowerCase().replaceAll...}
    # Replace .fromCity?.toLowerCase() with (.fromCity ?? '').toLowerCase()
    
    # Pattern: controller.fromCity?.toLowerCase()
    content = content.replace("controller.fromCity?.toLowerCase()", "(controller.fromCity ?? '').toLowerCase()")
    content = content.replace("controller.toCity?.toLowerCase()", "(controller.toCity ?? '').toLowerCase()")
    
    # Also fix explicit `?? "")}` parenthesis mess explicitly
    # View: ?? "")}
    # We want to remove the `?? "")` if we already handle null via (.. ?? '')
    # But let's just make the regex specific for the bad line
    
    # Target: ${controller.fromCity?.toLowerCase().replaceAll(' ', '_') ?? "")}
    # Replace with: ${(controller.fromCity ?? '').toLowerCase().replaceAll(' ', '_')}
    
    # Be careful with the closing brace/paren complexity.
    # Simplest manual replacement for the specific known string:
    bad_str = "controller.fromCity?.toLowerCase().replaceAll(' ', '_') ?? \"\")}"
    good_str = "(controller.fromCity ?? '').toLowerCase().replaceAll(' ', '_')}"
    content = content.replace(bad_str, good_str)
    
    bad_str2 = "controller.toCity?.toLowerCase().replaceAll(' ', '_') ?? \"\")}"
    good_str2 = "(controller.toCity ?? '').toLowerCase().replaceAll(' ', '_')}"
    content = content.replace(bad_str2, good_str2)

    return content

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    fname = os.path.basename(filepath)
    
    if fname == 'admin_analytics_dashboard.dart':
        content = fix_admin_analytics(content)
    elif fname == 'booking_details_screen.dart':
        content = fix_booking_details(content)
    elif fname == 'admin_refund_details.dart':
        content = fix_refund_details(content)
    elif fname == 'admin_refund_list.dart':
        content = fix_refund_list(content)
    elif fname == 'my_trips_stats_widget.dart':
        content = fix_stats_widget(content)
    elif fname == 'conductor_dashboard.dart':
        content = fix_simulated_conductor(content)
    elif fname == 'bus_list_screen.dart':
        content = fix_bus_list(content)

    if content != original:
        print(f"Fixed {fname}")
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

def main():
    root_dir = 'lib'
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith(".dart"):
                process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
