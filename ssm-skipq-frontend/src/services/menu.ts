import { api } from './api';
import type { CategoriesResponse, MenuItemsResponse } from '../types/menu';

export const fetchCategories = async () => {
  const { data } = await api.get<CategoriesResponse>('/menu/categories');
  return data.data.categories;
};

export const fetchMenuItems = async () => {
  const { data } = await api.get<MenuItemsResponse>('/menu/items');
  return data.data.items;
};
