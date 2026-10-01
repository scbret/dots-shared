#!/usr/bin/env bash
# check-vm-net.sh - Quick health check for libvirt NAT + UFW

set -e

echo "=== Libvirt NAT / VM Connectivity Check ==="

# 1. Bridge state
if ip link show virbr0 | grep -q "LOWER_UP"; then
  echo "[OK] virbr0 is UP"
else
  echo "[FAIL] virbr0 is DOWN (bridge not active)"
  exit 1
fi

# 2. VM DHCP leases
LEASES="/var/lib/libvirt/dnsmasq/default.leases"
if [ -s "$LEASES" ]; then
  echo "[OK] DHCP lease file has entries:"
  cat "$LEASES"
else
  echo "[WARN] No DHCP leases found (VM may not have IP)"
fi

# 3. Kernel IP forwarding
if [ "$(sysctl -n net.ipv4.ip_forward)" -eq 1 ]; then
  echo "[OK] IPv4 forwarding is enabled"
else
  echo "[FAIL] IPv4 forwarding is disabled"
  exit 1
fi

# 4. UFW forward policy
if grep -q 'DEFAULT_FORWARD_POLICY="ACCEPT"' /etc/default/ufw; then
  echo "[OK] UFW forward policy is ACCEPT"
else
  echo "[WARN] DEFAULT_FORWARD_POLICY not set to ACCEPT in /etc/default/ufw"
fi

# 5. NAT masquerade rule
if sudo iptables -t nat -S | grep -q "192.168.122.0/24"; then
  echo "[OK] MASQUERADE rule present:"
  sudo iptables -t nat -S | grep 192.168.122
else
  echo "[FAIL] No MASQUERADE rule for 192.168.122.0/24"
  exit 1
fi

# 6. DNS rules
if sudo iptables -S | grep -q -- "--dport 53"; then
  echo "[OK] DNS port 53 allowed on virbr0"
else
  echo "[WARN] No explicit DNS rules found (may break resolution)"
fi

# 7. Optional NAT ping test
echo "Running ping test to 8.8.8.8 (via host NAT)..."
if ping -c 3 -W 2 8.8.8.8 >/dev/null 2>&1; then
  echo "[OK] Host uplink can reach 8.8.8.8"
else
  echo "[FAIL] Host cannot reach 8.8.8.8 (internet down?)"
  exit 1
fi

echo "=== Check complete ==="
