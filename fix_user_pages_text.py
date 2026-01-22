import os

# Map of raw key -> English text
replacements = {
    # HomeScreen Hero & Search
    '"good_morning"': '"Good Morning"',
    '"good_afternoon"': '"Good Afternoon"',
    '"good_evening"': '"Good Evening"',
    '"welcome"': '"Welcome"',
    '"brand_tagline"': '"Book your journey in seconds."',
    '"where_from"': '"Where from?"',
    '"where_to"': '"Where to?"',
    '"departure_date"': '"Departure Date"',
    '"search"': '"Search"',
    '"origin"': '"Origin"',
    '"destination"': '"Destination"',
    '"bulk_booking"': '"Bulk Booking"',
    
    # Live Journey Card
    "'journey_live'": "'Live Journey'",
    "'your_bus_is_here'": "'Your bus is here'",
    "'track_now'": "'TRACK NOW'",
}

def process_file(filepath):
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return

    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    for key, value in replacements.items():
        content = content.replace(key, value)
        
    # Also Check single quotes vs double quotes variations
    for key, value in replacements.items():
        if key.startswith('"') and key.endswith('"'):
            # Try single quote version
            sq_key = "'" + key[1:-1] + "'"
            sq_val = "'" + value[1:-1] + "'"
            content = content.replace(sq_key, sq_val)

    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    process_file('lib/views/home/home_screen.dart')

if __name__ == "__main__":
    main()
