// Builds web/social-card.png - the picture that shows when somebody
// pastes a link to this site into Facebook, WhatsApp, iMessage or Slack.
//
// A checked-in binary with no way to regenerate it is a file nobody dares
// touch, so the card is written here as HTML and rendered by the headless
// Chromium the project already uses for its browser checks. No new
// dependency, and changing the wording is editing a string rather than
// opening an image editor.
//
//   node web/tools/build_social_card.mjs
//
// Re-run and commit the PNG whenever the copy or the palette changes.
// `test/features/social_preview_test.dart` checks that index.html's
// og:image tags and this file still agree on the size.

import { chromium } from 'playwright';
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

// 1200x630 is what every major crawler crops to. Rendered at 2x and
// downscaled by the encoder would be sharper, but these are the exact
// dimensions the og:image:width/height tags promise, and a mismatch makes
// some clients skip the image entirely.
const WIDTH = 1200;
const HEIGHT = 630;

// Straight from lib/core/config/church_settings.dart - BrandColors.fallback,
// which is also the Harbour theme and what a brand-new church opens on.
const NAVY = '#1B3A4B';
const GOLD = '#C9A24B';
const CREAM = '#F7F5F0';

/// The bundled fonts, inlined so the card never depends on a CDN - the
/// same reason the app ships them rather than linking Google Fonts.
const font = (file) =>
  readFileSync(join(root, 'assets', 'fonts', file)).toString('base64');

const html = `<!doctype html>
<html><head><meta charset="utf-8"><style>
  @font-face { font-family: Lora; font-weight: 700;
    src: url(data:font/ttf;base64,${font('Lora-Bold.ttf')}) format('truetype'); }
  @font-face { font-family: WorkSans; font-weight: 400;
    src: url(data:font/ttf;base64,${font('WorkSans-Regular.ttf')}) format('truetype'); }
  @font-face { font-family: WorkSans; font-weight: 700;
    src: url(data:font/ttf;base64,${font('WorkSans-Bold.ttf')}) format('truetype'); }

  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    width: ${WIDTH}px; height: ${HEIGHT}px;
    background: ${NAVY};
    color: ${CREAM};
    font-family: WorkSans, sans-serif;
    display: flex; flex-direction: column; justify-content: center;
    padding: 76px 88px;
    position: relative; overflow: hidden;
  }
  /* A single soft wash rather than any kind of pattern: the card is
     usually seen at about 500px wide in a chat bubble, and detail at
     this size reads as noise. */
  body::after {
    content: ''; position: absolute; right: -180px; top: -180px;
    width: 620px; height: 620px; border-radius: 50%;
    background: radial-gradient(circle, ${GOLD}26 0%, transparent 70%);
  }
  .wordmark {
    display: flex; align-items: center; gap: 14px;
    font-size: 30px; font-weight: 700; letter-spacing: 0.01em;
  }
  .mark {
    width: 34px; height: 34px; border-radius: 9px;
    background: ${GOLD};
    display: flex; align-items: center; justify-content: center;
    color: ${NAVY}; font-family: Lora, serif; font-weight: 700; font-size: 22px;
  }
  h1 {
    margin-top: 54px;
    font-family: Lora, serif; font-weight: 700;
    font-size: 72px; line-height: 1.08; letter-spacing: -0.015em;
    max-width: 15ch;
  }
  p {
    margin-top: 28px; max-width: 44ch;
    font-size: 25px; line-height: 1.45; color: #FFFFFFB8;
  }
</style></head>
<body>
  <div class="wordmark"><span class="mark">Y</span>Yoked</div>
  <h1>Everything your church needs online.</h1>
  <p>A website, a member app, and the tools to run a Sunday. Set it up
     yourself in a few minutes.</p>
</body></html>`;

const browser = await chromium.launch({
  executablePath: '/opt/pw-browsers/chromium',
  args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
});
const page = await browser.newPage({
  viewport: { width: WIDTH, height: HEIGHT },
  deviceScaleFactor: 1,
});
await page.setContent(html, { waitUntil: 'load' });
await page.evaluate(() => document.fonts.ready);

const out = join(root, 'web', 'social-card.png');
writeFileSync(out, await page.screenshot({ type: 'png' }));
await browser.close();

console.log(`wrote ${out} at ${WIDTH}x${HEIGHT}`);
