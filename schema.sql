-- ====================================================================
-- CPANEL1280 PRODUCTION DATABASE SCHEMA (MariaDB / MySQL)
-- Database: cpanel_system
-- ====================================================================

CREATE DATABASE IF NOT EXISTS cpanel_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE cpanel_system;

-- 1. System Users & Admins
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'user') DEFAULT 'admin',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Master Domains / Hosting Services
CREATE TABLE IF NOT EXISTS services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    domain VARCHAR(255) NOT NULL UNIQUE,
    php_version VARCHAR(10) DEFAULT '8.2',
    status VARCHAR(50) DEFAULT 'active',
    document_root VARCHAR(255) DEFAULT '',
    cloudflare_zone_id VARCHAR(255) DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    CONSTRAINT fk_services_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Subdomains
CREATE TABLE IF NOT EXISTS subdomains (
    id INT AUTO_INCREMENT PRIMARY KEY,
    service_id INT NOT NULL,
    subdomain VARCHAR(100) NOT NULL,
    full_domain VARCHAR(255) NOT NULL UNIQUE,
    document_root VARCHAR(255) NOT NULL,
    php_version VARCHAR(10) DEFAULT '8.2',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_service_id (service_id),
    CONSTRAINT fk_subdomains_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. MySQL Databases
CREATE TABLE IF NOT EXISTS databases_list (
    id INT AUTO_INCREMENT PRIMARY KEY,
    service_id INT NOT NULL,
    db_name VARCHAR(100) NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_service_id (service_id),
    CONSTRAINT fk_databases_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. MySQL Database Users
CREATE TABLE IF NOT EXISTS db_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    service_id INT NOT NULL,
    db_user VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_service_id (service_id),
    CONSTRAINT fk_db_users_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Email Accounts (Dovecot Maildir & Postfix virtual_mailboxes)
CREATE TABLE IF NOT EXISTS email_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    service_id INT NOT NULL,
    email_user VARCHAR(100) NOT NULL,
    full_email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    password_plain VARCHAR(255) DEFAULT '',
    quota_mb INT DEFAULT 1024,
    used_kb INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_full_email (full_email),
    CONSTRAINT fk_email_accounts_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Webmail & Inbox/Sent Messages Store
CREATE TABLE IF NOT EXISTS email_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email_account_id INT NOT NULL,
    folder VARCHAR(50) DEFAULT 'INBOX',
    sender VARCHAR(255) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    subject VARCHAR(500) NOT NULL,
    body_text LONGTEXT,
    body_html LONGTEXT,
    is_read BOOLEAN DEFAULT FALSE,
    received_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_account_folder (email_account_id, folder),
    CONSTRAINT fk_email_messages_account FOREIGN KEY (email_account_id) REFERENCES email_accounts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Domain DKIM RSA-2048 Cryptographic Keys
CREATE TABLE IF NOT EXISTS domain_dkim_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    domain VARCHAR(255) UNIQUE NOT NULL,
    selector VARCHAR(50) DEFAULT 'default',
    private_key TEXT NOT NULL,
    public_key TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_domain (domain)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Outbound SMTP Relay Settings (Bypasses Port 25 VPS Block via Brevo/SendGrid/Google)
CREATE TABLE IF NOT EXISTS smtp_relay_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    provider VARCHAR(100) DEFAULT 'brevo',
    relay_host VARCHAR(255) NOT NULL,
    relay_port INT DEFAULT 2525,
    relay_user VARCHAR(255) NOT NULL,
    relay_pass VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Virtual Aliases & Forwarders
CREATE TABLE IF NOT EXISTS virtual_aliases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    source VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    INDEX idx_source (source)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. System Configuration & Initial Setup State
CREATE TABLE IF NOT EXISTS system_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert Default System Settings
INSERT IGNORE INTO system_settings (setting_key, setting_value) VALUES 
('installed', 'false'),
('panel_title', 'Cpanel1280 Cloud Control Panel'),
('master_domain', ''),
('server_ip', ''),
('nameserver1', 'ns1.hoster1280.shop'),
('nameserver2', 'ns2.hoster1280.shop');
