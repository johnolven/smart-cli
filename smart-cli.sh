#!/bin/bash

set -e

# Obtener la ruta del script actual
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/smart-cli"
HISTORY_DIR="$CONFIG_DIR/history"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Debug mode por si falla
DEBUG_MODE=false

# Función de registro para depuración
log_debug() {
    if [ "$DEBUG_MODE" = true ]; then
        echo "DEBUG: $1" >&2
    fi
}

# Crear los directorios si no existen
mkdir -p "$CONFIG_DIR"
mkdir -p "$HISTORY_DIR"

# Función para obtener los tokens de API y configurar el modelo
get_api_tokens() {
    log_debug "Obteniendo tokens de API y configurando el modelo"
    if [ ! -f "$CONFIG_FILE" ]; then
        log_debug "Archivo de configuración no existe, creando uno nuevo"
        echo '{"chatgpt_model": "gpt-3.5-turbo", "default_llm": "chatgpt"}' > "$CONFIG_FILE"
    fi

    CHATGPT_TOKEN=$(jq -r '.chatgpt_token' "$CONFIG_FILE")
    CLAUDE_TOKEN=$(jq -r '.claude_token' "$CONFIG_FILE")
    CHATGPT_MODEL=$(jq -r '.chatgpt_model' "$CONFIG_FILE")

    if [ "$CHATGPT_TOKEN" == "null" ] || [ -z "$CHATGPT_TOKEN" ]; then
        read -p "Introduce tu ChatGPT API token: " CHATGPT_TOKEN
        jq --arg token "$CHATGPT_TOKEN" '.chatgpt_token = $token' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    fi

    if [ "$CLAUDE_TOKEN" == "null" ] || [ -z "$CLAUDE_TOKEN" ]; then
        read -p "Introduce tu Claude API token: " CLAUDE_TOKEN
        jq --arg token "$CLAUDE_TOKEN" '.claude_token = $token' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    fi

    if [ "$CHATGPT_MODEL" == "null" ] || [ -z "$CHATGPT_MODEL" ]; then
        CHATGPT_MODEL="gpt-3.5-turbo"
        jq --arg model "$CHATGPT_MODEL" '.chatgpt_model = $model' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    fi

    log_debug "Tokens y modelo guardados en el archivo de configuración"
    log_debug "Configuración actual: $(cat $CONFIG_FILE)"
}

# Función para enviar solicitud a ChatGPT
send_chatgpt_request() {
    local history=$1
    local model=$(jq -r '.chatgpt_model' "$CONFIG_FILE")
    log_debug "Enviando solicitud a ChatGPT. Modelo: $model"
    log_debug "Historia: $history"
    log_debug "Token: ${CHATGPT_TOKEN:0:5}...${CHATGPT_TOKEN: -5}"
    local response=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $CHATGPT_TOKEN" \
    -d '{
        "model": "'"${model}"'",
        "messages": '"${history}"'
    }')
    log_debug "Respuesta completa de ChatGPT: $response"
    echo "$response" | jq -r '.choices[0].message.content // "Error: No se pudo obtener una respuesta válida"'
}

# Función para enviar solicitud a Claude (implementación básica)
send_claude_request() {
    local history=$1
    log_debug "Enviando solicitud a Claude"
    log_debug "Historia: $history"
    log_debug "Token: ${CLAUDE_TOKEN:0:5}...${CLAUDE_TOKEN: -5}"
    local response=$(curl -s https://api.anthropic.com/v1/messages \
    -H "Content-Type: application/json" \
    -H "x-api-key: $CLAUDE_TOKEN" \
    -H "anthropic-version: 2023-06-01" \
    -d '{
        "model": "claude-3-opus-20240229",
        "max_tokens": 1000,
        "messages": '"${history}"'
    }')
    log_debug "Respuesta completa de Claude: $response"
    echo "$response" | jq -r '.content[0].text // "Error: No se pudo obtener una respuesta válida"'
}

# Función para extraer preguntas del historial
extract_questions() {
    local history="$1"
    echo "$history" | jq -r '.[] | select(.role == "user") | .content'
}

