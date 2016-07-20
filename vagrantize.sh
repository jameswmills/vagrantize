#!/bin/bash -ex

# This script is currently used in Jenkins, which supplies the
# variables below.  Plwase adjust these settings to match your
# environment.  Sudo is currently used for the following commands:

# virsh
# cp
# virt-install
# chown

# Ensure that sudo is setup for the user running this script so that
# these commands can be run via sudo without a password (or be ready
# to supply a password

# Jenkins workspace or PWD
WORKSPACE=${WORKSPACE:-"."}

# Path to the base qcow2 image you want to use
baseimage=${baseimage:-''}

# This name will be used to define the temporary VM for provisioning,
# as well as serve as the name of the finished vagrant box.
name=${name:-"vagrantvbox"}

# This password will be used as the password for the root and vagrant
# users
password=${password:-"vagrant"}

# This is the libvirt storage domain path.  if you want to use the
# default, change this value to "/var/lib/libvirt/images/"
storagedir=${storagedir:-"/var/lib/libvirt/images/"}

# vagrant "insecure" key, available on the net
vagrantsshid=${vagrantsshid:-"AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"}

# Image size in GB.  The initial qcow will be resized, and the
# meta-data will use this
size_in_gb=${size_in_gb:-10}

# Used for chown
userid=${userid:-""}
group=${group:-""}


# Test for undefined variables
echo "Testing for undefined variables."
undefined="false"
for x in baseimage name password storagedir vagrantsshid size_in_gb userid group; do
  if [ -z "${!x}" ]; then
    echo "\"${x}\" is undefined.  Please define a value for \"${x}\" and try again."
    undefined="true"
  fi
done

if [ ${undefined} = "true" ]; then
  echo "Exiting due to undefined variables."
  exit 1
fi

# Test for sudo access
echo "Testing for required sudo privileges."
missingsudo="false"
for x in virsh cp virt-install chown; do
  sudo -n ${x} --help >/dev/null 2>&1
  if [ $? != 0 ]; then
    echo "sudo permission missing for \"${x}\"".
    missingsudo="true"
  fi
done

if [ ${missingsudo} = "true" ]; then
  echo "Exiting due to missing sudo permissions"
  exit 1
fi

#Create some cloud-init ISO's

##cloud-init
cat > meta-data << EOF
instance-id: ${name}
local-hostname: ${name}
EOF

cat meta-data

cat > user-data << EOF
#cloud-config
cloud_final_modules:
 - rightscale_userdata
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - keys-to-console
 - phone-home
 - power-state-change
 - final-message
write_files:
  - path: /etc/sysconfig/docker-storage-setup
    permissions: 0644
    owner: root
    content: |
      ROOT_SIZE=$((${size_in_gb}-5))G
      SETUP_LVM_THIN_POOL=yes
debug: True
disable_root: False
ssh_pwauth: True
chpasswd:
  list: |
    vagrant:${password}
    root:${password}
  expire: False
users:
  - name: vagrant
    ssh-authorized-keys:
      - ssh-rsa ${vagrantsshid}
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
  - name: root
    lock-passwd: false
runcmd:
  - for SERVICES in sshd; do systemctl enable \$SERVICES; done
  - for SERVICES in cloud-init cloud-config cloud-final cloud-init-local; do systemctl disable \$SERVICES; done
  - sed -i -e 's/\(.*requiretty$\)/#\1/' /etc/sudoers
  - docker-storage-setup
  - xfs_growfs /dev/mapper/atomicos-root
power_state:
  mode: poweroff
  message: Bye Bye
EOF

cat user-data

genisoimage -output ${name}-cidata.iso -volid cidata -joliet -rock user-data meta-data

sudo virsh destroy ${name} || true
sudo virsh undefine ${name} --remove-all-storage || true
qemu-img resize ${baseimage} ${size_in_gb}GB
sudo cp -f ${baseimage} ${storagedir}/${name}.qcow2
sudo cp -f ${name}-cidata.iso ${storagedir}
sudo virt-install --import --name ${name} --ram 2048 --vcpus 2 --disk ${storagedir}/${name}.qcow2,format=qcow2,bus=virtio \
   --disk ${storagedir}/${name}-cidata.iso,device=cdrom --os-type=linux --graphics spice \
   --noautoconsole --force

while [ -z "$(sudo virsh domstate ${name}|grep '^shut off')" ]; do
  echo "waiting for ${name} to shut down"
  sleep 10
done


rm -rf box
mkdir -p box
cd box
cat > metadata.json << EOF
{"provider":"libvirt","format":"qcow2","virtual_size":${size_in_gb}}
EOF

cat metadata.json

cat > Vagrantfile << EOF
Vagrant.configure("2") do |config|
        config.vm.provider :libvirt do |libvirt|
          libvirt.disk_bus = 'virtio'
        end
end
EOF

cat Vagrantfile

sudo cp ${storagedir}/${name}.qcow2 box.img
sudo chown ${userid}:${group} box.img
tar cvzf ${WORKSPACE}/${name}.box ./metadata.json ./Vagrantfile ./box.img
cd ${WORKSPACE}
rm ${WORKSPACE}/${name}-cidata.iso
rm -rf ${WORKSPACE}/box
sudo virsh destroy ${name} || true
sudo virsh undefine ${name} --remove-all-storage || true
vagrant box add --name ${name} --force ${WORKSPACE}/${name}.box
rm ${WORKSPACE}/${name}.box
