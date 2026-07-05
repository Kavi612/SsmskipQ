export type ToastVariant = 'student' | 'manager';

export interface Toast {
  id: string;
  variant: ToastVariant;
  title: string;
  message?: string;
}
