#!/data/data/com.termux/files/usr/bin/bash

# Script interativo para gerenciamento de projetos Flutter no GitHub
# Autor: AI Assistant
# Data: 2025-05-02

# Cores para o terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
REPO_PATH="$HOME/development/markdownr"
REPO_OWNER="camillanapoles"
REPO_NAME="markdownr"
WORKFLOW_NAME="Flutter Build"
DOWNLOAD_PATH="/storage/emulated/0/Download"

# Função para exibir cabeçalho
show_header() {
  clear
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║                ${GREEN}Flutter GitHub Manager${BLUE}                      ║${NC}"
  echo -e "${BLUE}║                                                            ║${NC}"
  echo -e "${BLUE}║  ${YELLOW}Repositório:${NC} $REPO_OWNER/$REPO_NAME                       ${BLUE}║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# Função para verificar se o GitHub CLI está instalado
check_gh_cli() {
  if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI não está instalado.${NC}"
    echo -e "${YELLOW}Instalando GitHub CLI...${NC}"
    pkg install gh -y
    
    if ! command -v gh &> /dev/null; then
      echo -e "${RED}Falha ao instalar GitHub CLI. Por favor, instale manualmente.${NC}"
      echo "pkg install gh"
      exit 1
    fi
    
    echo -e "${GREEN}GitHub CLI instalado com sucesso.${NC}"
    echo -e "${YELLOW}Autenticando no GitHub...${NC}"
    gh auth login
  fi
  
  # Verificar se está autenticado
  if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}Você precisa autenticar no GitHub.${NC}"
    gh auth login
  fi
}

# Função para navegar para o diretório do repositório
go_to_repo() {
  if [ ! -d "$REPO_PATH" ]; then
    echo -e "${RED}Diretório do repositório não encontrado: $REPO_PATH${NC}"
    echo -e "${YELLOW}Deseja clonar o repositório? (s/n)${NC}"
    read -r response
    if [[ "$response" =~ ^([sS])$ ]]; then
      mkdir -p "$(dirname "$REPO_PATH")"
      gh repo clone "$REPO_OWNER/$REPO_NAME" "$REPO_PATH"
      if [ $? -ne 0 ]; then
        echo -e "${RED}Falha ao clonar o repositório.${NC}"
        exit 1
      fi
    else
      echo -e "${YELLOW}Por favor, especifique o caminho correto do repositório:${NC}"
      read -r REPO_PATH
      if [ ! -d "$REPO_PATH" ]; then
        echo -e "${RED}Diretório inválido.${NC}"
        exit 1
      fi
    fi
  fi
  
  cd "$REPO_PATH" || {
    echo -e "${RED}Falha ao navegar para o diretório do repositório.${NC}"
    exit 1
  }
}

# Função para puxar as últimas alterações
pull_changes() {
  show_header
  echo -e "${CYAN}Puxando as últimas alterações do repositório...${NC}"
  git pull origin master
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Alterações puxadas com sucesso!${NC}"
  else
    echo -e "${RED}Erro ao puxar alterações.${NC}"
    echo -e "${YELLOW}Verificando se há conflitos...${NC}"
    if git status | grep -q "both modified"; then
      echo -e "${RED}Há conflitos que precisam ser resolvidos.${NC}"
    fi
  fi
  echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
  read -r
}

