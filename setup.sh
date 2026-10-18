#!/bin/bash

# ====================================================================
# 🎨 কালার কোড ডিফাইন
# ====================================================================
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ====================================================================
# 🚀 ওয়েলকাম ব্যানার (এখানে আপনার নাম/টুলের নাম দিন)
# ====================================================================
clear
echo -e "${CYAN}================================================================${NC}"
echo -e "${GREEN}${BOLD}       🔥 MY-SERVER-AUTO-INSTALLER TOOL 🔥${NC}"
echo -e "${YELLOW}           Created by: [আপনার নাম লিখুন]${NC}"
echo -e "${CYAN}================================================================${NC}"
echo -e "${BOLD}আপনার ক্লাউড/Railway সার্ভার অটো সেটআপের জন্য নিচের তথ্যগুলো দিন:${NC}\n"

# ====================================================================
# 📝 ইউজার থেকে ডায়নামিক ইনপুট নেওয়া
# ====================================================================

# ১. ডোমেইন নাম ইনপুট
while [ -z "$MY_DOMAIN" ]; do
    echo -en "${YELLOW}👉 আপনার ডোমেইন নাম দিন (যেমন: demo.up.railway.app): ${NC}"
    read -r MY_DOMAIN
    if [ -z "$MY_DOMAIN" ]; then
        echo -e "${RED}⚠️  ডোমেইন নাম দেওয়া বাধ্যতামূলক!${NC}"
    fi
done

# ২. ফোল্ডারের নাম ইনপুট
echo -en "${YELLOW}👉 সাইটের ফোল্ডার নাম দিন [ডিফল্ট: mango]: ${NC}"
read -r MY_FOLDER
MY_FOLDER=${MY_FOLDER:-mango} # কিছু না দিলে mango সেট হবে

# ৩. ডাটাবেজ ইউজারনেম
echo -en "${YELLOW}👉 ডাটাবেজ ইউজারনেম দিন [ডিফল্ট: admin]: ${NC}"
read -r DB_USER
DB_USER=${DB_USER:-admin}

# ৪. ডাটাবেজ পাসওয়ার্ড
while [ -z "$DB_PASS" ]; do
    echo -en "${YELLOW}👉 ডাটাবেজ পাসওয়ার্ড দিন: ${NC}"
    read -r DB_PASS
    if [ -z "$DB_PASS" ]; then
        echo -e "${RED}⚠️  পাসওয়ার্ড খালি রাখা যাবে না!${NC}"
    fi
done

echo ""
echo -e "${GREEN}✔ সব তথ্য পাওয়া গেছে! ইনস্টলেশন শুরু হচ্ছে... একটু অপেক্ষা করুন।${NC}"
echo -e "${CYAN}================================================================${NC}\n"

# ব্যাকগ্রাউন্ড কাজের জন্য অটো-ইয়েস সেট করা
export DEBIAN_FRONTEND=noninteractive

# ====================================================================
# ⚙️ ইনস্টলেশন প্রসেস শুরু
# ====================================================================

echo -e "${CYAN}===> [১/৮] সিস্টেম আপডেট ও রিপোজিটরি কনফিগার হচ্ছে...${NC}"
apt update -qq && apt install -y -qq lsb-release ca-certificates apt-transport-https curl unzip psmisc mariadb-server > /dev/null 2>&1
curl -sSLo /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
apt update -qq > /dev/null 2>&1

echo -e "${CYAN}===> [২/৮] Apache ও PHP 8.1 প্যাকেজ ইনস্টল হচ্ছে...${NC}"
apt install -y -qq apache2 php8.1 libapache2-mod-php8.1 php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip php8.1-bcmath > /dev/null 2>&1

echo -e "${CYAN}===> [৩/৮] ionCube Loader সেটআপ হচ্ছে...${NC}"
cd /tmp
curl -sSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o ioncube.tar.gz
tar -xzf ioncube.tar.gz
rm -rf /usr/local/ioncube
mv ioncube /usr/local/
rm -f ioncube.tar.gz
echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_8.1.so" > /etc/php/8.1/mods-available/ioncube.ini
ln -sf /etc/php/8.1/mods-available/ioncube.ini /etc/php/8.1/apache2/conf.d/00-ioncube.ini
ln -sf /etc/php/8.1/mods-available/ioncube.ini /etc/php/8.1/cli/conf.d/00-ioncube.ini
phpdismod -v 8.1 opcache 2>/dev/null

