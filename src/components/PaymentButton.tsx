import React, { useState } from 'react';
import { CreditCard, Copy, CheckCircle2, X } from 'lucide-react';

interface PaymentButtonProps {
  amount: number;
  entryId: string;
  entryNumber: string;
}

export default function PaymentButton({ amount, entryNumber }: PaymentButtonProps) {
  const [showModal, setShowModal] = useState(false);
  const [copied, setCopied] = useState<string | null>(null);

  const bankDetails = {
    iban: 'NL74REVO1017283168',
    bic: 'NL74REVO1017283168',
    recipient: 'Motif Labs',
    reference: entryNumber
  };

  const copyToClipboard = async (text: string, field: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(field);
      setTimeout(() => setCopied(null), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  return (
    <>
      <button
        onClick={() => setShowModal(true)}
        className="glass-button px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2"
      >
        <CreditCard className="w-4 h-4" />
        Pay €{amount.toFixed(2)}
      </button>

      {showModal && (
        <div className="fixed inset-0 flex items-center justify-center z-50">
          {/* Backdrop */}
          <div 
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setShowModal(false)}
          />

          {/* Modal */}
          <div className="relative z-10 w-full max-w-lg">
            <div className="glass-card m-4 rounded-xl overflow-hidden border border-white/10">
              {/* Header */}
              <div className="bg-gradient-to-r from-black to-pikamon-dark-hover p-6 border-b border-white/10 flex justify-between items-center">
                <h3 className="text-lg font-semibold text-white">Bank Transfer Details</h3>
                <button
                  onClick={() => setShowModal(false)}
                  className="text-white/60 hover:text-white transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Content */}
              <div className="p-6 space-y-6">
                {/* Amount */}
                <div className="text-center">
                  <div className="text-sm text-white/60 mb-1">Amount Due</div>
                  <div className="text-2xl font-bold text-white">€{amount.toFixed(2)}</div>
                </div>

                {/* Bank Details */}
                <div className="space-y-4">
                  <div className="glass-effect rounded-lg p-4">
                    <label className="block text-sm text-white/60 mb-2">IBAN</label>
                    <div className="flex items-center justify-between bg-black/20 rounded-lg p-3">
                      <span className="text-white font-medium">{bankDetails.iban}</span>
                      <button
                        onClick={() => copyToClipboard(bankDetails.iban, 'iban')}
                        className="text-white/60 hover:text-white transition-colors"
                      >
                        {copied === 'iban' ? (
                          <CheckCircle2 className="w-5 h-5 text-green-400" />
                        ) : (
                          <Copy className="w-5 h-5" />
                        )}
                      </button>
                    </div>
                  </div>

                  <div className="glass-effect rounded-lg p-4">
                    <label className="block text-sm text-white/60 mb-2">BIC</label>
                    <div className="flex items-center justify-between bg-black/20 rounded-lg p-3">
                      <span className="text-white font-medium">{bankDetails.bic}</span>
                      <button
                        onClick={() => copyToClipboard(bankDetails.bic, 'bic')}
                        className="text-white/60 hover:text-white transition-colors"
                      >
                        {copied === 'bic' ? (
                          <CheckCircle2 className="w-5 h-5 text-green-400" />
                        ) : (
                          <Copy className="w-5 h-5" />
                        )}
                      </button>
                    </div>
                  </div>

                  <div className="glass-effect rounded-lg p-4">
                    <label className="block text-sm text-white/60 mb-2">Recipient</label>
                    <div className="flex items-center justify-between bg-black/20 rounded-lg p-3">
                      <span className="text-white font-medium">{bankDetails.recipient}</span>
                      <button
                        onClick={() => copyToClipboard(bankDetails.recipient, 'recipient')}
                        className="text-white/60 hover:text-white transition-colors"
                      >
                        {copied === 'recipient' ? (
                          <CheckCircle2 className="w-5 h-5 text-green-400" />
                        ) : (
                          <Copy className="w-5 h-5" />
                        )}
                      </button>
                    </div>
                  </div>

                  <div className="glass-effect rounded-lg p-4">
                    <label className="block text-sm text-white/60 mb-2">
                      Reference Number (Required)
                    </label>
                    <div className="flex items-center justify-between bg-black/20 rounded-lg p-3">
                      <span className="text-white font-medium">{bankDetails.reference}</span>
                      <button
                        onClick={() => copyToClipboard(bankDetails.reference, 'reference')}
                        className="text-white/60 hover:text-white transition-colors"
                      >
                        {copied === 'reference' ? (
                          <CheckCircle2 className="w-5 h-5 text-green-400" />
                        ) : (
                          <Copy className="w-5 h-5" />
                        )}
                      </button>
                    </div>
                  </div>
                </div>

                {/* Instructions */}
                <div className="bg-white/5 rounded-lg p-4 text-sm text-white/60">
                  <p>
                    Please include the reference number in your transfer description to ensure proper processing of your payment.
                    Once we receive your payment, we will update the status of your grading entry accordingly.
                  </p>
                </div>
              </div>

              {/* Footer */}
              <div className="border-t border-white/10 p-6">
                <button
                  onClick={() => setShowModal(false)}
                  className="w-full glass-button py-3 rounded-lg text-base font-medium"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}