#!/usr/bin/env bash
#
# ---------------------------------------------------- #
# Nome do Script: ansible_project2.sh
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
# Histórico: v2.0 2025-03-12, Marcos:
#             - Mudanças na estrutura.
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
        if [[ "$dir" == "tasks" || "$dir" == "handlers" || "$dir" == "vars" || "$dir" == "defaults" || "$dir" == "meta" ]]; then
            touch "$role_path/$dir/main.yml"
        fi
    done

    # Criar README.md para a role
    touch "$role_path/README.md"
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

# Criar arquivo ansible.cfg com configuração simplificada
cat <<EOF > ansible.cfg
[defaults]
inventory = ./inventory/
roles_path = ./roles
remote_user = ansible_user
become = True
become_method = sudo
become_user = root
timeout = 10

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
EOF

# Criar estrutura básica para a role 'common' usando a função
create_role_structure "common"

# Perguntar quantos serviços serão necessários
echo
read -p "Quantos serviços você precisa configurar? " NUM_SERVICES

# Loop para criar roles para cada serviço
for ((i = 1; i <= NUM_SERVICES; i++)); do
    read -p "Digite o nome do serviço $i: " SERVICE_NAME
    create_role_structure "$SERVICE_NAME"

    # Perguntar quantos hosts serão usados para este serviço
    read -p "Quantos hosts serão usados para o serviço '$SERVICE_NAME'? " NUM_HOSTS
    SERVICE_HOSTS["$SERVICE_NAME"]=$NUM_HOSTS

    # Criar arquivos de variáveis específicos do grupo
    touch "inventory/group_vars/${SERVICE_NAME}_service.yml"

    # Criar playbook específico para o serviço
    touch "playbooks/${SERVICE_NAME}.yml"

    # Criar arquivos de host_vars para cada host do serviço
    for ((j = 1; j <= NUM_HOSTS; j++)); do
        touch "inventory/host_vars/${SERVICE_NAME}_host${j}.yml"
    done
done

# Exibir estrutura criada
echo
if command -v tree &> /dev/null; then
    tree ../"$PROJECT_NAME"
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

