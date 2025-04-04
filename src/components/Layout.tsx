import React, { useEffect, useState } from 'react';
import { Outlet, Link, useNavigate, useLocation } from 'react-router-dom';
import { ClipboardList, LogOut, Lightbulb, Users, ShoppingCart, PlusCircle, Clock, Menu, X } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAdmin } from '../contexts/AdminContext';
import { addDays, format, formatDistanceToNow } from 'date-fns';

export default function Layout() {
  const navigate = useNavigate();
  const location = useLocation();
  const { isAdmin } = useAdmin();
  const [batchCloseDate, setBatchCloseDate] = useState<Date | null>(null);
  const [timeLeft, setTimeLeft] = useState<string>('');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    navigate('/');
  };

  const isActive = (path: string) => {
    return location.pathname === path
      ? 'border-white text-white'
      : 'border-transparent text-pikamon-dark-text hover:border-white/50 hover:text-white';
  };

  useEffect(() => {
    const fetchBatchInfo = async () => {
      const { data, error } = await supabase
        .from('batches')
        .select('closed_at')
        .eq('status', 'open')
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (!error && data) {
        setBatchCloseDate(new Date(data.closed_at));
      } else {
        setBatchCloseDate(addDays(new Date(), 60));
      }
    };

    fetchBatchInfo();
  }, []);

  useEffect(() => {
    if (!batchCloseDate) return;

    const updateTimeLeft = () => {
      const now = new Date();
      if (batchCloseDate > now) {
        setTimeLeft(formatDistanceToNow(batchCloseDate, { addSuffix: true }));
      } else {
        setTimeLeft('Batch closed');
      }
    };

    updateTimeLeft();
    const interval = setInterval(updateTimeLeft, 1000);

    return () => clearInterval(interval);
  }, [batchCloseDate]);

  const navigationLinks = [
    { to: '/dashboard', icon: <ClipboardList className="h-4 w-4 mr-1" />, text: 'Dashboard' },
    { to: '/submit', icon: <PlusCircle className="h-4 w-4 mr-1" />, text: 'Submit Cards' },
    { to: '/tips', icon: <Lightbulb className="h-4 w-4 mr-1" />, text: 'Grading Tips' },
    {
      href: 'https://pikamon.eu/collections/accessories',
      icon: <ShoppingCart className="h-4 w-4 mr-1" />,
      text: 'Buy Accessories',
      external: true
    },
    ...(isAdmin ? [{ to: '/users', icon: <Users className="h-4 w-4 mr-1" />, text: 'Users' }] : [])
  ];

  return (
    <div className="min-h-screen bg-pikamon-dark-bg">
      {batchCloseDate && (
        <div className="bg-gradient-to-r from-pikamon-dark-hover to-black border-b border-white/5">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-2">
            <div className="flex items-center justify-center gap-2 text-sm text-white/60">
              <Clock className="w-4 h-4" />
              <span className="text-center">Current batch closes {timeLeft}</span>
              <span className="hidden sm:inline text-white/40">
                ({format(batchCloseDate, 'MMMM d, yyyy')})
              </span>
            </div>
          </div>
        </div>
      )}

      <nav className="glass-effect border-b border-white/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <span className="text-xl sm:text-2xl font-bold text-white tracking-tight">
                  Pikamon Grading
                </span>
              </div>
              <div className="hidden md:ml-10 md:flex md:space-x-8">
                {navigationLinks.map((link) => 
                  link.external ? (
                    <a
                      key={link.href}
                      href={link.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center px-1 pt-1 border-b-2 border-transparent text-sm font-medium text-pikamon-dark-text hover:border-white/50 hover:text-white"
                    >
                      {link.icon}
                      {link.text}
                    </a>
                  ) : (
                    <Link
                      key={link.to}
                      to={link.to}
                      className={`${isActive(link.to)} inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium`}
                    >
                      {link.icon}
                      {link.text}
                    </Link>
                  )
                )}
              </div>
            </div>

            <div className="flex items-center gap-4">
              <button
                onClick={handleSignOut}
                className="glass-button px-4 py-2 rounded-md text-sm font-medium hidden sm:flex items-center"
              >
                <LogOut className="h-4 w-4 mr-2" />
                Sign Out
              </button>

              {/* Mobile menu button */}
              <button
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                className="md:hidden glass-button p-2 rounded-md"
              >
                {mobileMenuOpen ? (
                  <X className="h-6 w-6" />
                ) : (
                  <Menu className="h-6 w-6" />
                )}
              </button>
            </div>
          </div>
        </div>

        {/* Mobile menu */}
        {mobileMenuOpen && (
          <div className="md:hidden glass-effect border-t border-white/5">
            <div className="px-2 pt-2 pb-3 space-y-1">
              {navigationLinks.map((link) =>
                link.external ? (
                  <a
                    key={link.href}
                    href={link.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="glass-button block px-3 py-2 rounded-md text-base font-medium"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    <span className="flex items-center">
                      {link.icon}
                      {link.text}
                    </span>
                  </a>
                ) : (
                  <Link
                    key={link.to}
                    to={link.to}
                    className={`block px-3 py-2 rounded-md text-base font-medium ${
                      location.pathname === link.to
                        ? 'glass-effect text-white'
                        : 'text-pikamon-dark-text hover:text-white hover:bg-white/5'
                    }`}
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    <span className="flex items-center">
                      {link.icon}
                      {link.text}
                    </span>
                  </Link>
                )
              )}
              <button
                onClick={() => {
                  handleSignOut();
                  setMobileMenuOpen(false);
                }}
                className="w-full glass-button px-3 py-2 rounded-md text-base font-medium flex items-center"
              >
                <LogOut className="h-4 w-4 mr-2" />
                Sign Out
              </button>
            </div>
          </div>
        )}
      </nav>

      <main className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <Outlet />
      </main>
    </div>
  );
}