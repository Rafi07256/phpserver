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

clear

# ====================================================================
# 🚀 STYLISH TERMINAL BANNER
# ====================================================================
echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo -e "${MAGENTA}   ____  __  ______     _____ ______  _    ____________ "
echo -e "  / __ \/ / / / __ \   / ___// ____/ / |  / / ____/ __ \\"
echo -e " / /_/ / /_/ / /_/ /   \__ \/ __/   /  | / / __/ / /_/ /"
echo -e "/ ____/ __  / ____/   ___/ / /___  / /| |/ /___/ _, _/  "
echo -e "/_/   /_/ /_/_/       /____/_____/ /_/ |_/_____/_/ |_|   ${RESET}"
echo -e "${YELLOW}══════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}     ⚡  A U T O - D E P L O Y   W E B   S E R V E R  ⚡${RESET}"
echo -e "${WHITE}       Dev: ${CYAN}Rafi${WHITE}  |  Version: ${YELLOW}2.0 Pro${WHITE}  |  System: ${GREEN}Active${WHITE}       ${RESET}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""

# ====================================================================
# 📝 USER CONFIGURATION INPUTS
# ====================================================================
echo -e "${YELLOW}${BOLD}[*] Please configure your server parameters:${RESET}\n"

# Domain Name
while [ -z "$MY_DOMAIN" ]; do
    echo -en "${CYAN}[?] Enter Domain Name ${WHITE}(e.g. site.up.railway.app): ${GREEN}"
    read -r MY_DOMAIN
    echo -en "${RESET}"
    # Clean protocols if user adds http/https
    MY_DOMAIN=$(echo "$MY_DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    if [ -z "$MY_DOMAIN" ]; then
        echo -e "${RED}[!] Domain cannot be empty!${RESET}"
    fi
done

# Root Directory
echo -en "${CYAN}[?] Enter Site Folder Name ${WHITE}[Default: mango]: ${GREEN}"
read -r MY_FOLDER
echo -en "${RESET}"
MY_FOLDER=${MY_FOLDER:-mango}

# Database Username
echo -en "${CYAN}[?] Enter Database Username ${WHITE}[Default: admin]: ${GREEN}"
read -r DB_USER
echo -en "${RESET}"
DB_USER=${DB_USER:-admin}

# Database Password
while [ -z "$DB_PASS" ]; do
    echo -en "${CYAN}[?] Enter Database Password: ${GREEN}"
    read -r DB_PASS
    echo -en "${RESET}"
    if [ -z "$DB_PASS" ]; then
        echo -e "${RED}[!] Password cannot be empty!${RESET}"
    fi
done

echo ""
echo -e "${GREEN}✔ Credentials Verified. Starting Automated Setup...${RESET}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"

export DEBIAN_FRONTEND=noninteractive

# ====================================================================
# ⚙️ INSTALLATION ENGINE
# ====================================================================

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

echo -e "${YELLOW}[>] STEP 8/8:${RESET} Applying Permissions & Launching Engine..."
chmod -R 775 /var/www/html
chown -R www-data:www-data /var/www/html
service mariadb restart > /dev/null 2>&1

# ====================================================================
# 🎉 FINAL DASHBOARD SUMMARY (CLEAN & PROFESSIONAL)
# ====================================================================
clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${GREEN}${BOLD}             🎉  DEPLOYMENT SUCCESSFUL  🎉                    ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${BOLD}${WHITE}🌐 WEBSITE DETAILS:${RESET}"
echo -e "   • Public URL   : ${CYAN}https://$MY_DOMAIN${RESET}"
echo -e "   • Root Directory: ${YELLOW}/var/www/html/$MY_FOLDER${RESET}"
echo ""
echo -e "${BOLD}${WHITE}🗄️ DATABASE (phpMyAdmin):${RESET}"
echo -e "   • Login URL    : ${CYAN}https://$MY_DOMAIN/phpmyadmin${RESET}"
echo -e "   • User         : ${YELLOW}$DB_USER${RESET}"
echo -e "   • Password     : ${YELLOW}$DB_PASS${RESET}"
echo ""
echo -e "${BOLD}${WHITE}📁 FILE MANAGER (TinyFileManager):${RESET}"
echo -e "   • Access URL   : ${CYAN}https://$MY_DOMAIN/filemanager${RESET}"
echo -e "   • Default User : ${YELLOW}admin${RESET}"
echo -e "   • Default Pass : ${YELLOW}admin@123${RESET}"
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}[✔] Engine is LIVE and Running in Foreground.${RESET}"
echo -e "${YELLOW}[!] Keep this terminal open to maintain uptime.${RESET}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"

# Run Apache in foreground
rm -f /var/run/apache2/apache2.pid
exec apache2ctl -D FOREGROUND
