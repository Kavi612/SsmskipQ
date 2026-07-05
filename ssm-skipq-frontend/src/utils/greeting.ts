import type { LucideIcon } from 'lucide-react';
import {
  Cake,
  Coffee,
  Cookie,
  Drumstick,
  Leaf,
  Pizza,
  Soup,
  UtensilsCrossed,
  Wheat,
} from 'lucide-react';

const CATEGORY_ICONS: Record<string, LucideIcon> = {
  'Rice Varieties': Wheat,
  Parotta: Pizza,
  'Fried Rice': Soup,
  Chapati: Leaf,
  'Side Dishes': Drumstick,
  Gravies: Coffee,
  Puffs: Cookie,
  Snacks: UtensilsCrossed,
  Desserts: Cake,
};

export const getCategoryIcon = (name: string): LucideIcon =>
  CATEGORY_ICONS[name] ?? UtensilsCrossed;

export const getTimeGreeting = () => {
  const hour = Number(
    new Intl.DateTimeFormat('en-IN', {
      hour: 'numeric',
      hour12: false,
      timeZone: 'Asia/Kolkata',
    }).format(new Date()),
  );

  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
};
