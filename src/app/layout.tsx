import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Controle de Carga — App de Treino Inteligente',
  description: 'App de treino com progressão automática, prescrição inteligente baseada em ciência e sistema de periodização DUP. Treine melhor.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR" className="scroll-smooth">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@100..900&display=swap" rel="stylesheet" />
      </head>
      <body className="antialiased font-['Outfit']">{children}</body>
    </html>
  );
}
