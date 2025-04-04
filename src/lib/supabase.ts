import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export type GradingStatus = 
  | 'Pending'
  | 'Arrived at Pikamon'
  | 'Arrived at USA Warehouse'
  | 'Arrived at PSA'
  | 'Order Prep'
  | 'Research & ID'
  | 'Grading'
  | 'Assembly'
  | 'On the way Back'
  | 'Arrived back at Pikamon from Grading'
  | 'On the Way Back to you';

export type PaymentStatus =
  | 'Unpaid'
  | 'Paid'
  | 'Surcharge Pending'
  | 'Surcharge Paid';

export interface GradingEntry {
  id: string;
  entry_number: string;
  batch_number: string;
  consumer_id: string;
  status: GradingStatus;
  payment_status: PaymentStatus;
  price: number;
  created_at: string;
  updated_at: string;
}