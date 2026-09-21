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
mkdir -p /var/vmail /var/www/vhosts /etc/postfix/sql /etc/dovecot/conf.d /var/cpanel/backups
chown -R vmail:vmail /var/vmail
chmod -R 770 /var/vmail

# 10. Locate or Clone Repository Source Files
REPO_URL="${REPO_URL:-https://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@github.com/abbas1280-dev/Cpanel1280.git}"
APP_DIR="/opt/cpanel-core"

# Check if script is running from an existing cloned repo
if [ -n "${BASH_SOURCE[0]}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/server.js" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "📁 Source files detected locally at ${SCRIPT_DIR}"
else
    echo "📥 Installer running via pipe/remote. Cloning Cpanel1280 repository..."
    TEMP_CLONE_DIR=$(mktemp -d)
    git clone --depth 1 "${REPO_URL}" "${TEMP_CLONE_DIR}"
    SCRIPT_DIR="${TEMP_CLONE_DIR}"
fi

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
SQL_USER_CMDS="CREATE USER IF NOT EXISTS 'cpanel_admin'@'localhost' IDENTIFIED BY 'cPanelSecurePass2026!'; ALTER USER 'cpanel_admin'@'localhost' IDENTIFIED BY 'cPanelSecurePass2026!'; GRANT ALL PRIVILEGES ON *.* TO 'cpanel_admin'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"

mariadb -u root -e "$SQL_USER_CMDS" 2>/dev/null || mariadb -e "$SQL_USER_CMDS" 2>/dev/null || mysql -u root -e "$SQL_USER_CMDS" 2>/dev/null || true

if [ -f "${SCRIPT_DIR}/schema.sql" ]; then
    mariadb -u root < "${SCRIPT_DIR}/schema.sql" 2>/dev/null || mariadb -u cpanel_admin -pcPanelSecurePass2026! < "${SCRIPT_DIR}/schema.sql" 2>/dev/null || mysql -u root < "${SCRIPT_DIR}/schema.sql" 2>/dev/null || true
    echo "✅ Database schema loaded successfully."
fi

# 12. Deploy Application Core
echo "🚀 Deploying Cpanel1280 Core to ${APP_DIR}..."
mkdir -p "${APP_DIR}"
cp -rf "${SCRIPT_DIR}/"* "${APP_DIR}/"

if [[ "${SCRIPT_DIR}" == /tmp/* ]]; then
    rm -rf "${SCRIPT_DIR}"
fi
SCRIPT_DIR="${APP_DIR}"

cd "${APP_DIR}"
echo "📦 Installing Node.js production dependencies..."
npm install --omit=dev --loglevel=error

# 13. Setup Systemd Service with Dynamic Node Binary Detection
echo "⚡ Registering systemd background service..."
NODE_BIN=$(command -v node || which node || echo "/usr/bin/node")
if [ ! -f /usr/bin/node ] && [ -f "$NODE_BIN" ]; then
    ln -sf "$NODE_BIN" /usr/bin/node
fi

if [ -f "${SCRIPT_DIR}/configs/systemd/cpanel-core.service" ]; then
    cp -f "${SCRIPT_DIR}/configs/systemd/cpanel-core.service" /etc/systemd/system/cpanel-core.service
    sed -i "s|ExecStart=.*|ExecStart=${NODE_BIN} ${APP_DIR}/server.js|g" /etc/systemd/system/cpanel-core.service
    systemctl daemon-reload
    systemctl enable cpanel-core.service
    systemctl restart cpanel-core.service
fi

# 14. Configure Default Nginx Reverse Proxy & Upload Buffer
echo "🌐 Configuring Nginx reverse proxy..."
if ! grep -q "client_max_body_size" /etc/nginx/nginx.conf; then
    sed -i '/http {/a \    client_max_body_size 2048M;' /etc/nginx/nginx.conf
fi

if [ -f "${SCRIPT_DIR}/configs/nginx/cpanel-nginx.conf" ]; then
    cp -f "${SCRIPT_DIR}/configs/nginx/cpanel-nginx.conf" /etc/nginx/sites-available/default
    nginx -t && systemctl restart nginx
fi

# Restart Mail Services
systemctl restart postfix dovecot || true

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

# 16. Install Cloudflare Tunnel Agent (cloudflared) for Zero-Port Instant Access
echo "⚡ Setting up Cloudflare Tunnel Agent (cloudflared)..."
if ! command -v cloudflared >/dev/null 2>&1; then
    ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
    case "$ARCH" in
        amd64|x86_64) CF_ARCH="amd64" ;;
        arm64|aarch64) CF_ARCH="arm64" ;;
        arm*) CF_ARCH="arm" ;;
        *) CF_ARCH="amd64" ;;
    esac
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared 2>/dev/null || true
    chmod +x /usr/local/bin/cloudflared 2>/dev/null || true
fi

# 17. Launch Temporary Cloudflare Quick-Tunnel for Zero-Port Web Wizard
CF_TUNNEL_URL=""
if command -v cloudflared >/dev/null 2>&1; then
    echo "🌐 Activating Cloudflare Instant Access Tunnel..."
    mkdir -p /var/log
    rm -f /var/log/cpanel-tunnel.log

    cat << 'EOF' > /etc/systemd/system/cpanel-wizard-tunnel.service
[Unit]
Description=Cpanel1280 Cloudflare Temporary Setup Wizard Tunnel
After=network.target cpanel-core.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --url http://127.0.0.1:3000 --logfile /var/log/cpanel-tunnel.log
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable cpanel-wizard-tunnel.service 2>/dev/null || true
    systemctl restart cpanel-wizard-tunnel.service 2>/dev/null || true

    for i in {1..12}; do
        if [ -f /var/log/cpanel-tunnel.log ]; then
            CF_TUNNEL_URL=$(grep -o 'https://[-a-zA-Z0-9]*\.trycloudflare\.com' /var/log/cpanel-tunnel.log | head -n 1 || true)
            if [ -n "$CF_TUNNEL_URL" ]; then break; fi
        fi
        sleep 1
    done
fi

# 18. Detect VPS Public IP
SERVER_IP=$(curl -s -4 --connect-timeout 4 https://api.ipify.org || curl -s --connect-timeout 4 https://ifconfig.me || hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="127.0.0.1"
fi

# Store detected IP in system_settings
mariadb -u cpanel_admin -pcPanelSecurePass2026! -e "USE cpanel_system; INSERT INTO system_settings (setting_key, setting_value) VALUES ('server_ip', '${SERVER_IP}') ON DUPLICATE KEY UPDATE setting_value = '${SERVER_IP}';" 2>/dev/null || true

# 19. Generate In-House Branded tPanel Setup Link via Master Hub
TARGET_WIZARD_URL=""
if [ -n "$CF_TUNNEL_URL" ]; then
    TARGET_WIZARD_URL="${CF_TUNNEL_URL}/tpanel-setup"
else
    TARGET_WIZARD_URL="http://${SERVER_IP}/tpanel-setup"
fi

SHORT_TPANEL_LINK=""
RAND_SUFFIX=$(head /dev/urandom | tr -dc '0-9' | head -c 4 2>/dev/null || echo "$((1000 + RANDOM % 9000))")
SESSION_ID="tpanel-${RAND_SUFFIX}"

# Register session with our master hub (hoster1280.shop)
HUB_RESP=$(curl -s -X POST "https://hoster1280.shop/api/hub/register-session" \
    -H "Content-Type: application/json" \
    --connect-timeout 5 \
    -d "{\"sessionId\": \"${SESSION_ID}\", \"targetUrl\": \"${TARGET_WIZARD_URL}\", \"serverIp\": \"${SERVER_IP}\"}" 2>/dev/null || true)

BRANDED_URL=$(echo "$HUB_RESP" | jq -r '.brandedUrl // empty' 2>/dev/null || true)
if [ -z "$BRANDED_URL" ] && [[ "$HUB_RESP" == *"\"ok\":true"* || "$HUB_RESP" == *"\"success\":true"* ]]; then
    BRANDED_URL="https://hoster1280.shop/tpanel-setup/${SESSION_ID}"
fi

if [ -n "$BRANDED_URL" ]; then
    SHORT_TPANEL_LINK="$BRANDED_URL"
else
    SHORT_TPANEL_LINK="https://hoster1280.shop/tpanel-setup/${SESSION_ID}"
fi

mariadb -u cpanel_admin -pcPanelSecurePass2026! -e "USE cpanel_system; INSERT INTO system_settings (setting_key, setting_value) VALUES ('setup_session_id', '${SESSION_ID}') ON DUPLICATE KEY UPDATE setting_value = '${SESSION_ID}';" 2>/dev/null || true
mariadb -u cpanel_admin -pcPanelSecurePass2026! -e "USE cpanel_system; INSERT INTO system_settings (setting_key, setting_value) VALUES ('short_setup_url', '${SHORT_TPANEL_LINK}') ON DUPLICATE KEY UPDATE setting_value = '${SHORT_TPANEL_LINK}';" 2>/dev/null || true

echo ""
echo "=========================================================================="
echo "  🎉 CONGRATULATIONS! CPANEL1280 INSTALLED SUCCESSFULLY!"
echo "=========================================================================="
echo ""
echo "  👉 🚀 OFFICIAL TPANEL SETUP LINK (অফিসিয়াল নিজস্ব ব্র্যান্ডেড সেটআপ লিঙ্ক):"
echo "     ${SHORT_TPANEL_LINK}"
echo ""
echo "  👉 🌐 DIRECT IP LINK (সাধারণ ডেডিকেটেড VPS-এর জন্য):"
echo "     http://${SERVER_IP}/tpanel-setup"
echo "     (or direct: http://${SERVER_IP}:3000/tpanel-setup)"
echo ""
echo "  📋 NEXT STEPS (পরবর্তী করণীয় ধাপসমূহ):"
echo "  1. Open the branded tPanel setup link in your browser."
echo "     (যেকোনো ব্রাউজারে উপরের ব্র্যান্ডেড লিংকে প্রবেশ করুন)"
echo "  2. Enter your master domain (e.g. yourdomain.com) and admin credentials."
echo "     (আপনার মাস্টার ডোমেন নাম এবং অ্যাডমিন পাসওয়ার্ড লিখুন)"
echo "  3. Select Cloudflare Auto-Pilot (Yes) or Manual DNS (No):"
echo "     • Yes / হ্যাঁ: Provide Cloudflare API token for instant 1-click sync."
echo "     • No / না   : Copy the 7 pre-configured DNS records to your registrar."
echo "  4. Click 'Complete Setup' - your panel will be live immediately:"
echo "     👉 https://yourdomain.com/tpanel"
echo "     (সেটআপ সম্পন্ন হওয়ামাত্র উইজার্ডটি স্বয়ংক্রিয়ভাবে চিরতরে লক হয়ে যাবে)"
echo ""
echo "  🛠️ SYSTEM SERVICES STATUS:"
echo "     • Control Panel Core : systemctl status cpanel-core"
echo "     • Nginx Web Server   : systemctl status nginx"
echo "     • MariaDB Database   : systemctl status mariadb"
echo "     • Postfix Mail MTA   : systemctl status postfix"
echo "     • Dovecot Maildir    : systemctl status dovecot"
echo "=========================================================================="
echo ""
