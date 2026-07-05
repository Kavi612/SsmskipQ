import Category from '../models/Category.js';
import MenuItem from '../models/MenuItem.js';
import { uploadImageBuffer, deleteCloudinaryImage } from '../utils/cloudinaryUpload.js';

const CATEGORY_ORDER = [
  'Rice Varieties',
  'Parotta',
  'Fried Rice',
  'Chapati',
  'Side Dishes',
  'Gravies',
  'Puffs',
  'Snacks',
  'Desserts',
];

const sortCategories = (categories) =>
  [...categories].sort((a, b) => {
    const indexA = CATEGORY_ORDER.indexOf(a.name);
    const indexB = CATEGORY_ORDER.indexOf(b.name);
    return (indexA === -1 ? 999 : indexA) - (indexB === -1 ? 999 : indexB);
  });

const formatMenuItem = (item) => ({
  id: item._id,
  name: item.name,
  description: item.description ?? '',
  price: item.price,
  categoryId: item.category?._id ?? item.category,
  categoryName: item.category?.name ?? '',
  imageUrl: item.imageUrl ?? '',
  isVeg: item.isVeg,
  available: item.available,
  createdAt: item.createdAt,
});

export const getCategories = async (_req, res) => {
  try {
    const categories = await Category.find().lean();
    const sorted = sortCategories(categories);

    return res.json({
      success: true,
      data: { categories: sorted },
    });
  } catch (error) {
    console.error('Get categories error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch categories',
    });
  }
};

export const getMenuItems = async (_req, res) => {
  try {
    const items = await MenuItem.find()
      .populate('category', 'name')
      .sort({ name: 1 })
      .lean();

    return res.json({
      success: true,
      data: { items: items.map(formatMenuItem) },
    });
  } catch (error) {
    console.error('Get menu items error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch menu items',
    });
  }
};

export const getManagerMenuItems = async (_req, res) => {
  try {
    const [categories, items] = await Promise.all([
      Category.find().lean(),
      MenuItem.find().populate('category', 'name').sort({ name: 1 }).lean(),
    ]);

    return res.json({
      success: true,
      data: {
        categories: sortCategories(categories),
        items: items.map(formatMenuItem),
      },
    });
  } catch (error) {
    console.error('Get manager menu error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch menu',
    });
  }
};

export const createMenuItem = async (req, res) => {
  try {
    const { name, description, price, categoryId, isVeg } = req.body;

    if (!name?.trim() || price == null || !categoryId) {
      return res.status(400).json({
        success: false,
        message: 'Name, price, and category are required',
      });
    }

    const category = await Category.findById(categoryId);
    if (!category) {
      return res.status(400).json({
        success: false,
        message: 'Invalid category',
      });
    }

    let imageUrl = '';
    if (req.file) {
      const result = await uploadImageBuffer(req.file.buffer);
      imageUrl = result.secure_url;
    }

    const item = await MenuItem.create({
      name: name.trim(),
      description: description?.trim() ?? '',
      price: Number(price),
      category: categoryId,
      imageUrl,
      isVeg: isVeg === 'true' || isVeg === true,
      available: true,
    });

    const populated = await MenuItem.findById(item._id)
      .populate('category', 'name')
      .lean();

    return res.status(201).json({
      success: true,
      data: { item: formatMenuItem(populated) },
    });
  } catch (error) {
    console.error('Create menu item error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to create menu item',
    });
  }
};

export const updateMenuItem = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, price, categoryId, isVeg } = req.body;

    const item = await MenuItem.findById(id);
    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    if (name?.trim()) item.name = name.trim();
    if (description !== undefined) item.description = description.trim();
    if (price != null) item.price = Number(price);
    if (categoryId) {
      const category = await Category.findById(categoryId);
      if (!category) {
        return res.status(400).json({
          success: false,
          message: 'Invalid category',
        });
      }
      item.category = categoryId;
    }
    if (isVeg !== undefined) {
      item.isVeg = isVeg === 'true' || isVeg === true;
    }

    if (req.file) {
      await deleteCloudinaryImage(item.imageUrl);
      const result = await uploadImageBuffer(req.file.buffer);
      item.imageUrl = result.secure_url;
    }

    await item.save();

    const populated = await MenuItem.findById(item._id)
      .populate('category', 'name')
      .lean();

    return res.json({
      success: true,
      data: { item: formatMenuItem(populated) },
    });
  } catch (error) {
    console.error('Update menu item error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to update menu item',
    });
  }
};

export const updateMenuItemPrice = async (req, res) => {
  try {
    const { id } = req.params;
    const { price } = req.body;

    if (price == null || Number(price) < 0) {
      return res.status(400).json({
        success: false,
        message: 'Valid price is required',
      });
    }

    const item = await MenuItem.findByIdAndUpdate(
      id,
      { price: Number(price) },
      { new: true },
    )
      .populate('category', 'name')
      .lean();

    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    return res.json({
      success: true,
      data: { item: formatMenuItem(item) },
    });
  } catch (error) {
    console.error('Update price error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to update price',
    });
  }
};

export const toggleMenuItemAvailability = async (req, res) => {
  try {
    const { id } = req.params;
    const item = await MenuItem.findById(id);

    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    item.available = !item.available;
    await item.save();

    const populated = await MenuItem.findById(item._id)
      .populate('category', 'name')
      .lean();

    return res.json({
      success: true,
      data: { item: formatMenuItem(populated) },
    });
  } catch (error) {
    console.error('Toggle availability error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to toggle availability',
    });
  }
};

export const deleteMenuItem = async (req, res) => {
  try {
    const { id } = req.params;
    const item = await MenuItem.findById(id);

    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    await deleteCloudinaryImage(item.imageUrl);
    await item.deleteOne();

    return res.json({
      success: true,
      message: 'Menu item deleted',
    });
  } catch (error) {
    console.error('Delete menu item error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to delete menu item',
    });
  }
};
