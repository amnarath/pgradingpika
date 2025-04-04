import React, { useState } from 'react';
import { supabase } from '../lib/supabase';
import { ClipboardList, ArrowLeft, AlertCircle, Mail, Shield, Eye, EyeOff } from 'lucide-react';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [isSignUp, setIsSignUp] = useState(false);
  const [isForgotPassword, setIsForgotPassword] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      if (isForgotPassword) {
        const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
          redirectTo: `${window.location.origin}/reset-password`,
        });
        
        if (resetError) throw resetError;
        
        setSuccess('Password reset instructions have been sent to your email.');
      } else if (isSignUp) {
        if (password.length < 6) {
          throw new Error('Password must be at least 6 characters long');
        }

        // Check for password strength
        if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(password)) {
          throw new Error('Password must contain at least one uppercase letter, one lowercase letter, and one number');
        }

        const { error: signUpError } = await supabase.auth.signUp({
          email,
          password,
          options: {
            emailRedirectTo: `${window.location.origin}/auth/callback`,
            data: {
              email_confirmed: false,
              role: 'user'
            }
          }
        });
        
        if (signUpError) {
          if (signUpError.message.includes('rate_limit')) {
            throw new Error('Please wait a minute before trying again.');
          }
          if (signUpError.message.includes('User already registered')) {
            throw new Error('An account with this email already exists. Please sign in instead.');
          }
          throw signUpError;
        }
        
        setSuccess('Account created successfully! Please check your email to verify your account.');
      } else {
        const { error: signInError } = await supabase.auth.signInWithPassword({
          email,
          password,
        });

        if (signInError) {
          if (signInError.message.includes('Invalid login credentials')) {
            throw new Error('Incorrect email or password. Please try again.');
          }
          throw signInError;
        }
      }
    } catch (error: any) {
      let errorMessage = error.message;
      if (errorMessage.includes('Failed to fetch')) {
        errorMessage = 'Unable to connect to the server. Please check your internet connection and try again.';
      }
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const toggleMode = (mode: 'signin' | 'signup' | 'forgot') => {
    setIsSignUp(mode === 'signup');
    setIsForgotPassword(mode === 'forgot');
    setError(null);
    setSuccess(null);
    setEmail('');
    setPassword('');
  };

  return (
    <div 
      className="min-h-screen flex flex-col justify-center py-12 sm:px-6 lg:px-8 relative bg-gradient-to-br from-black to-pikamon-dark-hover"
    >
      <div className="sm:mx-auto sm:w-full sm:max-w-md relative z-10">
        <div className="flex justify-center">
          <div className="glass-card p-3 rounded-full">
            <ClipboardList className="h-12 w-12 text-white" />
          </div>
        </div>
        <h2 className="mt-6 text-center text-3xl font-extrabold text-white">
          {isForgotPassword 
            ? 'Reset your password'
            : isSignUp 
              ? 'Create an account' 
              : 'Sign in to Pikamon Grading'}
        </h2>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md relative z-10">
        <div className="glass-card py-8 px-4 shadow-xl sm:rounded-2xl sm:px-10">
          {success ? (
            <div className="space-y-6">
              <div className="bg-green-900/20 border border-green-500/20 text-green-300 px-4 py-3 rounded-lg flex items-center gap-2">
                <Mail className="h-5 w-5 flex-shrink-0" />
                <p>{success}</p>
              </div>
              <button
                onClick={() => toggleMode('signin')}
                className="w-full glass-button py-3 rounded-lg text-base font-medium"
              >
                <ArrowLeft className="h-4 w-4 mr-2 inline" />
                Back to Sign In
              </button>
            </div>
          ) : (
            <form className="space-y-6" onSubmit={handleSubmit}>
              {error && (
                <div className="flex items-center gap-2 bg-red-900/20 border border-red-500/20 text-red-300 px-4 py-3 rounded-lg">
                  <AlertCircle className="h-5 w-5 flex-shrink-0" />
                  <p className="text-sm">{error}</p>
                </div>
              )}
              
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-white">
                  Email address
                </label>
                <div className="mt-1">
                  <input
                    id="email"
                    name="email"
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="glass-input w-full rounded-lg"
                    placeholder="Enter your email"
                  />
                </div>
              </div>

              {!isForgotPassword && (
                <div>
                  <label htmlFor="password" className="block text-sm font-medium text-white">
                    Password
                  </label>
                  <div className="mt-1 relative">
                    <input
                      id="password"
                      name="password"
                      type={showPassword ? "text" : "password"}
                      required
                      minLength={6}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="glass-input w-full rounded-lg pr-10"
                      placeholder={isSignUp ? 'Create a secure password' : 'Enter your password'}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute inset-y-0 right-0 px-3 flex items-center text-white/60 hover:text-white"
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  {isSignUp && (
                    <p className="mt-2 text-sm text-white/60">
                      Password must be at least 6 characters and contain uppercase, lowercase, and numbers
                    </p>
                  )}
                </div>
              )}

              <div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full glass-button py-3 rounded-lg text-base font-medium flex items-center justify-center gap-2"
                >
                  {loading ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent" />
                      {isForgotPassword ? 'Sending...' : isSignUp ? 'Creating account...' : 'Signing in...'}
                    </>
                  ) : (
                    <>
                      <Shield className="h-4 w-4" />
                      {isForgotPassword ? 'Send Reset Instructions' : isSignUp ? 'Create account' : 'Sign in'}
                    </>
                  )}
                </button>
              </div>

              <div className="flex flex-col space-y-2 text-center text-sm">
                {!isForgotPassword && (
                  <button
                    type="button"
                    onClick={() => toggleMode(isSignUp ? 'signin' : 'signup')}
                    className="text-white/60 hover:text-white font-medium transition-colors"
                  >
                    {isSignUp ? 'Already have an account? Sign in' : 'Need an account? Sign up'}
                  </button>
                )}
                <button
                  type="button"
                  onClick={() => toggleMode(isForgotPassword ? 'signin' : 'forgot')}
                  className="text-white/60 hover:text-white transition-colors"
                >
                  {isForgotPassword ? 'Back to sign in' : 'Forgot your password?'}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}