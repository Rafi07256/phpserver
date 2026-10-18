#!/bin/bash
set -e

# Auto-Escalate to Sudo if not root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[1;33m[!] Elevated permissions required. Re-running with sudo...\e[0m"
  exec sudo bash "$0" "$@"
fi

# ====================================================================
# 🎨 COLOR PALETTE & STYLES
# ====================================================================
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"
CYAN="\e[1;36m"
WHITE="\e[1;37m"
RESET="\e[0m"
BOLD="\e[1m"

# ====================================================================
# 🚀 STYLISH BANNER FUNCTION
# ====================================================================
show_banner() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}██████╗ ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗"
    echo -e "██╔══██╗██╔══██╗██║  ██║██╔═══██╗██╔════╝╚══██╔══╝"
    echo -e "██████╔╝██████╔╝███████║██║   ██║███████╗   ██║   "
    echo -e "██╔══██╗██╔══██╗██╔══██║██║   ██║╚════██║   ██║   "
    echo -e "██║  ██║██║  ██║██║  ██║╚██████╔╝███████║   ██║   "
    echo -e "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝   ${RESET}"
    echo -e "${YELLOW}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}       ⚡  R R H O S T   C L O U D   M A N A G E R  ⚡${RESET}"
    echo -e "${WHITE}       Dev: ${CYAN}Rafi${WHITE}  |  Version: ${YELLOW}2.5 Pro${WHITE}  |  System: ${GREEN}Active${WHITE}       ${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# ====================================================================
