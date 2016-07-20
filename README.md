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
* baseimage - Path to the fownloaded qcow2 image you want to use (defauts to undefined)
* name - Name of the temporary VM used during provisioning, and also the finished vagrant box (defaults to "vagrantvbox")
* password - The password for the "root" and "vagrant" user in the box (defaults to "vagrant")
* storagedir - libvirt storage domain path (defaults to "/var/lib/libvirt/images/")
* vagrantsshid - Vagrant insecure ssh key (defaults to the one on the Internet).  This is automatically replaced during "vagrant up"
* size_in_gb - Image size in GB (defaults to 10).  The initial qcow will be resized to this value, and the meta-data will use it as well.
* userid - Your username, used to chown the box (defaults to undefined)
* group - Your group, used to chown the box (defaults to undefined)

If any of these are undefined, the script will not run.

### Known Issues

* This script was built to create and load a vagrant box for the user running the script.  If you just want the box created for others, comment out the last two lines
* It's a little crusty - There is some cleanup that could be done here

Read through the script before executing it.  This works without a hitch in my environment, but it is pretty invasive.  Better safe than sorry, right? ;)
