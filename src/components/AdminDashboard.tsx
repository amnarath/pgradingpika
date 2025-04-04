import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { format } from 'date-fns';
import type { GradingEntry, GradingStatus } from '../lib/supabase';
import { PlusCircle, MinusCircle, Send } from 'lucide-react';

export default function AdminDashboard() {
  const [entries, setEntries] = useState<GradingEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingSurcharge, setEditingSurcharge] = useState<string | null>(null);
  const [surchargeAmount, setSurchargeAmount] = useState<number>(0);
  const [sendingEmail, setSendingEmail] = useState<string | null>(null);

  useEffect(() => {
    fetchEntries();
  }, []);

  async function fetchEntries() {
    const { data, error } = await supabase
      .from('grading_entries')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching entries:', error);
    } else {
      setEntries(data || []);
    }
    setLoading(false);
  }

  async function updateStatus(entryId: string, status: GradingStatus) {
    const { error } = await supabase
      .from('grading_entries')
      .update({ status })
      .eq('id', entryId);

    if (error) {
      alert('Error updating status: ' + error.message);
    } else {
      fetchEntries();
    }
  }

  async function updateSurcharge(entryId: string) {
    const { error } = await supabase
      .from('grading_entries')
      .update({ 
        surcharge_amount: surchargeAmount,
        payment_status: surchargeAmount > 0 ? 'Surcharge Pending' : 'Paid'
      })
      .eq('id', entryId);

    if (error) {
      alert('Error updating surcharge: ' + error.message);
    } else {
      setEditingSurcharge(null);
      setSurchargeAmount(0);
      fetchEntries();
    }
  }

  async function sendPaymentEmail(entry: GradingEntry) {
    try {
      setSendingEmail(entry.id);
      
      const response = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/send-payment-email`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: entry.consumer_id,
          entryId: entry.id,
          amount: Number(entry.price),
          surchargeAmount: Number(entry.surcharge_amount),
          bankDetails: {
            iban: 'NL74REVO1017283168',
            bic: 'REVONL21',
            recipient: 'Motif Labs',
            reference: entry.entry_number
          }
        })
      });

      if (!response.ok) {
        throw new Error('Failed to send email');
      }

      alert('Payment email sent successfully');
    } catch (error) {
      console.error('Error sending email:', error);
      alert('Error sending payment email');
    } finally {
      setSendingEmail(null);
    }
  }

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      'Pending': 'bg-slate-500/20 text-slate-300',
      'Arrived at Pikamon': 'bg-purple-500/20 text-purple-300',
      'Arrived at USA Warehouse': 'bg-blue-500/20 text-blue-300',
      'Arrived at PSA': 'bg-green-500/20 text-green-300',
      'Order Prep': 'bg-yellow-500/20 text-yellow-300',
      'Research & ID': 'bg-orange-500/20 text-orange-300',
      'Grading': 'bg-red-500/20 text-red-300',
      'Assembly': 'bg-pink-500/20 text-pink-300',
      'On the way Back': 'bg-indigo-500/20 text-indigo-300',
      'Arrived back at Pikamon from Grading': 'bg-teal-500/20 text-teal-300',
      'On the Way Back to you': 'bg-emerald-500/20 text-emerald-300'
    };
    return colors[status] || 'bg-gray-500/20 text-gray-300';
  };

  const statusOptions: GradingStatus[] = [
    'Pending',
    'Arrived at Pikamon',
    'Arrived at USA Warehouse',
    'Arrived at PSA',
    'Order Prep',
    'Research & ID',
    'Grading',
    'Assembly',
    'On the way Back',
    'Arrived back at Pikamon from Grading',
    'On the Way Back to you'
  ];

  // Format batch number for display
  const formatBatchNumber = (batchNumber: string) => {
    const [yearMonth, sequence] = batchNumber.split('-');
    const year = yearMonth.slice(0, 4);
    const month = yearMonth.slice(4, 6);
    return `${year}-${month}-${sequence}`;
  };

  return (
    <div className="space-y-6">
      <div className="glass-card rounded-xl overflow-hidden hover-glow">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg leading-6 font-medium text-white mb-4">
            All Grading Entries
          </h3>
          
          {loading ? (
            <div className="text-center py-4">
              <div className="animate-spin rounded-full h-8 w-8 border-2 border-pikamon-accent border-t-transparent mx-auto"></div>
            </div>
          ) : entries.length === 0 ? (
            <div className="text-center py-4 text-pikamon-dark-muted">
              No entries found.
            </div>
          ) : (
            <div className="relative overflow-hidden rounded-lg">
              <div className="max-h-[70vh] overflow-y-auto">
                <table className="min-w-full divide-y divide-pikamon-dark-hover">
                  <thead>
                    <tr>
                      <th scope="col" className="sticky top-0 z-10 bg-pikamon-dark-card px-6 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                        Entry #
                      </th>
                      <th scope="col" className="sticky top-0 z-10 bg-pikamon-dark-card px-6 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                        Batch
                      </th>
                      <th scope="col" className="sticky top-0 z-10 bg-pikamon-dark-card px-6 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                        Status
                      </th>
                      <th scope="col" className="sticky top-0 z-10 bg-pikamon-dark-card px-6 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                        Base Price
                      </th>
                      <th scope="col" className="sticky top-0 z-10 bg-pikamon-dark-card px-6 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                        Surcharge
                      </th>
                      <th scope="col" className="sticky top-0 z-10 bg-pikamon-dark-card px-6 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                        Payment Status
                      </th>
                      <th scope="col" className="sticky top-0 z-10 bg-pikamon-dark-card px-6 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                        Submission Date
                      </th>
                      <th scope="col" className="sticky top-0 z-10 bg-pikamon-dark-card px-6 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-pikamon-dark-hover">
                    {entries.map((entry) => (
                      <tr key={entry.id} className="hover:bg-pikamon-dark-hover/50 transition-colors duration-200">
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-white">
                          {entry.entry_number}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-white">
                          {formatBatchNumber(entry.batch_number)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusColor(entry.status)}`}>
                            {entry.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-pikamon-dark-muted">
                          €{Number(entry.price).toFixed(2)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          {editingSurcharge === entry.id ? (
                            <div className="flex items-center space-x-2">
                              <input
                                type="number"
                                value={surchargeAmount}
                                onChange={(e) => setSurchargeAmount(Number(e.target.value))}
                                className="glass-input w-24 rounded-lg text-sm"
                                min="0"
                                step="0.01"
                              />
                              <button
                                onClick={() => updateSurcharge(entry.id)}
                                className="glass-button p-1 rounded-lg"
                              >
                                <PlusCircle className="h-4 w-4 text-green-400" />
                              </button>
                              <button
                                onClick={() => {
                                  setEditingSurcharge(null);
                                  setSurchargeAmount(0);
                                }}
                                className="glass-button p-1 rounded-lg"
                              >
                                <MinusCircle className="h-4 w-4 text-red-400" />
                              </button>
                            </div>
                          ) : (
                            <div className="flex items-center space-x-2">
                              <span className="text-pikamon-dark-muted">
                                €{Number(entry.surcharge_amount).toFixed(2)}
                              </span>
                              <button
                                onClick={() => {
                                  setEditingSurcharge(entry.id);
                                  setSurchargeAmount(Number(entry.surcharge_amount));
                                }}
                                className="glass-button p-1 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity"
                              >
                                <PlusCircle className="h-4 w-4" />
                              </button>
                            </div>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                            entry.payment_status === 'Paid' ? 'bg-green-500/20 text-green-300' :
                            entry.payment_status === 'Surcharge Paid' ? 'bg-green-500/20 text-green-300' :
                            entry.payment_status === 'Surcharge Pending' ? 'bg-yellow-500/20 text-yellow-300' :
                            'bg-red-500/20 text-red-300'
                          }`}>
                            {entry.payment_status}
                          </span>
                          {(entry.payment_status === 'Unpaid' || entry.payment_status === 'Surcharge Pending') && (
                            <button
                              onClick={() => sendPaymentEmail(entry)}
                              disabled={sendingEmail === entry.id}
                              className="ml-2 glass-button p-1 rounded-lg"
                            >
                              {sendingEmail === entry.id ? (
                                <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent" />
                              ) : (
                                <Send className="h-4 w-4" />
                              )}
                            </button>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-pikamon-dark-muted">
                          {format(new Date(entry.created_at), 'MMM d, yyyy')}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          <select
                            value={entry.status}
                            onChange={(e) => updateStatus(entry.id, e.target.value as GradingStatus)}
                            className="glass-input rounded-lg text-sm"
                          >
                            {statusOptions.map((status) => (
                              <option key={status} value={status}>
                                {status}
                              </option>
                            ))}
                          </select>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}