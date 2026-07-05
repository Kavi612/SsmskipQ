import path from 'path';
import { fileURLToPath } from 'url';
import sharp from 'sharp';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');
const picturesDir = path.join(root, '..', 'pictures');
const assetsDir = path.join(root, 'src', 'assets');

const BRAND_ASSETS = [
  { src: 'logo_app_icon.png', dest: 'logo-app-icon.png', width: 384 },
  { src: 'amimated front image.png', dest: 'splash-hero.png', width: 480 },
  {
    src: 'animated_food1-removebg-preview.png',
    dest: 'collage-food-1.png',
    width: 220,
  },
  {
    src: 'animated_foo2-removebg-preview.png',
    dest: 'collage-food-2.png',
    width: 220,
  },
  {
    src: 'animated_food3-removebg-preview.png',
    dest: 'collage-food-3.png',
    width: 220,
  },
  {
    src: 'animated_food4-removebg-preview.png',
    dest: 'collage-food-4.png',
    width: 220,
  },
];

for (const { src, dest, width } of BRAND_ASSETS) {
  const inputPath = path.join(picturesDir, src);
  const outputPath = path.join(assetsDir, dest);

  await sharp(inputPath)
    .resize(width, null, { withoutEnlargement: true, fit: 'inside' })
    .png({ compressionLevel: 9, effort: 10 })
    .toFile(outputPath);

  const meta = await sharp(outputPath).metadata();
  console.log(`Optimized ${dest} → ${meta.width}×${meta.height}px`);
}
