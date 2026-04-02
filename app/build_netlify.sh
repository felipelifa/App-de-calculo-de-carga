#!/bin/bash
set -e

# Script de build robusto para Flutter Web no Netlify
echo "--- INICIANDO BUILD FLUTTER ---"

# 1. Instalar SDK do Flutter (via download direto por ser mais seguro/leve)
if [ ! -f "flutter/bin/flutter" ]; then
    echo "Baixando Flutter SDK estável para Linux..."
    rm -rf flutter
    curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz
    tar xf flutter_linux_3.19.0-stable.tar.xz
    rm flutter_linux_3.19.0-stable.tar.xz
else
    echo "Flutter SDK já encontrado na cache local."
fi

# 2. Configurar PATH e permissões
export PATH="$PATH:$(pwd)/flutter/bin"
chmod +x ./flutter/bin/flutter

# 3. Executar o build com renderizador otimizado
echo "Configurações internas..."
flutter config --no-analytics
flutter doctor

echo "Baixando dependências do projeto..."
flutter pub get

echo "Iniciando build web (HTML renderer para economia de memória)..."
flutter build web --release --web-renderer html --no-pub

echo "--- BUILD CONCLUÍDO COM SUCESSO ---"
