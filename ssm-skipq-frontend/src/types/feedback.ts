import type { OrderItem } from './order';

export interface OrderFeedback {
  id: string;
  orderId: string;
  rating: number;
  review: string;
  createdAt: string;
  student?: {
    name: string;
    mobile: string;
  };
  order?: {
    tokenNumber: string;
    items: OrderItem[];
    total: number;
    createdAt: string;
  };
}

export interface SubmitFeedbackPayload {
  rating: number;
  review?: string;
}

export interface FeedbackResponse {
  success: boolean;
  data: { feedback: OrderFeedback };
}

export interface ManagerFeedbackResponse {
  success: boolean;
  data: { feedback: OrderFeedback[] };
}
