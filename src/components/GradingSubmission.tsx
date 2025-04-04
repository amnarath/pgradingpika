import React, { useCallback, useState } from 'react';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Plus, Calculator, Calendar, CreditCard, Upload, Download, X, Layers, CheckCircle2, AlertCircle } from 'lucide-react';
import { addBusinessDays, format } from 'date-fns';
import Papa from 'papaparse';
import { supabase } from '../lib/supabase';
import { useNavigate } from 'react-router-dom';
import {
  gradingCompanies,
  languages,
  calculatePrices,
  getServiceLevelForValue,
  submissionSchema,
  type GradingCompany,
  type ServiceLevel
} from '../lib/grading';

type SubmissionForm = {
  gradingCompany: GradingCompany;
  serviceLevel: ServiceLevel;
  cards: {
    cardName: string;
    cardNumber: string;
    language: string;
    setName: string;
    yearOfRelease: string;
    gameType: 'Pokemon' | 'One Piece';
    declaredValue: number;
  }[];
};

interface SubmissionSuccess {
  batchNumber: string;
  entryNumber: string;
  totalPrice: number;
  estimatedCompletion: Date;
}

export default function GradingSubmission() {
  const navigate = useNavigate();
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState<SubmissionSuccess | null>(null);
  const [error, setError] = useState<string | null>(null);

  const { register, control, handleSubmit, watch, setValue, formState: { errors } } = useForm<SubmissionForm>({
    resolver: zodResolver(submissionSchema),
    defaultValues: {
      gradingCompany: 'PSA',
      serviceLevel: 'economy',
      cards: [{}]
    }
  });

  const { fields, append, remove, replace } = useFieldArray({
    control,
    name: 'cards'
  });

  const gradingCompany = watch('gradingCompany');
  const serviceLevel = watch('serviceLevel');
  const cards = watch('cards');

  // Calculate prices
  const { pricePerCard, subtotal, vatAmount, total } = calculatePrices(
    gradingCompany,
    serviceLevel,
    cards.length
  );
  
  const estimatedCompletionDate = addBusinessDays(
    new Date(),
    gradingCompanies[gradingCompany].serviceLevels[serviceLevel].days
  );

  const onSubmit = async (data: SubmissionForm) => {
    try {
      setSubmitting(true);
      setError(null);

      // Get current user
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError) throw userError;
      if (!user) throw new Error('Not authenticated');

      // Get or create current batch
      const { data: currentBatch, error: batchError } = await supabase
        .rpc('get_or_create_current_batch');
      
      if (batchError) throw batchError;
      if (!currentBatch) throw new Error('Failed to get batch number');

      // Create the grading entry
      const { data: entry, error: entryError } = await supabase
        .from('grading_entries')
        .insert({
          consumer_id: user.id,
          batch_number: currentBatch,
          status: 'Pending',
          payment_status: 'Unpaid',
          price: total,
          service_level: data.serviceLevel,
          grading_company: data.gradingCompany,
          cards: data.cards
        })
        .select()
        .single();

      if (entryError) throw entryError;

      // Set success state
      setSuccess({
        batchNumber: currentBatch,
        entryNumber: entry.entry_number,
        totalPrice: total,
        estimatedCompletion: estimatedCompletionDate
      });

    } catch (err: any) {
      console.error('Submission error:', err);
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleFileUpload = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    Papa.parse(file, {
      header: true,
      complete: (results) => {
        const parsedCards = results.data.map((row: any) => ({
          cardName: row.cardName || '',
          cardNumber: row.cardNumber || '',
          language: row.language || 'English',
          setName: row.setName || '',
          yearOfRelease: row.yearOfRelease || new Date().getFullYear().toString(),
          gameType: row.gameType || 'Pokemon',
          declaredValue: parseFloat(row.declaredValue) || 0
        }));
        replace(parsedCards);
      },
      error: (error) => {
        console.error('CSV parsing error:', error);
        alert('Error parsing CSV file. Please check the format and try again.');
      }
    });

    event.target.value = '';
  }, [replace]);

  const downloadTemplate = useCallback(() => {
    const headers = ['cardName', 'cardNumber', 'language', 'setName', 'yearOfRelease', 'gameType', 'declaredValue'];
    const csvContent = Papa.unparse({
      fields: headers,
      data: [
        {
          cardName: 'Charizard',
          cardNumber: '4/102',
          language: 'English',
          setName: 'Base Set',
          yearOfRelease: '1999',
          gameType: 'Pokemon',
          declaredValue: '500'
        }
      ]
    });

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'card_submission_template.csv';
    link.click();
  }, []);

  if (success) {
    return (
      <div className="max-w-2xl mx-auto py-16 px-4">
        <div className="glass-card rounded-2xl overflow-hidden border border-white/10 p-8 text-center">
          <div className="mb-6">
            <CheckCircle2 className="w-16 h-16 text-green-400 mx-auto" />
          </div>
          <h2 className="text-2xl font-bold text-white mb-4">
            Submission Successful!
          </h2>
          <div className="space-y-4 mb-8">
            <p className="text-white/80">
              Your grading request has been submitted successfully.
            </p>
            <div className="glass-effect rounded-lg p-6 space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-white/60">Batch Number</span>
                <span className="text-white font-medium">{success.batchNumber}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-white/60">Entry Number</span>
                <span className="text-white font-medium">{success.entryNumber}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-white/60">Total Amount (incl. VAT)</span>
                <span className="text-white font-medium">€{success.totalPrice.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-white/60">Estimated Completion</span>
                <span className="text-white font-medium">
                  {format(success.estimatedCompletion, 'MMMM d, yyyy')}
                </span>
              </div>
            </div>
          </div>
          <div className="flex gap-4 justify-center">
            <button
              onClick={() => navigate('/dashboard')}
              className="glass-button px-6 py-3 rounded-xl text-base font-medium"
            >
              View Dashboard
            </button>
            <button
              onClick={() => {
                setSuccess(null);
                setValue('cards', [{}]);
              }}
              className="glass-button px-6 py-3 rounded-xl text-base font-medium"
            >
              Submit Another
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto py-8 px-4">
      <div className="glass-card rounded-2xl overflow-hidden border border-white/10">
        <div className="bg-gradient-to-r from-black to-pikamon-dark-hover p-6 border-b border-white/10">
          <h1 className="text-2xl font-bold text-white">Card Grading Submission</h1>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-8">
          {/* Grading Company Selection */}
          <div className="space-y-4">
            <h2 className="text-xl font-semibold text-white flex items-center">
              <CreditCard className="w-5 h-5 mr-2 text-white" />
              Grading Company
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {Object.entries(gradingCompanies).map(([key, company]) => (
                <label
                  key={key}
                  className={`relative flex flex-col p-4 rounded-lg cursor-pointer transition-all duration-300 ${
                    gradingCompany === key
                      ? 'glass-effect border border-white/20 shadow-lg shadow-white/10'
                      : 'glass-card hover:border-white/20'
                  }`}
                >
                  <input
                    type="radio"
                    {...register('gradingCompany')}
                    value={key}
                    className="sr-only"
                  />
                  <span className="font-medium text-white">{company.name}</span>
                  <span className="text-sm text-white/60 mt-1">{company.description}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Service Level Selection */}
          <div className="space-y-4">
            <h2 className="text-xl font-semibold text-white flex items-center">
              <CreditCard className="w-5 h-5 mr-2 text-white" />
              Service Level
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {Object.entries(gradingCompanies[gradingCompany].serviceLevels).map(([key, level]) => (
                <label
                  key={key}
                  className={`relative flex flex-col p-4 rounded-lg cursor-pointer transition-all duration-300 ${
                    serviceLevel === key
                      ? 'glass-effect border border-white/20 shadow-lg shadow-white/10'
                      : 'glass-card hover:border-white/20'
                  }`}
                >
                  <input
                    type="radio"
                    {...register('serviceLevel')}
                    value={key}
                    className="sr-only"
                  />
                  <span className="font-medium text-white">{level.name}</span>
                  <span className="text-lg font-bold text-white">€{level.price}/card</span>
                  <span className="text-sm text-white/60">{level.days} business days</span>
                  {level.maxValue && (
                    <span className="text-xs text-white/40 mt-1">
                      Max card value: €{level.maxValue}
                    </span>
                  )}
                </label>
              ))}
            </div>
          </div>

          {/* Card Entries */}
          <div className="space-y-4">
            <div className="flex flex-wrap gap-4 items-center justify-between">
              <div className="flex items-center space-x-2">
                <h2 className="text-xl font-semibold text-white flex items-center">
                  <Layers className="w-5 h-5 mr-2 text-white" />
                  Card Details
                </h2>
                <span className="text-sm text-white/60">({cards.length} cards)</span>
              </div>
              
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={downloadTemplate}
                  className="glass-button rounded-md px-3 py-2 text-sm font-medium flex items-center"
                >
                  <Download className="w-4 h-4 mr-2" />
                  Download Template
                </button>

                <label className="glass-button rounded-md px-3 py-2 text-sm font-medium flex items-center cursor-pointer">
                  <Upload className="w-4 h-4 mr-2" />
                  Upload CSV
                  <input
                    type="file"
                    accept=".csv"
                    onChange={handleFileUpload}
                    className="hidden"
                  />
                </label>

                <button
                  type="button"
                  onClick={() => append({})}
                  className="glass-button rounded-md px-3 py-2 text-sm font-medium flex items-center"
                >
                  <Plus className="w-4 h-4 mr-2" />
                  Add Card
                </button>
              </div>
            </div>

            <div className="space-y-8">
              {fields.map((field, index) => {
                const cardValue = watch(`cards.${index}.declaredValue`);
                const recommendedLevel = cardValue ? getServiceLevelForValue(gradingCompany, cardValue) : null;
                const currentLevel = watch('serviceLevel');
                const showLevelWarning = recommendedLevel && recommendedLevel !== currentLevel && 
                  gradingCompanies[gradingCompany].serviceLevels[currentLevel].maxValue && 
                  cardValue > gradingCompanies[gradingCompany].serviceLevels[currentLevel].maxValue;

                return (
                  <div 
                    key={field.id} 
                    className={`
                      glass-card p-6 rounded-xl relative border border-white/10 
                      ${index > 0 ? 'mt-12' : ''}
                      hover:shadow-lg hover:shadow-white/5 transition-all duration-300
                    `}
                  >
                    <div className="absolute -top-4 left-4 bg-gradient-to-r from-white/10 to-white/5 rounded-t-xl px-6 py-2 text-white font-medium border-t border-l border-r border-white/10">
                      Card #{index + 1}
                    </div>
                    
                    {index > 0 && (
                      <button
                        type="button"
                        onClick={() => remove(index)}
                        className="absolute -top-3 -right-3 bg-red-500/20 hover:bg-red-500/30 text-red-300 rounded-full p-2 transition-colors duration-200 hover:scale-110"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    )}

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-4">
                      <div className="space-y-4">
                        <div>
                          <label className="block text-sm font-medium text-white mb-1">
                            Card Name
                          </label>
                          <input
                            type="text"
                            {...register(`cards.${index}.cardName`)}
                            className="glass-input w-full rounded-lg"
                            placeholder="e.g., Charizard"
                          />
                          {errors.cards?.[index]?.cardName && (
                            <p className="mt-1 text-sm text-red-400">
                              {errors.cards[index]?.cardName?.message}
                            </p>
                          )}
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-white mb-1">
                            Card Number
                          </label>
                          <input
                            type="text"
                            {...register(`cards.${index}.cardNumber`)}
                            className="glass-input w-full rounded-lg"
                            placeholder="e.g., 4/102"
                          />
                          {errors.cards?.[index]?.cardNumber && (
                            <p className="mt-1 text-sm text-red-400">
                              {errors.cards[index]?.cardNumber?.message}
                            </p>
                          )}
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-white mb-1">
                            Language
                          </label>
                          <select
                            {...register(`cards.${index}.language`)}
                            className="glass-input w-full rounded-lg"
                          >
                            <option value="">Select language</option>
                            {languages.map(lang => (
                              <option key={lang} value={lang}>{lang}</option>
                            ))}
                          </select>
                          {errors.cards?.[index]?.language && (
                            <p className="mt-1 text-sm text-red-400">
                              {errors.cards[index]?.language?.message}
                            </p>
                          )}
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-white mb-1">
                            Declared Value (€)
                          </label>
                          <input
                            type="number"
                            {...register(`cards.${index}.declaredValue`)}
                            className="glass-input w-full rounded-lg"
                            placeholder="e.g., 500"
                            min="1"
                            step="0.01"
                          />
                          {errors.cards?.[index]?.declaredValue && (
                            <p className="mt-1 text-sm text-red-400">
                              {errors.cards[index]?.declaredValue?.message}
                            </p>
                          )}
                          {showLevelWarning && (
                            <div className="mt-2 flex items-start gap-2 text-amber-400 text-sm">
                              <AlertCircle className="w-4 h-4 flex-shrink-0 mt-0.5" />
                              <p>
                                Based on the declared value, this card requires {gradingCompanies[gradingCompany].serviceLevels[recommendedLevel].name} service level or higher
                              </p>
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="space-y-4">
                        <div>
                          <label className="block text-sm font-medium text-white mb-1">
                            Set Name
                          </label>
                          <input
                            type="text"
                            {...register(`cards.${index}.setName`)}
                            className="glass-input w-full rounded-lg"
                            placeholder="e.g., Base Set"
                          />
                          {errors.cards?.[index]?.setName && (
                            <p className="mt-1 text-sm text-red-400">
                              {errors.cards[index]?.setName?.message}
                            </p>
                          )}
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-white mb-1">
                            Year of Release
                          </label>
                          <input
                            type="number"
                            {...register(`cards.${index}.yearOfRelease`)}
                            min="1996"
                            max={new Date().getFullYear()}
                            className="glass-input w-full rounded-lg"
                            placeholder={new Date().getFullYear().toString()}
                          />
                          {errors.cards?.[index]?.yearOfRelease && (
                            <p className="mt-1 text-sm text-red-400">
                              {errors.cards[index]?.yearOfRelease?.message}
                            </p>
                          )}
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-white mb-1">
                            Game Type
                          </label>
                          <select
                            {...register(`cards.${index}.gameType`)}
                            className="glass-input w-full rounded-lg"
                          >
                            <option value="">Select game type</option>
                            <option value="Pokemon">Pokemon</option>
                            <option value="One Piece">One Piece</option>
                          </select>
                          {errors.cards?.[index]?.gameType && (
                            <p className="mt-1 text-sm text-red-400">
                              {errors.cards[index]?.gameType?.message}
                            </p>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Summary */}
          <div className="glass-card p-6 rounded-xl space-y-4 border border-white/10">
            <h2 className="text-xl font-semibold text-white flex items-center">
              <Calculator className="w-5 h-5 mr-2 text-white" />
              Submission Summary
            </h2>

            <div className="space-y-3">
              <div className="flex justify-between text-sm text-white/60">
                <span>Grading Company</span>
                <span>{gradingCompanies[gradingCompany].name}</span>
              </div>
              <div className="flex justify-between text-sm text-white/60">
                <span>Service Level</span>
                <span>{gradingCompanies[gradingCompany].serviceLevels[serviceLevel].name}</span>
              </div>
              <div className="flex justify-between text-sm text-white/60">
                <span>Number of Cards</span>
                <span>{cards.length}</span>
              </div>
              <div className="flex justify-between text-sm text-white/60">
                <span>Price per Card</span>
                <span>€{pricePerCard.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm text-white/60">
                <span>Subtotal</span>
                <span>€{subtotal.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm text-white/60">
                <span>VAT (21%)</span>
                <span>€{vatAmount.toFixed(2)}</span>
              </div>
              <div className="h-px bg-white/10"></div>
              <div className="flex justify-between font-semibold text-lg text-white">
                <span>Total Price</span>
                <span>€{total.toFixed(2)}</span>
              </div>
              <div className="flex justify-between items-center text-sm text-white/60">
                <span className="flex items-center">
                  <Calendar className="w-4 h-4 mr-1" />
                  Estimated Completion
                </span>
                <span>{format(estimatedCompletionDate, 'MMMM d, yyyy')}</span>
              </div>
            </div>
          </div>

          {/* Submit Button */}
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={submitting}
              className={`
                glass-button px-6 py-3 rounded-xl text-base font-medium
                hover:shadow-lg hover:shadow-white/10
                ${submitting ? 'opacity-50 cursor-not-allowed' : ''}
              `}
            >
              {submitting ? 'Submitting...' : 'Submit Grading Request'}
            </button>
          </div>

          {error && (
            <div className="text-red-400 text-sm mt-4">
              {error}
            </div>
          )}
        </form>
      </div>
    </div>
  );
}