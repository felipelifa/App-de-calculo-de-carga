'use client';

import Link from 'next/link';

// Cores do tema Neo-Tactile
const bg = '#0A0A0F';
const surface = '#181822';
const surfaceH = '#232332';
const accent = '#3B82FF';
const accentV = '#2563EB';
const success = '#22C55E';
const danger = '#EF4444';
const textP = '#F3F4F6';
const textS = '#9CA3AF';

export default function Home() {
  return (
    <main style={{ background: bg, minHeight: '100vh' }}>
      {/* NAV */}
      <nav style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '20px 40px', maxWidth: 1200, margin: '0 auto',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: `linear-gradient(135deg, ${accent}, ${accentV})`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5">
              <path d="M6.5 6.5h11M6.5 17.5h11M12 6.5v11" strokeLinecap="round"/>
            </svg>
          </div>
          <span style={{ fontSize: 20, fontWeight: 800, color: textP }}>Controle de Carga</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <a href="#features" style={{ color: textS, textDecoration: 'none', fontSize: 14, fontWeight: 500 }}>Recursos</a>
          <a href="#download" style={{ color: textS, textDecoration: 'none', fontSize: 14, fontWeight: 500 }}>Download</a>
          <a href="#science" style={{ color: textS, textDecoration: 'none', fontSize: 14, fontWeight: 500 }}>Ciência</a>
          <Link href="/app/index.html" style={{
            background: accent,
            color: 'white',
            padding: '8px 20px',
            borderRadius: 8,
            textDecoration: 'none',
            fontSize: 14,
            fontWeight: 600,
            display: 'flex',
            alignItems: 'center',
            gap: 6,
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4M10 17l5-5-5-5M15 12H3" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            Entrar
          </Link>
        </div>
      </nav>

      {/* HERO */}
      <section style={{
        display: 'flex', flexDirection: 'column', alignItems: 'center',
        textAlign: 'center', padding: '80px 20px 60px',
      }}>
        <div className="animate-in" style={{
          display: 'inline-flex', alignItems: 'center', gap: 8,
          background: surfaceH, borderRadius: 100, padding: '6px 16px',
          marginBottom: 24, fontSize: 13, color: accent, fontWeight: 600,
        }}>
          <span style={{ width: 6, height: 6, borderRadius: '50%', background: success }}></span>
          Treino inteligente baseado em ciência
        </div>

        <h1 className="animate-in delay-1" style={{
          fontSize: 'clamp(36px, 6vw, 64px)', fontWeight: 800, lineHeight: 1.1,
          maxWidth: 700, color: textP, marginBottom: 20,
        }}>
          Seu treino com{' '}
          <span style={{
            background: `linear-gradient(135deg, ${accent}, #6366F1)`,
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
          }}>
            periodização DUP
          </span>
        </h1>

        <p className="animate-in delay-2" style={{
          fontSize: 18, color: textS, maxWidth: 560, marginBottom: 40, lineHeight: 1.6,
        }}>
          Prescrição automática que alterna força, hipertrofia e resistência.
          Rotação inteligente de exercícios. Progressão real por RIR.
          Tudo baseado em Schoenfeld, Israetel e Bompa.
        </p>

        <div className="animate-in delay-3" style={{ display: 'flex', gap: 16, flexWrap: 'wrap', justifyContent: 'center' }}>
          <a href="#download" style={{
            background: accent, color: 'white', padding: '14px 32px',
            borderRadius: 12, textDecoration: 'none', fontWeight: 700, fontSize: 16,
            boxShadow: `0 0 30px ${accent}40`,
          }}>
            Baixar APK Grátis
          </a>
          <a href="#features" style={{
            background: surface, color: textP, padding: '14px 32px',
            borderRadius: 12, textDecoration: 'none', fontWeight: 600, fontSize: 16,
            border: `1px solid ${surfaceH}`,
          }}>
            Ver Recursos
          </a>
        </div>

        {/* Stats */}
        <div className="animate-in delay-4" style={{
          display: 'flex', gap: 48, marginTop: 60, flexWrap: 'wrap', justifyContent: 'center',
        }}>
          <Stat num="80+" label="Exercícios" />
          <Stat num="6" label="Divisões" />
          <Stat num="DUP" label="Periodização" />
          <Stat num="RIR" label="Progressão" />
        </div>
      </section>

      {/* FEATURES */}
      <section id="features" style={{ padding: '60px 20px', maxWidth: 1200, margin: '0 auto' }}>
        <h2 className="animate-in" style={{
          textAlign: 'center', fontSize: 36, fontWeight: 800,
          marginBottom: 12, color: textP,
        }}>
          Recursos que fazem diferença
        </h2>
        <p className="animate-in delay-1" style={{
          textAlign: 'center', color: textS, marginBottom: 48, fontSize: 16, maxWidth: 500, margin: '0 auto 48px',
        }}>
          Não é só um timer de treino. É um sistema completo de prescrição e progressão.
        </p>

        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
          gap: 20,
        }}>
          <FeatureCard
            icon="🎯"
            title="Prescrição Inteligente"
            desc="Motor DUP: alterna sessões de força (4×6), hipertrofia (3×10) e resistência (2×15) automaticamente baseado no seu nível e objetivo."
          />
          <FeatureCard
            icon="📈"
            title="Progressão por RIR"
            desc="Baseado em Schoenfeld 2021: aumento de carga quando RIR ≥ 3, consolidar quando 1-2, reduzir 10% quando falha por 2 sessões."
          />
          <FeatureCard
            icon="🔄"
            title="Rotação Semanal"
            desc="1-2 exercícios trocados por semana para estimular ângulos diferentes. Não troca favoritos. Evita platô de adaptação."
          />
          <FeatureCard
            icon="🛡️"
            title="Controle de Fadiga"
            desc="Acumulador de fadiga multiarticular: previne sobrecarga lombar, ombros e joelhos durante montagem da sessão."
          />
          <FeatureCard
            icon="🏥"
            title="Reabilitação"
            desc="Filtro de lesões: remove exercícios agravantes e injeta bloco de reabilitação para ombro, joelho, lombar, punho e cotovelo."
          />
          <FeatureCard
            icon="📊"
            title="Analytics Avançado"
            desc="Gráficos de volume por músculo, progressão de carga, histórico de sessões e detecção automática de recordes pessoais."
          />
        </div>
      </section>

      {/* SCIENCE SECTION */}
      <section id="science" style={{
        padding: '60px 20px', maxWidth: 1200, margin: '0 auto',
        borderTop: `1px solid ${surfaceH}`,
      }}>
        <h2 className="animate-in" style={{
          textAlign: 'center', fontSize: 36, fontWeight: 800,
          marginBottom: 48, color: textP,
        }}>
          Baseado em ciência, não em achismo
        </h2>
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 24,
        }}>
          <RefCard
            tag="Volume"
            title="Israetel — MEV/MAV/MRV"
            desc="Faixas de volume semanal calibradas por nível de experiência e capacidade de recuperação."
          />
          <RefCard
            tag="Progressão"
            title="Schoenfeld 2021 — IUSCA"
            desc="Variação de posição alongada vs encurtada, rotação de exercícios e tabela de decisão por RIR."
          />
          <RefCard
            tag="Periodização"
            title="Bompa 2015 — Periodization"
            desc="Estrutura de mesociclos com fases de acumulação, intensificação, pico e deload."
          />
          <RefCard
            tag="Lesões"
            title="Murer 2019 / Doral 2012"
            desc="Regras de proporção push:pull, limite de isoladores para iniciantes e adaptações por restrição."
          />
        </div>
      </section>

      {/* DOWNLOAD */}
      <section id="download" style={{
        padding: '80px 20px', textAlign: 'center',
        borderTop: `1px solid ${surfaceH}`,
      }}>
        <div className="animate-in">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke={accent} strokeWidth="2" style={{ marginBottom: 24 }}>
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <h2 className="animate-in delay-1" style={{
          fontSize: 36, fontWeight: 800, marginBottom: 12, color: textP,
        }}>
          Baixe o app
        </h2>
        <p className="animate-in delay-2" style={{
          color: textS, fontSize: 16, maxWidth: 450, margin: '0 auto 32px',
        }}>
          Android APK — instalação direta, sem loja de aplicativos.
        </p>
        <div className="animate-in delay-3" style={{ display: 'flex', gap: 16, justifyContent: 'center' }}>
          <a
            href="/download/apk"
            download
            style={{
              background: accent, color: 'white', padding: '14px 32px',
              borderRadius: 12, textDecoration: 'none', fontWeight: 700, fontSize: 16,
              boxShadow: `0 0 30px ${accent}40`,
            }}
          >
            Download APK (v1.0.0)
          </a>
          <a
            href="/app/index.html"
            style={{
              background: surface, color: textP, padding: '14px 32px',
              borderRadius: 12, textDecoration: 'none', fontWeight: 600, fontSize: 16,
              border: `1px solid ${surfaceH}`,
            }}
          >
            Usar no Navegador
          </a>
        </div>
        <p className="animate-in delay-4" style={{
          color: textS, fontSize: 13, marginTop: 16,
        }}>
          Requer Android 9+. Permissão "fontes desconhecidas" pode ser necessária.
        </p>
      </section>

      {/* FOOTER */}
      <footer style={{
        padding: '24px 20px', borderTop: `1px solid ${surfaceH}`,
        textAlign: 'center', color: textS, fontSize: 13,
      }}>
        Controle de Carga — App de treino inteligente. Feito com ciência e dedicação.
      </footer>
    </main>
  );
}

