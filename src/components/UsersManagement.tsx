import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { format } from 'date-fns';
import { Users, UserPlus, Edit, Plus, ChevronDown, ChevronUp, X, Check, Mail, MailCheck, Send, CreditCard } from 'lucide-react';
import type { GradingEntry, GradingStatus, PaymentStatus } from '../lib/supabase';
import { useNavigate } from 'react-router-dom';
import { useAdmin } from '../contexts/AdminContext';

interface User {
  id: string;
  email: string;
  created_at: string;
  role?: string;
  email_confirmed_at?: string | null;
}

interface UserEntries {
  [key: string]: {
    entries: GradingEntry[];
    loading: boolean;
    error: string | null;
  };
}

interface NewEntry {
  batch_number: string;
  price: number;
}

interface EditingField {
  entryId: string;
  field: keyof GradingEntry;
}

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

const paymentStatusOptions: PaymentStatus[] = [
  'Unpaid',
  'Paid',
  'Surcharge Pending',
  'Surcharge Paid'
];

export default function UsersManagement() {
  const navigate = useNavigate();
  const { isAdmin } = useAdmin();
  const [users, setUsers] = useState<User[]>([]);
  const [userEntries, setUserEntries] = useState<UserEntries>({});
  const [expandedUsers, setExpandedUsers] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showNewUserForm, setShowNewUserForm] = useState(false);
  const [showNewEntryForm, setShowNewEntryForm] = useState<string | null>(null);
  const [newUser, setNewUser] = useState({ email: '', password: '' });
  const [newEntry, setNewEntry] = useState<NewEntry>({ batch_number: '', price: 0 });
  const [editingField, setEditingField] = useState<EditingField | null>(null);
  const [editingValue, setEditingValue] = useState<any>(null);
  const [verificationLoading, setVerificationLoading] = useState<string | null>(null);
  const [showCardDetails, setShowCardDetails] = useState<string | null>(null);
  const [sendingEmail, setSendingEmail] = useState<string | null>(null);

  useEffect(() => {
    if (!isAdmin) {
      navigate('/dashboard');
      return;
    }
    fetchUsers();
  }, [isAdmin, navigate]);

  async function fetchUsers() {
    try {
      setLoading(true);
      setError(null);

      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (!user) {
        navigate('/login');
        return;
      }

      const { data: usersData, error: usersError } = await supabase
        .from('users')
        .select('*')
        .order('created_at', { ascending: false });

      if (usersError) throw usersError;

      const { data: authUsersData, error: authError } = await supabase.rpc('get_users_with_verification');
      
      if (authError) throw authError;

      const combinedUsers = usersData.map(user => {
        const authUser = authUsersData.find((au: any) => au.id === user.id);
        return {
          ...user,
          email_confirmed_at: authUser?.email_confirmed_at
        };
      });

      setUsers(combinedUsers);
    } catch (err: any) {
      console.error('Error fetching users:', err);
      setError(err.message);
      if (err.message === 'Not authenticated') {
        navigate('/login');
      }
    } finally {
      setLoading(false);
    }
  }

  async function toggleEmailVerification(userId: string, currentStatus: boolean) {
    try {
      setVerificationLoading(userId);
      setError(null);

      const { error } = await supabase.rpc('toggle_email_verification', {
        user_id: userId,
        is_verified: !currentStatus
      });

      if (error) throw error;
      await fetchUsers();
    } catch (err: any) {
      console.error('Error toggling email verification:', err);
      setError(err.message);
    } finally {
      setVerificationLoading(null);
    }
  }

  async function fetchUserEntries(userId: string) {
    try {
      setUserEntries(prev => ({
        ...prev,
        [userId]: { entries: [], loading: true, error: null }
      }));

      const { data, error: fetchError } = await supabase
        .from('grading_entries')
        .select('*')
        .eq('consumer_id', userId)
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;
      
      setUserEntries(prev => ({
        ...prev,
        [userId]: { entries: data || [], loading: false, error: null }
      }));
    } catch (err: any) {
      console.error('Error fetching user entries:', err);
      setUserEntries(prev => ({
        ...prev,
        [userId]: { entries: [], loading: false, error: err.message }
      }));
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

  const startEditing = (entryId: string, field: keyof GradingEntry, value: any) => {
    setEditingField({ entryId, field });
    setEditingValue(value);
  };

  const cancelEditing = () => {
    setEditingField(null);
    setEditingValue(null);
  };

  const saveFieldChange = async (entry: GradingEntry) => {
    if (!editingField) return;

    try {
      const { error: updateError } = await supabase
        .from('grading_entries')
        .update({
          [editingField.field]: editingValue
        })
        .eq('id', entry.id);

      if (updateError) throw updateError;

      await fetchUserEntries(entry.consumer_id);
      cancelEditing();
    } catch (err: any) {
      console.error('Error updating entry:', err);
      setError(err.message);
    }
  };

  const toggleUserExpansion = async (userId: string) => {
    const newExpandedUsers = new Set(expandedUsers);
    if (expandedUsers.has(userId)) {
      newExpandedUsers.delete(userId);
    } else {
      newExpandedUsers.add(userId);
      if (!userEntries[userId]?.entries.length) {
        await fetchUserEntries(userId);
      }
    }
    setExpandedUsers(newExpandedUsers);
  };

  async function handleCreateUser(e: React.FormEvent) {
    e.preventDefault();
    try {
      setError(null);

      const { data: existingUsers, error: checkError } = await supabase
        .from('users')
        .select('id')
        .eq('email', newUser.email)
        .limit(1);

      if (checkError) throw checkError;

      if (existingUsers && existingUsers.length > 0) {
        throw new Error('A user with this email already exists');
      }
      
      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email: newUser.email,
        password: newUser.password,
        options: {
          emailRedirectTo: window.location.origin,
          data: {
            role: 'user'
          }
        }
      });

      if (signUpError) throw signUpError;
      if (!authData.user) throw new Error('Failed to create user');

      const { error: insertError } = await supabase
        .from('users')
        .insert({
          id: authData.user.id,
          email: newUser.email,
          role: 'user'
        });

      if (insertError) throw insertError;
      
      setShowNewUserForm(false);
      setNewUser({ email: '', password: '' });
      await fetchUsers();
    } catch (err: any) {
      setError(err.message);
    }
  }

  async function handleCreateEntry(userId: string, e: React.FormEvent) {
    e.preventDefault();
    try {
      setError(null);

      const { error: insertError } = await supabase
        .from('grading_entries')
        .insert({
          consumer_id: userId,
          batch_number: newEntry.batch_number,
          price: newEntry.price,
          status: 'Pending',
          payment_status: 'Unpaid'
        });

      if (insertError) throw insertError;
      
      setShowNewEntryForm(null);
      setNewEntry({ batch_number: '', price: 0 });
      if (expandedUsers.has(userId)) {
        await fetchUserEntries(userId);
      }
    } catch (err: any) {
      setError(err.message);
    }
  }

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      'Pending': 'bg-slate-100 text-slate-800',
      'Arrived at Pikamon': 'bg-purple-100 text-purple-800',
      'Arrived at USA Warehouse': 'bg-blue-100 text-blue-800',
      'Arrived at PSA': 'bg-green-100 text-green-800',
      'Order Prep': 'bg-yellow-100 text-yellow-800',
      'Research & ID': 'bg-orange-100 text-orange-800',
      'Grading': 'bg-red-100 text-red-800',
      'Assembly': 'bg-pink-100 text-pink-800',
      'On the way Back': 'bg-indigo-100 text-indigo-800',
      'Arrived back at Pikamon from Grading': 'bg-teal-100 text-teal-800',
      'On the Way Back to you': 'bg-emerald-100 text-emerald-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  const getPaymentStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      'Unpaid': 'bg-red-100 text-red-800',
      'Paid': 'bg-green-100 text-green-800',
      'Surcharge Pending': 'bg-yellow-100 text-yellow-800',
      'Surcharge Paid': 'bg-green-100 text-green-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  const renderEmailStatus = (user: User) => {
    const isVerified = !!user.email_confirmed_at;
    const isLoading = verificationLoading === user.id;

    return (
      <button
        onClick={(e) => {
          e.stopPropagation();
          if (!isLoading) {
            toggleEmailVerification(user.id, isVerified);
          }
        }}
        disabled={isLoading}
        className={`flex items-center px-3 py-1.5 rounded-md transition-colors ${
          isVerified 
            ? 'bg-green-100 text-green-800 hover:bg-green-200' 
            : 'bg-yellow-100 text-yellow-800 hover:bg-yellow-200'
        } ${isLoading ? 'opacity-50 cursor-not-allowed' : ''}`}
      >
        {isLoading ? (
          <div className="animate-spin rounded-full h-4 w-4 border-2 border-gray-500 border-t-transparent mr-2" />
        ) : isVerified ? (
          <MailCheck className="h-4 w-4 mr-2" />
        ) : (
          <Mail className="h-4 w-4 mr-2" />
        )}
        <span>{isVerified ? 'Verified' : 'Pending'}</span>
      </button>
    );
  };

  const renderEditableCell = (entry: GradingEntry, field: keyof GradingEntry, content: React.ReactNode) => {
    const isEditing = editingField?.entryId === entry.id && editingField?.field === field;
    
    let editComponent = null;
    if (isEditing) {
      switch (field) {
        case 'status':
          editComponent = (
            <select
              value={editingValue}
              onChange={(e) => setEditingValue(e.target.value)}
              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-pikamon-accent focus:ring-pikamon-accent sm:text-sm"
              autoFocus
            >
              {statusOptions.map((status) => (
                <option key={status} value={status}>{status}</option>
              ))}
            </select>
          );
          break;
        case 'payment_status':
          editComponent = (
            <select
              value={editingValue}
              onChange={(e) => setEditingValue(e.target.value)}
              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-pikamon-accent focus:ring-pikamon-accent sm:text-sm"
              autoFocus
            >
              {paymentStatusOptions.map((status) => (
                <option key={status} value={status}>{status}</option>
              ))}
            </select>
          );
          break;
        case 'price':
        case 'surcharge_amount':
          editComponent = (
            <input
              type="number"
              value={editingValue}
              onChange={(e) => setEditingValue(parseFloat(e.target.value))}
              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-pikamon-accent focus:ring-pikamon-accent sm:text-sm"
              min="0"
              step="0.01"
              autoFocus
            />
          );
          break;
        case 'created_at':
          editComponent = (
            <input
              type="datetime-local"
              value={format(new Date(editingValue), "yyyy-MM-dd'T'HH:mm")}
              onChange={(e) => setEditingValue(new Date(e.target.value).toISOString())}
              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-pikamon-accent focus:ring-pikamon-accent sm:text-sm"
              autoFocus
            />
          );
          break;
      }
    }

    return (
      <td 
        className="px-4 py-2 whitespace-nowrap text-sm group relative"
        onMouseEnter={() => !isEditing && !editingField && field !== 'entry_number' && field !== 'batch_number'}
      >
        {isEditing ? (
          <div className="flex items-center space-x-2">
            {editComponent}
            <div className="flex space-x-1">
              <button
                onClick={() => saveFieldChange(entry)}
                className="text-green-600 hover:text-green-800"
              >
                <Check className="h-4 w-4" />
              </button>
              <button
                onClick={cancelEditing}
                className="text-red-600 hover:text-red-800"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>
        ) : (
          <div className="flex items-center justify-between">
            {content}
            {field !== 'entry_number' && field !== 'batch_number' && (
              <button
                onClick={() => startEditing(entry.id, field, entry[field])}
                className="opacity-0 group-hover:opacity-100 transition-opacity duration-200 text-gray-400 hover:text-gray-600"
              >
                <Edit className="h-3 w-3" />
              </button>
            )}
          </div>
        )}
      </td>
    );
  };

  const renderCardDetails = (entry: GradingEntry) => {
    if (!entry.cards) return null;

    const cards = Array.isArray(entry.cards) ? entry.cards : [];

    return (
      <div className="bg-white p-4 rounded-lg shadow mt-2">
        <h4 className="text-sm font-medium text-gray-900 mb-3">Card Details</h4>
        <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3">
          {cards.map((card: any, index: number) => (
            <div key={index} className="border rounded-lg p-3 bg-gray-50">
              <div className="text-sm">
                <p className="font-medium">{card.cardName}</p>
                <p className="text-gray-500">{card.cardNumber}</p>
                <p className="text-gray-500">{card.setName} ({card.yearOfRelease})</p>
                <p className="text-gray-500">{card.language}</p>
                <p className="text-gray-500">Value: €{card.declaredValue}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  const renderEntryRow = (entry: GradingEntry) => (
    <React.Fragment key={entry.id}>
      <tr className="hover:bg-gray-50">
        {renderEditableCell(entry, 'entry_number',
          <div className="flex items-center">
            <span className="text-gray-900">{entry.entry_number}</span>
            <button
              onClick={() => setShowCardDetails(showCardDetails === entry.id ? null : entry.id)}
              className="ml-2 text-gray-400 hover:text-gray-600"
            >
              <CreditCard className="h-4 w-4" />
            </button>
          </div>
        )}
        {renderEditableCell(entry, 'batch_number',
          <span className="text-gray-900">{entry.batch_number}</span>
        )}
        {renderEditableCell(entry, 'status',
          <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusColor(entry.status)}`}>
            {entry.status}
          </span>
        )}
        {renderEditableCell(entry, 'payment_status',
          <div className="flex items-center space-x-2">
            <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${getPaymentStatusColor(entry.payment_status)}`}>
              {entry.payment_status}
            </span>
            {(entry.payment_status === 'Unpaid' || entry.payment_status === 'Surcharge Pending') && (
              <button
                onClick={() => sendPaymentEmail(entry)}
                disabled={sendingEmail === entry.id}
                className="text-gray-400 hover:text-gray-600"
              >
                {sendingEmail === entry.id ? (
                  <div className="animate-spin rounded-full h-4 w-4 border-2 border-gray-400 border-t-transparent" />
                ) : (
                  <Send className="h-4 w-4" />
                )}
              </button>
            )}
          </div>
        )}
        {renderEditableCell(entry, 'price',
          <span className="text-gray-500">€{Number(entry.price).toFixed(2)}</span>
        )}
        {renderEditableCell(entry, 'surcharge_amount',
          <span className="text-gray-500">€{Number(entry.surcharge_amount).toFixed(2)}</span>
        )}
        {renderEditableCell(entry, 'created_at',
          <span className="text-gray-500">{format(new Date(entry.created_at), 'MMM d, yyyy')}</span>
        )}
      </tr>
      {showCardDetails === entry.id && (
        <tr>
          <td colSpan={7} className="px-4 py-2">
            {renderCardDetails(entry)}
          </td>
        </tr>
      )}
    </React.Fragment>
  );

  return (
    <div className="space-y-6">
      <div className="bg-white shadow sm:rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <div className="flex justify-between items-center mb-6">
            <div className="flex items-center">
              <Users className="h-6 w-6 text-pikamon-primary mr-2" />
              <h3 className="text-lg font-medium text-gray-900">User Management</h3>
            </div>
            <button
              onClick={() => setShowNewUserForm(true)}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-pikamon-primary hover:bg-opacity-90"
            >
              <UserPlus className="h-4 w-4 mr-2" />
              New User
            </button>
          </div>

          {error && (
            <div className="mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded">
              {error}
            </div>
          )}

          {showNewUserForm && (
            <div className="mb-6 p-4 border rounded-md bg-gray-50">
              <h4 className="text-md font-medium text-gray-900 mb-4">Create New User</h4>
              <form onSubmit={handleCreateUser} className="space-y-4">
                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                    Email
                  </label>
                  <input
                    type="email"
                    id="email"
                    value={newUser.email}
                    onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-pikamon-accent focus:ring-pikamon-accent sm:text-sm"
                    required
                  />
                </div>
                <div>
                  <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                    Password
                  </label>
                  <input
                    type="password"
                    id="password"
                    value={newUser.password}
                    onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-pikamon-accent focus:ring-pikamon-accent sm:text-sm"
                    required
                  />
                </div>
                <div className="flex justify-end space-x-3">
                  <button
                    type="button"
                    onClick={() => setShowNewUserForm(false)}
                    className="px-3 py-1 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-3 py-1 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-pikamon-primary hover:bg-opacity-90"
                  >
                    Create User
                  </button>
                </div>
              </form>
            </div>
          )}

          {loading ? (
            <div className="text-center py-4">Loading...</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Email
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Role
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Email Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Created
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {users.map((user) => (
                    <React.Fragment key={user.id}>
                      <tr className="hover:bg-gray-50 cursor-pointer" onClick={() => toggleUserExpansion(user.id)}>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          <div className="flex items-center">
                            {expandedUsers.has(user.id) ? (
                              <ChevronUp className="h-4 w-4 mr-2" />
                            ) : (
                              <ChevronDown className="h-4 w-4  mr-2" />
                            )}
                            {user.email}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {user.role || 'User'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          {renderEmailStatus(user)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {format(new Date(user.created_at), 'MMM d, yyyy')}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <div className="flex space-x-3">
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setShowNewEntryForm(user.id);
                              }}
                              className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-pikamon-primary hover:bg-gray-50"
                            >
                              <Plus className="h-4 w-4 mr-1" />
                              Add Entry
                            </button>
                          </div>

                          {showNewEntryForm === user.id && (
                            <div 
                              className="absolute mt-2 p-4 bg-white border rounded-md shadow-lg z-10"
                              onClick={(e) => e.stopPropagation()}
                            >
                              <div className="flex justify-between items-center mb-4">
                                <h4 className="text-sm font-medium text-gray-900">Add New Entry</h4>
                                <button
                                  onClick={() => setShowNewEntryForm(null)}
                                  className="text-gray-400 hover:text-gray-500"
                                >
                                  <X className="h-4 w-4" />
                                </button>
                              </div>
                              <form onSubmit={(e) => handleCreateEntry(user.id, e)} className="space-y-4">
                                <div>
                                  <label htmlFor="batch_number" className="block text-sm font-medium text-gray-700">
                                    Batch Number
                                  </label>
                                  <input
                                    type="text"
                                    id="batch_number"
                                    value={newEntry.batch_number}
                                    onChange={(e) => setNewEntry({ ...newEntry, batch_number: e.target.value })}
                                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-pikamon-accent focus:ring-pikamon-accent sm:text-sm"
                                    required
                                  />
                                </div>
                                <div>
                                  <label htmlFor="price" className="block text-sm font-medium text-gray-700">
                                    Price
                                  </label>
                                  <input
                                    type="number"
                                    id="price"
                                    value={newEntry.price}
                                    onChange={(e) => setNewEntry({ ...newEntry, price: Number(e.target.value) })}
                                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-pikamon-accent focus:ring-pikamon-accent sm:text-sm"
                                    required
                                  />
                                </div>
                                <div className="flex justify-end space-x-3">
                                  <button
                                    type="button"
                                    onClick={() => setShowNewEntryForm(null)}
                                    className="px-3 py-1 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                                  >
                                    Cancel
                                  </button>
                                  <button
                                    type="submit"
                                    className="px-3 py-1 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-pikamon-primary hover:bg-opacity-90"
                                  >
                                    Create Entry
                                  </button>
                                </div>
                              </form>
                            </div>
                          )}
                        </td>
                      </tr>
                      {expandedUsers.has(user.id) && (
                        <tr>
                          <td colSpan={5} className="px-6 py-4">
                            {userEntries[user.id]?.loading ? (
                              <div className="text-center py-4">Loading entries...</div>
                            ) : userEntries[user.id]?.error ? (
                              <div className="text-center py-4 text-red-600">
                                Error loading entries: {userEntries[user.id]?.error}
                              </div>
                            ) : userEntries[user.id]?.entries.length === 0 ? (
                              <div className="text-center py-4 text-gray-500">No entries found</div>
                            ) : (
                              <div className="overflow-x-auto">
                                <table className="min-w-full divide-y divide-gray-200">
                                  <thead className="bg-gray-50">
                                    <tr>
                                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Entry Number
                                      </th>
                                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Batch Number
                                      </th>
                                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Status
                                      </th>
                                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Payment
                                      </th>
                                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Price
                                      </th>
                                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Surcharge
                                      </th>
                                      <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Created
                                      </th>
                                    </tr>
                                  </thead>
                                  <tbody className="bg-white divide-y divide-gray-200">
                                    {userEntries[user.id]?.entries.map(renderEntryRow)}
                                  </tbody>
                                </table>
                              </div>
                            )}
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}