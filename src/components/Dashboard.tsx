import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { format } from 'date-fns';
import type { GradingEntry, PaymentStatus } from '../lib/supabase';
import PaymentButton from './PaymentButton';
import { Link } from 'react-router-dom';
import { PlusCircle, ChevronLeft, ChevronRight } from 'lucide-react';

const ENTRIES_PER_PAGE = 5;

export default function Dashboard() {
  const [entries, setEntries] = useState<GradingEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);
  const [totalDue, setTotalDue] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [showNotification, setShowNotification] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    const fetchUserDataAndEntries = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) throw new Error('No user found');

        setIsAdmin(user.user_metadata?.role === 'admin');

        // First, get the total amount due from all entries
        const { data: allEntries, error: totalError } = await supabase
          .from('grading_entries')
          .select('price, surcharge_amount, payment_status');

        if (totalError) throw totalError;

        if (allEntries) {
          const total = allEntries.reduce((sum, entry) => {
            if (entry.payment_status === 'Unpaid' || entry.payment_status === 'Surcharge Pending') {
              return sum + Number(entry.price || 0) + Number(entry.surcharge_amount || 0);
            }
            return sum;
          }, 0);
          setTotalDue(total);
          setShowNotification(total > 0);
        }

        await fetchEntries();
      } catch (err) {
        console.error('Error fetching user data:', err);
        setError('Error loading user data');
      }
    };

    fetchUserDataAndEntries();
  }, []);

  async function fetchEntries() {
    try {
      setLoading(true);
      setError(null);

      // Get total count first
      const { count, error: countError } = await supabase
        .from('grading_entries')
        .select('*', { count: 'exact', head: true });

      if (countError) throw countError;

      // Calculate total pages
      const total = count || 0;
      setTotalPages(Math.ceil(total / ENTRIES_PER_PAGE));

      // Fetch paginated data
      const { data, error: fetchError } = await supabase
        .from('grading_entries')
        .select('*')
        .order('created_at', { ascending: false })
        .range((currentPage - 1) * ENTRIES_PER_PAGE, currentPage * ENTRIES_PER_PAGE - 1);

      if (fetchError) throw fetchError;

      if (data) {
        setEntries(data);
      }
    } catch (err: any) {
      console.error('Error fetching entries:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchEntries();
  }, [currentPage]);

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

  const getPaymentStatusColor = (status: PaymentStatus) => {
    const colors: Record<PaymentStatus, string> = {
      'Unpaid': 'bg-red-500/20 text-red-300',
      'Paid': 'bg-green-500/20 text-green-300',
      'Surcharge Pending': 'bg-yellow-500/20 text-yellow-300',
      'Surcharge Paid': 'bg-green-500/20 text-green-300'
    };
    return colors[status];
  };

  if (error) {
    return (
      <div className="bg-red-900/20 border border-red-500/20 text-red-300 px-4 py-3 rounded-lg">
        {error}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {showNotification && (
        <div className="glass-card p-4 border-l-4 border-l-amber-500">
          <div className="flex">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-amber-400" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <p className="text-sm text-amber-300">
                Outstanding balance: €{totalDue.toFixed(2)}
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Financial Overview Section */}
      <div className="glass-card rounded-xl overflow-hidden hover-glow">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg font-medium leading-6 text-pikamon-dark-text">
            Financial Overview
          </h3>
          <div className="mt-5">
            <dl className="grid grid-cols-1 gap-5 sm:grid-cols-2">
              <div className="px-4 py-5 bg-pikamon-dark-hover/50 shadow rounded-lg overflow-hidden sm:p-6">
                <dt className="text-sm font-medium text-pikamon-dark-muted truncate">
                  Total Amount Due
                </dt>
                <dd className="mt-1 text-3xl font-semibold text-pikamon-accent">
                  €{totalDue.toFixed(2)}
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </div>

      {/* Grading Entries Section */}
      <div className="glass-card rounded-xl overflow-hidden hover-glow">
        <div className="px-4 py-5 sm:p-6">
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
            <h3 className="text-lg font-medium text-pikamon-dark-text">
              Your Grading Entries
            </h3>
            <Link
              to="/submit"
              className="glass-button px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 w-full sm:w-auto justify-center"
            >
              <PlusCircle className="w-4 h-4" />
              Submit New Cards
            </Link>
          </div>
          
          {loading ? (
            <div className="text-center py-4">
              <div className="animate-spin rounded-full h-8 w-8 border-2 border-pikamon-accent border-t-transparent mx-auto"></div>
            </div>
          ) : entries.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-pikamon-dark-muted mb-4">No entries found.</p>
              <Link
                to="/submit"
                className="glass-button px-6 py-3 rounded-xl text-base font-medium inline-flex items-center gap-2"
              >
                <PlusCircle className="w-5 h-5" />
                Submit Your First Cards
              </Link>
            </div>
          ) : (
            <>
              <div className="overflow-x-auto">
                <div className="-mx-4 sm:mx-0">
                  <table className="min-w-full divide-y divide-pikamon-dark-hover">
                    <thead className="bg-pikamon-dark-card">
                      <tr>
                        <th className="px-4 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                          Entry #
                        </th>
                        <th className="px-4 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                          Status
                        </th>
                        <th className="px-4 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                          Payment
                        </th>
                        <th className="px-4 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                          Base Price
                        </th>
                        <th className="px-4 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                          Surcharge
                        </th>
                        <th className="px-4 py-3 text-left text-xs font-medium text-pikamon-dark-muted uppercase tracking-wider">
                          Total
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-pikamon-dark-hover">
                      {entries.map((entry) => {
                        const basePrice = Number(entry.price);
                        const surcharge = Number(entry.surcharge_amount);
                        const total = basePrice + surcharge;
                        const isPaid = entry.payment_status === 'Paid' || entry.payment_status === 'Surcharge Paid';

                        return (
                          <tr key={entry.id} className="hover:bg-pikamon-dark-hover/50 transition-colors duration-200">
                            <td className="px-4 py-4 whitespace-nowrap">
                              <div>
                                <div className="text-sm font-medium text-pikamon-dark-text">
                                  {entry.entry_number}
                                </div>
                                <div className="text-xs text-pikamon-dark-muted">
                                  {format(new Date(entry.created_at), 'MMM d, yyyy')}
                                </div>
                              </div>
                            </td>
                            <td className="px-4 py-4 whitespace-nowrap">
                              <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusColor(entry.status)}`}>
                                {entry.status}
                              </span>
                            </td>
                            <td className="px-4 py-4 whitespace-nowrap">
                              <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getPaymentStatusColor(entry.payment_status)}`}>
                                {entry.payment_status}
                              </span>
                            </td>
                            <td className="px-4 py-4 whitespace-nowrap">
                              <div className="text-sm text-pikamon-dark-text">
                                €{basePrice.toFixed(2)}
                              </div>
                            </td>
                            <td className="px-4 py-4 whitespace-nowrap">
                              <div className="text-sm text-pikamon-dark-text">
                                €{surcharge.toFixed(2)}
                              </div>
                            </td>
                            <td className="px-4 py-4 whitespace-nowrap">
                              <div className="text-sm text-pikamon-dark-text">
                                €{total.toFixed(2)}
                                {!isPaid && (
                                  <div className="mt-2">
                                    <PaymentButton 
                                      amount={total}
                                      entryId={entry.id}
                                      entryNumber={entry.entry_number}
                                    />
                                  </div>
                                )}
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Pagination */}
              {totalPages > 1 && (
                <div className="flex justify-center items-center space-x-4 mt-6">
                  <button
                    onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                    disabled={currentPage === 1}
                    className={`glass-button p-2 rounded-lg ${
                      currentPage === 1 ? 'opacity-50 cursor-not-allowed' : ''
                    }`}
                  >
                    <ChevronLeft className="w-5 h-5" />
                  </button>
                  
                  <span className="text-pikamon-dark-text">
                    Page {currentPage} of {totalPages}
                  </span>
                  
                  <button
                    onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                    disabled={currentPage === totalPages}
                    className={`glass-button p-2 rounded-lg ${
                      currentPage === totalPages ? 'opacity-50 cursor-not-allowed' : ''
                    }`}
                  >
                    <ChevronRight className="w-5 h-5" />
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}