# Función para mostrar el historial y continuar la conversación
show_history() {
    echo "Historial de conversaciones:"
    files=($(ls -t "$HISTORY_DIR" | head -n 10))
    select file in "${files[@]}"; do
        if [ -n "$file" ]; then
            echo "Archivo seleccionado: $file"
            HISTORY=$(cat "$HISTORY_DIR/$file")
            echo "$HISTORY"
            
            # Extraer y mostrar solo las preguntas del usuario
            echo "Preguntas realizadas en esta conversación:"
            extract_questions "$HISTORY"
            
            # Preguntar al usuario si quiere continuar esta conversación
            read -p "¿Quieres continuar esta conversación? (s/n): " continue_convo
            if [[ $continue_convo == "s" || $continue_convo == "S" ]]; then
                # Extraer el LLM del nombre del archivo
                if [[ $file == *"_chatgpt_"* ]]; then
                    LLM="chatgpt"
                else
                    LLM="claude"
                fi
                
                # Continuar la conversación
                while true; do
                    read -p "Tú: " user_input
                    if [ "$user_input" == "exit" ]; then
                        break
                    elif [ "$user_input" == "history" ]; then
                        echo "Preguntas realizadas en esta conversación:"
                        extract_questions "$HISTORY"
                        continue
                    fi
                    
                    HISTORY=$(echo "$HISTORY" | jq --arg content "$user_input" '. + [{"role": "user", "content": $content}]')
                    
                    if [ "$LLM" == "chatgpt" ]; then
                        RESPONSE_MESSAGE=$(send_chatgpt_request "$HISTORY")
                    else
                        RESPONSE_MESSAGE=$(send_claude_request "$HISTORY")
                    fi
                    
                    echo "$LLM: $RESPONSE_MESSAGE"
                    
                    HISTORY=$(echo "$HISTORY" | jq --arg content "$RESPONSE_MESSAGE" '. + [{"role": "assistant", "content": $content}]')
                done
                
                # Guardar la conversación actualizada
                echo "$HISTORY" > "$HISTORY_DIR/$file"
                echo "Conversación guardada."
            fi
            break
        else
            echo "Selección inválida. Intenta de nuevo."
        fi
    done
}

# Función para seleccionar el modelo
select_model() {
    local llm=$(jq -r '.default_llm' "$CONFIG_FILE")
    
    if [ "$llm" == "chatgpt" ]; then
        echo "Selecciona el modelo de ChatGPT:"
        models=$(curl -s https://api.openai.com/v1/models \
            -H "Authorization: Bearer $CHATGPT_TOKEN" \
            | jq -r '.data[].id' | grep -E 'gpt-3.5-turbo|gpt-4')
        select model in $models; do
            if [ -n "$model" ]; then
                jq --arg model "$model" '.chatgpt_model = $model' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                echo "Modelo de ChatGPT seleccionado: $model"
                break
            else
                echo "Selección inválida. Intenta de nuevo."
            fi
        done
    elif [ "$llm" == "claude" ]; then
        echo "Selecciona el modelo de Claude:"
        # Nota: Esta lista de modelos puede necesitar actualizaciones según las ofertas actuales de Anthropic
        models="claude-3-5-sonnet-20240620 claude-3-opus-20240229 claude-3-sonnet-20240229 claude-2.1 claude-2.0 claude-instant-1.2"
        select model in $models; do
            if [ -n "$model" ]; then
                jq --arg model "$model" '.claude_model = $model' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                echo "Modelo de Claude seleccionado: $model"
                break
            else
                echo "Selección inválida. Intenta de nuevo."
            fi
        done
    else
        echo "LLM no reconocido. Por favor, selecciona primero un LLM válido usando 'sli -l'."
        exit 1
    fi
}
# Modo interactivo
interactive_mode() {
    local llm=$(jq -r '.default_llm' "$CONFIG_FILE")
    local timestamp=$(date +%Y%m%d%H%M%S)
    local session_file="$HISTORY_DIR/history_${llm}_$timestamp.json"
    local HISTORY='[]'

    echo "Modo interactivo iniciado. Escribe 'exit' para salir o 'history' para ver el historial."
    
    while true; do
        read -p "Tú: " user_input
        if [ "$user_input" == "exit" ]; then
            break
        elif [ "$user_input" == "history" ]; then
            echo "Historial de la conversación:"
            echo "$HISTORY" | jq -r '.[] | select(.role == "user") | .content'
            continue
        fi

        HISTORY=$(echo "$HISTORY" | jq --arg content "$user_input" '. + [{"role": "user", "content": $content}]')
        
        if [ "$llm" == "chatgpt" ]; then
            response=$(send_chatgpt_request "$HISTORY")
        elif [ "$llm" == "claude" ]; then
            response=$(send_claude_request "$HISTORY")
        else
            response="Error: LLM no reconocido"
        fi
        
        if [[ $response == Error:* ]]; then
            echo "Se produjo un error: $response"
            echo "¿Deseas continuar la conversación? (s/n)"
            read continue_choice
            if [[ $continue_choice != "s" && $continue_choice != "S" ]]; then
                break
            fi
            continue
        fi
        
        echo "$llm: $response"
        
        HISTORY=$(echo "$HISTORY" | jq --arg content "$response" '. + [{"role": "assistant", "content": $content}]')
        
        # Guardar la conversación actualizada después de cada interacción
        echo "$HISTORY" > "$session_file"
    done

    echo "Conversación guardada en: $session_file"
}

