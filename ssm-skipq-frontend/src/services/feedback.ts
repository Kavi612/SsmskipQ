import { api } from './api';
import type {
  FeedbackResponse,
  ManagerFeedbackResponse,
  SubmitFeedbackPayload,
} from '../types/feedback';

export const submitOrderFeedback = async (
  orderId: string,
  payload: SubmitFeedbackPayload,
) => {
  const { data } = await api.post<FeedbackResponse>(
    `/api/orders/${orderId}/feedback`,
    payload,
  );
  return data.data.feedback;
};

export const fetchManagerFeedback = async () => {
  const { data } = await api.get<ManagerFeedbackResponse>(
    '/api/orders/feedback/manager',
  );
  return data.data.feedback;
};