# 🛠️ FEATURE 1: FRESH INSTALLATION
# ====================================================================
install_server() {
    echo -e "${YELLOW}${BOLD}[*] Fresh Server Setup Initialization:${RESET}\n"

    while [ -z "$MY_DOMAIN" ]; do
        echo -en "${CYAN}[?] Enter Domain Name ${WHITE}(e.g. site.up.railway.app): ${GREEN}"
        read -r MY_DOMAIN
        echo -en "${RESET}"
        MY_DOMAIN=$(echo "$MY_DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        if [ -z "$MY_DOMAIN" ]; then
            echo -e "${RED}[!] Domain cannot be empty!${RESET}"
        fi
    done

    echo -en "${CYAN}[?] Enter Site Folder Name ${WHITE}[Default: mango]: ${GREEN}"
    read -r MY_FOLDER
    echo -en "${RESET}"
    MY_FOLDER=${MY_FOLDER:-mango}

    echo -en "${CYAN}[?] Enter Database Username ${WHITE}[Default: admin]: ${GREEN}"
    read -r DB_USER
    echo -en "${RESET}"
    DB_USER=${DB_USER:-admin}

    while [ -z "$DB_PASS" ]; do
        echo -en "${CYAN}[?] Enter Database Password: ${GREEN}"
        read -r DB_PASS
        echo -en "${RESET}"
        if [ -z "$DB_PASS" ]; then
            echo -e "${RED}[!] Password cannot be empty!${RESET}"
        fi
    done

    echo ""
    echo -e "${GREEN}✔ Configuration Saved. Deploying Server...${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"

    export DEBIAN_FRONTEND=noninteractive

    echo -e "${YELLOW}[>] STEP 1/8:${RESET} Updating packages & PHP repository..."
    apt-get update -qq
    apt-get install -y -qq lsb-release ca-certificates apt-transport-https curl unzip psmisc mariadb-server > /dev/null 2>&1
    curl -sSLo /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
    apt-get update -qq

    echo -e "${YELLOW}[>] STEP 2/8:${RESET} Installing Apache2 & PHP 8.1 Stack..."
    apt-get install -y -qq apache2 php8.1 libapache2-mod-php8.1 php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip php8.1-bcmath > /dev/null 2>&1

    echo -e "${YELLOW}[>] STEP 3/8:${RESET} Installing ionCube Loader..."
    cd /tmp
    curl -sSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o ioncube.tar.gz
    tar -xzf ioncube.tar.gz
    rm -rf /usr/local/ioncube
    mv ioncube /usr/local/
    rm -f ioncube.tar.gz
    echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_8.1.so" > /etc/php/8.1/mods-available/ioncube.ini
    ln -sf /etc/php/8.1/mods-available/ioncube.ini /etc/php/8.1/apache2/conf.d/00-ioncube.ini
    ln -sf /etc/php/8.1/mods-available/ioncube.ini /etc/php/8.1/cli/conf.d/00-ioncube.ini
    phpdismod -v 8.1 opcache 2>/dev/null || true

    echo -e "${YELLOW}[>] STEP 4/8:${RESET} Setting up MariaDB Server..."
    service mariadb start > /dev/null 2>&1
    mariadb -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'; GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"

    echo -e "${YELLOW}[>] STEP 5/8:${RESET} Deploying phpMyAdmin Core..."
    mkdir -p /var/www/html/phpmyadmin
    curl -sSL https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz -o /tmp/pma.tar.gz
    tar -xzf /tmp/pma.tar.gz -C /var/www/html/phpmyadmin --strip-components=1
    rm -f /tmp/pma.tar.gz

    echo -e "${YELLOW}[>] STEP 6/8:${RESET} Setting up Online File Manager..."
    mkdir -p /var/www/html/filemanager
    curl -sSL https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php -o /var/www/html/filemanager/index.php

    echo -e "${YELLOW}[>] STEP 7/8:${RESET} Configuring Apache Routing & VHost..."
    mkdir -p /var/www/html/$MY_FOLDER
    APP_PORT=${PORT:-80}
    echo "Listen $APP_PORT" > /etc/apache2/ports.conf

    a2enmod rewrite headers setenvif mpm_prefork php8.1 2>/dev/null || true
    a2dismod mpm_event mpm_worker 2>/dev/null || true
    sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

    # সেভ ডোমেন ও ফোল্ডার ইনফো ফর ফিউচার চেঞ্জ
    echo "MY_FOLDER=$MY_FOLDER" > /etc/rrhost.conf
    echo "DB_USER=$DB_USER" >> /etc/rrhost.conf

    cat << EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:$APP_PORT>
    ServerName $MY_DOMAIN
    ServerAlias www.$MY_DOMAIN

    SetEnvIf X-Forwarded-Proto "^https$" HTTPS=on
    UseCanonicalName Off
    UseCanonicalPhysicalPort Off

    DocumentRoot /var/www/html/$MY_FOLDER

    <Directory /var/www/html/$MY_FOLDER>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    Alias /filemanager /var/www/html/filemanager
    <Directory /var/www/html/filemanager>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    Alias /phpmyadmin /var/www/html/phpmyadmin
    <Directory /var/www/html/phpmyadmin>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

    cat << EOF > /var/www/html/$MY_FOLDER/index.php
<?php echo "<h1 style='text-align:center;margin-top:100px;font-family:sans-serif;'>🚀 Server is Live on Port $APP_PORT for $MY_DOMAIN</h1>"; ?>
EOF

    echo -e "${YELLOW}[>] STEP 8/8:${RESET} Applying Permissions & Launching..."
    chmod -R 775 /var/www/html
    chown -R www-data:www-data /var/www/html
    service mariadb restart > /dev/null 2>&1

    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${GREEN}${BOLD}             🎉  DEPLOYMENT SUCCESSFUL  🎉                    ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}🌐 WEBSITE DETAILS:${RESET}"
    echo -e "   • Public URL    : ${CYAN}https://$MY_DOMAIN${RESET}"
    echo -e "   • Root Directory: ${YELLOW}/var/www/html/$MY_FOLDER${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}🗄️ DATABASE (phpMyAdmin):${RESET}"
    echo -e "   • Login URL     : ${CYAN}https://$MY_DOMAIN/phpmyadmin${RESET}"
    echo -e "   • User          : ${YELLOW}$DB_USER${RESET}"
    echo -e "   • Password      : ${YELLOW}$DB_PASS${RESET}"
    echo ""
    echo -e "${BOLD}${WHITE}📁 FILE MANAGER (TinyFileManager):${RESET}"
    echo -e "   • Access URL    : ${CYAN}https://$MY_DOMAIN/filemanager${RESET}"
    echo -e "   • Default User  : ${YELLOW}admin${RESET}"
    echo -e "   • Default Pass  : ${YELLOW}admin@123${RESET}"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}[✔] RRHOST Engine is LIVE and Running in Foreground.${RESET}"
    echo -e "${YELLOW}[!] Keep this terminal open to maintain uptime.${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"

    rm -f /var/run/apache2/apache2.pid
    exec apache2ctl -D FOREGROUND
}

