const puppeteer = require('puppeteer-core');
const fs = require('fs');
const OUT = process.env.SHOTS_OUT || 'out';
const APP = process.env.APP_URL || 'http://localhost:5055';
exports.launch = async () => puppeteer.launch({
  executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  headless: 'new',
  args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-first-run'],
});
const sleep = ms => new Promise(r => setTimeout(r, ms));
exports.sleep = sleep;
// Open the app at a size; pretend the notification prompt was already answered.
exports.open = async (browser, w, h, dsf, mobile, semantics = true) => {
  const page = await browser.newPage();
  await page.setViewport({ width: w, height: h, deviceScaleFactor: dsf, isMobile: !!mobile, hasTouch: !!mobile });
  await page.evaluateOnNewDocument(() => {
    localStorage.setItem('flutter.notification_prompt_answer', '"allowed"');
  });
  await page.goto(APP, { waitUntil: 'networkidle2', timeout: 90000 });
  await sleep(6000);
  await page.addStyleTag({ content: '.firebase-emulator-warning{display:none!important} ' });
  if (semantics) await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await sleep(1500);
  return page;
};
// Labels of everything the accessibility tree exposes.
const leaf = `[...document.querySelectorAll('flt-semantics')].filter(e => !e.querySelector('flt-semantics'))`;
exports.labels = page => page.evaluate(`${leaf}.map(e => { const r = e.getBoundingClientRect(); return (e.getAttribute('aria-label') || e.textContent || '').trim().replace(/\\n/g,' ') + ' @' + Math.round(r.x) + ',' + Math.round(r.y); }).filter(s => !s.startsWith('@'))`);
// Press the nth element whose label contains `text` (a DOM click works where a mouse click does not).
// Press the nth element whose label matches `text` (exact match first, then "contains").
exports.tap = async (page, text, nth = 0) => {
  const pt = await page.evaluate((t, n) => {
    const all = [...document.querySelectorAll('flt-semantics')].filter(e => !e.querySelector('flt-semantics'));
    const lab = e => (e.getAttribute('aria-label') || e.textContent || '').trim().toLowerCase();
    let els = all.filter(e => lab(e) === t.toLowerCase() || lab(e).split('\n')[0] === t.toLowerCase());
    if (!els.length) els = all.filter(e => lab(e).includes(t.toLowerCase()));
    const e = els[n]; if (!e) return null;
    const r = e.getBoundingClientRect(); (e.closest('[flt-tappable]') || e).click();
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  }, text, nth);
  if (!pt) throw new Error('not found: ' + text);
  await sleep(1500);
};
exports.type = async (page, text) => { await page.keyboard.type(text, { delay: 10 }); await sleep(300); };
exports.shot = async (page, name) => {
  await sleep(1500);
  fs.mkdirSync(OUT, { recursive: true });
  await page.screenshot({ path: `${OUT}/${name}.png` });
  console.log('shot', name);
};
// Fill the nth text box on screen (Flutter exposes real inputs for them).
exports.fill = async (page, idx, text) => {
  const pt = await page.evaluate(i => {
    const e = [...document.querySelectorAll('flt-semantics input, flt-semantics textarea')][i];
    if (!e) return null; const r = e.getBoundingClientRect(); return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  }, idx);
  if (!pt) throw new Error('no input ' + idx);
  await page.mouse.click(pt.x, pt.y); await sleep(400);
  await page.keyboard.type(text, { delay: 10 }); await sleep(300);
};
exports.login = async (page, who) => {
  await exports.fill(page, 0, who + '@test.local');
  await exports.fill(page, 1, 'Test1234!');
  await exports.tap(page, 'Log In'); await sleep(5000);
};
// Click whatever accessibility node starts at about x,y (CSS pixels).
exports.tapAt = async (page, x, y) => {
  const ok = await page.evaluate((x, y) => {
    const e = [...document.querySelectorAll('flt-semantics')].filter(e => !e.querySelector('flt-semantics'))
      .find(e => { const r = e.getBoundingClientRect(); return Math.abs(r.x - x) < 4 && Math.abs(r.y - y) < 4; });
    if (!e) return false; e.click(); return true;
  }, x, y);
  if (!ok) throw new Error(`nothing at ${x},${y}`);
  await sleep(1500);
};
exports.dump = async (p, n) => console.log('--', n, '\n' + (await exports.labels(p)).filter(l=>!/^(BusLink|Home|My Trips|Favorites|Support|Select Language|Notifications|Account menu|Log Out) /.test(l)).join('\n'));
