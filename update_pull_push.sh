#!/data/data/com.termux/files/usr/bin/bash

# Script para atualizar o workflow do GitHub Actions, fazer pull, commit e push

echo "🚀 Iniciando o processo de atualização e push..."

# Verificar se estamos no diretório correto
if [ ! -d ".git" ]; then
  echo "❌ Erro: Este script deve ser executado na raiz do repositório."
  exit 1
fi

# Verificar se estamos no branch master
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "master" ]; then
  echo "⚠️ Aviso: Você não está no branch master. Mudando para master..."
  git checkout master
  if [ $? -ne 0 ]; then
    echo "❌ Erro: Não foi possível mudar para o branch master."
    exit 1
  fi
fi

# Fazer pull para obter as alterações mais recentes
echo "⬇️ Fazendo pull para obter as alterações mais recentes..."
git pull origin master

if [ $? -ne 0 ]; then
  echo "⚠️ Conflitos detectados durante o pull. Tentando resolver..."
  
  # Verificar se há conflitos no arquivo de workflow
  if git ls-files -u | grep -q ".github/workflows/flutter-build.yml"; then
    echo "🔄 Resolvendo conflito no arquivo de workflow..."
    git checkout --ours .github/workflows/flutter-build.yml
    git add .github/workflows/flutter-build.yml
  else
    echo "❌ Existem conflitos que precisam ser resolvidos manualmente."
    echo "   Execute 'git status' para ver os arquivos com conflito."
    exit 1
  fi
fi

# Atualizar o arquivo de workflow
echo "📝 Criando/atualizando o arquivo de workflow..."
mkdir -p .github/workflows
cat > .github/workflows/flutter-build.yml << 'EOL'
name: Flutter Build

on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '11'
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-release
          path: build/app/outputs/flutter-apk/app-release.apk
EOL

# Verificar se o arquivo foi criado corretamente
if [ ! -f ".github/workflows/flutter-build.yml" ]; then
  echo "❌ Erro: Não foi possível criar o arquivo de workflow."
  exit 1
fi

echo "✅ Arquivo de workflow criado/atualizado com sucesso."

# Adicionar o arquivo ao Git
echo "📋 Adicionando o arquivo ao Git..."
git add .github/workflows/flutter-build.yml

# Verificar se há alterações para commit
if git diff-index --quiet HEAD --; then
  echo "ℹ️ Nenhuma alteração detectada. Nada para fazer commit."
else
  # Fazer commit das alterações
  echo "💾 Fazendo commit das alterações..."
  git commit -m "Atualiza workflow Flutter Build com versão 3.19.0 do Flutter"

  # Fazer push para o repositório remoto
  echo "☁️ Fazendo push para o repositório remoto..."
  git push origin master

  if [ $? -ne 0 ]; then
    echo "❌ Erro: Não foi possível fazer push para o repositório remoto."
    exit 1
  fi

  echo "✅ Push realizado com sucesso."

  # Verificar se o gh CLI está instalado
  if command -v gh &> /dev/null; then
    echo "🔄 Executando o workflow manualmente..."
    gh workflow run "Flutter Build"
    
    if [ $? -ne 0 ]; then
      echo "⚠️ Aviso: Não foi possível executar o workflow manualmente. Verifique o status no GitHub."
    else
      echo "✅ Workflow iniciado com sucesso."
      
      echo "🔍 Monitorando o status da execução (pressione Ctrl+C para sair)..."
      sleep 5
      gh run list --workflow="Flutter Build" --limit=1
    fi
  else
    echo "ℹ️ O GitHub CLI (gh) não está instalado. Acesse o GitHub para executar o workflow manualmente."
  fi
fi

echo "🎉 Processo concluído!"
echo "📱 Após a conclusão do workflow, você poderá baixar o APK do GitHub Actions."
echo "💡 Ou compile localmente com: flutter build apk --release"
