export interface OrderingWindow {
  orderingOpenTime: string;
  orderingCloseTime: string;
  isOpen: boolean;
}

export interface OrderingWindowResponse {
  success: boolean;
  data: OrderingWindow;
}
