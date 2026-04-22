'use client';

import React from 'react';
import Link from 'next/link';

export default function InitialPage() {
  return (
    <>
      <div style={{
        minHeight: '100vh',
        background: '#000',
        color: '#fff',
        fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '24px'
      }}>
        <div style={{
          width: '80px',
          height: '80px',
          background: '#CCFF00',
          borderRadius: '16px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          marginBottom: '32px',
          transform: 'rotate(12deg)'
        }}>
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#000" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M6.5 6.5h11M6.5 17.5h11M3 10v4M21 10v4M5 8v8M19 8v8" />
          </svg>
        </div>

        <h1 style={{ fontSize: '48px', fontWeight: '900', letterSpacing: '-0.02em', marginBottom: '16px' }}>
          TITAN ENGINE
        </h1>

        <p style={{ fontSize: '18px', color: '#a3a3a3', marginBottom: '48px', lineHeight: '1.6', maxWidth: '400px', textAlign: 'center' }}>
          Sistema de treinamento bio-adaptativo com prescrição científica, periodização DUP e controle real de fadiga.
        </p>

        <Link href="/treino/index.html" style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '12px',
          padding: '16px 32px',
          background: '#CCFF00',
          color: '#000',
          fontWeight: '900',
          borderRadius: '16px',
          fontSize: '18px',
          textDecoration: 'none',
          transition: 'transform 0.2s'
        }}>
          ENTRAR
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 12h14M12 5l7 7-7 7" />
          </svg>
        </Link>
      </div>

      <footer style={{ padding: '32px', textAlign: 'center' }}>
        <p style={{ color: '#525252', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.1em', fontWeight: '900' }}>
          © 2026 Titan Engine
        </p>
      </footer>
    </>
  );
}