### vagrantize
Convert a RHEL Atomic Host qcow image into a libvirt Vagrant box.

### Requirements
* vagrant
* vagrant-libvirt plugin
* Ability to run the following commands via sudo with no password:
  * chown
  * virsh
  * cp
  * virt-install
* A RHEL Atomic Host qcow image, available with a RH subscription 

### Execution

This was originally a Jenkins job, and a lot of the parameters were passed via Jenkins.  In order to run without Jenkins, you can edit the script and set these parameters, export them into the environment prior to running the script, or simply pass them into the script as you run it.

### Variables

The following variables need to be set in order for this script to function as expected:
* WORKSPACE - Defaults to PWD
* baseimage - Path to the downloaded qcow2 image you want to use (defauts to undefined)
* name - Name of the temporary VM used during provisioning, and also the finished vagrant box (defaults to "vagrantvbox")
* password - The password for the "root" and "vagrant" user in the box (defaults to "vagrant")
* storagedir - libvirt storage domain path (defaults to "/var/lib/libvirt/images/")
* vagrantsshid - Vagrant insecure ssh key (defaults to https://github.com/mitchellh/vagrant/blob/master/keys/vagrant.pub).  This is automatically replaced during "vagrant up"
* size_in_gb - Image size in GB (defaults to 10).  The initial qcow will be resized to this value, and the meta-data will use it as well.
* userid - Your username, used to chown the box (defaults to `$(id -un)`)
* group - Your group, used to chown the box (defaults to `${id -gn)`)
* vgname - The name of the VG that is extended *inside* the QCOW image (defaults to "atomicos")
* disk_name - The disk *inside* the QCOW image (defaults to "vda")
* disk_part - The number of the new parition added *inside* the QCOW image (defaults to "3")

If any of these are undefined, the script will not run.

### Known Issues

* This script was built to create and load a vagrant box for the user running the script.  If you just want the box created for others, comment out the last two lines
* It's a little crusty - There is some cleanup that could be done here
* It is *very specific* to RHEL AH images - This is not a general purpose tool, and attempts to use this on non-RHEL-AH images might have very unexpected results!

Read through the script before executing it.  This works without a hitch in my environment, but it is pretty invasive.  Better safe than sorry, right? ;)

### Example Execution

```
# id -un
jameswmills
# id -gn
jameswmills
# cd /home/jamesemills/vagrantize
# name=atomic-7.2.5 baseimage=/path/to/downloaded/rhel-atomic-cloud.qcow2 ./vagrantize.sh
```

The above command will have the following variables set:
* WORKSPACE=/home/jamesemills/vagrantize
* baseimage=/path/to/downloaded/rhel-atomic-cloud.qcow2
* name=atomic-7.2.5
* password=vagrant
* storagedir=/var/lib/libvirt/images/
* vagrantsshid="AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
* size_in_gb=10
* userid=jameswmills
* group=jameswmills
* vgname=atomicos
* disk_name=vda
* disk_part=3

Upon completion, an "atomic-7.2.5" vagrant box should exist:

```
# id -un
jameswmills
# vagrant box list
atomic-7.2.5 (libvirt, 0)
```