function Stat({ num, label }: { num: string; label: string }) {
  return (
    <div style={{ textAlign: 'center' }}>
      <div style={{ fontSize: 32, fontWeight: 800, color: accent }}>{num}</div>
      <div style={{ color: textS, fontSize: 14, marginTop: 4 }}>{label}</div>
    </div>
  );
}

function FeatureCard({ icon, title, desc }: { icon: string; title: string; desc: string }) {
  return (
    <div className="animate-in" style={{
      background: surface, borderRadius: 16, padding: 24,
      border: `1px solid ${surfaceH}`, transition: 'border-color 0.2s',
    }}>
      <div style={{ fontSize: 32, marginBottom: 12 }}>{icon}</div>
      <h3 style={{ fontSize: 18, fontWeight: 700, marginBottom: 8, color: textP }}>{title}</h3>
      <p style={{ fontSize: 14, color: textS, lineHeight: 1.6 }}>{desc}</p>
    </div>
  );
}

function RefCard({ tag, title, desc }: { tag: string; title: string; desc: string }) {
  return (
    <div className="animate-in" style={{
      background: surfaceH, borderRadius: 14, padding: 20,
      border: `1px solid #333344`,
    }}>
      <span style={{
        fontSize: 11, fontWeight: 700, color: accent, textTransform: 'uppercase',
        letterSpacing: 1, marginBottom: 8, display: 'block',
      }}>{tag}</span>
      <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 8, color: textP }}>{title}</h3>
      <p style={{ fontSize: 13, color: textS, lineHeight: 1.6 }}>{desc}</p>
    </div>
  );
}
