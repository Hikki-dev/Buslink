"""Fills the LOCAL Firebase emulators with test accounts and a little data.

  firebase emulators:start --only auth,firestore --project buslink-416e1
  python3 scripts/seed_emulator.py

Accounts (emulator only, they do not exist in the real project):
  customer@, admin@, conductor@ and newcomer@ test.local, password Test1234!
"""
import json, urllib.request, datetime as dt

PROJECT = 'buslink-416e1'
AUTH = f'http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=x'
DB = f'http://localhost:8080/v1/projects/{PROJECT}/databases/(default)/documents'
H = {'Content-Type': 'application/json', 'Authorization': 'Bearer owner'}


def call(url, body, method='POST'):
    r = urllib.request.Request(url, json.dumps(body).encode(), H, method=method)
    return json.load(urllib.request.urlopen(r))


def val(v):
    if isinstance(v, bool): return {'booleanValue': v}
    if isinstance(v, int): return {'integerValue': str(v)}
    if isinstance(v, float): return {'doubleValue': v}
    if isinstance(v, dt.datetime): return {'timestampValue': v.strftime('%Y-%m-%dT%H:%M:%SZ')}
    if isinstance(v, list): return {'arrayValue': {'values': [val(x) for x in v]}}
    if isinstance(v, dict): return {'mapValue': {'fields': {k: val(x) for k, x in v.items()}}}
    return {'stringValue': str(v)}


def put(col, doc_id, data):
    call(f'{DB}/{col}/{doc_id}', {'fields': {k: val(v) for k, v in data.items()}}, 'PATCH')


# start from an empty emulator so the script can be run again and again
for url in (f'http://localhost:8080/emulator/v1/projects/{PROJECT}/databases/(default)/documents',
            f'http://localhost:9099/emulator/v1/projects/{PROJECT}/accounts'):
    urllib.request.urlopen(urllib.request.Request(url, method='DELETE'))

uids = {}
for role in ['customer', 'admin', 'conductor']:
    email = f'{role}@test.local'
    uid = call(AUTH, {'email': email, 'password': 'Test1234!', 'returnSecureToken': True})['localId']
    uids[role] = uid
    put('users', uid, {'uid': uid, 'email': email, 'displayName': role.title() + ' Test', 'role': role})

put('routes', 'r1', {'originCity': 'Colombo', 'destinationCity': 'Kandy', 'via': '',
                     'stops': ['Colombo', 'Kadawatha', 'Kegalle', 'Kandy'], 'distanceKm': 115,
                     'estimatedDurationMins': 195, 'isActive': True})
put('schedules', 's1', {'routeId': 'r1', 'busNumber': 'NP-1234', 'operatorName': 'SuperLine Express',
                        'busType': 'Luxury AC', 'amenities': ['Air conditioning', 'WiFi'],
                        'recurrenceDays': [1, 2, 3, 4, 5, 6, 7], 'departureTime': '06:30',
                        'basePrice': 1200, 'totalSeats': 40, 'conductorId': uids['conductor'],
                        'platform': '4'})
now = dt.datetime.now(dt.timezone.utc).replace(tzinfo=None).replace(minute=0, second=0, microsecond=0)
for i in range(1, 6):
    d = now + dt.timedelta(days=i)
    put('trips', f't{i}', {'scheduleId': 's1', 'date': d, 'originCity': 'Colombo',
                           'destinationCity': 'Kandy', 'departureDateTime': d,
                           'arrivalDateTime': d + dt.timedelta(minutes=195), 'price': 1200,
                           'status': 'scheduled', 'totalSeats': 40, 'delayMinutes': 0,
                           'bookedSeats': ['5', '6'] if i == 1 else [], 'currentLocation': '',
                           'conductorId': uids['conductor'], 'via': '', 'platformNumber': '4'})
t1 = now + dt.timedelta(days=1)
put('tickets', 'tk1', {'ticketId': 'tk1', 'tripId': 't1', 'userId': uids['customer'],
                       'seatNumbers': [5, 6], 'userName': 'Customer Test',
                       'passengerPhone': '0771234567', 'passengerEmail': 'customer@test.local',
                       'bookingTime': now, 'totalAmount': 2400.0, 'status': 'confirmed',
                       'shortId': 'K7M2',
                       'tripData': {'originCity': 'Colombo', 'destinationCity': 'Kandy',
                                    'departureDateTime': t1, 'arrivalDateTime': t1 + dt.timedelta(minutes=195),
                                    'busNumber': 'NP-1234', 'operatorName': 'SuperLine Express',
                                    'platformNumber': '4', 'scheduleId': 's1'}})

def trip_data(d, dest='Kandy'):
    return {'originCity': 'Colombo', 'destinationCity': dest, 'departureDateTime': d,
            'arrivalDateTime': d + dt.timedelta(minutes=195), 'busNumber': 'NP-1234',
            'operatorName': 'SuperLine Express', 'platformNumber': '4', 'scheduleId': 's1'}


# a few more people, so the admin pages are not empty
people = [('Nimali Perera', '0712345678'), ('Kasun Silva', '0723456789'),
          ('Dilani Fernando', '0734567890'), ('Ruwan Jayasuriya', '0745678901')]
