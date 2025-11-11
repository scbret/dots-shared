#!/usr/bin/env bash
# fix-vm-nat.sh — auto-detect uplink and ensure libvirt NAT works now + on reboot

set -euo pipefail

LIBVIRT_SUBNET="192.168.122.0/24"
UFW_RULES="/etc/ufw/before.rules"

echo "== Detecting uplink interface =="
UPLINK=$(ip route get 1.1.1.1 2>/dev/null | awk '/ dev /{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
if [[ -z "${UPLINK:-}" ]]; then
  echo "[FAIL] Could not detect uplink (no default route?)."
  exit 1
fi
echo "[OK] Uplink: $UPLINK"

echo "== Enabling IPv4 forwarding =="
# live
sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null
# persistent
sudo sed -i \
  -e 's|^\s*#\?\s*net/ipv4/ip_forward=.*|net/ipv4/ip_forward=1|' \
  /etc/ufw/sysctl.conf || true

echo "== Ensuring UFW forward policy is ACCEPT =="
sudo sed -i 's/^DEFAULT_FORWARD_POLICY.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

echo "== Fixing live iptables NAT rule =="
# Remove any duplicate/old MASQUERADEs for this subnet
while sudo iptables -t nat -C POSTROUTING -s "$LIBVIRT_SUBNET" -j MASQUERADE 2>/dev/null; do
  sudo iptables -t nat -D POSTROUTING -s "$LIBVIRT_SUBNET" -j MASQUERADE || true
done
while sudo iptables -t nat -C POSTROUTING -s "$LIBVIRT_SUBNET" -o "$UPLINK" -j MASQUERADE 2>/dev/null; do
  # already good; break to avoid infinite loop
  echo "[OK] Live MASQUERADE already correct for $UPLINK"
  break 2
done
# Add the interface-specific one
sudo iptables -t nat -A POSTROUTING -s "$LIBVIRT_SUBNET" -o "$UPLINK" -j MASQUERADE
echo "[OK] Live MASQUERADE added for $UPLINK"

echo "== Updating $UFW_RULES to persist (NAT section) =="
# Ensure NAT section exists; create if missing
if ! sudo grep -q '^\*nat' "$UFW_RULES"; then
  cat <<'EOF' | sudo tee -a "$UFW_RULES" >/dev/null

# -----------------------------
# NAT TABLE (for libvirt VMs)
# -----------------------------
*nat
:PREROUTING ACCEPT [0:0]
:INPUT       ACCEPT [0:0]
:OUTPUT      ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

# Placeholder; will be replaced by fix-vm-nat.sh
-A POSTROUTING -s 192.168.122.0/24 -o REPLACE_UPLINK -j MASQUERADE

COMMIT
EOF
fi

# Replace any existing MASQUERADE line for 192.168.122.0/24 with the detected uplink
sudo awk -v uplink="$UPLINK" -v subnet="$LIBVIRT_SUBNET" '
  BEGIN{replaced=0}
  /^\-A POSTROUTING/ && $0 ~ subnet && $0 ~ /-j MASQUERADE/ {
    print "-A POSTROUTING -s " subnet " -o " uplink " -j MASQUERADE";
    replaced=1; next
  }
  {print}
  END{
    if(!replaced){
      print "-A POSTROUTING -s " subnet " -o " uplink " -j MASQUERADE"
    }
  }
' "$UFW_RULES" | sudo tee "$UFW_RULES.tmp" >/dev/null

# Keep only one MASQUERADE line for that subnet
sudo awk -v subnet="$LIBVIRT_SUBNET" '
  /^\-A POSTROUTING/ && $0 ~ subnet && $0 ~ /-j MASQUERADE/ {
    if(seen++) next
  }
  {print}
' "$UFW_RULES.tmp" | sudo tee "$UFW_RULES" >/dev/null
sudo rm -f "$UFW_RULES.tmp"

echo "== Reloading UFW =="
sudo ufw reload

echo "== Verifying =="
sudo iptables -t nat -S | grep MASQUERADE || true
echo "[DONE] NAT fixed for uplink: $UPLINK"
