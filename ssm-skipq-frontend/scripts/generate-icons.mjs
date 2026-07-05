import path from 'path';
import { fileURLToPath } from 'url';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');
const logoSourcePath = path.join(root, '..', 'pictures', 'logo_app_icon.png');
const publicDir = path.join(root, 'public');

await sharp(logoSourcePath)
  .resize(32, 32)
  .png()
  .toFile(path.join(publicDir, 'icon-32.png'));
await sharp(logoSourcePath)
  .resize(192, 192)
  .png()
  .toFile(path.join(publicDir, 'icon-192.png'));
await sharp(logoSourcePath)
  .resize(512, 512)
  .png()
  .toFile(path.join(publicDir, 'icon-512.png'));

console.log('Generated icon-32.png, icon-192.png, icon-512.png');
