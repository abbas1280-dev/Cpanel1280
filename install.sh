#!/usr/bin/env bash
# ==============================================================================
# CPANEL1280 MASTER ZERO-TOUCH INSTALLER
# Production Automated Installation Script for Ubuntu 20.04/22.04/24.04 & Debian
# Repository: https://github.com/abbas1280-dev/Cpanel1280
# ==============================================================================

set -e

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root. Run with 'sudo bash install.sh'"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo ""
echo "=========================================================================="
echo "  🚀 Starting Cpanel1280 Engine Installation..."
echo "  ⚡ Automated Linux Hosting, Mail Engine & Control Panel Stack"
echo "=========================================================================="
echo ""

# 2. Detect Operating System
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID
else
    echo "❌ Error: Cannot detect operating system."
    exit 1
fi

echo "📦 Detected OS: ${OS_NAME} ${OS_VERSION}"

# 3. System Update & Essential Tools
echo "🔄 Updating package lists and installing core dependencies..."
apt-get update -y -q
apt-get install -y -q \
    curl wget git software-properties-common ca-certificates \
    lsb-release apt-transport-https build-essential ufw zip unzip tar \
    nano jq net-tools dnsutils ssl-cert

# 4. Install Nginx Web Server
echo "🌐 Installing Nginx Web Server..."
apt-get install -y -q nginx
systemctl enable nginx
systemctl start nginx

# 5. Install MariaDB Database Server
echo "🗄️ Installing MariaDB Database Engine..."
apt-get install -y -q mariadb-server mariadb-client
systemctl enable mariadb
systemctl start mariadb

# 6. Install Node.js LTS (v20)
if ! command -v node >/dev/null 2>&1 || [ "$(node -v | cut -d'.' -f1 | tr -d 'v')" -lt 18 ]; then
    echo "🟢 Installing Node.js LTS (v20)..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y -q nodejs
fi
echo "✅ Node.js $(node -v) & NPM $(npm -v) ready."

# 7. Install PHP FastCGI & Multi-Version Extensions
echo "🐘 Installing PHP Runtime & Modules..."
if [ "$OS_NAME" = "ubuntu" ]; then
    add-apt-repository -y ppa:ondrej/php || true
    apt-get update -y -q
fi

apt-get install -y -q \
    php8.2-fpm php8.2-mysql php8.2-cli php8.2-curl php8.2-gd php8.2-mbstring \
    php8.2-xml php8.2-zip php8.2-bcmath php8.2-soap php8.2-intl || true

# Optional auxiliary PHP versions
apt-get install -y -q php8.1-fpm php8.1-mysql php8.1-cli php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip || true
apt-get install -y -q php8.3-fpm php8.3-mysql php8.3-cli php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml php8.3-zip || true

systemctl enable php8.2-fpm || true
systemctl start php8.2-fpm || true

# 8. Install Mail Server Stack (Postfix + Dovecot)
echo "✉️ Installing In-House Mail Stack (Postfix SMTP & Dovecot Maildir)..."
debconf-set-selections <<< "postfix postfix/mailname string localhost"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

apt-get install -y -q \
    postfix postfix-mysql \
    dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql \
    bind9 bind9utils certbot python3-certbot-nginx

# 9. Create Dedicated vmail User & Storage
echo "📂 Configuring Maildir and Web Hosting Directories..."
groupadd -g 5000 vmail 2>/dev/null || true
useradd -g vmail -u 5000 vmail -d /var/vmail -m -s /usr/sbin/nologin 2>/dev/null || true
mkdir -p /var/vmail /var/www/vhosts /etc/postfix/sql /etc/dovecot/conf.d
chown -R vmail:vmail /var/vmail
chmod -R 770 /var/vmail

