'use client';

import React from 'react';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { Dumbbell, ChevronRight } from 'lucide-react';

export default function InitialPage() {
  return (
    <div className="min-h-screen bg-black text-white flex flex-col">
      <main className="flex-1 flex flex-col items-center justify-center px-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
          className="text-center max-w-lg"
        >
          <motion.div
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.2, duration: 0.5 }}
            className="w-20 h-20 bg-[#CCFF00] rounded-2xl flex items-center justify-center mx-auto mb-8 rotate-3"
          >
            <Dumbbell className="text-black w-10 h-10 -rotate-3" />
          </motion.div>

          <motion.h1
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.3, duration: 0.6 }}
            className="text-5xl font-black tracking-tighter mb-4"
          >
            TITAN ENGINE
          </motion.h1>

          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.4, duration: 0.6 }}
            className="text-lg text-neutral-400 mb-12 leading-relaxed"
          >
            Sistema de treinamento bio-adaptativo com prescrição científica,
            periodização DUP e controle real de fadiga.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5, duration: 0.4 }}
          >
            <Link
              href="/treino/index.html"
              className="inline-flex items-center gap-3 px-8 py-4 bg-[#CCFF00] text-black font-black rounded-2xl text-lg transition-all hover:scale-105 active:scale-95"
            >
              ENTRAR
              <ChevronRight className="w-5 h-5" />
            </Link>
          </motion.div>
        </motion.div>
      </main>

      <footer className="py-8 text-center">
        <p className="text-neutral-600 text-xs uppercase tracking-widest font-black">
          © 2026 Titan Engine
        </p>
      </footer>
    </div>
  );
}