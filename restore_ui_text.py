import os

# Map of raw key -> English text
# We include quotes in the key to ensure we only replace string literals
replacements = {
    # Admin Dashboard
    "'route_management'": "'Route Management'",
    "'route_management_desc'": "'Manage your routes, trips, and bookings.'",
    "'add_new_trip'": "'Add New Trip'",
    "'add_route'": "'Add Route'",
    "'manage_routes'": "'Manage Routes'",
    "'bookings'": "'Bookings'",
    "'refunds'": "'Refunds'",
    "'analytics'": "'Analytics'",
    "'app_feedback'": "'App Feedback'",
    "'find_routes'": "'Find Routes'",
    "'select_date'": "'Select Date'",
    "'search_action'": "'Search'",
    "'no_routes_found'": "'No Routes Found'",
    "'adjust_filters'": "'Adjust filters to see results'",
    
    # Ticket Screen (some use double quotes in original)
    '"bulk_booking"': '"Bulk Booking"',
    '"route"': '"Route"',
    '"bundle"': '"Bundle"',
    '"e_ticket"': '"E-Ticket"',
    '"download_consolidated_pdf"': '"Download Consolidated PDF"',
    '"download_pdf"': '"Download PDF"',
    '"boarding_pass"': '"Boarding Pass"',
    '"confirmed"': '"Confirmed"',
    '"from"': '"FROM"',
    '"to"': '"TO"',
    '"travel_dates"': '"TRAVEL DATES"',
    '"time"': '"TIME"',
    '"seats"': '"SEATS"',
    '"show_qr_code"': '"Show QR Code"',
    '"track_bus_live"': '"Track Bus Live"',
    '"passenger"': '"PASSENGER"',
    '"total_price"': '"TOTAL PRICE"',
    '"saved_to_downloads"': '"Saved to Downloads"',
    '"permission_denied"': '"Permission Denied"',
    '"error_saving_pdf"': '"Error saving PDF"',

    # Admin Refund List
    "'status_pending'": "'Pending'",
    "'status_approved'": "'Approved'",
    "'status_rejected'": "'Rejected'",
    "'refund_management_title'": "'Refund Management'",
    "'no_refunds_status'": "'No refunds found'",
    "'no_refunds_search'": "'No refunds match your search'",

    # Admin Refund Details
    "'refund_details_title'": "'Refund Details'",
    "'refund_status_banner'": "'Refund Status:'",
    "'ref_prefix'": "'Ref'",
    "'booking_ref_copied'": "'Booking Reference Copied'",
    "'trip_price'": "'Trip Price'",
    "'cancellation_rule'": "'Cancellation Rule'",
    "'refund_amount_prefix'": "'Refund Amount'",
    "'reason_prefix'": "'Reason'",
    "'comment_label'": "'Comment'",
    "'reject_button'": "'Reject'",
    "'approve_refund_button'": "'Approve Refund'",
    "'reject_dialog_title'": "'Reject Refund'",
    "'reject_dialog_desc'": "'Are you sure you want to reject this refund?'",
    "'reason_policy'": "'Policy Violation'",
    "'reason_used'": "'Ticket Used'",
    "'reason_other'": "'Other'",
    "'select_reason_hint'": "'Select Reason'",
    "'cancel_button'": "'Cancel'",
    "'confirm_reject_button'": "'Confirm Reject'",
    "'refund_processed_success'": "'Refund Processed Successfully'",

    # Analytics
    "'analytics_hub'": "'Analytics Hub'",
    "'tab_revenue'": "'Revenue'",
    "'tab_late_departures'": "'Late Departures'",

    # My Trip Stats Widget
    "'stat_delayed'": "'Delayed'",
    "'stat_arrived'": "'Arrived'",
    "'stat_cancelled'": "'Cancelled'",
    '"upcoming"': '"Upcoming"', 
    '"stat_delayed"': '"Delayed"',
    '"stat_arrived"': '"Arrived"',
    '"stat_cancelled"': '"Cancelled"',

    # Admin Booking List
    "'booking_management_title'": "'Booking Management'", # Guessing key
    "'booking_details'": "'Booking Details'",

    # Common
    '"app_feedback"': '"App Feedback"', # Double quote variant
    "'unknown'": "'Unknown'",
    "\"unknown\"": "\"Unknown\"",

    # Mixed usage in logic
    "status == 'refund_requested'": "status == 'Refund Requested'", # Logic constant vs UI? Be careful.
    # Actually, status keys in logic (lowercase) should stay lowercase potentially? 
    # The user complained about UI text. "route_management" is clearly a UI key.
    # "refund_requested" is a value in _statusOptions. We should NOT replace values in logic unless they are display texts.
    # Best practice: Only replace strings that look like localization keys (snake_case) inside Text() or labels.
    # My dict above targets specific known keys. I will stick to exact matches.
}

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    
    for key, value in replacements.items():
        content = content.replace(key, value)
        
    # Also try replacing single quoted versions of double quote keys and vice versa
    # to catch inconsistencies
    for key, value in replacements.items():
        if key.startswith("'") and key.endswith("'"):
            # Try double quote
            dq_key = '"' + key[1:-1] + '"'
            dq_val = '"' + value[1:-1] + '"'
            content = content.replace(dq_key, dq_val)
        elif key.startswith('"') and key.endswith('"'):
             # Try single quote
            sq_key = "'" + key[1:-1] + "'"
            sq_val = "'" + value[1:-1] + "'"
            content = content.replace(sq_key, sq_val)

    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    target_files = [
        'lib/views/admin/admin_dashboard.dart',
        'lib/views/ticket/ticket_screen.dart',
        'lib/views/admin/refunds/admin_refund_list.dart',
        'lib/views/admin/refunds/admin_refund_details.dart',
        'lib/views/admin/bookings/booking_details_screen.dart',
        'lib/views/admin/analytics/admin_analytics_dashboard.dart',
        'lib/views/booking/my_trips_stats_widget.dart',
    ]

    # Walk lib views to catch others
    for root, _, files in os.walk('lib/views'):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                process_file(path)

if __name__ == "__main__":
    main()
