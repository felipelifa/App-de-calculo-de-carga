'use client';

import React, { useEffect, useRef } from 'react';
import Link from 'next/link';
import { motion, useScroll, useTransform, useSpring, AnimatePresence } from 'framer-motion';
import { 
  Zap, 
  Target, 
  TrendingUp, 
  ShieldCheck, 
  Activity, 
  Download, 
  ChevronRight, 
  Menu, 
  X,
  Stethoscope,
  Dumbbell,
  Trophy,
  Users
} from 'lucide-react';

// Animation Variants
const fadeInUp = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.6, ease: [0.22, 1, 0.36, 1] }
};

const staggerContainer = {
  animate: {
    transition: {
      staggerChildren: 0.1
    }
  }
};

export default function LandingPage() {
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, {
    stiffness: 100,
    damping: 30,
    restDelta: 0.001
  });

  return (
    <div className="bg-black text-white selection:bg-neon selection:text-black">
      {/* Scroll Progress Bar */}
      <motion.div
        className="fixed top-0 left-0 right-0 h-1 bg-neon z-[100] origin-left"
        style={{ scaleX }}
      />

      <Navbar />

      <main>
        {/* HERO SECTION */}
        <section className="relative min-h-screen flex flex-col items-center justify-center px-4 overflow-hidden pt-20">
          {/* Background Ambient Glows */}
          <div className="absolute top-1/4 -left-20 w-96 h-96 bg-tiktok/20 blur-[120px] rounded-full" />
          <div className="absolute bottom-1/4 -right-20 w-96 h-96 bg-neon/10 blur-[120px] rounded-full" />
          
          <motion.div 
            initial="initial"
            animate="animate"
            variants={staggerContainer}
            className="relative z-10 text-center max-w-5xl"
          >
            <motion.div 
              variants={fadeInUp}
              className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full glass mb-8 border-white/10"
            >
              <span className="w-2 h-2 rounded-full bg-neon animate-pulse" />
              <span className="text-xs font-bold tracking-widest uppercase text-neon">Motor Bio-Adaptativo v7.0</span>
            </motion.div>

            <motion.h1 
              variants={fadeInUp}
              className="text-6xl md:text-8xl font-black tracking-tighter leading-[0.9] mb-8"
            >
              SEJA SAUDÁVEL.<br />
              <span className="text-neon underline decoration-4 underline-offset-8">SEJA FORTE.</span><br />
              SEJA CONFIANTE.
            </motion.h1>

            <motion.p 
              variants={fadeInUp}
              className="text-lg md:text-xl text-neutral-400 max-w-2xl mx-auto mb-12 leading-relaxed"
            >
              O sistema definitivo de treinamento bio-adaptativo. 
              Geração automática de prescrições baseadas em ciência, 
              periodização DUP e controle real de fadiga.
            </motion.p>

            <motion.div 
              variants={fadeInUp}
              className="flex flex-col sm:flex-row gap-4 justify-center items-center"
            >
              <Link 
                href="/treino/index.html"
                className="group relative px-10 py-5 bg-neon text-black font-black rounded-2xl transition-all hover:scale-105 active:scale-95"
              >
                COMEÇAR AGORA
                <div className="absolute inset-0 bg-white/20 scale-x-0 group-hover:scale-x-100 transition-transform origin-left rounded-2xl" />
              </Link>
              <a 
                href="#features"
                className="px-10 py-5 glass font-bold rounded-2xl border-white/10 hover:bg-white/5 transition-all"
              >
                VER RECURSOS
              </a>
            </motion.div>
          </motion.div>

          {/* Floating Elements (Physics-like look) */}
          <motion.div 
            animate={{ y: [0, -20, 0] }}
            transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
            className="absolute bottom-10 left-1/2 -translate-x-1/2 opacity-30"
          >
            <div className="w-px h-20 bg-gradient-to-b from-neon to-transparent" />
          </motion.div>
        </section>

        {/* BENTO GRID FEATURES */}
        <section id="features" className="py-32 px-4 max-w-7xl mx-auto">
          <div className="mb-20">
            <h2 className="text-4xl md:text-6xl font-black tracking-tighter mb-4">MOTOR MOVIDO A CIÊNCIA.</h2>
            <p className="text-neutral-500 max-w-xl">Nosso motor não usa algoritmos simples. Ele simula a sua fisiologia para garantir resultados sem lesões.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-12 gap-4 auto-rows-[240px]">
            {/* Bento Item 1: Wide */}
            <BentoCard 
              className="md:col-span-8 md:row-span-2 bg-tiktok flex flex-col justify-end p-8 group overflow-hidden"
              icon={<Zap className="w-12 h-12 mb-4" />}
              title="Prescrição DUP Inteligente"
              desc="Daily Undulating Periodization que varia entre Força, Hipertrofia e Resistência a cada sessão, otimizando o estímulo sem estagnar o SNC."
            />

            {/* Bento Item 2: Square */}
            <BentoCard 
              className="md:col-span-4 md:row-span-1 bg-surface-muted border border-white/5 flex flex-col justify-center p-8"
              icon={<TrendingUp className="text-neon mb-4" />}
              title="Progressão RIR"
              desc="Controle real de esforço."
            />

            {/* Bento Item 3: Square */}
            <BentoCard 
              className="md:col-span-4 md:row-span-1 bg-tactical flex flex-col justify-center p-8"
              icon={<ShieldCheck className="mb-4" />}
              title="Filtro de Lesões"
              desc="Proteção articular ativa."
            />

            {/* Bento Item 4: Long Vertical */}
            <BentoCard 
              className="md:col-span-4 md:row-span-2 bg-surface border border-white/5 group flex flex-col justify-between p-8"
              icon={<Activity className="text-tiktok w-10 h-10" />}
              title="Nutrição Bio-Adaptive"
              desc="O primeiro app que ajusta seu orçamento semanal de calorias com base no que você realmente comeu e na carga do treino do dia."
            />

            {/* Bento Item 5: Wide Middle */}
            <BentoCard 
              className="md:col-span-8 md:row-span-2 glass flex flex-col md:flex-row gap-8 items-center justify-center p-8 bg-gradient-to-br from-surface to-black border-white/10"
              icon={<div className="text-8xl font-black text-white/5 absolute -left-4 -bottom-4">O GENÉRICO MORREU.</div>}
              title="Treino Individualizado"
              desc="Fim das planilhas genéricas. O algoritmo monta o treino do ZERO baseado no seu equipamento, tempo disponível e restrições médicas."
            />
          </div>
        </section>

        {/* STATS STORYTELLING */}
        <section className="py-20 border-y border-white/5 bg-surface/30">
          <div className="max-w-7xl mx-auto px-4 grid grid-cols-2 md:grid-cols-4 gap-12">
            <StatItem num="949" label="Exercícios no Banco" />
            <StatItem num="10k+" label="Usuários Ativos" />
            <StatItem num="100%" label="Baseado em Evidência" />
            <StatItem num="500m²" label="De Conhecimento" />
          </div>
        </section>

        {/* DOWNLOAD CTA */}
        <section id="download" className="py-40 px-4 relative overflow-hidden">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-neon/10 blur-[150px] rounded-full pointer-events-none" />
          
          <div className="max-w-4xl mx-auto text-center relative z-10">
            <Download className="w-20 h-20 mx-auto mb-8 text-neon" />
            <h2 className="text-5xl md:text-7xl font-black tracking-tighter mb-8 italic">PRONTO PARA DOMINAR?</h2>
            <p className="text-xl text-neutral-400 mb-12">Disponível via APK para Android e WebApp para iOS/Navegador.</p>
            
            <div className="flex flex-col sm:flex-row gap-6 justify-center">
              <Link 
                href="/download/apk"
                className="px-12 py-6 bg-white text-black font-black rounded-3xl hover:bg-neon transition-colors text-lg"
              >
                BAIXAR APK (v7.0)
              </Link>
              <Link 
                href="/treino/index.html"
                className="px-12 py-6 glass font-black rounded-3xl border-white/10 hover:bg-white/10 transition-colors text-lg"
              >
                ABRIR NO NAVEGADOR
              </Link>
            </div>
            <p className="mt-8 text-neutral-600 text-sm">Sem assinaturas escondidas. Sem firulas. Apenas resultados.</p>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  );
}