for i, (name, phone) in enumerate(people):
    email = name.split()[0].lower() + '@test.local'
    uid = call(AUTH, {'email': email, 'password': 'Test1234!', 'returnSecureToken': True})['localId']
    put('users', uid, {'uid': uid, 'email': email, 'displayName': name, 'role': 'customer'})
    d = now + dt.timedelta(days=2 + i % 3)
    put('tickets', f'tp{i}', {'ticketId': f'tp{i}', 'tripId': f't{2 + i % 3}', 'userId': uid,
                              'seatNumbers': [10 + i, 20 + i], 'userName': name, 'passengerPhone': phone,
                              'passengerEmail': email, 'bookingTime': now - dt.timedelta(days=1),
                              'totalAmount': 2400.0, 'status': 'confirmed', 'shortId': f'P{i}Q9',
                              'tripData': trip_data(d)})

past = now - dt.timedelta(days=9)
put('tickets', 'tk2', {'ticketId': 'tk2', 'tripId': 't0', 'userId': uids['customer'], 'seatNumbers': [12],
                       'userName': 'Customer Test', 'passengerPhone': '0771234567',
                       'passengerEmail': 'customer@test.local', 'bookingTime': past - dt.timedelta(days=2),
                       'totalAmount': 1200.0, 'status': 'completed', 'shortId': 'W4X8',
                       'tripData': trip_data(past)})
d3 = now + dt.timedelta(days=4)
put('tickets', 'tk3', {'ticketId': 'tk3', 'tripId': 't4', 'userId': uids['customer'], 'seatNumbers': [3],
                       'userName': 'Customer Test', 'passengerPhone': '0771234567',
                       'passengerEmail': 'customer@test.local', 'bookingTime': now - dt.timedelta(days=1),
                       'totalAmount': 1200.0, 'status': 'cancelled', 'shortId': 'Z3R5',
                       'tripData': trip_data(d3)})

put('refunds', 'rf1', {'bookingId': 'tk3', 'ticketId': 'tk3', 'tripId': 't4', 'paymentId': 'pay_test',
                       'paymentIntentId': 'pi_test', 'userId': uids['customer'],
                       'passengerName': 'Customer Test', 'passengerPhone': '0771234567',
                       'email': 'customer@test.local', 'requestedAt': now, 'createdAt': now, 'updatedAt': now,
                       'amountRequested': 1200.0, 'tripPrice': 1200.0, 'refundPercentage': 0.9,
                       'refundAmount': 1080.0, 'cancellationFee': 120.0, 'status': 'pending',
                       'reason': 'changeOfPlans', 'otherReasonText': ''})
put('refunds', 'rf2', {'bookingId': 'tp1', 'ticketId': 'tp1', 'tripId': 't3', 'paymentId': 'pay_test2',
                       'paymentIntentId': 'pi_test2', 'userId': uids['customer'],
                       'passengerName': 'Kasun Silva', 'passengerPhone': '0723456789',
                       'email': 'kasun@test.local', 'requestedAt': now - dt.timedelta(days=1),
                       'createdAt': now - dt.timedelta(days=1), 'updatedAt': now, 'amountRequested': 2400.0,
                       'tripPrice': 2400.0, 'refundPercentage': 1.0, 'refundAmount': 2400.0,
                       'cancellationFee': 0.0, 'status': 'approved', 'reason': 'tripDelay',
                       'otherReasonText': ''})

for i, (r, c) in enumerate([(5, 'Clean bus and the seat map made choosing easy.'),
                            (4, 'Ticket on my phone worked. Arrival time was a little late.'),
                            (5, 'Tracking told me exactly when to leave home.')]):
    put('feedback', f'fb{i}', {'userId': uids['customer'], 'userName': people[i][0],
                               'userEmail': 'customer@test.local', 'rating': r, 'comment': c,
                               'timestamp': now - dt.timedelta(days=i), 'platform': 'web'})

for i, (typ, title, body, read) in enumerate([
        ('tripStatus', 'Your bus is on time', 'Colombo to Kandy leaves at 10:30 PM from platform 4.', False),
        ('delay', 'Trip delayed 15 minutes', 'Colombo to Kandy will leave 15 minutes late.', False),
        ('cancellation', 'Refund approved', 'Your refund of LKR 1,080 is on its way.', True)]):
    put('notifications', f'n{i}', {'userId': uids['customer'], 'tripId': 't1', 'type': typ, 'title': title,
                                   'body': body, 'isRead': read,
                                   'timestamp': now - dt.timedelta(hours=3 * (i + 1))})

put(f"users/{uids['customer']}/favorite_routes", 'fav1', {'fromCity': 'Colombo', 'toCity': 'Kandy'})
put(f"users/{uids['customer']}/favorite_routes", 'fav2', {'fromCity': 'Colombo', 'toCity': 'Galle'})
# someone with nothing yet, for the empty screens
uid = call(AUTH, {'email': 'newcomer@test.local', 'password': 'Test1234!', 'returnSecureToken': True})['localId']
put('users', uid, {'uid': uid, 'email': 'newcomer@test.local', 'displayName': 'Newcomer Test', 'role': 'customer'})
print('seeded', list(uids))
