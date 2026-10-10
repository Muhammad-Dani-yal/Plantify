// Smoke check preserving account data and removing its temporary UI dump.
const {execFile} = require('node:child_process');
const {promisify} = require('node:util');
const fs = require('node:fs');
const path = require('node:path');
const run = promisify(execFile);
const sdk = process.env.ANDROID_HOME || path.join(process.env.LOCALAPPDATA, 'Android/Sdk');
const adb = path.join(sdk, 'platform-tools', process.platform === 'win32' ? 'adb.exe' : 'adb');
async function command(args, options = {}) {
  return run(adb, args, {encoding: 'utf8', maxBuffer: 10 * 1024 * 1024,
    timeout: 45000, ...options});
}
async function main() {
  const {stdout: pid} = await command(['shell', 'pidof', 'com.muhammaddaniyal.plantify']);
  if (!pid.trim()) throw new Error('Plantify is not running.');
  const {stdout: logs} = await command(['logcat', '-d', `--pid=${pid.trim()}`]);
  if (/FATAL EXCEPTION|Unhandled Exception|MissingPluginException/.test(logs)) {
    throw new Error('Android runtime reported an app exception.');
  }
  const dump = '/sdcard/plantify-startup-check.xml';
  let hierarchy;
  try {
    await command(['shell', 'uiautomator', 'dump', dump]);
    hierarchy = (await command(['shell', 'cat', dump])).stdout;
  } finally {
    await command(['shell', 'rm', '-f', dump]);
  }
  if (!hierarchy.includes('package="com.muhammaddaniyal.plantify"') ||
      !/Discover|Get started|Sign in|Find your/.test(hierarchy)) {
    throw new Error('Expected Plantify screen is not visible; check whether the phone is locked.');
  }
  const {stdout: screenshot} = await command(['exec-out', 'screencap', '-p'], {encoding: 'buffer'});
  fs.mkdirSync('build/qa', {recursive: true});
  fs.writeFileSync('build/qa/android-release.png', screenshot);
  console.log('PASS: optimized Android app is running, renders its screen, and reports no Flutter/plugin/runtime exceptions.');
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