// Subcomponents

function Navbar() {
  const [isOpen, setIsOpen] = React.useState(false);

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 px-6 py-6 transition-all duration-300">
      <div className="max-w-7xl mx-auto flex items-center justify-between px-6 py-4 glass rounded-3xl border-white/5">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-neon rounded-xl flex items-center justify-center rotate-3 group-hover:rotate-12 transition-transform">
            <Dumbbell className="text-black w-6 h-6 -rotate-3" />
          </div>
          <span className="text-xl font-black tracking-tighter">TITAN ENGINE</span>
        </div>

        <div className="hidden md:flex items-center gap-8">
          <NavLink href="#features">Recursos</NavLink>
          <NavLink href="#science">Ciência</NavLink>
          <NavLink href="#download">Download</NavLink>
          <Link href="/treino/index.html" className="px-6 py-2 bg-white text-black text-sm font-black rounded-xl hover:bg-neon transition-colors">
            ENTRAR
          </Link>
        </div>

        <button className="md:hidden text-white" onClick={() => setIsOpen(!isOpen)}>
          {isOpen ? <X /> : <Menu />}
        </button>
      </div>

      {/* Mobile Menu */}
      <AnimatePresence>
        {isOpen && (
          <motion.div 
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="md:hidden absolute top-24 left-6 right-6 p-8 glass rounded-3xl border-white/5 flex flex-col gap-6 text-center"
          >
            <a href="#features" className="text-xl font-bold" onClick={() => setIsOpen(false)}>Recursos</a>
            <a href="#science" className="text-xl font-bold" onClick={() => setIsOpen(false)}>Ciência</a>
            <a href="#download" className="text-xl font-bold" onClick={() => setIsOpen(false)}>Download</a>
            <Link href="/treino/index.html" className="py-4 bg-neon text-black font-black rounded-2xl">
              ENTRAR
            </Link>
          </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
}

function NavLink({ href, children }: { href: string, children: React.ReactNode }) {
  return (
    <a href={href} className="text-sm font-bold text-neutral-400 hover:text-neon transition-colors">
      {children}
    </a>
  );
}

function BentoCard({ className, icon, title, desc }: { className: string, icon: React.ReactNode, title: string, desc: string }) {
  return (
    <motion.div 
      whileHover={{ scale: 0.985 }}
      transition={{ duration: 0.2 }}
      className={`rounded-[32px] cursor-pointer group relative ${className}`}
    >
      <div className="relative z-10">
        <div className="group-hover:scale-110 transition-transform duration-500 origin-left">
          {icon}
        </div>
        <h3 className="text-2xl font-black mb-2 tracking-tight">{title}</h3>
        <p className="text-sm opacity-60 leading-relaxed">{desc}</p>
      </div>
      {/* Gloss Effect */}
      <div className="absolute inset-0 bg-gradient-to-tr from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity rounded-[32px]" />
    </motion.div>
  );
}

function StatItem({ num, label }: { num: string, label: string }) {
  return (
    <div className="text-center group">
      <div className="text-4xl md:text-5xl font-black text-white group-hover:text-neon transition-colors mb-2 tracking-tighter italic">
        {num}
      </div>
      <div className="text-xs uppercase font-bold tracking-[3px] text-neutral-500">
        {label}
      </div>
    </div>
  );
}

function Footer() {
  return (
    <footer className="py-20 px-4 border-t border-white/5">
      <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-center gap-12">
        <div className="text-center md:text-left">
          <div className="text-2xl font-black tracking-tighter mb-4">TITAN ENGINE</div>
          <p className="text-neutral-500 max-w-sm">O futuro do treinamento inteligente. Construído por atletas para quem quer resultados reais.</p>
        </div>
        <div className="flex gap-12 text-center md:text-right">
          <div>
            <div className="font-bold mb-4">SISTEMA</div>
            <ul className="text-sm text-neutral-500 space-y-2">
              <li>App Treino</li>
              <li>Nutrição Inteligente</li>
              <li>Gêmeo Digital</li>
            </ul>
          </div>
          <div>
            <div className="font-bold mb-4">SCIENCE</div>
            <ul className="text-sm text-neutral-500 space-y-2">
              <li>Periodização DUP</li>
              <li>Schoenfeld Lab</li>
              <li>Bio-Adaptation</li>
            </ul>
          </div>
        </div>
      </div>
      <div className="mt-20 text-center text-[10px] text-neutral-800 uppercase tracking-widest font-black">
        © 2026 TITAN ENGINE / CONTROLE DE CARGA — TRANSFORMING DATA INTO MUSCLE.
      </div>
    </footer>
  );
}