# Función principal
main() {
    log_debug "Iniciando Smart CLI desde $SCRIPT_PATH"
    get_api_tokens

    # Cargar configuración
    DEFAULT_LLM=$(jq -r '.default_llm // "chatgpt"' "$CONFIG_FILE")
    CHATGPT_TOKEN=$(jq -r '.chatgpt_token' "$CONFIG_FILE")
    CLAUDE_TOKEN=$(jq -r '.claude_token' "$CONFIG_FILE")
    CHATGPT_MODEL=$(jq -r '.chatgpt_model' "$CONFIG_FILE")
    CLAUDE_MODEL=$(jq -r '.claude_model' "$CONFIG_FILE")

    log_debug "Configuración cargada. LLM por defecto: $DEFAULT_LLM"
    log_debug "Modelo ChatGPT: $CHATGPT_MODEL"
    log_debug "Modelo Claude: $CLAUDE_MODEL"

    # Procesar opciones
    while getopts ":imhl" opt; do
        case ${opt} in
            i )
                interactive_mode
                exit 0
                ;;
            m )
                select_model
                exit 0
                ;;
            h )
                show_history
                exit 0
                ;;
            l )
                echo "Selecciona el LLM por defecto:"
                select LLM in "chatgpt" "claude"; do
                    if [ -n "$LLM" ]; then
                        jq --arg llm "$LLM" '.default_llm = $llm' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                        echo "LLM seleccionado: $LLM"
                        break
                    else
                        echo "Selección inválida. Intenta de nuevo."
                    fi
                done
                exit 0
                ;;
            d )
                DEBUG_MODE=true
                ;;
            \? )
                echo "Opción inválida: $OPTARG" 1>&2
                exit 1
                ;;
            : )
                echo "La opción -$OPTARG requiere un argumento." 1>&2
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    # Modo de una sola pregunta si no se pasó ninguna opción
    if [ $# -ne 0 ]; then
        USER_MESSAGE="$*"
        HISTORY=$(jq -n --arg content "$USER_MESSAGE" '[{"role": "user", "content": $content}]')
        
        echo "$DEFAULT_LLM (procesando...)"
        
        if [[ "$DEFAULT_LLM" == "chatgpt" ]]; then
            RESPONSE_MESSAGE=$(send_chatgpt_request "$HISTORY")
        else
            RESPONSE_MESSAGE=$(send_claude_request "$HISTORY")
        fi
        
        tput cuu1 && tput el
        echo "$DEFAULT_LLM: $RESPONSE_MESSAGE"
        
        # Guardar la interacción en el historial
        timestamp=$(date +%Y%m%d%H%M%S)
        session_file="$HISTORY_DIR/history_${DEFAULT_LLM}_$timestamp.json"
        HISTORY=$(jq --arg content "$RESPONSE_MESSAGE" '. + [{"role": "assistant", "content": $content}]' <<< "$HISTORY")
        echo "$HISTORY" > "$session_file"
    else
        echo "Uso: sli [opción] o sli 'tu pregunta'"
        echo "Opciones:"
        echo "  -i  Modo interactivo"
        echo "  -m  Seleccionar modelo"
        echo "  -h  Mostrar historial"
        echo "  -l  Seleccionar LLM (ChatGPT o Claude)"
    fi
}

# Ejecutar la función principal
main "$@"