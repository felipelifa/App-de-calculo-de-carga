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
        {/* Logo */}
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

        {/* Title */}
        <h1 style={{ fontSize: '48px', fontWeight: '900', letterSpacing: '-0.02em', marginBottom: '16px', textAlign: 'center' }}>
          BUILD FIT
        </h1>

        <p style={{ fontSize: '18px', color: '#a3a3a3', marginBottom: '48px', lineHeight: '1.6', maxWidth: '400px', textAlign: 'center' }}>
          Sistema de treinamento bio-adaptativo com prescrição inteligente, periodização DUP e controle real de carga.
        </p>

        {/* Download Buttons */}
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '16px',
          width: '100%',
          maxWidth: '320px',
          marginBottom: '32px'
        }}>
          {/* Android Download */}
          <a
            href="/download/apk.apk"
            download="BuildFit.apk"
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '12px',
              padding: '16px 24px',
              background: '#CCFF00',
              color: '#000',
              fontWeight: '900',
              borderRadius: '16px',
              fontSize: '16px',
              textDecoration: 'none',
              transition: 'transform 0.2s, opacity 0.2s',
              cursor: 'pointer'
            }}
            onMouseOver={(e) => {
              e.currentTarget.style.transform = 'scale(1.02)';
              e.currentTarget.style.opacity = '0.9';
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.transform = 'scale(1)';
              e.currentTarget.style.opacity = '1';
            }}
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M17.523 2.237l1.586 2.747a.5.5 0 0 1-.866.5l-1.61-2.79A10.017 10.017 0 0 0 12 1.5a10.017 10.017 0 0 0-4.633 1.194l-1.61-2.79a.5.5 0 0 1 .866-.5l1.586 2.747A9.93 9.93 0 0 1 12 1c1.468 0 2.86.317 4.113.893L17.523 2.237zM5.5 22V9h13v13h-2v2.5a1 1 0 0 1-2 0V22h-5v2.5a1 1 0 0 1-2 0V22h-2zm-3-13v9a1 1 0 0 0 2 0V9a1 1 0 0 0-2 0zm17 0v9a1 1 0 0 0 2 0V9a1 1 0 0 0-2 0z"/>
            </svg>
            Download para Android
          </a>

          {/* iOS Download */}
          <a
            href="#"
            onClick={(e) => {
              e.preventDefault();
              alert('Em breve na App Store! Estamos aguardando aprovação da Apple.');
            }}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '12px',
              padding: '16px 24px',
              background: '#fff',
              color: '#000',
              fontWeight: '900',
              borderRadius: '16px',
              fontSize: '16px',
              textDecoration: 'none',
              transition: 'transform 0.2s, opacity 0.2s',
              cursor: 'pointer'
            }}
            onMouseOver={(e) => {
              e.currentTarget.style.transform = 'scale(1.02)';
              e.currentTarget.style.opacity = '0.9';
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.transform = 'scale(1)';
              e.currentTarget.style.opacity = '1';
            }}
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
            </svg>
            Download para iOS
          </a>

          {/* Web App */}
          <a href="/treino/" style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '12px',
            padding: '16px 24px',
            background: 'transparent',
            color: '#fff',
            fontWeight: '700',
            borderRadius: '16px',
            fontSize: '16px',
            textDecoration: 'none',
            border: '2px solid #333',
            transition: 'transform 0.2s, border-color 0.2s',
            cursor: 'pointer'
          }}
            onMouseOver={(e) => {
              e.currentTarget.style.transform = 'scale(1.02)';
              e.currentTarget.style.borderColor = '#CCFF00';
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.transform = 'scale(1)';
              e.currentTarget.style.borderColor = '#333';
            }}
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="10"/>
              <line x1="2" y1="12" x2="22" y2="12"/>
              <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
            </svg>
            Acessar na Web
          </a>
        </div>

        {/* Features */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))',
          gap: '16px',
          width: '100%',
          maxWidth: '600px',
          marginBottom: '48px'
        }}>
          {[
            { icon: '🏋️', title: 'Prescrição', desc: 'Treinos personalizados' },
            { icon: '📊', title: 'Analytics', desc: 'Gráficos de progresso' },
            { icon: '🍎', title: 'Nutrição', desc: 'Bio-gestão adaptativa' },
            { icon: '⚡', title: 'Progressão', desc: 'Carga automática' },
          ].map((feature, i) => (
            <div key={i} style={{
              background: '#111',
              borderRadius: '16px',
              padding: '20px 16px',
              textAlign: 'center',
              border: '1px solid #222'
            }}>
              <div style={{ fontSize: '28px', marginBottom: '8px' }}>{feature.icon}</div>
              <div style={{ fontWeight: '700', fontSize: '14px', marginBottom: '4px' }}>{feature.title}</div>
              <div style={{ color: '#666', fontSize: '12px' }}>{feature.desc}</div>
            </div>
          ))}
        </div>

        {/* Version */}
        <p style={{ color: '#333', fontSize: '12px', marginTop: '16px' }}>
          v1.0.0 • Android & iOS
        </p>
      </div>

      <footer style={{ padding: '32px', textAlign: 'center', background: '#000' }}>
        <p style={{ color: '#525252', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.1em', fontWeight: '900' }}>
          © 2026 Build Fit
        </p>
      </footer>
    </>
  );
}
