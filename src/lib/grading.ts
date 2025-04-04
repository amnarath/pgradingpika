import { z } from 'zod';

// Grading companies and their service levels
export const gradingCompanies = {
  PSA: {
    name: 'PSA',
    description: 'Professional Sports Authenticator - The industry standard in card grading',
    serviceLevels: {
      economy: { price: 50, days: 30, name: 'Economy', maxValue: 499 },
      regular: { price: 100, days: 15, name: 'Regular', maxValue: 999 },
      express: { price: 150, days: 10, name: 'Express', maxValue: 2499 },
      superExpress: { price: 300, days: 5, name: 'Super Express', maxValue: 4999 },
      walkThrough: { price: 600, days: 2, name: 'Walk-Through', maxValue: null }
    }
  },
  TAG: {
    name: 'TAG',
    description: 'Trading Art Gallery - Specialized in Japanese TCG grading',
    serviceLevels: {
      economy: { price: 35, days: 25, name: 'Economy', maxValue: 299 },
      regular: { price: 75, days: 12, name: 'Regular', maxValue: 799 },
      express: { price: 125, days: 8, name: 'Express', maxValue: 1999 },
      superExpress: { price: 250, days: 4, name: 'Super Express', maxValue: 3999 },
      walkThrough: { price: 500, days: 1, name: 'Walk-Through', maxValue: null }
    }
  }
} as const;

// Types
export type GradingCompany = keyof typeof gradingCompanies;
export type ServiceLevel = keyof typeof gradingCompanies.PSA.serviceLevels;

// Validation schema
export const cardSchema = z.object({
  cardName: z.string().min(1, 'Card name is required'),
  cardNumber: z.string().min(1, 'Card number is required'),
  language: z.enum(['English', 'Japanese', 'Korean', 'Chinese (Simplified)', 'Chinese (Traditional)', 'German', 'French', 'Italian', 'Spanish', 'Portuguese']),
  setName: z.string().min(1, 'Set name is required'),
  yearOfRelease: z.string()
    .regex(/^\d{4}$/, 'Must be a valid year')
    .refine(val => parseInt(val) >= 1996 && parseInt(val) <= new Date().getFullYear(), {
      message: `Year must be between 1996 and ${new Date().getFullYear()}`
    }),
  gameType: z.enum(['Pokemon', 'One Piece']),
  declaredValue: z.string()
    .transform((val) => Number(val))
    .pipe(
      z.number()
        .min(1, 'Declared value is required')
        .nonnegative('Declared value must be positive')
    )
});

export const submissionSchema = z.object({
  gradingCompany: z.enum(['PSA', 'TAG']),
  serviceLevel: z.enum(['economy', 'regular', 'express', 'superExpress', 'walkThrough']),
  cards: z.array(cardSchema).min(1, 'At least one card is required')
});

// Dutch VAT rate
export const VAT_RATE = 0.21;

// Languages available for cards
export const languages = [
  'English',
  'Japanese',
  'Korean',
  'Chinese (Simplified)',
  'Chinese (Traditional)',
  'German',
  'French',
  'Italian',
  'Spanish',
  'Portuguese'
] as const;

// Helper functions
export function calculatePrices(company: GradingCompany, serviceLevel: ServiceLevel, cardCount: number) {
  const pricePerCard = gradingCompanies[company].serviceLevels[serviceLevel].price;
  const subtotal = cardCount * pricePerCard;
  const vatAmount = subtotal * VAT_RATE;
  const total = subtotal + vatAmount;

  return {
    pricePerCard,
    subtotal,
    vatAmount,
    total
  };
}

export function getServiceLevelForValue(company: GradingCompany, declaredValue: number): ServiceLevel {
  const levels = gradingCompanies[company].serviceLevels;
  
  // Find the appropriate service level based on declared value
  for (const [level, details] of Object.entries(levels)) {
    if (!details.maxValue || declaredValue <= details.maxValue) {
      return level as ServiceLevel;
    }
  }
  
  // If no level found, return walk-through
  return 'walkThrough';
}