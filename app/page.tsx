'use client';

import React, { useState, useEffect } from 'react';

export default function LandingPage() {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    setIsVisible(true);
  }, []);

  return (
    <div className="min-h-screen bg-black text-white font-['Outfit']">
      {/* Hero Section */}
      <section className="relative min-h-screen flex flex-col items-center justify-center px-6 py-20">
        {/* Background gradient */}
        <div className="absolute inset-0 bg-gradient-to-b from-neon/5 to-transparent pointer-events-none" />
        
        {/* Logo */}
        <div 
          className={`w-20 h-20 bg-neon rounded-2xl flex items-center justify-center mb-8 transform rotate-12 transition-all duration-700 ${isVisible ? 'scale-100 opacity-100' : 'scale-50 opacity-0'}`}
        >
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#000" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M6.5 6.5h11M6.5 17.5h11M3 10v4M21 10v4M5 8v8M19 8v8" />
          </svg>
        </div>

        {/* Title */}
        <h1 
          className={`text-5xl md:text-7xl font-black tracking-tight text-center mb-6 transition-all duration-700 delay-200 ${isVisible ? 'translate-y-0 opacity-100' : 'translate-y-10 opacity-0'}`}
        >
          BUILD<span className="text-neon">FIT</span>
        </h1>

        {/* Subtitle */}
        <p 
          className={`text-lg md:text-xl text-gray-400 max-w-2xl text-center mb-12 leading-relaxed transition-all duration-700 delay-300 ${isVisible ? 'translate-y-0 opacity-100' : 'translate-y-10 opacity-0'}`}
        >
          Sistema de treinamento bio-adaptativo com prescrição inteligente, 
          periodização DUP e controle real de carga.
        </p>

        {/* Download Buttons */}
        <div 
          className={`flex flex-col sm:flex-row gap-4 w-full max-w-md mb-16 transition-all duration-700 delay-400 ${isVisible ? 'translate-y-0 opacity-100' : 'translate-y-10 opacity-0'}`}
        >
          {/* Android */}
          <a
            href="/download/apk.apk"
            download="BuildFit.apk"
            className="flex-1 flex items-center justify-center gap-3 px-6 py-4 bg-neon text-black font-bold rounded-2xl text-lg hover:scale-105 hover:shadow-[0_0_30px_rgba(204,255,0,0.3)] transition-all duration-200"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M17.523 2.237l1.586 2.747a.5.5 0 0 1-.866.5l-1.61-2.79A10.017 10.017 0 0 0 12 1.5a10.017 10.017 0 0 0-4.633 1.194l-1.61-2.79a.5.5 0 0 1 .866-.5l1.586 2.747A9.93 9.93 0 0 1 12 1c1.468 0 2.86.317 4.113.893L17.523 2.237zM5.5 22V9h13v13h-2v2.5a1 1 0 0 1-2 0V22h-5v2.5a1 1 0 0 1-2 0V22h-2zm-3-13v9a1 1 0 0 0 2 0V9a1 1 0 0 0-2 0zm17 0v9a1 1 0 0 0 2 0V9a1 1 0 0 0-2 0z"/>
            </svg>
            Android
          </a>

          {/* iOS */}
          <a
            href="#"
            onClick={(e) => {
              e.preventDefault();
              alert('Em breve na App Store! Estamos aguardando aprovação da Apple.');
            }}
            className="flex-1 flex items-center justify-center gap-3 px-6 py-4 bg-white text-black font-bold rounded-2xl text-lg hover:scale-105 hover:shadow-[0_0_30px_rgba(255,255,255,0.2)] transition-all duration-200"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
            </svg>
            iOS
          </a>
        </div>

        {/* Web App Button */}
        <a 
          href="/treino/" 
          className={`flex items-center gap-3 px-8 py-4 border-2 border-gray-700 text-white font-semibold rounded-2xl text-lg hover:border-neon hover:shadow-[0_0_20px_rgba(204,255,0,0.1)] transition-all duration-200 ${isVisible ? 'translate-y-0 opacity-100' : 'translate-y-10 opacity-0'}`}
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="12" cy="12" r="10"/>
            <line x1="2" y1="12" x2="22" y2="12"/>
            <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
          </svg>
          Acessar na Web
        </a>
      </section>

      {/* Features Section */}
      <section className="px-6 py-20 bg-gradient-to-b from-transparent to-surface/50">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-4">
            Tudo que você precisa para <span className="text-neon">treinar melhor</span>
          </h2>
          <p className="text-gray-400 text-center mb-16 max-w-2xl mx-auto">
            Ciência do esporte aplicada diretamente no seu treino. 
            Sem achismo, sem achismo, só resultados.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              {
                icon: '🧠',
                title: 'Prescrição Inteligente',
                desc: 'Motor científico que monta planos personalizados baseados na sua anamnese, objetivos e nível de experiência.',
                color: 'bg-tactical/10 border-tactical/20'
              },
              {
                icon: '📈',
                title: 'Progressão Automática',
                desc: 'Sistema RIR que detecta quando você está pronto para evoluir a carga ou entrar em deload.',
                color: 'bg-neon/10 border-neon/20'
              },
              {
                icon: '🔄',
                title: 'Rotação de Exercícios',
                desc: 'A cada 2 semanas, exercícios são trocados por equivalentes para maximizar estímulo muscular.',
                color: 'bg-tiktok/10 border-tiktok/20'
              },
              {
                icon: '📊',
                title: 'Analytics Avançados',
                desc: 'Gráficos de volume por músculo, progressão de carga e comparativo semanal.',
                color: 'bg-training/10 border-training/20'
              },
              {
                icon: '🍎',
                title: 'Nutrição Bio-Adaptativa',
                desc: 'TDEE dinâmico com carb cycling e compensação inteligente de calorias.',
                color: 'bg-neon/10 border-neon/20'
              },
              {
                icon: '⚡',
                title: 'DUP Avançado',
                desc: 'Ondulação diária de intensidade com dias de força, hipertrofia e volume.',
                color: 'bg-tactical/10 border-tactical/20'
              },
            ].map((feature, i) => (
              <div 
                key={i}
                className={`p-6 rounded-2xl border ${feature.color} hover:scale-105 transition-all duration-200`}
              >
                <div className="text-4xl mb-4">{feature.icon}</div>
                <h3 className="text-xl font-bold mb-2">{feature.title}</h3>
                <p className="text-gray-400 text-sm leading-relaxed">{feature.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Science Section */}
      <section className="px-6 py-20">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Baseado em <span className="text-neon">ciência real</span>
          </h2>
          <p className="text-gray-400 mb-12 max-w-2xl mx-auto">
            Nosso motor de prescrição é fundamentado nos maiores pesquisadores do esporte.
          </p>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {[
              { name: 'Schoenfeld', field: 'Hipertrofia', year: '2021' },
              { name: 'Bompa', field: 'Periodização', year: '2019' },
              { name: 'NSCA', field: 'Força & Condicionamento', year: '2022' },
              { name: 'Mifflin-St Jeor', field: 'Metabolismo', year: '1990' },
            ].map((scientist, i) => (
              <div key={i} className="p-4 bg-surface rounded-xl border border-white/5">
                <div className="text-neon font-bold text-lg">{scientist.name}</div>
                <div className="text-gray-400 text-sm">{scientist.field}</div>
                <div className="text-gray-600 text-xs mt-1">{scientist.year}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How it Works */}
      <section className="px-6 py-20 bg-gradient-to-b from-transparent to-surface/50">
        <div className="max-w-4xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-16">
            Como <span className="text-neon">funciona</span>
          </h2>

          <div className="space-y-12">
            {[
              {
                step: '01',
                title: 'Anamnese Completa',
                desc: 'Conte-nos sobre seus objetivos, experiência, equipamentos disponíveis e restrições de saúde.',
              },
              {
                step: '02',
                title: 'Plano Gerado',
                desc: 'Nosso motor científico monta um plano personalizado com divisão, exercícios, séries, reps e RIR.',
              },
              {
                step: '03',
                title: 'Treine & Registre',
                desc: 'Execute o treino, registre séries e RIR. O app calcula volume e detecta PRs automaticamente.',
              },
              {
                step: '04',
                title: 'Progressão Automática',
                desc: 'Baseado no seu RIR, o app ajusta cargas, sugere deload e rotaciona exercícios.',
              },
            ].map((item, i) => (
              <div key={i} className="flex gap-6 items-start">
                <div className="flex-shrink-0 w-16 h-16 bg-neon/10 border border-neon/20 rounded-2xl flex items-center justify-center">
                  <span className="text-neon font-bold text-xl">{item.step}</span>
                </div>
                <div>
                  <h3 className="text-xl font-bold mb-2">{item.title}</h3>
                  <p className="text-gray-400 leading-relaxed">{item.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="px-6 py-20">
        <div className="max-w-2xl mx-auto text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Pronto para treinar com <span className="text-neon">ciência</span>?
          </h2>
          <p className="text-gray-400 mb-8">
            Baixe o app agora e comece a treinar com inteligência.
          </p>
          
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a
              href="/download/apk.apk"
              download="BuildFit.apk"
              className="px-8 py-4 bg-neon text-black font-bold rounded-2xl text-lg hover:scale-105 hover:shadow-[0_0_30px_rgba(204,255,0,0.3)] transition-all duration-200"
            >
              Download Android
            </a>
            <a
              href="/treino/"
              className="px-8 py-4 border-2 border-gray-700 text-white font-semibold rounded-2xl text-lg hover:border-neon transition-all duration-200"
            >
              Acessar na Web
            </a>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="px-6 py-12 border-t border-white/5">
        <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-neon rounded-lg flex items-center justify-center">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#000" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M6.5 6.5h11M6.5 17.5h11M3 10v4M21 10v4M5 8v8M19 8v8" />
              </svg>
            </div>
            <span className="font-bold text-lg">BUILD<span className="text-neon">FIT</span></span>
          </div>
          
          <div className="flex gap-6 text-sm text-gray-400">
            <a href="/treino/" className="hover:text-white transition-colors">Web App</a>
            <a href="/download/apk.apk" className="hover:text-white transition-colors">Download</a>
            <span>v1.0.0</span>
          </div>
          
          <p className="text-sm text-gray-600">
            © 2026 Build Fit. Todos os direitos reservados.
          </p>
        </div>
      </footer>
    </div>
  );
}
