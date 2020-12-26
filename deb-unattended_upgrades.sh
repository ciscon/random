apt-get install unattended-upgrades apt-listchanges -y && \
sed -i 's,.*Unattended-Upgrade::Mail.*,,g' /etc/apt/apt.conf.d/50unattended-upgrades;echo 'Unattended-Upgrade::Mail "root";' >> /etc/apt/apt.conf.d/50unattended-upgrades && \
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections && \
dpkg-reconfigure -f noninteractive unattended-upgrades && \
unattended-upgrade -d && \
echo -e "\nSUCCESS\n"