# Função para editar arquivos comuns
edit_files() {
  while true; do
    show_header
    echo -e "${CYAN}Editar Arquivos${NC}"
    echo -e "${YELLOW}1.${NC} pubspec.yaml (Dependências)"
    echo -e "${YELLOW}2.${NC} .github/workflows/flutter-build.yml (Workflow)"
    echo -e "${YELLOW}3.${NC} android/app/build.gradle (Configurações Android)"
    echo -e "${YELLOW}4.${NC} android/gradle.properties (Propriedades Gradle)"
    echo -e "${YELLOW}5.${NC} lib/main.dart (Código Principal)"
    echo -e "${YELLOW}6.${NC} Outro arquivo (especificar caminho)"
    echo -e "${YELLOW}0.${NC} Voltar ao menu principal"
    echo ""
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    read -r option
    
    case $option in
      1)
        nano pubspec.yaml
        ;;
      2)
        mkdir -p .github/workflows
        if [ ! -f .github/workflows/flutter-build.yml ]; then
          echo -e "${YELLOW}Arquivo de workflow não existe. Criando um modelo básico...${NC}"
          cat > .github/workflows/flutter-build.yml << 'EOF'
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
          java-version: '8'
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
EOF
        fi
        nano .github/workflows/flutter-build.yml
        ;;
      3)
        nano android/app/build.gradle
        ;;
      4)
        nano android/gradle.properties
        ;;
      5)
        nano lib/main.dart
        ;;
      6)
        echo -e "${YELLOW}Digite o caminho do arquivo:${NC}"
        read -r file_path
        if [ -f "$file_path" ]; then
          nano "$file_path"
        else
          echo -e "${RED}Arquivo não encontrado.${NC}"
          echo -e "${YELLOW}Deseja criar o arquivo? (s/n)${NC}"
          read -r create_file
          if [[ "$create_file" =~ ^([sS])$ ]]; then
            mkdir -p "$(dirname "$file_path")"
            nano "$file_path"
          fi
        fi
        echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
        read -r
        ;;
      0)
        return
        ;;
      *)
        echo -e "${RED}Opção inválida.${NC}"
        sleep 1
        ;;
    esac
  done
}

# Função para fazer commit e push das alterações
commit_and_push() {
  show_header
  echo -e "${CYAN}Status do Git:${NC}"
  git status
  
  echo -e "\n${YELLOW}Deseja adicionar todos os arquivos modificados? (s/n)${NC}"
  read -r add_all
  
  if [[ "$add_all" =~ ^([sS])$ ]]; then
    git add .
  else
    echo -e "${YELLOW}Digite os arquivos que deseja adicionar (separados por espaço):${NC}"
    read -r files_to_add
    git add $files_to_add
  fi
  
  echo -e "${YELLOW}Digite a mensagem de commit:${NC}"
  read -r commit_message
  
  git commit -m "$commit_message"
  
  echo -e "${YELLOW}Fazendo push para o branch master...${NC}"
  git push origin master
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Push realizado com sucesso!${NC}"
  else
    echo -e "${RED}Erro ao fazer push.${NC}"
    echo -e "${YELLOW}Deseja puxar as alterações remotas e tentar novamente? (s/n)${NC}"
    read -r pull_and_retry
    
    if [[ "$pull_and_retry" =~ ^([sS])$ ]]; then
      git pull origin master
      git push origin master
      
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}Push realizado com sucesso após pull!${NC}"
      else
        echo -e "${RED}Erro ao fazer push mesmo após pull.${NC}"
      fi
    fi
  fi
  
  echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
  read -r
}

# Função para executar o workflow
run_workflow() {
  show_header
  echo -e "${CYAN}Executando workflow '$WORKFLOW_NAME'...${NC}"
  
  gh workflow run "$WORKFLOW_NAME"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Workflow iniciado com sucesso!${NC}"
    echo -e "${YELLOW}Deseja monitorar o progresso? (s/n)${NC}"
    read -r monitor
    
    if [[ "$monitor" =~ ^([sS])$ ]]; then
      monitor_workflow
    fi
  else
    echo -e "${RED}Erro ao iniciar o workflow.${NC}"
  fi
  
  echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
  read -r
}

