#!/bin/bash

# Script para iniciar o Jupyter Lab facilmente
# Uso: ./iniciar_jupyter.sh

echo "🚀 Iniciando Jupyter Lab..."
echo ""

# Ativar ambiente virtual
source .venv/bin/activate

# Verificar se está ativado
if [ -z "$VIRTUAL_ENV" ]; then
    echo "❌ Erro: Ambiente virtual não foi ativado!"
    exit 1
fi

echo "✓ Ambiente virtual ativado: $VIRTUAL_ENV"
echo ""

# Iniciar Jupyter Lab
echo "📓 Iniciando Jupyter Lab..."
echo "   O navegador deve abrir automaticamente."
echo "   Se não abrir, copie o link que aparecer abaixo."
echo ""
echo "   Para parar o Jupyter, pressione Ctrl+C"
echo ""

jupyter lab

