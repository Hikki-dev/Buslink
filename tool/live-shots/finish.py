"""Turns the raw captures into the files the docs use: sharp, but small enough to keep in git."""
import sys, os, glob
from PIL import Image
SRC = os.environ.get('SHOTS_OUT', 'out')
DST = sys.argv[1]            # e.g. ../../docs/images
ONLY = sys.argv[2:]          # optional: only names that contain one of these words
names = {
 # desktop
 'd-login': 'passenger-1-sign-in', 'd-signup': 'passenger-1-sign-up', 'd-phone-login': 'passenger-1-phone',
 'd-home': 'passenger-2-search', 'd-favourites': 'passenger-3-favourites', 'd-results': 'passenger-4-results',
 'd-bus-details': 'passenger-5-bus-details', 'd-seats': 'passenger-6-seats', 'd-seats-chosen': 'passenger-6-seats-chosen',
 'd-payment': 'passenger-7-payment', 'd-ticket': 'passenger-8-ticket', 'd-tracking': 'passenger-9-tracking',
 'd-my-trips': 'passenger-10-my-trips', 'd-refund-request': 'passenger-11-refund', 'd-travel-stats': 'passenger-12-travel-numbers',
 'd-notifications': 'passenger-13-notifications', 'd-account-menu': 'passenger-14-account-menu', 'd-profile': 'passenger-14-profile',
 'd-settings': 'passenger-14-settings', 'd-support': 'passenger-15-support',
 'd-conductor-home': 'conductor-1-home', 'd-conductor-verified': 'conductor-2-verified', 'd-conductor-boarded': 'conductor-3-boarded',
 'd-conductor-find': 'conductor-4-find-trips', 'd-conductor-date': 'conductor-4-pick-date', 'd-conductor-trips': 'conductor-4-results',
 'd-admin-dashboard': 'admin-1-trips', 'd-admin-trip-form': 'admin-2-trip-form', 'd-admin-routes': 'admin-3-routes',
 'd-admin-bookings': 'admin-4-bookings', 'd-admin-refunds': 'admin-5-refunds', 'd-admin-feedback': 'admin-6-feedback',
 'd-admin-analytics': 'admin-7-analytics', 'd-admin-users': 'admin-8-users',
 'd-admin-refund-details': 'admin-5-refund-details', 'd-admin-late': 'admin-7-late',
 'd-empty-trips': 'empty-trips', 'd-empty-favourites': 'empty-favourites', 'd-empty-notifications': 'empty-notifications',
 'd-bulk-search': 'bulk-1-search', 'd-bulk-dates': 'bulk-2-dates', 'd-bulk-passengers-2': 'bulk-3-passengers', 'd-bulk-payment': 'bulk-4-summary',
 'd-admin-booking-details': 'admin-4-booking-details', 'd-confirmed': 'passenger-8-confirmed',
 'd-otp': 'passenger-1-code', 'd-otp-filled': 'passenger-1-code-filled', 'd-conductor-manage': 'conductor-5-update-status',
 'd-board-again': 'conductor-3-already-boarded', 'd-refund-reasons': 'passenger-11-refund-reasons',
 'd-notification-settings': 'passenger-14-notification-settings', 'd-feedback': 'passenger-14-feedback',
}
tot = 0
manifest = []
for k, v in names.items():
    if ONLY and not any(w in v for w in ONLY): continue
    for pre, suf in (('d-', ''), ('m-', '-phone')):
        src = f'{SRC}/{pre}{k[2:]}.png'
        if not os.path.exists(src): continue
        im = Image.open(src).convert('RGB')
        out = f'{DST}/{v}{suf}.png'
        im.save(out, optimize=True)
        if os.path.getsize(out) > 1300 * 1024:      # photo-heavy screen: a very high quality JPEG is far smaller
            os.remove(out); out = out[:-4] + '.jpg'
            im.save(out, quality=93, optimize=True, subsampling=0)
        tot += os.path.getsize(out); manifest.append(os.path.basename(out))
        print(f'{os.path.getsize(out)//1024:5d} KB {os.path.basename(out)} {im.size}')
print('total', tot // 1024 // 1024, 'MB')

open(os.path.join(SRC, 'manifest.txt'), 'w').write('\n'.join(manifest))