# ====================================================================
# 🔄 FEATURE 2: CHANGE DOMAIN (INSTANT 2 SECONDS UPDATE)
# ====================================================================
change_domain() {
    echo -e "${YELLOW}${BOLD}[*] Instant Domain Switcher:${RESET}\n"

    while [ -z "$NEW_DOMAIN" ]; do
        echo -en "${CYAN}[?] Enter NEW Domain Name ${WHITE}(e.g. newdomain.com): ${GREEN}"
        read -r NEW_DOMAIN
        echo -en "${RESET}"
        NEW_DOMAIN=$(echo "$NEW_DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    done

    echo -e "\n${YELLOW}[>] Updating VirtualHost configuration...${RESET}"
    sed -i "s/ServerName .*/ServerName $NEW_DOMAIN/" /etc/apache2/sites-available/000-default.conf
    sed -i "s/ServerAlias www\..*/ServerAlias www.$NEW_DOMAIN/" /etc/apache2/sites-available/000-default.conf

    echo -e "${YELLOW}[>] Reloading Apache Engine...${RESET}"
    apache2ctl graceful > /dev/null 2>&1 || service apache2 restart > /dev/null 2>&1

    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}✔ Domain Successfully Changed!${RESET}"
    echo -e "🔗 New Website URL : ${CYAN}https://$NEW_DOMAIN${RESET}"
    echo -e "🔗 New phpMyAdmin  : ${CYAN}https://$NEW_DOMAIN/phpmyadmin${RESET}"
    echo -e "🔗 New FileManager : ${CYAN}https://$NEW_DOMAIN/filemanager${RESET}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${RESET}\n"
    exit 0
}

# ====================================================================
# 🔑 FEATURE 3: RESET DATABASE PASSWORD
# ====================================================================
reset_db_pass() {
    echo -e "${YELLOW}${BOLD}[*] Reset Database User Password:${RESET}\n"

    echo -en "${CYAN}[?] Database Username ${WHITE}[Default: admin]: ${GREEN}"
    read -r TARGET_USER
    TARGET_USER=${TARGET_USER:-admin}

    while [ -z "$NEW_PASS" ]; do
        echo -en "${CYAN}[?] Enter NEW Database Password: ${GREEN}"
        read -r NEW_PASS
        echo -en "${RESET}"
    done

    echo -e "\n${YELLOW}[>] Updating database privileges...${RESET}"
    service mariadb start > /dev/null 2>&1
    mariadb -e "ALTER USER '$TARGET_USER'@'localhost' IDENTIFIED BY '$NEW_PASS'; FLUSH PRIVILEGES;"

    echo -e "${GREEN}✔ Password updated successfully for user: ${YELLOW}$TARGET_USER${RESET}\n"
    exit 0
}

# ====================================================================
# 🎛️ MAIN CONTROL MENU
# ====================================================================
show_banner

echo -e "${BOLD}${WHITE}Select an action from below:${RESET}"
echo -e "  ${GREEN}[1]${RESET} Fresh Install Server ${WHITE}(Complete Setup)${RESET}"
echo -e "  ${YELLOW}[2]${RESET} Change Domain Name   ${WHITE}(Instant 2-Sec Update)${RESET}"
echo -e "  ${CYAN}[3]${RESET} Reset DB Password    ${WHITE}(Change MySQL Pass)${RESET}"
echo -e "  ${MAGENTA}[4]${RESET} Restart Engine       ${WHITE}(Reboot Apache & MySQL)${RESET}"
echo -e "  ${RED}[0]${RESET} Exit"
echo ""
echo -en "${CYAN}[?] Choose option [0-4]: ${GREEN}"
read -r CHOICE
echo -e "${RESET}"

case $CHOICE in
    1)
        install_server
        ;;
    2)
        change_domain
        ;;
    3)
        reset_db_pass
        ;;
    4)
        echo -e "${YELLOW}[>] Restarting Apache and MariaDB...${RESET}"
        service mariadb restart
        service apache2 restart
        echo -e "${GREEN}✔ All Services Restarted!${RESET}"
        ;;
    0)
        echo -e "${RED}[*] Exiting installer. Goodbye!${RESET}"
        exit 0
        ;;
    *)
        echo -e "${RED}[!] Invalid option selected.${RESET}"
        exit 1
        ;;
esac