# Função para monitorar o workflow
monitor_workflow() {
  show_header
  echo -e "${CYAN}Monitorando execuções recentes do workflow '$WORKFLOW_NAME'...${NC}"
  
  # Obter o ID da execução mais recente
  echo -e "${YELLOW}Obtendo execuções recentes...${NC}"
  gh run list --workflow="$WORKFLOW_NAME" --limit=5
  
  echo -e "\n${YELLOW}Digite o ID da execução que deseja monitorar (ou deixe em branco para a mais recente):${NC}"
  read -r run_id
  
  if [ -z "$run_id" ]; then
    run_id=$(gh run list --workflow="$WORKFLOW_NAME" --limit=1 --json databaseId -q .[0].databaseId)
    if [ -z "$run_id" ]; then
      echo -e "${RED}Não foi possível obter o ID da execução mais recente.${NC}"
      return
    fi
  fi
  
  echo -e "${CYAN}Monitorando execução $run_id...${NC}"
  gh run watch "$run_id"
  
  # Verificar o status final
  status=$(gh run view "$run_id" --json status -q .status)
  conclusion=$(gh run view "$run_id" --json conclusion -q .conclusion 2>/dev/null || echo "em_andamento")
  
  echo -e "${CYAN}Status final: $status, Conclusão: $conclusion${NC}"
  
  # Se o workflow for bem-sucedido, baixar o artefato
  if [ "$status" = "completed" ] && [ "$conclusion" = "success" ]; then
    echo -e "${GREEN}Workflow concluído com sucesso!${NC}"
    echo -e "${YELLOW}Deseja baixar o APK? (s/n)${NC}"
    read -r download_apk
    
    if [[ "$download_apk" =~ ^([sS])$ ]]; then
      echo -e "${CYAN}Baixando APK...${NC}"
      
      mkdir -p "$HOME/downloads"
      gh run download "$run_id" --dir "$HOME/downloads"
      
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}APK baixado com sucesso para $HOME/downloads${NC}"
        
        # Copiar para a pasta de downloads do Android (se acessível)
        if [ -d "$DOWNLOAD_PATH" ]; then
          find "$HOME/downloads" -name "*.apk" -exec cp {} "$DOWNLOAD_PATH/" \;
          if [ $? -eq 0 ]; then
            echo -e "${GREEN}APK copiado para $DOWNLOAD_PATH/${NC}"
          else
            echo -e "${RED}Não foi possível copiar o APK para a pasta de downloads do Android.${NC}"
          fi
        fi
      else
        echo -e "${RED}Erro ao baixar o APK.${NC}"
      fi
    fi
  elif [ "$status" = "completed" ]; then
    echo -e "${RED}Workflow falhou ou foi cancelado.${NC}"
    echo -e "${YELLOW}Deseja ver os logs? (s/n)${NC}"
    read -r view_logs
    
    if [[ "$view_logs" =~ ^([sS])$ ]]; then
      gh run view "$run_id" --log
    fi
  else
    echo -e "${YELLOW}Workflow ainda está em andamento.${NC}"
  fi
  
  echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
  read -r
}

# Função para compilar localmente
build_locally() {
  show_header
  echo -e "${CYAN}Compilando APK localmente...${NC}"
  
  echo -e "${YELLOW}Atualizando dependências...${NC}"
  flutter pub get
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao atualizar dependências.${NC}"
    echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
    read -r
    return
  fi
  
  echo -e "${YELLOW}Escolha o tipo de build:${NC}"
  echo -e "${YELLOW}1.${NC} Debug (mais rápido, maior tamanho)"
  echo -e "${YELLOW}2.${NC} Release (otimizado, menor tamanho)"
  echo -e "${YELLOW}3.${NC} Profile (para análise de desempenho)"
  read -r build_type
  
  case $build_type in
    1)
      echo -e "${CYAN}Compilando APK de debug...${NC}"
      flutter build apk --debug
      apk_path="build/app/outputs/flutter-apk/app-debug.apk"
      ;;
    2)
      echo -e "${CYAN}Compilando APK de release...${NC}"
      flutter build apk --release
      apk_path="build/app/outputs/flutter-apk/app-release.apk"
      ;;
    3)
      echo -e "${CYAN}Compilando APK de profile...${NC}"
      flutter build apk --profile
      apk_path="build/app/outputs/flutter-apk/app-profile.apk"
      ;;
    *)
      echo -e "${RED}Opção inválida.${NC}"
      echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
      read -r
      return
      ;;
  esac
  
  if [ $? -eq 0 ] && [ -f "$apk_path" ]; then
    echo -e "${GREEN}APK compilado com sucesso!${NC}"
    echo -e "${YELLOW}Deseja copiar o APK para a pasta de downloads? (s/n)${NC}"
    read -r copy_apk
    
    if [[ "$copy_apk" =~ ^([sS])$ ]]; then
      if [ -d "$DOWNLOAD_PATH" ]; then
        cp "$apk_path" "$DOWNLOAD_PATH/"
        echo -e "${GREEN}APK copiado para $DOWNLOAD_PATH/$(basename "$apk_path")${NC}"
      else
        echo -e "${RED}Pasta de downloads não encontrada.${NC}"
        echo -e "${YELLOW}O APK está disponível em: $REPO_PATH/$apk_path${NC}"
      fi
    fi
  else
    echo -e "${RED}Erro ao compilar o APK.${NC}"
  fi
  
  echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
  read -r
}

