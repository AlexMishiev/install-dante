#!/bin/bash

# ============================================
# Dante Server Automatic Installation Script
# Ubuntu 24.04
# Author: Your Name
# ============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# CONFIGURATION - EDIT THESE VARIABLES
# ============================================

# SOCKS5 proxy port
PROXY_PORT="1080"

# Proxy user credentials
PROXY_USER="proxyuser"
PROXY_PASS="YourStrongPassword123!"  # CHANGE THIS!

# Network interface (check with 'ip a' or 'ifconfig')
# Common names: ens3, ens4, eth0, eno1, enp0s3
EXTERNAL_IF="ens3"  # CHANGE THIS!

# ============================================
# Installation functions
# ============================================

print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root!"
   exit 1
fi

# Welcome message
clear
print_status "Starting Dante SOCKS5 Proxy Installation"
print_status "========================================"
echo ""

# Check Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
if [[ "$UBUNTU_VERSION" != "24.04" ]]; then
    print_warning "This script was tested on Ubuntu 24.04 (current: $UBUNTU_VERSION)"
    print_warning "It may still work, but no guarantees!"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ============================================
# Installation
# ============================================

# Update package list and install Dante
print_status "Updating package list..."
apt update -qq

print_status "Installing Dante server..."
apt install dante-server -y -qq

if [ $? -ne 0 ]; then
    print_error "Failed to install Dante server!"
    exit 1
fi

# Create proxy user
print_status "Creating proxy user: $PROXY_USER..."
useradd -r -s /bin/false "$PROXY_USER" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "$PROXY_USER:$PROXY_PASS" | chpasswd
    print_status "User created with password: $PROXY_PASS"
else
    # If user exists, just update password
    echo "$PROXY_USER:$PROXY_PASS" | chpasswd
    print_warning "User already exists, password updated"
fi

# Backup original config
if [ -f /etc/danted.conf ]; then
    cp /etc/danted.conf /etc/danted.conf.backup.$(date +%Y%m%d_%H%M%S)
    print_status "Original config backed up"
fi

# Create Dante configuration
print_status "Creating Dante configuration..."

cat > /etc/danted.conf << EOF
# Dante SOCKS5 Server Configuration
# Auto-generated on $(date)

logoutput: syslog
user.privileged: root
user.unprivileged: nobody

# Listen on all interfaces, port $PROXY_PORT
internal: 0.0.0.0 port = $PROXY_PORT

# External interface (check with 'ip a')
external: $EXTERNAL_IF

# Authentication method
socksmethod: username

# Client rules
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}

# SOCKS5 rules
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
    command: bind connect udpassociate
    log: error
}
EOF

# Verify configuration
if [ -f /etc/danted.conf ]; then
    print_status "Configuration created successfully"
else
    print_error "Failed to create configuration!"
    exit 1
fi

# ============================================
# Firewall configuration (if ufw is active)
# ============================================

if command -v ufw &> /dev/null; then
    if ufw status | grep -q "active"; then
        print_status "Configuring UFW firewall..."
        ufw allow $PROXY_PORT/tcp comment 'Dante SOCKS5 Proxy'
        print_status "UFW rule added for port $PROXY_PORT"
    fi
fi

# ============================================
# Start and enable service
# ============================================

print_status "Restarting Dante service..."
systemctl restart danted

if [ $? -ne 0 ]; then
    print_error "Failed to restart Dante service!"
    print_warning "Checking configuration..."
    danted -t
    exit 1
fi

print_status "Enabling Dante service on boot..."
systemctl enable danted

# ============================================
# Final checks
# ============================================

echo ""
print_status "Installation Complete!"
print_status "======================"
echo ""

# Check if service is running
if systemctl is-active --quiet danted; then
    print_status "✓ Dante service is running"
else
    print_error "✗ Dante service is not running"
fi

# Check listening port
if ss -tlnp | grep -q ":$PROXY_PORT"; then
    print_status "✓ Proxy is listening on port $PROXY_PORT"
else
    print_error "✗ Proxy is NOT listening on port $PROXY_PORT"
fi

# Display connection info
echo ""
print_status "Connection Information:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Server IP    : $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo "Port         : $PROXY_PORT"
echo "Username     : $PROXY_USER"
echo "Password     : $PROXY_PASS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_status "Test connection:"
echo "curl --socks5 $PROXY_USER:$PROXY_PASS@SERVER_IP:$PROXY_PORT ifconfig.me"
echo ""
print_warning "Don't forget to:"
echo "1. Change the password in this script if you saved it"
echo "2. Check your external interface with 'ip a' (current: $EXTERNAL_IF)"
echo "3. Configure your firewall if needed"
echo ""
print_status "Configuration file: /etc/danted.conf"
print_status "Logs: journalctl -u danted -f"

# Test configuration
echo ""
print_status "Testing Dante configuration..."
danted -t

exit 0
