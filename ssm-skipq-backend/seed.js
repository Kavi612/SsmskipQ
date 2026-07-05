import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import mongoose from 'mongoose';
import connectDB from './config/db.js';
import cloudinary from './config/cloudinary.js';
import Category from './models/Category.js';
import MenuItem from './models/MenuItem.js';

dotenv.config();

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SEED_IMAGES_DIR = path.join(__dirname, 'seed-images');
const IMAGE_EXTENSIONS = ['.png', '.jpg', '.jpeg', '.webp'];

const MENU_DATA = [
  {
    category: 'Rice Varieties',
    items: [
      { slug: 'vegetable-biryani', name: 'Vegetable Biryani', price: 80, isVeg: true },
      { slug: 'mushroom-biryani', name: 'Mushroom Biryani', price: 90, isVeg: true },
      { slug: 'chicken-biryani', name: 'Chicken Biryani', price: 120, isVeg: false },
      { slug: 'curd-rice', name: 'Curd Rice', price: 50, isVeg: true },
      { slug: 'sambar-rice', name: 'Sambar Rice', price: 60, isVeg: true },
    ],
  },
  {
    category: 'Parotta',
    items: [
      { slug: 'parotta-2-pieces', name: 'Parotta (2 Pieces)', price: 30, isVeg: true },
      { slug: 'kothu-parotta', name: 'Kothu Parotta', price: 70, isVeg: true },
      { slug: 'egg-kothu-parotta', name: 'Egg Kothu Parotta', price: 90, isVeg: false },
      { slug: 'chicken-kothu-parotta', name: 'Chicken Kothu Parotta', price: 110, isVeg: false },
    ],
  },
  {
    category: 'Fried Rice',
    items: [
      { slug: 'veg-fried-rice', name: 'Veg Fried Rice', price: 80, isVeg: true },
      { slug: 'egg-fried-rice', name: 'Egg Fried Rice', price: 90, isVeg: false },
      { slug: 'chicken-fried-rice', name: 'Chicken Fried Rice', price: 100, isVeg: false },
    ],
  },
  {
    category: 'Chapati',
    items: [
      { slug: 'chapati-2-pieces', name: 'Chapati (2 Pieces)', price: 30, isVeg: true },
    ],
  },
  {
    category: 'Side Dishes',
    items: [
      { slug: 'chicken-65', name: 'Chicken 65', price: 100, isVeg: false },
      { slug: 'mushroom-65', name: 'Mushroom 65', price: 80, isVeg: true },
      { slug: 'omelette', name: 'Omelette', price: 20, isVeg: false },
    ],
  },
  {
    category: 'Gravies',
    items: [
      { slug: 'chicken-gravy', name: 'Chicken Gravy', price: 70, isVeg: false },
      { slug: 'paneer-gravy', name: 'Paneer Gravy', price: 60, isVeg: true },
    ],
  },
  {
    category: 'Puffs',
    items: [
      { slug: 'egg-puff', name: 'Egg Puff', price: 25, isVeg: false },
      { slug: 'paneer-puff', name: 'Paneer Puff', price: 30, isVeg: true },
      { slug: 'chicken-puff', name: 'Chicken Puff', price: 35, isVeg: false },
      { slug: 'mushroom-puff', name: 'Mushroom Puff', price: 30, isVeg: true },
    ],
  },
  {
    category: 'Snacks',
    items: [
      { slug: 'paruppu-vadai', name: 'Paruppu Vadai', price: 15, isVeg: true },
      { slug: 'ulundhu-vadai', name: 'Ulundhu Vadai', price: 15, isVeg: true },
      { slug: 'bajji', name: 'Bajji', price: 20, isVeg: true },
    ],
  },
  {
    category: 'Desserts',
    items: [
      { slug: 'gulab-jamun-2-pieces', name: 'Gulab Jamun (2 Pieces)', price: 30, isVeg: true },
    ],
  },
];

const findLocalImage = (slug) => {
  for (const ext of IMAGE_EXTENSIONS) {
    const filePath = path.join(SEED_IMAGES_DIR, `${slug}${ext}`);
    if (fs.existsSync(filePath)) {
      return filePath;
    }
  }
  return null;
};

const uploadImage = async (slug, filePath) => {
  const result = await cloudinary.uploader.upload(filePath, {
    folder: 'ssm-skipq/menu',
    public_id: slug,
    overwrite: true,
    resource_type: 'image',
  });
  return result.secure_url;
};

const resolveImageUrl = async (slug) => {
  const filePath = findLocalImage(slug);
  if (!filePath) {
    return '';
  }

  try {
    const url = await uploadImage(slug, filePath);
    console.log(`  ↑ uploaded ${slug} → Cloudinary`);
    return url;
  } catch (error) {
    console.warn(`  ⚠ upload failed for ${slug}: ${error.message}`);
    return '';
  }
};

const seed = async () => {
  await connectDB();

  console.log('Clearing existing menu items and categories...');
  const deletedItems = await MenuItem.deleteMany({});
  const deletedCategories = await Category.deleteMany({});
  console.log(`  Removed ${deletedItems.deletedCount} menu items`);
  console.log(`  Removed ${deletedCategories.deletedCount} categories\n`);

  const categoryMap = new Map();
  let totalItems = 0;
  let uploadedCount = 0;
  let placeholderCount = 0;

  for (const { category, items } of MENU_DATA) {
    const categoryDoc = await Category.create({ name: category });
    categoryMap.set(category, categoryDoc._id);
    console.log(`Category: ${category}`);

    for (const item of items) {
      const imageUrl = await resolveImageUrl(item.slug);
      if (imageUrl) {
        uploadedCount += 1;
      } else {
        placeholderCount += 1;
        console.log(`  ○ ${item.name} — no local image (${item.slug})`);
      }

      await MenuItem.create({
        name: item.name,
        description: '',
        price: item.price,
        category: categoryDoc._id,
        imageUrl,
        isVeg: item.isVeg,
        available: true,
      });

      totalItems += 1;
    }

    console.log('');
  }

  console.log('── Seed summary ──');
  console.log(`Categories inserted : ${categoryMap.size}`);
  console.log(`Menu items inserted : ${totalItems}`);
  console.log(`Images uploaded     : ${uploadedCount}`);
  console.log(`Placeholder icons   : ${placeholderCount}`);

  console.log('\n── Verification (MongoDB Atlas) ──');
  const categories = await Category.find().sort({ name: 1 }).lean();
  for (const cat of categories) {
    const items = await MenuItem.find({ category: cat._id })
      .sort({ name: 1 })
      .lean();
    console.log(`\n${cat.name} (${items.length})`);
    items.forEach((item) => {
      const vegLabel = item.isVeg ? 'veg' : 'non-veg';
      const imageLabel = item.imageUrl ? 'image ✓' : 'placeholder';
      console.log(`  • ${item.name} — ₹${item.price} — ${vegLabel} — ${imageLabel}`);
    });
  }

  const dbItemCount = await MenuItem.countDocuments();
  const dbCategoryCount = await Category.countDocuments();
  console.log(`\nTotal in DB: ${dbCategoryCount} categories, ${dbItemCount} items`);

  if (dbCategoryCount !== 9 || dbItemCount !== 26) {
    throw new Error(
      `Expected 9 categories and 26 items, got ${dbCategoryCount} and ${dbItemCount}`,
    );
  }

  console.log('\nSeed completed successfully.');
};

seed()
  .catch((error) => {
    console.error('\nSeed failed:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
