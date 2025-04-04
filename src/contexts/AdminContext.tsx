import React, { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

interface AdminContextType {
  isAdmin: boolean;
  checkAdminStatus: () => Promise<void>;
}

const AdminContext = createContext<AdminContextType>({
  isAdmin: false,
  checkAdminStatus: async () => {},
});

export const useAdmin = () => useContext(AdminContext);

export function AdminProvider({ children }: { children: React.ReactNode }) {
  const [isAdmin, setIsAdmin] = useState(false);

  const checkAdminStatus = async () => {
    try {
      const { data, error } = await supabase.rpc('check_if_admin');
      if (error) {
        console.error('Error checking admin status:', error);
        return;
      }
      setIsAdmin(!!data);
    } catch (err) {
      console.error('Error in checkAdminStatus:', err);
    }
  };

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange(() => {
      checkAdminStatus();
    });

    checkAdminStatus();

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  return (
    <AdminContext.Provider value={{ isAdmin, checkAdminStatus }}>
      {children}
    </AdminContext.Provider>
  );
}