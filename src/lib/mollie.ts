import { createMollieClient } from '@mollie/api-client';

// The actual client will be initialized in the Edge Function
// This file is for types and constants
export const MOLLIE_METHODS = [
  'ideal',
  'creditcard',
  'bancontact',
  'sofort',
  'giropay',
  'eps',
  'paypal'
] as const;

export type MollieMethod = typeof MOLLIE_METHODS[number];

export interface CreatePaymentResponse {
  checkoutUrl: string;
  paymentId: string;
}