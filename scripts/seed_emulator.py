"""Fills the LOCAL Firebase emulators with test accounts and a little data.

  firebase emulators:start --only auth,firestore --project buslink-416e1
  python3 scripts/seed_emulator.py

Accounts (emulator only, they do not exist in the real project):
  customer@test.local / admin@test.local / conductor@test.local, password Test1234!
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
now = dt.datetime.utcnow().replace(minute=0, second=0, microsecond=0)
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
                       'shortId': 'BL1234',
                       'tripData': {'originCity': 'Colombo', 'destinationCity': 'Kandy',
                                    'departureDateTime': t1, 'arrivalDateTime': t1 + dt.timedelta(minutes=195),
                                    'busNumber': 'NP-1234', 'operatorName': 'SuperLine Express',
                                    'platformNumber': '4', 'scheduleId': 's1'}})
print('seeded', list(uids))
