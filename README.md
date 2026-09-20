# Cpanel1280 ⚡ Autonomous Web Hosting Control Panel & In-House Mail Engine

> **Production-ready, Zero-Touch alternative to cPanel/WHM for Ubuntu & Debian VPS with built-in Postfix/Dovecot Mail Stack, DKIM, Cloudflare Auto-Pilot, File Manager, and Multi-Version PHP.**

---

## 🚀 1-Command Automated VPS Installation (১-ক্লিক ইনস্টলেশন)

যেকোনো ফ্রেশ **Ubuntu 20.04 / 22.04 / 24.04** অথবা **Debian 11 / 12** ভিপিএসে রুট ইউজার হিসেবে নিচের কমান্ডটি রান করুন:

```bash
git clone https://github.com/abbas1280-dev/Cpanel1280.git && cd Cpanel1280 && sudo bash install.sh
```

অথবা কার্ল (curl) দিয়ে সরাসরি ওয়ান-লাইনে ইনস্টল করতে পারেন:

```bash
curl -sSL https://raw.githubusercontent.com/abbas1280-dev/Cpanel1280/main/install.sh | sudo bash
```

---

## 🌟 ইনস্টলেশন পরবর্তী ওয়েব সেটআপ উইজার্ড (Web Setup Wizard)

ইনস্টলেশন সম্পন্ন হওয়ার সাথে সাথে টার্মিনালে আপনাকে একটি কাস্টম ওয়েব উইজার্ড লিংক দেওয়া হবে:

```text
==========================================================================
  🎉 CONGRATULATIONS! CPANEL1280 INSTALLED SUCCESSFULLY!
==========================================================================

  👉 INITIAL SETUP WIZARD LINK:
     http://<YOUR_VPS_IP>:3000/install-wizard
     (or http://<YOUR_VPS_IP>/install-wizard)
==========================================================================
```

### ব্রাউজারে উইজার্ড ওপেন করে যা করবেন:
1. **System Health Verification:** Nginx, MariaDB, Postfix এবং Dovecot সার্ভিসের লাইভ স্ট্যাটাস দেখতে পাবেন।
2. **Master Domain & Admin Credentials:**
   - আপনার প্রধান ডোমেইন নাম লিখুন (যেমন: `tamim1280.shop` বা `yourdomain.com`)।
   - অ্যাডমিন ইউজারনেম এবং সুরক্ষিত পাসওয়ার্ড দিন।
3. **DNS Routing & Email Method:**
   - **অপশন ১ (Cloudflare Auto-Pilot):** আপনার Cloudflare API Token দিলে সার্ভার স্বয়ংক্রিয়ভাবে A রেকর্ড, CNAME এবং **৫টি পার্মানেন্ট ইমেইল রেকর্ড (MX, mail A, SPF, DKIM, DMARC)** ক্লাউডফ্লেয়ারে বসিয়ে দিবে। ম্যানুয়ালি কোনো কপি-পেস্ট করা লাগবে না!
   - **অপশন ২ (Manual DNS / Nameservers):** ক্লাউডফ্লেয়ার না থাকলে সার্ভার আপনাকে সবকটি ডিএনএস রেকর্ডের (2048-bit RSA DKIM সহ) রেডিমেড কপি ভ্যালু প্রদর্শন করবে যা যেকোনো ডোমেন প্যানেলে ১ ক্লিকে পেস্ট করতে পারবেন।
4. **Final Launch:** সেটআপ বাটনে ক্লিক করামাত্রই আপনার কন্ট্রোল প্যানেল সরাসরি `https://yourdomain.com/tpanel`-এ লাইভ হয়ে যাবে!

---

## 💎 প্রধান ফিচারসমূহ (Core Features)

### ১. ইন-হাউস মেল সার্ভার ও ওয়েবমেইল (Complete Mail Stack)
- **Postfix SMTP MTA:** ইনকামিং ও আউটগোয়িং পোর্ট ২৫, ৫৮৭ এবং ৪৬৫ (SMTPS) ফুল সাপোর্ট।
- **Dovecot Maildir Engine:** নিরাপদ IMAP (Port 993 SSL, 143) ও POP3 (Port 995 SSL, 110)।
- **2048-bit RSA DKIM Engine:** প্রতিটি ডোমেইনের জন্য ইউনিক ক্রিপ্টোগ্রাফিক কি স্বয়ংক্রিয়ভাবে জেনারেট হয়।
- **In-Panel Slide-Over Webmail:** কোনো থার্ড-পার্টি অ্যাপ ছাড়াই প্যানেলের ডান পাশ থেকে স্লাইড-ওভার উইন্ডোতে সরাসরি যেকোনো মেইলবক্স থেকে মেইল পড়া ও পাঠানো যায়।
- **Invoice & Software Automation:** মোবাইল বা যেকোনো পিএইচপি/নোডজেএস বিলিং স্ক্রিপ্টের জন্য রেডিমেড কোড স্নিপেট।
- **Outbound SMTP Relay Support:** ডিজিটালওশান বা ক্লাউড ভিপিএসের পোর্ট ২৫ ব্লক বাইপাস করতে Brevo (Port 2525) বা Gmail App Password ইন্টিগ্রেশন।

