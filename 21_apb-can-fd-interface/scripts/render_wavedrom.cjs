// Render WaveJSON with WaveDrom, then capture each diagram in Chromium.
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const { chromium } = require('playwright');

async function main() {
  const root = path.resolve(__dirname, '..');
  const sourceDir = path.join(root, 'docs', 'wavedrom');
  const outputDir = path.join(root, 'docs', 'diagrams');
  const cli = path.join(path.dirname(require.resolve('wavedrom/package.json')), 'bin', 'cli.js');
  const options = { headless: true };
  if (process.env.BROWSER_CHANNEL) options.channel = process.env.BROWSER_CHANNEL;
  const browser = await chromium.launch(options);
  try {
    const page = await browser.newPage({ viewport: { width: 1700, height: 1000 }, deviceScaleFactor: 2 });
    for (const file of fs.readdirSync(sourceDir).filter(name => name.endsWith('.json')).sort()) {
      const name = path.basename(file, '.json');
      const svg = execFileSync(process.execPath, [cli, '--input', path.join(sourceDir, file)], { encoding: 'utf8' });
      fs.writeFileSync(path.join(outputDir, `${name}.svg`), svg);
      await page.setContent('<!doctype html><meta charset="utf-8"><style>body{margin:0;background:white}#capture{display:inline-block;padding:20px;background:white}svg{display:block}</style><div id="capture">' + svg + '</div>');
      await page.evaluate(() => document.fonts.ready);
      await page.locator('#capture').screenshot({ path: path.join(outputDir, `${name}.png`) });
      console.log(`Captured WaveDrom: ${name}`);
    }
  } finally {
    await browser.close();
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
