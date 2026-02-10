#!/usr/bin/env bash
#
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# ---------------------------------------------------- #
# Nome do Script: ansible_project.sh
# Descrição: Cria uma estrutura completa de um projeto Ansible.
# Site:
# Escrito por: Marcos
# Manutenção: Marcos
# ---------------------------------------------------- #
# Uso:
#       $ ./ansible_project.sh
# ---------------------------------------------------- #
# Testado em:
#       Bash 5.2.26
# ---------------------------------------------------- #
# Histórico:  v1.0 2025-03-10, Marcos:
#             - script base.
#             v1.1 2025-03-12, Marcos:
#             - Mudanças na estrutura.
#             v1.2 2025-03-15, Marcos:
#             - configuracao basica do ansible.cfg.
#
# ---------------------------------------------------- #
# Agradecimentos: FATEC
#
# ---------------------------------------------------- #
# -------------------- VARIABLES --------------------- #
#
PROJECT_NAME=""
declare -a ROLE_DIRS=("tasks" "handlers" "templates" "files" "vars" "defaults" "meta" "library")
declare -A SERVICE_HOSTS  # Armazena o número de hosts por serviço
#
# ---------------------------------------------------- #
# -------------------- FUNCTIONS --------------------- #
#
# Função para criar diretórios e arquivos básicos de uma role
create_role_structure() {
    local role_path="roles/$1"

    echo "Criando estrutura para a role '$1'..."
    # Criar diretórios
    for dir in "${ROLE_DIRS[@]}"; do
        mkdir -p "$role_path/$dir"
    done

    # Criar arquivos main.yml apenas nos diretórios necessários
    for dir in "${ROLE_DIRS[@]}"; do
        if [[ "$dir" == "tasks"    \
           || "$dir" == "handlers" \
           || "$dir" == "vars"     \
           || "$dir" == "defaults" \
           || "$dir" == "meta" ]]; then
            touch "$role_path/$dir/main.yml"
        fi
    done

    # Criar README.md para a role
    touch "$role_path/README.md"
}

# Função para criar os serviços
create_services() {
    for ((i = 1; i <= NUM_SERVICES; i++)); do
        read -p "Digite o nome do serviço $i: " SERVICE_NAME
        create_role_structure "$SERVICE_NAME"

        # Perguntar quantos hosts serão usados para este serviço
        read -p "Quantos hosts serão usados para o serviço '$SERVICE_NAME'? " NUM_HOSTS
        SERVICE_HOSTS["$SERVICE_NAME"]=$NUM_HOSTS

        # Criar playbook específico para o serviço
        touch "playbooks/${SERVICE_NAME}.yml"
    done
}

# Função para preencher o inventário
add_inventory() {
    local inventory_file="inventory/production"

    echo "Preenchendo o inventário em '$inventory_file'..."

    # Adicionar hosts para cada serviço
    for service in "${!SERVICE_HOSTS[@]}"; do
        num_hosts=${SERVICE_HOSTS[$service]}

        # Adicionar grupo ao inventário
        echo "[${service}_service]" >> "$inventory_file"

        # Adicionar hosts ao grupo
        for ((i = 1; i <= num_hosts; i++)); do
            echo "${service}_host${i}" >> "$inventory_file"
        done

        # Adicionar uma linha em branco para separar grupos
        echo >> "$inventory_file"

        # Criar arquivos de variáveis específicos do grupo
        touch "inventory/group_vars/${service}_service.yml"

        # Criar arquivos de host_vars para cada host do serviço
        for ((i = 1; i <= num_hosts; i++)); do
            touch "inventory/host_vars/${service}_host${i}.yml"
        done
    done

    echo "Inventário preenchido com sucesso!"
}

copy_if_yes() {
    local QUESTION="$1"
    local SRC="$2"
    local DST="$3"

    echo
    read -p "$QUESTION (s/n): " RESP
    case "$RESP" in
        s|S|sim|SIM|y|Y|yes|YES)
            cp "$SRC" "$DST"
            echo "Arquivo copiado: $DST"
            ;;
        *)
            echo "Ignorando."
            ;;
    esac
}

#
# ---------------------------------------------------- #
# --------------------- CHECKS ----------------------- #
#
#
# ---------------------------------------------------- #
# ----------------------- CODE ----------------------- #
#
clear
echo -e "\nBem-vindo ao script de criação de projetos Ansible!\n"

# Solicitar nome do projeto
while [[ -z "$PROJECT_NAME" ]]; do
    read -p "Digite o nome do projeto Ansible: " PROJECT_NAME
done

# Criar diretório raiz do projeto
echo "Criando diretório para o projeto '$PROJECT_NAME'..."
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Criar estrutura básica do projeto
echo "Criando estrutura básica do projeto..."
mkdir -p inventory/{group_vars,host_vars}
mkdir -p playbooks
mkdir -p roles  # Apenas cria o diretório roles, a role 'common' será criada pela função
mkdir -p vars
mkdir -p library
mkdir -p module_utils
mkdir -p filter_plugins

# Criar arquivos básicos
touch inventory/{production,staging,testing}
touch inventory/group_vars/all.yml
touch playbooks/all.yml
touch vars/main.yml
touch ansible.cfg
touch requirements.yml
touch README.md

# Criar estrutura básica para a role 'common' usando a função
create_role_structure "common"

# Perguntar quantos serviços serão necessários
echo
read -p "Quantos serviços você precisa configurar? " NUM_SERVICES

# Criar roles para cada serviço
create_services "$NUM_SERVICES"

# Preencher o inventário automaticamente
add_inventory

# Copiar arquivos pre preenchidos
cd ..
copy_if_yes "Deseja copiar o ansible.cfg?" \
    "./exemplo_ansible.cfg" \
    "$PROJECT_NAME/ansible.cfg"

copy_if_yes "Deseja copiar o group_vars/all.yml?" \
    "./exemplo_inventory/exemplo_group_vars/exemplo_all.yml" \
    "$PROJECT_NAME/inventory/group_vars/all.yml"

copy_if_yes "Deseja copiar o group_vars/linux.yml?" \
    "./exemplo_inventory/exemplo_group_vars/exemplo_linux.yml" \
    "$PROJECT_NAME/inventory/group_vars/linux.yml"

copy_if_yes "Deseja copiar o group_vars/windows.yml?" \
    "./exemplo_inventory/exemplo_group_vars/exemplo_windows.yml" \
    "$PROJECT_NAME/inventory/group_vars/windows.yml"

copy_if_yes "Deseja copiar o group_vars/network.yml?" \
    "./exemplo_inventory/exemplo_group_vars/exemplo_network.yml" \
    "$PROJECT_NAME/inventory/group_vars/network.yml"

# Exibir estrutura criada
echo
if command -v tree &> /dev/null; then
    tree ./"$PROJECT_NAME"
else
    echo "Estrutura do projeto criada em: $(pwd)"
fi

# Exibir resumo dos serviços e hosts
echo -e "\nResumo dos serviços e hosts:"
for service in "${!SERVICE_HOSTS[@]}"; do
    echo "Serviço: $service, Hosts: ${SERVICE_HOSTS[$service]}"
done

echo -e "\nEstrutura do projeto Ansible '$PROJECT_NAME' criada com sucesso!\n"
#
# ---------------------------------------------------- #
# ------------------------ END ----------------------- #

