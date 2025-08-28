'use client';

import { useState, useEffect } from 'react';
import { ConnectButton, useCurrentAccount, useSuiClient } from '@mysten/dapp-kit';

interface WalletConnectionProps {
  refreshKey?: number;
}

export function WalletConnection({ refreshKey = 0 }: WalletConnectionProps) {
  const currentAccount = useCurrentAccount();
  const client = useSuiClient();
  const [balance, setBalance] = useState<string>('');
  const [isLoadingBalance, setIsLoadingBalance] = useState(false);

  // Fetch SUI balance when account is connected
  useEffect(() => {
    const fetchBalance = async () => {
      if (!currentAccount) {
        setBalance('');
        return;
      }

      setIsLoadingBalance(true);
      try {
        const balanceResult = await client.getBalance({
          owner: currentAccount.address,
          coinType: '0x2::sui::SUI',
        });

        // Convert from MIST to SUI (divide by 1 billion)
        const suiBalance = (parseInt(balanceResult.totalBalance) / 1_000_000_000).toFixed(4);
        setBalance(suiBalance);
      } catch (error) {
        console.error('Error fetching balance:', error);
        setBalance('Error');
      } finally {
        setIsLoadingBalance(false);
      }
    };

    fetchBalance();
  }, [currentAccount, client, refreshKey]);

  return (
    <div className="glass rounded-xl p-6 mb-6 lift">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold mb-2">
            {currentAccount ? 'Wallet Connected' : 'Connect Wallet'}
          </h3>
          {currentAccount ? (
            <div className="space-y-1">
              <p className="text-sm text-white/80">
                Address: {currentAccount.address.slice(0, 8)}...{currentAccount.address.slice(-6)}
              </p>
              <p className="text-sm font-medium bg-gradient-to-r from-sky-300 to-indigo-300 bg-clip-text text-transparent">
                Balance: {isLoadingBalance ? 'Loading...' : `${balance} SUI`}
              </p>
            </div>
          ) : (
            <p className="text-white/80">
              Connect your Sui wallet to send tips with gas-free transactions.
            </p>
          )}
        </div>
        <div className="flex items-center">
          <ConnectButton />
        </div>
      </div>
    </div>
  );
}