### ২. ফাইল ম্যানেজার (Advanced File Manager)
- Monaco কোড এডিটর (VS Code ইঞ্জিন) সিনট্যাক্স হাইলাইটিং সহ।
- ড্র্যাগ-অ্যান্ড-ড্রপ ফাইল ও জিপ আপলোড।
- ১-ক্লিকে ZIP ফাইল এক্সট্র্যাক্ট ও কম্প্রেস।
- ফাইল ও ফোল্ডার পারমিশন (Chmod) ও রিনেম/মুভ টুলস।

### ৩. ডাটাবেজ ও phpMyAdmin SSO
- আনলিমিটেড MySQL/MariaDB ডাটাবেজ ও ইউজার তৈরি।
- ডোমেনভিত্তিক বিচ্ছিন্ন ডাটাবেজ পারমিশন।
- কোনো পাসওয়ার্ড টাইপ না করেই **১-ক্লিক phpMyAdmin Single Sign-On (SSO)**।

### ৪. পিএইচপি মাল্টি-ভার্সন ও ডিরেক্টিভ ম্যানেজার
- PHP 7.4, 8.1, 8.2 এবং 8.3 এর মধ্যে ১-ক্লিকে স্যুইচিং।
- `upload_max_filesize`, `memory_limit`, `max_execution_time` ইত্যাদি সরাসরি ব্রাউজার থেকে পরিবর্তন।

---

## 📁 রিপোজিটরি ডিরেক্টরি কাঠামো (Project Structure)

```text
Cpanel1280/
├── install.sh                  # 🚀 মাস্টার অটোমেটেড ওয়ান-ক্লিক শেল ইনস্টলার
├── server.js                   # সম্পূর্ণ ব্যাকএন্ড ইঞ্জিন (DKIM, Postfix/Dovecot sync, Cloudflare, DB API)
├── package.json                # প্রোডাকশন ডিপেনডেন্সি ও স্ক্রিপ্টস
├── schema.sql                  # MariaDB cpanel_system সম্পূর্ণ স্কিমা ও টেবিল স্ট্রাকচার
├── public/
│   ├── index.html              # প্রধান কন্ট্রোল প্যানেল UI (Webmail, File Manager, DB, DNS, Cron)
│   └── install-wizard.html     # 🌟 নতুন ফ্রেশ VPS-এর জন্য ব্রাউজার-বেজড ফার্স্ট-টাইম সেটআপ উইজার্ড
├── configs/
│   ├── systemd/
│   │   └── cpanel-core.service # সিস্টেমডি সার্ভিস ফাইল
│   ├── nginx/
│   │   └── cpanel-nginx.conf   # Nginx রিভার্স প্রক্সি ও Vhost কনফিগারেশন
│   ├── postfix/
│   │   ├── main.cf             # Postfix কনফিগারেশন
│   │   ├── master.cf           # Submission/SMTPS পোর্ট ডেমন
│   │   └── sql/                # MySQL Virtual Domains/Mailboxes/Aliases ম্যাপস
│   ├── dovecot/
│   │   ├── dovecot.conf        # Dovecot মাস্টার কনফিগ
│   │   ├── conf.d/             # Maildir, LMTP, SSL, Auth কনফিগ ফাইলসমূহ
│   │   └── dovecot-sql.conf.ext# Dovecot MySQL অথেনটিকেশন ফাইল
│   └── bind/
│       └── named.conf.local    # BIND9 জোন টেমপ্লেট
└── README.md                   # ডকুমেন্টেশন
```

---

## 🛠️ সার্ভিস ম্যানেজমেন্ট কমান্ডসমূহ (CLI Commands)

| সার্ভিস | স্ট্যাটাস চেক | রিস্টার্ট কমান্ড |
| :--- | :--- | :--- |
| **Cpanel Core Panel** | `sudo systemctl status cpanel-core` | `sudo systemctl restart cpanel-core` |
| **Nginx Web Server** | `sudo systemctl status nginx` | `sudo systemctl restart nginx` |
| **MariaDB Database** | `sudo systemctl status mariadb` | `sudo systemctl restart mariadb` |
| **Postfix Mail MTA** | `sudo systemctl status postfix` | `sudo systemctl restart postfix` |
| **Dovecot Maildir** | `sudo systemctl status dovecot` | `sudo systemctl restart dovecot` |

### লাইভ লগ দেখার কমান্ড:
```bash
# কন্ট্রোল প্যানেল লাইভ লগ
journalctl -u cpanel-core -f

# মেইল সার্ভার আদান-প্রদান লগ
tail -f /var/log/mail.log
```

---

## 🛡️ লাইসেন্স (License)

This project is licensed under the **MIT License**. Created with ❤️ by **abbas1280-dev**.
