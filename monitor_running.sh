#!/data/data/com.termux/files/usr/bin/bash

# Script para monitorar execuções em andamento e baixar o APK quando concluídas

# IDs das execuções em andamento
RUN_ID1="14805003423"
RUN_ID2="14804997488"

# Função para verificar o status de uma execução
check_run() {
  local run_id=$1
  echo "🔍 Verificando execução $run_id..."
  
  # Verificar o status
  local status=$(gh run view $run_id --json status -q .status)
  local conclusion=$(gh run view $run_id --json conclusion -q .conclusion 2>/dev/null || echo "em_andamento")
  
  echo "📊 Status: $status, Conclusão: $conclusion"
  
  # Se o workflow estiver concluído, verificar o resultado
  if [ "$status" = "completed" ]; then
    if [ "$conclusion" = "success" ]; then
      echo "🎉 Workflow concluído com sucesso!"
      echo "⬇️ Baixando o APK..."
      
      mkdir -p ~/downloads
      gh run download $run_id --dir ~/downloads
      
      if [ $? -eq 0 ]; then
        echo "✅ APK baixado com sucesso para a pasta ~/downloads"
        
        # Listar os arquivos baixados
        ls -la ~/downloads
        
        # Copiar para a pasta de downloads do Android (se acessível)
        if [ -d "/storage/emulated/0/Download" ]; then
          find ~/downloads -name "*.apk" -exec cp {} /storage/emulated/0/Download/ \;
          if [ $? -eq 0 ]; then
            echo "✅ APK copiado para /storage/emulated/0/Download/"
          else
            echo "⚠️ Não foi possível copiar o APK para a pasta de downloads do Android."
          fi
        fi
        return 0
      else
        echo "❌ Erro ao baixar o APK."
        return 1
      fi
    else
      echo "❌ Workflow falhou ou foi cancelado."
      echo "🔍 Veja os logs para mais detalhes:"
      gh run view $run_id --log
      return 1
    fi
  else
    echo "⏳ Workflow ainda está em andamento."
    return 2
  fi
}

# Loop principal
echo "🔄 Iniciando monitoramento das execuções em andamento..."
echo "   Pressione Ctrl+C para interromper."

while true; do
  clear
  date
  echo "===================================================="
  
  # Verificar a primeira execução
  echo "📋 Execução 1 (manual via workflow_dispatch):"
  check_run $RUN_ID1
  result1=$?
  
  echo "===================================================="
  
  # Verificar a segunda execução
  echo "📋 Execução 2 (automática via push):"
  check_run $RUN_ID2
  result2=$?
  
  echo "===================================================="
  
  # Se ambas as execuções estiverem concluídas, sair do loop
  if [ $result1 -ne 2 ] && [ $result2 -ne 2 ]; then
    echo "✅ Todas as execuções monitoradas foram concluídas."
    break
  fi
  
  echo "🕒 Verificando novamente em 30 segundos..."
  sleep 30
done

echo "🎉 Monitoramento concluído!"