# 10. Deploy Postfix & Dovecot Configurations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "⚙️ Applying Postfix & Dovecot Configuration Templates..."
if [ -d "${SCRIPT_DIR}/configs/postfix" ]; then
    cp -f "${SCRIPT_DIR}/configs/postfix/main.cf" /etc/postfix/main.cf
    cp -f "${SCRIPT_DIR}/configs/postfix/master.cf" /etc/postfix/master.cf
    cp -rf "${SCRIPT_DIR}/configs/postfix/sql/"* /etc/postfix/sql/
    chmod 640 /etc/postfix/sql/*.cf || true
fi

if [ -d "${SCRIPT_DIR}/configs/dovecot" ]; then
    cp -f "${SCRIPT_DIR}/configs/dovecot/dovecot.conf" /etc/dovecot/dovecot.conf
    cp -f "${SCRIPT_DIR}/configs/dovecot/dovecot-sql.conf.ext" /etc/dovecot/dovecot-sql.conf.ext
    cp -rf "${SCRIPT_DIR}/configs/dovecot/conf.d/"* /etc/dovecot/conf.d/
    chmod 640 /etc/dovecot/dovecot-sql.conf.ext || true
fi

# Ensure snakeoil SSL cert exists
make-ssl-cert generate-default-snakeoil --force-overwrite 2>/dev/null || true

# 11. Database Setup & Schema Initialization
echo "🗃️ Setting up MariaDB 'cpanel_system' database..."
mariadb -u root <<EOF
CREATE USER IF NOT EXISTS 'cpanel_admin'@'localhost' IDENTIFIED BY 'cPanelSecurePass2026!';
GRANT ALL PRIVILEGES ON *.* TO 'cpanel_admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

if [ -f "${SCRIPT_DIR}/schema.sql" ]; then
    mariadb -u root < "${SCRIPT_DIR}/schema.sql" || mariadb -u cpanel_admin -pcPanelSecurePass2026! < "${SCRIPT_DIR}/schema.sql"
    echo "✅ Database schema loaded successfully."
fi

# 12. Deploy Application Core
APP_DIR="/opt/cpanel-core"
echo "🚀 Deploying Cpanel1280 Core to ${APP_DIR}..."
mkdir -p "${APP_DIR}"
cp -rf "${SCRIPT_DIR}/"* "${APP_DIR}/"

cd "${APP_DIR}"
echo "📦 Installing Node.js production dependencies..."
npm install --omit=dev --loglevel=error

# 13. Setup Systemd Service
echo "⚡ Registering systemd background service..."
if [ -f "${SCRIPT_DIR}/configs/systemd/cpanel-core.service" ]; then
    cp -f "${SCRIPT_DIR}/configs/systemd/cpanel-core.service" /etc/systemd/system/cpanel-core.service
    systemctl daemon-reload
    systemctl enable cpanel-core.service
    systemctl restart cpanel-core.service
fi

# 14. Configure Default Nginx Reverse Proxy
echo "🌐 Configuring Nginx reverse proxy..."
if [ -f "${SCRIPT_DIR}/configs/nginx/cpanel-nginx.conf" ]; then
    cp -f "${SCRIPT_DIR}/configs/nginx/cpanel-nginx.conf" /etc/nginx/sites-available/default
    nginx -t && systemctl restart nginx
fi

# Restart Mail Services
systemctl restart postfix dovecot

# 15. Configure Firewall (UFW)
echo "🛡️ Configuring Firewall rules (Ports: 80, 443, 3000, 25, 587, 465, 143, 993, 2525)..."
ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 3000/tcp || true
ufw allow 25/tcp || true
ufw allow 587/tcp || true
ufw allow 465/tcp || true
ufw allow 143/tcp || true
ufw allow 993/tcp || true
ufw allow 110/tcp || true
ufw allow 995/tcp || true
ufw allow 2525/tcp || true

# 16. Detect VPS Public IP
SERVER_IP=$(curl -s -4 --connect-timeout 3 https://api.ipify.org || curl -s --connect-timeout 3 https://ifconfig.me || hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="127.0.0.1"
fi

# Store detected IP in system_settings
mariadb -u root -e "USE cpanel_system; INSERT INTO system_settings (setting_key, setting_value) VALUES ('server_ip', '${SERVER_IP}') ON DUPLICATE KEY UPDATE setting_value = '${SERVER_IP}';" 2>/dev/null || true

echo ""
echo "=========================================================================="
echo "  🎉 CONGRATULATIONS! CPANEL1280 INSTALLED SUCCESSFULLY!"
echo "=========================================================================="
echo ""
echo "  👉 INITIAL SETUP WIZARD LINK:"
echo "     http://${SERVER_IP}:3000/install-wizard"
echo "     (or: http://${SERVER_IP}/install-wizard)"
echo ""
echo "  📋 NEXT STEPS:"
echo "  1. Open the URL above in your web browser."
echo "  2. Enter your master domain (e.g. yourdomain.com) and admin password."
echo "  3. Select Cloudflare Auto-Pilot or Manual DNS."
echo "  4. Click 'Complete Setup' - your panel will be live at https://yourdomain.com/tpanel!"
echo ""
echo "  🛠️ SYSTEM SERVICES STATUS:"
echo "     • Control Panel Core : systemctl status cpanel-core"
echo "     • Nginx Web Server   : systemctl status nginx"
echo "     • MariaDB Database   : systemctl status mariadb"
echo "     • Postfix Mail MTA   : systemctl status postfix"
echo "     • Dovecot Maildir    : systemctl status dovecot"
echo "=========================================================================="
echo ""
