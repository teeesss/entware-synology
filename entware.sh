#!/bin/sh

# Function to check if a package is installed
package_installed() {
    if /opt/bin/opkg list-installed "$1" >/dev/null 2>&1; then
        return 0 # Package is installed
    else
        return 1 # Package is not installed
    fi
}

# Step 1: Create a folder on your HDD (outside rootfs)
mkdir -p /volume1/@Entware/opt

# Step 2: Remove /opt and mount Optware folder
rm -rf /opt
mkdir /opt
if ! mount -o bind "/volume1/@Entware/opt" /opt; then
    echo "Failed to mount Optware folder"
    exit 1
fi

# Step 3: Check if Entware packages are already installed or up to date
if package_installed entware-base; then
    echo "Entware packages are already installed."
else
    # Step 4: Run install script depending on the processor
    case "$(uname -m)" in
      "armv8")
        wget -O - https://bin.entware.net/aarch64-k3.10/installer/generic.sh | /bin/sh
        ;;
      "armv5")
        wget -O - https://bin.entware.net/armv5sf-k3.2/installer/generic.sh | /bin/sh
        ;;
      "armv7")
        wget -O - https://bin.entware.net/armv7sf-k3.2/installer/generic.sh | /bin/sh
        ;;
      "x86_64")
        wget -O - https://bin.entware.net/x64-k3.2/installer/generic.sh | /bin/sh
        ;;
      *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
    esac
fi

# Step 5: Create Autostart Task
cat << EOF > /etc/rc.local
#!/bin/sh

# Mount/Start Entware
mkdir -p /opt
/opt/etc/init.d/rc.unslung start

# Add Entware Profile in Global Profile
if grep -qF '/opt/etc/profile' /etc/profile; then
    echo "Confirmed: Entware Profile in Global Profile"
else
    echo "Adding: Entware Profile in Global Profile"
    cat >> /etc/profile <<"PROFILE_EOF"

# Load Entware Profile
[ -r "/opt/etc/profile" ] && . /opt/etc/profile

# Update PATH to include /opt/bin
export PATH=/opt/bin:$PATH
PROFILE_EOF
fi

# Update Entware List
/opt/bin/opkg update
EOF

# Step 6: Create a script in /usr/local/bin/entware.sh for manual invocation
cat << EOF > /usr/local/bin/entware.sh
#!/bin/sh

# Mount/Start Entware
mkdir -p /opt
/opt/etc/init.d/rc.unslung start

# Add Entware Profile in Global Profile
if grep -qF '/opt/etc/profile' /etc/profile; then
    echo "Confirmed: Entware Profile in Global Profile"
else
    echo "Adding: Entware Profile in Global Profile"
    cat >> /etc/profile <<"PROFILE_EOF"

# Load Entware Profile
[ -r "/opt/etc/profile" ] && . /opt/etc/profile

# Update PATH to include /opt/bin
export PATH=/opt/bin:$PATH
PROFILE_EOF
fi

# Update Entware List
/opt/bin/opkg update
EOF

# Make scripts executable
chmod +x /etc/rc.local /usr/local/bin/entware.sh

# Step 7: Reboot your NAS
#reboot
