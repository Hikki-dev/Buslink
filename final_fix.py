import os

def fix_bus_list(content):
    # Fix broken Text widgets where style is orphaned
    # Pattern: Text(string), style: ... -> Text(string, style: ...)
    # Search for: .replaceAll(' ', '_')),
    #             style: const TextStyle(
    # Replace with: .replaceAll(' ', '_'),
    #               style: const TextStyle(
    
    content = content.replace(".replaceAll(' ', '_')),\n                style: const TextStyle(", ".replaceAll(' ', '_'),\n                style: const TextStyle(")
    
    # Also fix line 668: child: Text -> Container(child: Text...) or just Text
    # The context is inside a Column children list.
    # The original code likely had a Container that was commented out, leaving 'child: Text' exposed?
    # Let's just wrap it in a Container to be safe, or remove 'child:'
    # "child: Text" is definitely wrong in a list.
    # If we remove 'child: ', we get Text("Bus", ...) which is valid in a Column.
    content = content.replace("child: Text(\"Bus\",", "Text(\"Bus\",")

    return content

def fix_conductor(content):
    # Fix trip: t.trip -> trip: t
    content = content.replace("ConductorTripManagementScreen(trip: t.trip)", "ConductorTripManagementScreen(trip: t)")
    # Also remove unused import provider
    content = content.replace("import 'package:provider/provider.dart';", "")
    return content

def remove_provider_import(content):
    return content.replace("import 'package:provider/provider.dart';", "")

def main():
    # Bus List
    path_bus = 'lib/views/results/bus_list_screen.dart'
    if os.path.exists(path_bus):
        with open(path_bus, 'r') as f: s = f.read()
        s = fix_bus_list(s)
        with open(path_bus, 'w') as f: f.write(s)
        print("Fixed bus_list_screen.dart")

    # Conductor
    path_cond = 'lib/views/conductor/conductor_dashboard.dart'
    if os.path.exists(path_cond):
        with open(path_cond, 'r') as f: s = f.read()
        s = fix_conductor(s)
        with open(path_cond, 'w') as f: f.write(s)
        print("Fixed conductor_dashboard.dart")

    # Unused imports
    paths = [
        'lib/views/layout/app_footer.dart',
        'lib/views/layout/mobile_navbar.dart',
        'lib/utils/location_permission_helper.dart',
        'lib/views/admin/analytics/admin_analytics_dashboard.dart',
        'lib/views/admin/analytics/revenue_analytics_screen.dart',
        'lib/views/admin/bookings/admin_booking_list.dart',
        'lib/views/admin/bookings/booking_details_screen.dart',
        'lib/views/admin/refunds/admin_refund_details.dart',
        'lib/views/admin/refunds/admin_refund_list.dart',
        'lib/views/booking/my_trips_stats_widget.dart',
        'lib/views/tracking/track_bus_screen.dart'
    ]
    
    for p in paths:
        if os.path.exists(p):
            with open(p, 'r') as f: s = f.read()
            original_len = len(s)
            s = remove_provider_import(s)
            if len(s) != original_len:
                with open(p, 'w') as f: f.write(s)
                print(f"Cleaned {p}")

if __name__ == "__main__":
    main()