# Função para configurar o ambiente
setup_environment() {
  show_header
  echo -e "${CYAN}Configurando ambiente de desenvolvimento...${NC}"
  
  # Verificar se o Flutter está instalado
  if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter não está instalado.${NC}"
    echo -e "${YELLOW}Por favor, instale o Flutter manualmente seguindo as instruções em:${NC}"
    echo -e "${BLUE}https://flutter.dev/docs/get-started/install${NC}"
    echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
    read -r
    return
  fi
  
  # Verificar a versão do Flutter
  flutter_version=$(flutter --version | head -1 | awk '{print $2}')
  echo -e "${GREEN}Flutter versão $flutter_version instalado.${NC}"
  
  # Verificar dependências do Flutter
  echo -e "${YELLOW}Verificando dependências do Flutter...${NC}"
  flutter doctor
  
  # Configurar o arquivo gradle.properties para resolver problemas comuns
  echo -e "${YELLOW}Deseja configurar o arquivo gradle.properties para resolver problemas comuns? (s/n)${NC}"
  read -r setup_gradle
  
  if [[ "$setup_gradle" =~ ^([sS])$ ]]; then
    mkdir -p android
    cat > android/gradle.properties << 'EOF'
# Configurações para resolver problemas comuns
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true
kotlin.jvm.target.validation.mode=warning
android.nonTransitiveRClass=true
android.defaults.buildfeatures.buildconfig=true
android.nonFinalResIds=false
EOF
    echo -e "${GREEN}Arquivo gradle.properties configurado com sucesso!${NC}"
  fi
  
  echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
  read -r
}

# Função para corrigir problemas comuns
fix_common_issues() {
  show_header
  echo -e "${CYAN}Assistente de correção de problemas comuns${NC}"
  
  echo -e "${YELLOW}Selecione o problema que deseja corrigir:${NC}"
  echo -e "${YELLOW}1.${NC} Incompatibilidade JVM-target no share_plus"
  echo -e "${YELLOW}2.${NC} Problemas com versões do Flutter"
  echo -e "${YELLOW}3.${NC} Problemas com dependências incompatíveis"
  echo -e "${YELLOW}4.${NC} Problemas com o Gradle"
  echo -e "${YELLOW}0.${NC} Voltar ao menu principal"
  
  read -r issue
  
  case $issue in
    1)
      echo -e "${CYAN}Corrigindo incompatibilidade JVM-target no share_plus...${NC}"
      
      # Atualizar o arquivo de workflow para usar Java 8
      if [ -f ".github/workflows/flutter-build.yml" ]; then
        sed -i 's/java-version: .*/java-version: '\''8'\''/g' .github/workflows/flutter-build.yml
        echo -e "${GREEN}Arquivo de workflow atualizado para usar Java 8.${NC}"
      fi
      
      # Configurar gradle.properties
      mkdir -p android
      cat > android/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true
