#!/bin/bash


copy_to_pc()
{
	test_ssh=$(sshpass -V)

	mv tor.sh tor.sh_backup
	mv tor.conf tor.conf_backup
	mv tor-helper.py tor-helper.py_backup
	mv tor-utils.sh tor-utils.sh_backup



	if [ -f "../.ssh_passwd" ] && [ ! -z "$test_ssh" ];then
	sshpass -f ../.ssh_passwd scp root@192.168.1.1:/etc/init.d/tor.sh .
	sshpass -f ../.ssh_passwd scp root@192.168.1.1:/etc/init.d/tor-utils.sh .
	sshpass -f ../.ssh_passwd scp root@192.168.1.1:/etc/config/tor tor.conf
	sshpass -f ../.ssh_passwd scp root@192.168.1.1:/usr/bin/tor-helper.py tor-helper.py
	else
	scp root@192.168.1.1:/etc/init.d/{tor.sh,tor-utils.sh} .
	scp root@192.168.1.1:/etc/config/tor tor.conf
	scp root@192.168.1.1:/usr/bin/tor-helper.py tor-helper.py
	fi

}

copy_from_pc()
{
	test_ssh=$(sshpass -V)
	if [ -f "../.ssh_passwd" ] && [ ! -z "$test_ssh" ];then
	sshpass -f ../.ssh_passwd 	scp tor.sh root@192.168.1.1:/etc/init.d/
	sshpass -f ../.ssh_passwd 	scp tor-utils.sh root@192.168.1.1:/etc/init.d/
	sshpass -f ../.ssh_passwd 	scp tor.conf root@192.168.1.1:/etc/config/tor
	sshpass -f ../.ssh_passwd 	scp tor-helper.py root@192.168.1.1:/usr/bin/tor-helper.py
	else
	scp {tor.sh,tor-utils.sh} root@192.168.1.1:/etc/init.d/
	scp tor.conf root@192.168.1.1:/etc/config/tor
	scp tor-helper.py root@192.168.1.1:/usr/bin/tor-helper.py
	fi

}


cd net/tor-conf/files

if [ ! -e tor.conf ] || [ ! -e tor.sh ]; then
	echo "Error! Script called from wrong directory!"
	exit
fi



case "$1" in
	copy)
		echo "Copy files to router"
		copy_from_pc
	;;
	get)
		echo "Copy files from router"
		copy_to_pc
	;;
	*)
		echo "Help:"
		echo "copy - copy files to router"
		echo "get  - copy files from router"
	;;
esac