echo -e "${CYAN}===> [৪/৮] ডাটাবেজ তৈরি হচ্ছে...${NC}"
service mariadb start > /dev/null 2>&1
mariadb -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'; GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"

echo -e "${CYAN}===> [৫/৮] phpMyAdmin ইনস্টল হচ্ছে...${NC}"
mkdir -p /var/www/html/phpmyadmin
curl -sSL https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz -o /tmp/pma.tar.gz
tar -xzf /tmp/pma.tar.gz -C /var/www/html/phpmyadmin --strip-components=1
rm -f /tmp/pma.tar.gz

echo -e "${CYAN}===> [৬/৮] File Manager সেটআপ হচ্ছে...${NC}"
mkdir -p /var/www/html/filemanager
curl -sSL https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php -o /var/www/html/filemanager/index.php

echo -e "${CYAN}===> [৭/৮] সাইট ও Apache কনফিগারেশন হচ্ছে...${NC}"
mkdir -p /var/www/html/$MY_FOLDER
echo "Listen 80" > /etc/apache2/ports.conf
a2enmod rewrite headers setenvif mpm_prefork php8.1 2>/dev/null > /dev/null
a2dismod mpm_event mpm_worker php8.2 2>/dev/null > /dev/null
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

cat << EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
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

# টেস্ট ইনডেক্স ফাইল তৈরি
cat << EOF > /var/www/html/$MY_FOLDER/index.php
<?php echo "<h1 style='text-align:center;margin-top:100px;font-family:sans-serif;'>🚀 Server is Live on Port 80 for $MY_DOMAIN</h1>"; ?>
EOF

echo -e "${CYAN}===> [৮/৮] পারমিশন ফিক্স ও Apache রিস্টার্ট হচ্ছে...${NC}"
chmod -R 775 /var/www/html
chown -R www-data:www-data /var/www/html
rm -f /var/run/apache2/apache2.pid
fuser -k 80/tcp 2>/dev/null
apache2ctl restart || service apache2 restart > /dev/null 2>&1

# ====================================================================
# 🎉 ফাইনাল ড্যাশবোর্ড ও ক্রেডেনশিয়াল আউটপুট
# ====================================================================
clear
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}${BOLD}         🎉 অভিনন্দন! সার্ভার সেটআপ সফল হয়েছে! 🎉${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e "${BOLD}📌 সাইট ও সার্ভারের ডিটেইলস:${NC}"
echo -e "   🌐 মূল ওয়েবসাইট:    ${CYAN}https://$MY_DOMAIN${NC}"
echo -e "   📁 ফাইল ডিরেক্টরি:  ${YELLOW}/var/www/html/$MY_FOLDER${NC}"
echo ""
echo -e "${BOLD}🗄️ ডাটাবেজ (phpMyAdmin):${NC}"
echo -e "   🔗 লিঙ্ক:           ${CYAN}https://$MY_DOMAIN/phpmyadmin${NC}"
echo -e "   👤 ইউজার:           ${YELLOW}$DB_USER${NC}"
echo -e "   🔑 পাসওয়ার্ড:       ${YELLOW}$DB_PASS${NC}"
echo ""
echo -e "${BOLD}📂 অনলাইন ফাইল ম্যানেজার (TinyFileManager):${NC}"
echo -e "   🔗 লিঙ্ক:           ${CYAN}https://$MY_DOMAIN/filemanager${NC}"
echo -e "   👤 ডিফল্ট ইউজার:    ${YELLOW}admin${NC}"
echo -e "   🔑 ডিফল্ট পাসওয়ার্ড: ${YELLOW}admin@123${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e "${YELLOW}পরামর্শ: সিকিউরিটির স্বার্থে ফাইল ম্যানেজারের পাসওয়ার্ড পরিবর্তন করে নিন।${NC}"
echo -e "${GREEN}================================================================${NC}\n"
