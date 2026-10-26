const L = require('./lib');
const mode = process.argv[2] || 'desktop';         // desktop | phone
const only = process.argv[3];                       // optional: run one scene
const dims = mode === 'desktop' ? [1600, 1000, 2, false] : [390, 844, 3, true];
const pre = mode === 'desktop' ? 'd' : 'm';
const log = [];
const snap = async (p, name) => { await L.shot(p, `${pre}-${name}`); log.push('## ' + name + '\n' + (await L.labels(p)).join('\n')); };
const fs = require('fs');

const scenes = {
  async passenger(b) {
    const p = await L.open(b, ...dims);
    await snap(p, 'login');
    await L.login(p, 'customer');
    await snap(p, 'home');
    await L.tap(p, 'Favorites'); await L.sleep(1500); await snap(p, 'favourites');
    await L.tap(p, 'BOOK AGAIN'); await L.sleep(1500);
    await L.tap(p, 'Day of travel: '); await L.tap(p, '27, Tuesday'); await L.tap(p, 'OK');
    await L.tap(p, 'Search Buses'); await L.sleep(3000); await snap(p, 'results');
    await L.tap(p, 'Stops and what is on the bus'); await L.sleep(2500); await snap(p, 'bus-details');
    await L.tap(p, 'Choose seats'); await L.sleep(2500); await snap(p, 'seats');
    await L.tap(p, 'Seat 9, free'); await L.tap(p, 'Seat 10, free'); await snap(p, 'seats-chosen');
    await L.tap(p, 'Continue to payment'); await L.sleep(3000); await snap(p, 'payment');
    return p;
  },
};
scenes.account = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'customer');
  await L.tap(p, 'My Trips'); await snap(p, 'my-trips');
  await L.tap(p, 'VIEW TICKET'); await L.sleep(2500); await snap(p, 'ticket');
  await L.tap(p, 'Track bus'); await L.sleep(3500); await snap(p, 'tracking');
  await L.tap(p, 'Go back').catch(() => {}); await L.sleep(1500); await L.tap(p, 'Close').catch(() => {}); await L.sleep(1500);
  await L.tap(p, 'My Trips').catch(() => {}); await L.sleep(1500);
  await L.tap(p, 'Refund'); await L.sleep(2500); await snap(p, 'refund-request');
  await L.tap(p, 'Go back'); await L.sleep(1500);
  await L.tap(p, 'Your travel numbers'); await L.sleep(2500); await p.setViewport({ width: 1600, height: 1500, deviceScaleFactor: 2 }); await snap(p, 'travel-stats'); await p.setViewport({ width: 1600, height: 1000, deviceScaleFactor: 2 });
  await L.tap(p, 'Go back'); await L.sleep(1500); await L.tap(p, 'Home'); await L.sleep(1500);
  await L.tap(p, 'Notifications'); await L.sleep(2500); await snap(p, 'notifications');
  await L.tap(p, 'Go back'); await L.sleep(1500);
  await L.tap(p, 'Account menu'); await L.sleep(1500); await snap(p, 'account-menu');
};
scenes.profile = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'customer');
  await L.tap(p, 'Account menu'); await L.tap(p, 'Profile'); await L.sleep(2500);
  await p.setViewport({ width: 1600, height: 1400, deviceScaleFactor: 2 }); await snap(p, 'profile'); await p.setViewport({ width: 1600, height: 1000, deviceScaleFactor: 2 });
  await L.tap(p, 'Go back'); await L.sleep(1500);
  await L.tap(p, 'Account menu'); await L.tap(p, 'Settings'); await L.sleep(2500); await snap(p, 'settings');
  await L.tap(p, 'Go back'); await L.sleep(1500);
  await L.tap(p, 'Support'); await L.sleep(2500); await snap(p, 'support');
};
scenes.admin = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'admin');
  if (mode === 'desktop') await p.setViewport({ width: 1600, height: 1100, deviceScaleFactor: 2 });
  await snap(p, 'admin-dashboard');
  for (const [lab, name] of [['Routes', 'admin-routes'], ['Bookings', 'admin-bookings'], ['Refunds', 'admin-refunds'], ['Feedback', 'admin-feedback'], ['Analytics', 'admin-analytics'], ['Users and roles', 'admin-users']]) {
    await L.tap(p, lab); await L.sleep(3000); await snap(p, name);
  }
  await L.tap(p, 'Trips'); await L.sleep(2500); await L.tap(p, 'Add new trip'); await L.sleep(2500); await snap(p, 'admin-trip-form');
};
scenes.adminPhone = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'admin');
  await snap(p, 'admin-dashboard');
  for (const [lab, name] of [['Manage Routes', 'admin-routes'], ['Bookings', 'admin-bookings'], ['Refunds', 'admin-refunds'], ['Analytics', 'admin-analytics'], ['App Feedback', 'admin-feedback'], ['Add New Trip', 'admin-trip-form']]) {
    await L.tap(p, lab); await L.sleep(3000); await snap(p, name);
    await L.tap(p, 'Go back').catch(() => L.tap(p, 'Admin', 0)); await L.sleep(2000);
  }
  await L.tap(p, 'Roles'); await L.sleep(2500); await snap(p, 'admin-users');
};
scenes.conductor = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'conductor'); await L.sleep(2000);
  await L.tap(p, 'Decline'); await L.sleep(2500);
  await snap(p, 'conductor-home');
  await L.fill(p, 0, 'K7M2'); await L.tap(p, 'Verify'); await L.sleep(3000); await snap(p, 'conductor-verified');
  await L.tap(p, 'Approve Boarding'); await L.sleep(3000); await snap(p, 'conductor-boarded');
  await L.tap(p, 'Search Trips').catch(async () => { await L.tap(p, 'Close').catch(() => {}); await L.sleep(1500); await L.tap(p, 'Search Trips'); });
  await L.sleep(2500); await snap(p, 'conductor-find');
  await L.tap(p, 'Origin'); await L.sleep(1200); await snap(p, 'conductor-origin'); await L.tap(p, 'Colombo'); await L.sleep(1000); await L.tap(p, 'Destination'); await L.sleep(1200); await L.tap(p, 'Kandy'); await L.sleep(1000); await L.tap(p, '2026-10-25'); await L.sleep(1500); await L.tap(p, '27, Tuesday'); await L.tap(p, 'OK'); await L.sleep(1000); await L.tap(p, 'Search', 0); await L.sleep(3500); await snap(p, 'conductor-trips');
  await L.tap(p, 'Colombo -> Kandy'); await L.sleep(3500); await L.tap(p, 'Decline'); await L.sleep(2500); await snap(p, 'conductor-manage');
};
// Admin and conductor screens in dark mode: run with THEME=dark so the app starts with the dark choice saved.
scenes.darkAdmin = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'admin');
  if (mode === 'desktop') await p.setViewport({ width: 1600, height: 1100, deviceScaleFactor: 2 });
  await snap(p, 'dark-admin-dashboard');
  const pages = mode === 'desktop'
    ? [['Routes', 'routes'], ['Bookings', 'bookings'], ['Refunds', 'refunds'], ['Feedback', 'feedback'], ['Analytics', 'analytics'], ['Users and roles', 'users']]
    : [['Manage Routes', 'routes'], ['Bookings', 'bookings'], ['Refunds', 'refunds'], ['Analytics', 'analytics'], ['App Feedback', 'feedback'], ['Add New Trip', 'trip-form']];
  for (const [lab, name] of pages) {
    await L.tap(p, lab); await L.sleep(3000); await snap(p, 'dark-admin-' + name);
    if (mode === 'phone') { await L.tap(p, 'Go back').catch(() => L.tap(p, 'Admin', 0)); await L.sleep(2000); }
  }
  if (mode === 'desktop') { await L.tap(p, 'Trips'); await L.sleep(2500); await L.tap(p, 'Add new trip'); await L.sleep(2500); await snap(p, 'dark-admin-trip-form'); }
};
scenes.darkConductor = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'conductor'); await L.sleep(2000);
  await L.tap(p, 'Decline').catch(() => {}); await L.sleep(2500);
  await snap(p, 'dark-conductor-home');
  await L.fill(p, 0, 'K7M2'); await L.tap(p, 'Verify'); await L.sleep(3000); await snap(p, 'dark-conductor-verified');
  await L.tap(p, 'Approve Boarding'); await L.sleep(3000); await snap(p, 'dark-conductor-boarded');
  await L.tap(p, 'Search Trips').catch(async () => { await L.tap(p, 'Close').catch(() => {}); await L.sleep(1500); await L.tap(p, 'Search Trips'); });
  await L.sleep(2500); await snap(p, 'dark-conductor-find');
};
scenes.phoneAccount = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'customer');
  await L.tap(p, 'My Trips'); await L.sleep(1500); await snap(p, 'my-trips');
  await L.tap(p, 'VIEW TICKET'); await L.sleep(2500); await snap(p, 'ticket');
  await L.tap(p, 'Track bus'); await L.sleep(3500); await snap(p, 'tracking');
  await L.tap(p, 'Go back').catch(() => {}); await L.sleep(1500); await L.tap(p, 'Close').catch(() => {}); await L.sleep(1500);
  await L.tap(p, 'My Trips').catch(() => {}); await L.sleep(1500);
  await L.tap(p, 'Refund'); await L.sleep(2500); await snap(p, 'refund-request');
  await L.tap(p, 'Go back'); await L.sleep(1500);
  await L.tap(p, 'Your travel numbers'); await L.sleep(2500); await p.setViewport({ width: 390, height: 1300, deviceScaleFactor: 3, isMobile: true, hasTouch: true }); await snap(p, 'travel-stats'); await p.setViewport({ width: 390, height: 844, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
  await L.tap(p, 'Go back'); await L.sleep(1500); await L.tap(p, 'Home'); await L.sleep(1500);
  await L.tap(p, 'Notifications'); await L.sleep(2500); await snap(p, 'notifications');
  await L.tap(p, 'Go back'); await L.sleep(1500);
  await L.tap(p, 'Profile'); await L.sleep(2500); await snap(p, 'profile');
  await L.tap(p, 'Account Settings'); await L.sleep(2500); await snap(p, 'settings');
};
scenes.extras = async b => {
  const p = await L.open(b, ...dims);
  await L.tap(p, 'Forgot Password?'); await L.sleep(2000); await snap(p, 'forgot');
  await L.tap(p, 'Go back').catch(() => {}); await L.sleep(1500);
  await L.tap(p, 'Log in with phone number'); await L.sleep(2000); await snap(p, 'phone-login');
  await L.tap(p, 'Go back').catch(() => {}); await L.sleep(1500);
  await L.tap(p, 'Sign Up'); await L.sleep(2000); await snap(p, 'signup');
};
scenes.phoneProfile = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'customer');
  await L.tap(p, 'Profile'); await L.sleep(2000);
  await L.tap(p, 'Support & FAQs'); await L.sleep(2500); await p.setViewport({ width: 390, height: 1400, deviceScaleFactor: 3, isMobile: true, hasTouch: true }); await snap(p, 'support'); await p.setViewport({ width: 390, height: 844, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
  await L.tap(p, 'Go back'); await L.sleep(1500);
  await L.tap(p, 'Notification Settings'); await L.sleep(2500); await snap(p, 'notification-settings');
  await L.tap(p, 'Go back'); await L.sleep(1500);
  await L.tap(p, 'Send Feedback'); await L.sleep(2000); await snap(p, 'feedback');
};
scenes.otp = async b => {
  const p = await L.open(b, ...dims);
  await L.tap(p, 'Log in with phone number'); await L.sleep(2000);
  await L.fill(p, 0, '771234567');
  await L.tap(p, 'Send Code'); await L.sleep(5000); await snap(p, 'otp');
  // the pretend Firebase lists the code it "texted"
  const list = await (await fetch('http://localhost:9099/emulator/v1/projects/buslink-416e1/verificationCodes')).json();
  const code = list.verificationCodes[list.verificationCodes.length - 1].code;
  await L.fill(p, 0, code); await L.sleep(2500); await snap(p, 'otp-filled');
};
scenes.boardTwice = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'conductor'); await L.sleep(2000);
  await L.tap(p, 'Decline').catch(() => {}); await L.sleep(2000);
  await L.fill(p, 0, 'K7M2'); await L.tap(p, 'Verify'); await L.sleep(3000);
  await L.tap(p, 'Approve Boarding'); await L.sleep(3000); await snap(p, 'board-approved');
  await L.fill(p, 0, 'K7M2'); await L.tap(p, 'Verify'); await L.sleep(3000); await snap(p, 'board-again');
};
scenes.refundSubmit = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'customer');
  await L.tap(p, 'My Trips'); await L.sleep(2000);
  await L.tap(p, 'Refund'); await L.sleep(2500);
  await L.tap(p, 'Choose a reason'); await L.sleep(1200); await snap(p, 'refund-reasons');
};
// Every main screen with dark mode switched on (a theme check, not for the docs).
scenes.dark = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'customer');
  if (mode === 'desktop') { await L.tap(p, 'Account menu'); await L.tap(p, 'Dark mode'); await L.sleep(1500); await L.tap(p, 'Dismiss menu').catch(() => {}); }
  else { await L.tap(p, 'Profile'); await L.sleep(1500); await L.tap(p, 'Dark Mode'); await L.sleep(1500); await L.tap(p, 'Home'); }
  await L.sleep(1500); await snap(p, 'dark-home');
  await L.tap(p, 'Favorites'); await L.sleep(1500); await snap(p, 'dark-favourites');
  await L.tap(p, 'BOOK AGAIN'); await L.sleep(1500);
  await L.tap(p, 'Day of travel: '); await L.tap(p, '27, Tuesday'); await L.tap(p, 'OK');
  await L.tap(p, 'Search Buses'); await L.sleep(3000); await snap(p, 'dark-results');
  await L.tap(p, 'Stops and what is on the bus'); await L.sleep(2500); await snap(p, 'dark-bus-details');
  await L.tap(p, 'Choose seats'); await L.sleep(2500); await L.tap(p, 'Seat 9, free'); await snap(p, 'dark-seats');
  await L.tap(p, 'Continue to payment'); await L.sleep(3000); await snap(p, 'dark-payment');
};
scenes.dark2 = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'customer');
  if (mode === 'desktop') { await L.tap(p, 'Account menu'); await L.tap(p, 'Dark mode'); await L.sleep(1500); await L.tap(p, 'Dismiss menu').catch(() => {}); }
  else { await L.tap(p, 'Profile'); await L.sleep(1500); await L.tap(p, 'Dark Mode'); await L.sleep(1500); }
  await L.tap(p, 'My Trips'); await L.sleep(2000); await snap(p, 'dark-my-trips');
  await L.tap(p, 'VIEW TICKET'); await L.sleep(2500); await snap(p, 'dark-ticket');
  await L.tap(p, 'Close').catch(() => {}); await L.sleep(1500);
  if (mode === 'desktop') { await L.tap(p, 'Support'); await L.sleep(2500); await snap(p, 'dark-support'); await L.tap(p, 'Account menu'); await L.tap(p, 'Profile'); await L.sleep(2500); await snap(p, 'dark-profile'); }
  else { await L.tap(p, 'Profile'); await L.sleep(2000); await snap(p, 'dark-profile'); await L.tap(p, 'Support & FAQs'); await L.sleep(2500); await snap(p, 'dark-support'); }
};
scenes.noBuses = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'customer');
  await L.tap(p, 'Favorites'); await L.tap(p, 'BOOK AGAIN'); await L.sleep(1500);
  await L.tap(p, 'Search Buses'); await L.sleep(3500); await snap(p, 'nobuses-today');
  await L.tap(p, 'buses').catch(() => {}); await L.sleep(3500); await snap(p, 'nobuses-then-day');
};
scenes.empty = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'newcomer');
  await L.tap(p, 'My Trips'); await L.sleep(2000); await snap(p, 'empty-trips');
  await L.tap(p, 'Favorites'); await L.sleep(2000); await snap(p, 'empty-favourites');
  await L.tap(p, 'Notifications').catch(() => {}); await L.sleep(2000); await snap(p, 'empty-notifications');
};
scenes.bulk = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'customer');
  await L.tap(p, 'Favorites'); await L.tap(p, 'BOOK AGAIN'); await L.sleep(1500);
  await L.tap(p, 'Bulk booking'); await L.sleep(800); await snap(p, 'bulk-search');
  await L.tap(p, 'days chosen'); await L.sleep(1500);
  for (const d of ['25, Sunday', '27, Tuesday', '28, Wednesday', '29, Thursday']) await L.tap(p, d);
  await snap(p, 'bulk-dates'); await L.tap(p, 'OK'); await L.sleep(1200); await snap(p, 'bulk-chosen');
  await L.tap(p, 'Search Buses'); await L.sleep(3000); await snap(p, 'bulk-results');
  await L.tap(p, 'Book Now'); await L.sleep(2500); await snap(p, 'bulk-passengers');
  await L.tap(p, 'One more passenger'); await L.sleep(800); await snap(p, 'bulk-passengers-2');
  await L.tap(p, 'Proceed to Payment'); await L.sleep(3500); await snap(p, 'bulk-payment');
};
scenes.adminPhoneMore = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'admin');
  await L.tap(p, 'Bookings'); await L.sleep(3000);
  await L.tap(p, 'Colombo').catch(() => {}); await L.sleep(2500); await snap(p, 'admin-booking-details');
};
scenes.confirmed = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'customer');
  await L.gotoRoute(p, '/payment_success?booking_id=tpend&payment_intent=pi_test'); await L.sleep(3000);
  if (mode === 'phone') await p.setViewport({ width: 390, height: 1050, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
  await snap(p, 'confirmed');
};
scenes.adminMore = async b => {
  const p = await L.open(b, ...dims);
  await L.login(p, 'admin');
  if (mode === 'desktop') await p.setViewport({ width: 1600, height: 1100, deviceScaleFactor: 2 });
  await L.tap(p, 'Refunds'); await L.sleep(3000);
  await L.tap(p, 'Review'); await L.sleep(3000); await snap(p, 'admin-refund-details');
  await L.tap(p, 'Go back').catch(() => {}); await L.sleep(1500);
  await L.tap(p, 'Bookings'); await L.sleep(3000);
  await snap(p, 'admin-bookings-list');
  await L.tap(p, 'Colombo').catch(() => {}); await L.sleep(2500); await snap(p, 'admin-booking-details');
  await L.tap(p, 'Go back').catch(() => {}); await L.sleep(1500);
  await L.tap(p, 'Analytics'); await L.sleep(3000);
  await L.tap(p, 'Late Departures'); await L.sleep(3000); await snap(p, 'admin-late');
};
(async () => {
  const b = await L.launch();
  try {
    for (const [name, fn] of Object.entries(scenes)) if (!only || only === name) { await fn(b); }
  } catch (e) { console.error('STOPPED:', e.message); }
  fs.writeFileSync(`labels-${pre}.txt`, log.join('\n\n'));
  await b.close();
})();
