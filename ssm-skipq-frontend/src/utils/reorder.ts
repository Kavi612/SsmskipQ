import type { MenuItem } from '../types/menu';
import type { OrderItem } from '../types/order';

export interface ReorderLine {
  menuItem: MenuItem;
  quantity: number;
}

export const resolveReorderLines = (
  orderItems: OrderItem[],
  menuItems: MenuItem[],
) => {
  const menuById = new Map(menuItems.map((item) => [item.id, item]));
  const lines: ReorderLine[] = [];
  let skippedCount = 0;

  for (const orderItem of orderItems) {
    const menuItem = menuById.get(String(orderItem.menuItemId));

    if (!menuItem || !menuItem.available) {
      skippedCount += 1;
      continue;
    }

    lines.push({ menuItem, quantity: orderItem.quantity });
  }

  return { lines, skippedCount };
};
