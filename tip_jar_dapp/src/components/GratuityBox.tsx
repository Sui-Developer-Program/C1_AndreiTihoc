'use client';

import { useState, useEffect } from 'react';
import { useSuiClient, useCurrentAccount } from '@mysten/dapp-kit';
import { Transaction } from '@mysten/sui/transactions';
import { useSponsoredTransaction } from '@/hooks/useSponsoredTransaction';

const PACKAGE_ID = process.env.NEXT_PUBLIC_PACKAGE_ID || '0x0';
// Prefer new env var but fall back to the old one for compatibility
const VAULT_ID = process.env.NEXT_PUBLIC_VAULT_ID || process.env.NEXT_PUBLIC_TIP_JAR_ID || '0x0';

interface VaultStats {
  owner: string;
  totalGratuities: string;
  gratuityCount: string;
  lastTipper: string;
}

interface GratuityBoxProps {
  refreshKey?: number;
  onGratuitySuccess?: () => void;
}

export function GratuityBox({ refreshKey = 0, onGratuitySuccess }: GratuityBoxProps) {
  const [amount, setAmount] = useState('');
  const [stats, setStats] = useState<VaultStats | null>(null);

  const { executeSponsoredTransaction, isLoading } = useSponsoredTransaction();
  const client = useSuiClient();
  const currentAccount = useCurrentAccount();

  // Fetch vault statistics
  useEffect(() => {
    const fetchStats = async () => {
      if (!VAULT_ID || VAULT_ID === '0x0') return;

      try {
        const obj = await client.getObject({
          id: VAULT_ID,
          options: {
            showContent: true,
          },
        });

        if (obj.data?.content && 'fields' in obj.data.content) {
          const fields = obj.data.content.fields as Record<string, unknown>;
          setStats({
            owner: String(fields.owner || ''),
            totalGratuities: String(fields.total_gratuities || '0'),
            gratuityCount: String(fields.gratuity_count || '0'),
            lastTipper: String(fields.last_tipper || ''),
          });
        }
      } catch (error) {
        console.error('Error fetching vault stats:', error);
      }
    };

    fetchStats();
  }, [client, refreshKey]);

  const sendGratuity = async () => {
    if (!currentAccount || !amount || !PACKAGE_ID || !VAULT_ID) {
      alert('Connect wallet, enter amount, and set PACKAGE_ID/VAULT_ID');
      return;
    }

    const mist = Math.floor(parseFloat(amount) * 1_000_000_000);
    if (mist <= 0) {
      alert('Enter a valid amount');
      return;
    }

    try {
      const tx = new Transaction();

      // Get user's SUI coins
      const coins = await client.getCoins({
        owner: currentAccount.address,
        coinType: '0x2::sui::SUI',
      });

      if (!coins.data.length) {
        alert('No SUI coins found');
        return;
      }

      // Pick a coin with sufficient balance or the largest one
      let selected = coins.data[0];
      for (const c of coins.data) {
        if (parseInt(c.balance) >= mist) { selected = c; break; }
        if (parseInt(c.balance) > parseInt(selected.balance)) selected = c;
      }

      if (parseInt(selected.balance) < mist) {
        alert(`Insufficient balance. Need ${amount} SUI, largest coin has ${(parseInt(selected.balance) / 1_000_000_000).toFixed(4)} SUI`);
        return;
      }

      const [pay] = tx.splitCoins(tx.object(selected.coinObjectId), [mist]);

      // Call the new function
      tx.moveCall({
        target: `${PACKAGE_ID}::gratuity_box::deposit_gratuity`,
        arguments: [
          tx.object(VAULT_ID),
          pay,
        ],
      });

      await executeSponsoredTransaction(tx, {
        onSuccess: (result) => {
          console.log('Gratuity sent successfully:', result);
          alert(`Sent ${amount} SUI (gas-free)`);
          setAmount('');
          onGratuitySuccess?.();
        },
        onError: (error) => {
          console.error('Error sending gratuity:', error);
          const msg = error instanceof Error ? error.message : String(error);
          alert(`Error: ${msg}`);
        },
      });
    } catch (error) {
      console.error('Error creating transaction:', error);
      alert('Error creating transaction. Please try again.');
    }
  };

  if (!currentAccount) {
    return (
      <div className="glass rounded-xl p-6 lift">
        <div className="flex items-center gap-2 mb-1 text-xs text-emerald-300">
          <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />
          Gas-free enabled
        </div>
        <h2 className="text-2xl font-bold mb-2">💰 Gratuity Box</h2>
        <p className="text-white/80">Connect your wallet to send a gratuity.</p>
      </div>
    );
  }

  return (
    <div className="glass rounded-xl p-6 lift">
      <div className="flex items-center gap-2 mb-4 text-xs text-emerald-300">
        <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />
        Gas-free enabled
      </div>
      <h2 className="text-2xl font-bold mb-6">💰 Gratuity Box</h2>

      {stats && (
        <div className="rounded-lg p-4 mb-6 border border-white/10 bg-white/5">
          <h3 className="text-lg font-semibold mb-3">Statistics</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center">
              <p className="text-2xl font-extrabold bg-gradient-to-r from-sky-300 to-indigo-300 bg-clip-text text-transparent">
                {(parseInt(stats.totalGratuities) / 1_000_000_000).toFixed(3)}
              </p>
              <p className="text-sm text-white/70">Total SUI Received</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-extrabold bg-gradient-to-r from-emerald-300 to-teal-300 bg-clip-text text-transparent">{stats.gratuityCount}</p>
              <p className="text-sm text-white/70">Gratuities</p>
            </div>
            <div className="text-center">
              <p className="text-xs text-white/60 break-all">
                Owner: {stats.owner.slice(0, 8)}...{stats.owner.slice(-6)}
              </p>
              {stats.lastTipper && (
                <p className="text-xs text-white/60 break-all mt-1">
                  Last tipper: {stats.lastTipper.slice(0, 8)}...{stats.lastTipper.slice(-6)}
                </p>
              )}
            </div>
          </div>
        </div>
      )}

      <div className="space-y-4">
        <div>
          <label htmlFor="gratuity-amount" className="block text-sm font-medium text-white/80 mb-1">
            Amount (SUI)
          </label>
          <input
            type="number"
            id="gratuity-amount"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="w-full px-3 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-sky-400 text-white/90 placeholder-white/40 border border-white/20 bg-white/10"
            placeholder="0.1"
            step="0.001"
            min="0"
            disabled={isLoading}
          />
        </div>

        <div className="flex items-center justify-center gap-2 text-xs text-emerald-300 border border-emerald-400/20 py-2 px-3 rounded-md bg-emerald-400/10">
          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
          </svg>
          <span>Gas-Free Transaction via Enoki</span>
        </div>

        <button
          onClick={sendGratuity}
          disabled={isLoading || !amount || parseFloat(amount) <= 0}
          className="w-full text-white py-2 px-4 rounded-md disabled:bg-white/20 disabled:cursor-not-allowed transition-all bg-gradient-to-r from-sky-500 to-indigo-500 hover:from-sky-400 hover:to-indigo-400"
        >
          {isLoading ? 'Sending (Gas-Free)...' : 'Send Gratuity (Free)'}
        </button>
      </div>

      <div className="mt-6 rounded-lg p-4 border border-white/10 bg-white/5">
        <h3 className="text-sm font-semibold mb-2">How it works</h3>
        <ul className="text-sm text-white/80 space-y-1">
          <li>• Enter the amount you want to send in SUI</li>
          <li>• Click "Send Gratuity"</li>
          <li>• Transactions are sponsored (gas-free) via Enoki</li>
          <li>• Funds go directly to the vault owner</li>
        </ul>
      </div>
    </div>
  );
}
