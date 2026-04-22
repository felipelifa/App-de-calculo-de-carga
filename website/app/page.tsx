'use client';

import React from 'react';
import Link from 'next/link';
import { Dumbbell, ChevronRight } from 'lucide-react';

export default function InitialPage() {
  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#000', color: '#fff', display: 'flex', flexDirection: 'column' }}>
      <main style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '24px' }}>
        <div style={{ textAlign: 'center', maxWidth: '400px' }}>
          <div style={{ 
            width: '80px', 
            height: '80px', 
            backgroundColor: '#CCFF00', 
            borderRadius: '16px', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            margin: '0 auto 32px',
            transform: 'rotate(12deg)'
          }}>
            <Dumbbell style={{ width: '40px', height: '40px', color: '#000', transform: 'rotate(-12deg)' }} />
          </div>

          <h1 style={{ fontSize: '48px', fontWeight: '900', letterSpacing: '-0.02em', marginBottom: '16px' }}>
            TITAN ENGINE
          </h1>

          <p style={{ fontSize: '18px', color: '#a3a3a3', marginBottom: '48px', lineHeight: '1.6' }}>
            Sistema de treinamento bio-adaptativo com prescrição científica,
            periodização DUP e controle real de fadiga.
          </p>

          <Link
            href="/treino/index.html"
            style={{ 
              display: 'inline-flex', 
              alignItems: 'center', 
              gap: '12px',
              padding: '16px 32px',
              backgroundColor: '#CCFF00',
              color: '#000',
              fontWeight: '900',
              borderRadius: '16px',
              fontSize: '18px',
              textDecoration: 'none'
            }}
          >
            ENTRAR
            <ChevronRight style={{ width: '20px', height: '20px' }} />
          </Link>
        </div>
      </main>

      <footer style={{ padding: '32px', textAlign: 'center' }}>
        <p style={{ color: '#525252', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.1em', fontWeight: '900' }}>
          © 2026 Titan Engine
        </p>
      </footer>
    </div>
  );
}