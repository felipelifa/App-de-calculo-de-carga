#!/bin/bash

# Script de build robusto para Flutter Web no Netlify
echo "--- INICIANDO BUILD FLUTTER ---"

# 1. Instalar Flutter se não existir ou estiver corrompido
if [ ! -f "./flutter/bin/flutter" ]; then
    echo "Clonando Flutter SDK..."
    rm -rf flutter
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
    echo "Flutter SDK já encontrado na cache."
fi

# 2. Configurar o binário no PATH temporário
export PATH="$PATH:$(pwd)/flutter/bin"

# 3. Executar o build
echo "Baixando dependências (pub get)..."
flutter pub get

echo "Iniciando build web (renderizador HTML)..."
flutter build web --release --web-renderer html

echo "--- BUILD CONCLUÍDO ---"
