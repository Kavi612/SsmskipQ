import { api } from './api';
import type { Order } from '../types/order';

export interface PaymentConfig {
  enabled: boolean;
  keyId: string;
  testMode: boolean;
}

export interface RazorpayCheckoutDetails {
  orderId: string;
  keyId: string;
  amount: number;
  currency: string;
  testMode: boolean;
}

export interface CreateOrderData {
  order: Order;
  razorpay: RazorpayCheckoutDetails | null;
}

export const fetchPaymentConfig = async () => {
  const { data } = await api.get<{
    success: boolean;
    data: { razorpay: PaymentConfig };
  }>('/payments/config');
  return data.data.razorpay;
};

export const verifyRazorpayPayment = async (payload: {
  orderId: string;
  razorpayOrderId: string;
  razorpayPaymentId: string;
  razorpaySignature: string;
}) => {
  const { data } = await api.post<{ success: boolean; data: { order: Order } }>(
    '/payments/razorpay/verify',
    payload,
  );
  return data.data.order;
};

declare global {
  interface Window {
    Razorpay?: new (options: Record<string, unknown>) => {
      open: () => void;
      on: (event: string, handler: (response: unknown) => void) => void;
    };
  }
}

export const loadRazorpayScript = () =>
  new Promise<boolean>((resolve) => {
    if (window.Razorpay) {
      resolve(true);
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.onload = () => resolve(true);
    script.onerror = () => resolve(false);
    document.body.appendChild(script);
  });

export const openRazorpayCheckout = async ({
  checkout,
  skipqOrderId,
  customerName,
  customerMobile,
  description,
}: {
  checkout: RazorpayCheckoutDetails;
  skipqOrderId: string;
  customerName: string;
  customerMobile: string;
  description: string;
}) => {
  const loaded = await loadRazorpayScript();
  if (!loaded || !window.Razorpay) {
    throw new Error('Unable to load Razorpay checkout');
  }

  return new Promise<{
    razorpayPaymentId: string;
    razorpayOrderId: string;
    razorpaySignature: string;
  }>((resolve, reject) => {
    const razorpay = new window.Razorpay!({
      key: checkout.keyId,
      amount: checkout.amount,
      currency: checkout.currency,
      name: 'SkipQ@SSM',
      description,
      order_id: checkout.orderId,
      prefill: {
        name: customerName,
        contact: customerMobile,
      },
      notes: {
        skipq_order_id: skipqOrderId,
      },
      theme: {
        color: '#FE4101',
      },
      handler: (response: {
        razorpay_payment_id: string;
        razorpay_order_id: string;
        razorpay_signature: string;
      }) => {
        resolve({
          razorpayPaymentId: response.razorpay_payment_id,
          razorpayOrderId: response.razorpay_order_id,
          razorpaySignature: response.razorpay_signature,
        });
      },
      modal: {
        ondismiss: () => reject(new Error('Payment cancelled')),
      },
    });

    razorpay.open();
  });
};
