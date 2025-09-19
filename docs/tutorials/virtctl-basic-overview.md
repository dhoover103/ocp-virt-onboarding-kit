# Basic usage of the virtctl command

This tutorial will provide a brief overview of the virtctl command. This document is designed to quickly cover some of the basic usage of this incredibly useful tool for controlling your virtual machines on OpenShift, but for more in-depth information on this tool, see our [official documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.13/html/virtualization/virt-using-the-cli-tools)

At a basic level, we have virtctl fslist \<your vm name\> to list the file systems available
```
$ virtctl fslist my-vm
```

virtctl userlist \<your vm name\> for a list of logged-in users
```
$ virtctl userlist my-vm
```

and virtctl guestosinfo \<your vm name\> for information about the operating system.
```
$ virtctl guestinfo my-vm
```

You can type virtctl start \<your vm name\> to start a VM
```
$ virtctl start my-vm
```

and virtctl stop \<your vm\> to stop a VM. 
```
$ virtctl stop my-vm
```
This can also be used with --force to force a stop, but be aware this can mess up the data on the VM.

To pause a VM, keeping the machine state in memory you can run virtctl pause vm \<your vm name\>, and unpause it with virtctl unpause vm <name>. 

**Note: these commands require you to specify that you're talking about a vm, and the others don't.**

One of the more useful commands is virtctl scp. Just like a regular scp command, this lets you copy files to and from your virtual machines. To use scp, you'll need to make sure your virtual machine has an SSH key to allow connections. 
To copy a file locally to your virtual machine, use virtctl scp -i \<ssh key\> \<file name\> \<user name\>@\<your name\>. 
```
$ virtctl scp -i key myLocalFile.txt user@my-vm:mvVMFileLocation.txt
```

If you need a file off a VM, you just reverse the command - virtctl scp -i \<ssh key\> \<user name\>@\<your name\>:\<file name\> \<destination directory\>.
```
$ virtctl scp -i key user@my-vm:VMFile.txt ~/Documents/
```
