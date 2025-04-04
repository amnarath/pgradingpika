import { loadStripe } from '@stripe/stripe-js';

const stripePublicKey = 'pk_live_51NQCWbDbqXbu8HsFjbkoSi7ca9X0F2IhXZAHlTT43gXalc7FDFnC1OtIjF7OSIjQb4Ea4fmmcbmKBbxmgXWSkBrn00pGrx5c7a';

if (!stripePublicKey) {
  throw new Error('Missing Stripe public key');
}

export const stripe = loadStripe(stripePublicKey);