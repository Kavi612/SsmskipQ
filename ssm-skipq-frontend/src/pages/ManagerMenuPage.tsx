import { useEffect, useState, type FormEvent } from 'react';
import { Check, Pencil, Trash2, UtensilsCrossed, X } from 'lucide-react';
import {
  fetchManagerMenu,
  createMenuItem,
  updateMenuItem,
  updateMenuItemPrice,
  toggleMenuItemAvailability,
  deleteMenuItem,
} from '../services/managerMenu';
import type { Category, MenuItem } from '../types/menu';
import { FoodCardSkeletonGrid } from '../components/FoodCardSkeleton';
import { EmptyState } from '../components/ui/UiStates';
import styles from './ManagerMenuPage.module.css';

const normalizeId = (id: unknown) => String(id ?? '');

const resolveCategoryId = (item: MenuItem, categories: Category[]) => {
  const itemCat = normalizeId(item.categoryId);
  if (categories.some((c) => normalizeId(c._id) === itemCat)) return itemCat;
  return categories[0] ? normalizeId(categories[0]._id) : '';
};

const ManagerMenuPage = () => {
  const [categories, setCategories] = useState<Category[]>([]);
  const [items, setItems] = useState<MenuItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [priceEdits, setPriceEdits] = useState<Record<string, string>>({});
  const [savingPriceId, setSavingPriceId] = useState<string | null>(null);

  const [form, setForm] = useState({
    name: '',
    description: '',
    price: '',
    categoryId: '',
    isVeg: true,
  });
  const [formImage, setFormImage] = useState<File | null>(null);
  const [formLoading, setFormLoading] = useState(false);

  const [editForm, setEditForm] = useState({
    name: '',
    description: '',
    price: '',
    categoryId: '',
    isVeg: true,
  });
  const [editImage, setEditImage] = useState<File | null>(null);

  useEffect(() => {
    let cancelled = false;

    fetchManagerMenu()
      .then((data) => {
        if (!cancelled) {
          setCategories(data.categories);
          setItems(data.items);
          if (data.categories[0]) {
            setForm((f) =>
              f.categoryId
                ? f
                : { ...f, categoryId: normalizeId(data.categories[0]._id) },
            );
          }
        }
      })
      .catch(() => {
        if (!cancelled) setError('Unable to load menu.');
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    setFormLoading(true);
    setError('');
    try {
      const fd = new FormData();
      fd.append('name', form.name);
      fd.append('description', form.description);
      fd.append('price', form.price);
      fd.append('categoryId', form.categoryId);
      fd.append('isVeg', String(form.isVeg));
      if (formImage) fd.append('image', formImage);

      const item = await createMenuItem(fd);
      setItems((prev) =>
        [...prev, item].sort((a, b) => a.name.localeCompare(b.name)),
      );
      setForm({
        name: '',
        description: '',
        price: '',
        categoryId: categories[0] ? normalizeId(categories[0]._id) : '',
        isVeg: true,
      });
      setFormImage(null);
    } catch {
      setError('Unable to create item.');
    } finally {
      setFormLoading(false);
    }
  };

  const startEdit = (item: MenuItem) => {
    setEditingId(item.id);
    setEditForm({
      name: item.name,
      description: item.description,
      price: String(item.price),
      categoryId: resolveCategoryId(item, categories),
      isVeg: item.isVeg,
    });
    setEditImage(null);
  };

  const handleFinishEdit = async (id: string) => {
    setFormLoading(true);
    try {
      const fd = new FormData();
      fd.append('name', editForm.name);
      fd.append('description', editForm.description);
      fd.append('price', editForm.price);
      fd.append('categoryId', editForm.categoryId);
      fd.append('isVeg', String(editForm.isVeg));
      if (editImage) fd.append('image', editImage);

      const updated = await updateMenuItem(id, fd);
      setItems((prev) => prev.map((i) => (i.id === id ? updated : i)));
      setEditingId(null);
    } catch {
      setError('Unable to update item.');
    } finally {
      setFormLoading(false);
    }
  };

  const handlePriceBlur = async (item: MenuItem) => {
    const raw = priceEdits[item.id];
    if (raw === undefined) return;

    const price = Number(raw);
    if (Number.isNaN(price) || price < 0) {
      setPriceEdits((prev) => {
        const next = { ...prev };
        delete next[item.id];
        return next;
      });
      return;
    }

    if (price === item.price) {
      setPriceEdits((prev) => {
        const next = { ...prev };
        delete next[item.id];
        return next;
      });
      return;
    }

    setSavingPriceId(item.id);
    try {
      const updated = await updateMenuItemPrice(item.id, price);
      setItems((prev) => prev.map((i) => (i.id === item.id ? updated : i)));
      setPriceEdits((prev) => {
        const next = { ...prev };
        delete next[item.id];
        return next;
      });
    } catch {
      setError('Unable to update price.');
    } finally {
      setSavingPriceId(null);
    }
  };

  const handleToggle = async (id: string) => {
    try {
      const updated = await toggleMenuItemAvailability(id);
      setItems((prev) => prev.map((i) => (i.id === id ? updated : i)));
    } catch {
      setError('Unable to toggle availability.');
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Delete this menu item?')) return;
    try {
      await deleteMenuItem(id);
      setItems((prev) => prev.filter((i) => i.id !== id));
    } catch {
      setError('Unable to delete item.');
    }
  };

  const renderCategoryOptions = (placeholder: string) => {
    if (categories.length === 0) {
      return (
        <option value="" disabled>
          No categories — run seed script
        </option>
      );
    }

    return (
      <>
        <option value="" disabled>
          {placeholder}
        </option>
        {categories.map((c) => (
          <option key={c._id} value={normalizeId(c._id)}>
            {c.name}
          </option>
        ))}
      </>
    );
  };

  return (
    <div className={styles.page}>
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Add New Item</h2>
        <p className={styles.sectionHint}>
          Fill in the details below to add a dish to the menu.
        </p>
        <form className={styles.addForm} onSubmit={handleCreate}>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Item name</span>
            <input
              type="text"
              placeholder="e.g. Veg Fried Rice"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              required
              className={styles.input}
            />
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Description</span>
            <input
              type="text"
              placeholder="Optional short description"
              value={form.description}
              onChange={(e) =>
                setForm({ ...form, description: e.target.value })
              }
              className={styles.input}
            />
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Price (₹)</span>
            <input
              type="number"
              placeholder="0"
              value={form.price}
              onChange={(e) => setForm({ ...form, price: e.target.value })}
              required
              min={0}
              className={styles.input}
            />
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Category</span>
            <select
              value={form.categoryId}
              onChange={(e) => setForm({ ...form, categoryId: e.target.value })}
              required
              className={styles.select}
            >
              {renderCategoryOptions('Choose category')}
            </select>
          </label>
          <label className={styles.checkLabel}>
            <input
              type="checkbox"
              checked={form.isVeg}
              onChange={(e) => setForm({ ...form, isVeg: e.target.checked })}
            />
            Vegetarian
          </label>
          <label className={styles.field}>
            <span className={styles.fieldLabel}>Photo</span>
            <input
              type="file"
              accept="image/*"
              onChange={(e) => setFormImage(e.target.files?.[0] ?? null)}
              className={styles.fileInput}
            />
          </label>
          <button
            type="submit"
            className={styles.addBtn}
            disabled={formLoading || categories.length === 0}
          >
            Add Item
          </button>
        </form>
      </section>

      {error && <p className={styles.error}>{error}</p>}

      {isLoading && (
        <div className={styles.list}>
          <FoodCardSkeletonGrid count={4} />
        </div>
      )}

      {!isLoading && !error && items.length === 0 && (
        <EmptyState
          icon={UtensilsCrossed}
          title="No menu items"
          message="Add your first dish using the form above."
        />
      )}

      {!isLoading && items.length > 0 && (
        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Menu Items</h2>
          <p className={styles.sectionHint}>
            Edit price inline — changes apply when you leave the field. Use the
            pencil to edit other details.
          </p>
          <ul className={styles.list}>
            {items.map((item) => (
              <li key={item.id} className={styles.itemRow}>
                <div className={styles.imageWrap}>
                  {item.imageUrl ? (
                    <img
                      src={item.imageUrl}
                      alt={item.name}
                      className={styles.image}
                    />
                  ) : (
                    <div className={styles.placeholder}>
                      <UtensilsCrossed size={28} />
                    </div>
                  )}
                  {!item.available && (
                    <span className={styles.soldOutBadge}>Sold Out</span>
                  )}
                </div>

                {editingId === item.id ? (
                  <div className={styles.editPanel}>
                    <div className={styles.editGrid}>
                      <label className={styles.field}>
                        <span className={styles.fieldLabel}>Name</span>
                        <input
                          value={editForm.name}
                          onChange={(e) =>
                            setEditForm({ ...editForm, name: e.target.value })
                          }
                          className={styles.input}
                        />
                      </label>
                      <label className={styles.field}>
                        <span className={styles.fieldLabel}>Description</span>
                        <input
                          value={editForm.description}
                          onChange={(e) =>
                            setEditForm({
                              ...editForm,
                              description: e.target.value,
                            })
                          }
                          className={styles.input}
                        />
                      </label>
                      <label className={styles.field}>
                        <span className={styles.fieldLabel}>Price (₹)</span>
                        <input
                          type="number"
                          min={0}
                          value={editForm.price}
                          onChange={(e) =>
                            setEditForm({ ...editForm, price: e.target.value })
                          }
                          className={styles.input}
                        />
                      </label>
                      <label className={styles.field}>
                        <span className={styles.fieldLabel}>Category</span>
                        <select
                          value={editForm.categoryId}
                          onChange={(e) =>
                            setEditForm({
                              ...editForm,
                              categoryId: e.target.value,
                            })
                          }
                          className={styles.select}
                        >
                          {renderCategoryOptions('Choose category')}
                        </select>
                      </label>
                      <label className={styles.checkLabel}>
                        <input
                          type="checkbox"
                          checked={editForm.isVeg}
                          onChange={(e) =>
                            setEditForm({
                              ...editForm,
                              isVeg: e.target.checked,
                            })
                          }
                        />
                        Vegetarian
                      </label>
                      <label className={styles.field}>
                        <span className={styles.fieldLabel}>New photo</span>
                        <input
                          type="file"
                          accept="image/*"
                          onChange={(e) =>
                            setEditImage(e.target.files?.[0] ?? null)
                          }
                          className={styles.fileInput}
                        />
                      </label>
                    </div>
                    <div className={styles.editActions}>
                      <button
                        type="button"
                        className={styles.doneBtn}
                        onClick={() => handleFinishEdit(item.id)}
                        disabled={formLoading}
                        title="Done editing"
                      >
                        <Check size={18} />
                        Done
                      </button>
                      <button
                        type="button"
                        className={styles.cancelBtn}
                        onClick={() => setEditingId(null)}
                        title="Cancel editing"
                      >
                        <X size={18} />
                        Cancel
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className={styles.itemBody}>
                    <div className={styles.itemHeader}>
                      <div>
                        <h3 className={styles.itemName}>{item.name}</h3>
                        <p className={styles.category}>{item.categoryName}</p>
                      </div>
                      <span
                        className={`${styles.vegBadge} ${item.isVeg ? styles.vegBadgeVeg : styles.vegBadgeNonVeg}`}
                      >
                        {item.isVeg ? 'Veg' : 'Non-Veg'}
                      </span>
                    </div>

                    {item.description && (
                      <p className={styles.description}>{item.description}</p>
                    )}

                    <div className={styles.itemFooter}>
                      <label className={styles.priceField}>
                        <span className={styles.fieldLabel}>Price (₹)</span>
                        <input
                          type="number"
                          value={priceEdits[item.id] ?? item.price}
                          onChange={(e) =>
                            setPriceEdits({
                              ...priceEdits,
                              [item.id]: e.target.value,
                            })
                          }
                          onBlur={() => handlePriceBlur(item)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') {
                              e.currentTarget.blur();
                            }
                          }}
                          className={styles.priceInput}
                          min={0}
                          disabled={savingPriceId === item.id}
                        />
                      </label>

                      <div className={styles.cardActions}>
                        <button
                          type="button"
                          className={styles.iconBtn}
                          onClick={() => startEdit(item)}
                          title="Edit item"
                        >
                          <Pencil size={18} />
                        </button>
                        <button
                          type="button"
                          className={`${styles.availBtn} ${item.available ? styles.availOn : styles.availOff}`}
                          onClick={() => handleToggle(item.id)}
                        >
                          {item.available ? 'Available' : 'Unavailable'}
                        </button>
                        <button
                          type="button"
                          className={styles.iconBtnDanger}
                          onClick={() => handleDelete(item.id)}
                          title="Delete item"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
};

export default ManagerMenuPage;
