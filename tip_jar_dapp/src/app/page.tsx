'use client';

import { useState } from 'react';
import { WalletConnection } from '@/components/WalletConnection';
import { GratuityBox } from '@/components/GratuityBox';

export default function Home() {
  const [refreshKey, setRefreshKey] = useState(0);

  const handleTipSuccess = () => {
    setRefreshKey((prev) => prev + 1);
  };

  return (
    <div className="relative min-h-screen overflow-hidden">
      {/* Animated aurora background */}
      <div className="absolute inset-0 bg-aurora" />
      {/* Decorative gradient blobs */}
      <div className="pointer-events-none absolute -top-24 -left-24 h-72 w-72 rounded-full blur-3xl opacity-40"
           style={{ background: 'radial-gradient(circle at 30% 30%, #60a5fa 0%, transparent 60%)', animation: 'float 8s ease-in-out infinite' }}
      />
      <div className="pointer-events-none absolute -bottom-24 -right-24 h-80 w-80 rounded-full blur-3xl opacity-40"
           style={{ background: 'radial-gradient(circle at 70% 70%, #f472b6 0%, transparent 60%)', animation: 'float 10s ease-in-out infinite' }}
      />
      {/* Subtle grid overlay */}
      <div className="grid-overlay" />

      <main className="relative z-10 py-14">
        <div className="mx-auto max-w-3xl px-4">
          {/* Hero */}
          <div className="text-center mb-10 fade-up">
            <div className="inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs border border-white/20 glass">
              <span className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
              Gas-free tips powered by Enoki
            </div>
            <h1 className="mt-4 text-5xl font-extrabold tracking-tight">
              <span className="bg-gradient-to-r from-sky-400 via-indigo-400 to-pink-400 bg-clip-text text-transparent">
                Gratuity Box
              </span>
            </h1>
            <p className="mt-3 text-base text-white/80 max-w-xl mx-auto">
              Send and celebrate tips on Sui with a polished, dynamic experience.
            </p>
          </div>

          {/* Cards */}
          <div className="space-y-6">
            <WalletConnection refreshKey={refreshKey} />
            <GratuityBox refreshKey={refreshKey} onGratuitySuccess={handleTipSuccess} />
          </div>

          {/* Footer */}
          <footer className="mt-12 text-center text-sm text-white/70">
            <p>Built on Sui • Sponsored by Enoki</p>
            <div className="mt-2 space-x-4">
              <a
                href="https://docs.sui.io"
                target="_blank"
                rel="noopener noreferrer"
                className="hover:text-sky-300 transition-colors"
              >
                Sui Docs
              </a>
              <a
                href="https://docs.enoki.mystenlabs.com"
                target="_blank"
                rel="noopener noreferrer"
                className="hover:text-sky-300 transition-colors"
              >
                Enoki Docs
              </a>
            </div>
          </footer>
        </div>
      </main>
    </div>
  );
}