kotlin.jvm.target.validation.mode=warning
EOF
      echo -e "${GREEN}Arquivo gradle.properties configurado.${NC}"
      
      echo -e "${YELLOW}Deseja fazer commit e push dessas alterações? (s/n)${NC}"
      read -r commit_fixes
      
      if [[ "$commit_fixes" =~ ^([sS])$ ]]; then
        git add .github/workflows/flutter-build.yml android/gradle.properties
        git commit -m "Corrige incompatibilidade JVM-target no share_plus"
        git push origin master
        
        if [ $? -eq 0 ]; then
          echo -e "${GREEN}Alterações enviadas com sucesso!${NC}"
          echo -e "${YELLOW}Deseja executar o workflow agora? (s/n)${NC}"
          read -r run_workflow_now
          
          if [[ "$run_workflow_now" =~ ^([sS])$ ]]; then
            run_workflow
          fi
        else
          echo -e "${RED}Erro ao enviar alterações.${NC}"
        fi
      fi
      ;;
    2)
      echo -e "${CYAN}Corrigindo problemas com versões do Flutter...${NC}"
      
      echo -e "${YELLOW}Atualizando Flutter para a versão mais recente...${NC}"
      flutter upgrade
      
      echo -e "${YELLOW}Limpando cache do Flutter...${NC}"
      flutter clean
      
      echo -e "${YELLOW}Atualizando dependências...${NC}"
      flutter pub get
      
      echo -e "${GREEN}Flutter atualizado e cache limpo.${NC}"
      ;;
    3)
      echo -e "${CYAN}Corrigindo problemas com dependências incompatíveis...${NC}"
      
      echo -e "${YELLOW}Verificando dependências desatualizadas...${NC}"
      flutter pub outdated
      
      echo -e "${YELLOW}Deseja atualizar todas as dependências para as versões compatíveis? (s/n)${NC}"
      read -r update_deps
      
      if [[ "$update_deps" =~ ^([sS])$ ]]; then
        flutter pub upgrade --major-versions
        echo -e "${GREEN}Dependências atualizadas.${NC}"
      fi
      ;;
    4)
      echo -e "${CYAN}Corrigindo problemas com o Gradle...${NC}"
      
      echo -e "${YELLOW}Limpando cache do Gradle...${NC}"
      rm -rf ~/.gradle/caches/
      
      echo -e "${YELLOW}Atualizando wrapper do Gradle...${NC}"
      if [ -f "android/gradlew" ]; then
        chmod +x android/gradlew
        (cd android && ./gradlew wrapper --gradle-version=7.5)
      fi
      
      echo -e "${GREEN}Cache do Gradle limpo e wrapper atualizado.${NC}"
      ;;
    0)
      return
      ;;
    *)
      echo -e "${RED}Opção inválida.${NC}"
      sleep 1
      ;;
  esac
  
  echo -e "${YELLOW}Pressione Enter para continuar...${NC}"
  read -r
}

# Função principal
main() {
  # Verificar se o GitHub CLI está instalado
  check_gh_cli
  
  # Navegar para o diretório do repositório
  go_to_repo
  
  while true; do
    show_header
    echo -e "${CYAN}Menu Principal${NC}"
    echo -e "${YELLOW}1.${NC} Puxar alterações (git pull)"
    echo -e "${YELLOW}2.${NC} Editar arquivos"
    echo -e "${YELLOW}3.${NC} Commit e push"
    echo -e "${YELLOW}4.${NC} Executar workflow"
    echo -e "${YELLOW}5.${NC} Monitorar workflow"
    echo -e "${YELLOW}6.${NC} Compilar localmente"
    echo -e "${YELLOW}7.${NC} Configurar ambiente"
    echo -e "${YELLOW}8.${NC} Corrigir problemas comuns"
    echo -e "${YELLOW}0.${NC} Sair"
    echo ""
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    read -r option
    
    case $option in
      1)
        pull_changes
        ;;
      2)
        edit_files
        ;;
      3)
        commit_and_push
        ;;
      4)
        run_workflow
        ;;
      5)
        monitor_workflow
        ;;
      6)
        build_locally
        ;;
      7)
        setup_environment
        ;;
      8)
        fix_common_issues
        ;;
      0)
        echo -e "${GREEN}Até logo!${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}Opção inválida.${NC}"
        sleep 1
        ;;
    esac
  done
}

# Iniciar o script
main
