#!/bin/sh /etc/rc.common
# Copyright (C) 2017

START=52
STOP=52

USE_PROCD=1
#set -x

TORRC_FILE=/etc/tor/torrc_generated # file with torrc config
HS_DIR_PATH=/etc/tor/hidden_service #hidden service directory path
TOR_USER=tor
DEBUG_SCRIPT=1

print_debug() {
	if [ "$DEBUG_SCRIPT" == "1" ]; then
		echo $1
	fi
}

print_log_header() {
	name="$1"
	description="$2"
	echo "">>$TORRC_FILE
	echo "">>$TORRC_FILE
	echo "########################################">>$TORRC_FILE
	echo "#Service name: $name">>$TORRC_FILE
	echo "#Description: $description">>$TORRC_FILE
	echo "########################################">>$TORRC_FILE
}

write_param() {
	#write param to generated torrc
	#read from uci conf and generate torrc file
	local config="$1"
	local var_from_conf="$2"
	local var_to_conf="$3"
	local val_default="$4"
	local var_tmp

	config_get var_tmp "$config" $var_from_conf

	#v pripade prazdne promnene nic nezapisuj
	if [ "$var_tmp" == "" ] && [ "$val_default" == "" ]; then
		echo "empty var!!!"
	else
		echo $var_from_conf $var_tmp>>$TORRC_FILE
	fi

	print_debug "$var_from_conf $var_tmp"
}


write_list_param() {
	#write param
	local value="$1"
	local var_to_conf="$2" #var name for torrc

	#write list to torrc file
	print_debug "$var_to_conf $value"
	echo "$var_to_conf $value">>$TORRC_FILE
}


handle_list_param() {
	local config="$1"
	local var_from_conf="$2"
	local var_to_conf="$3"
	local var_tmp

	config_list_foreach "$config" "$var_from_conf" write_list_param "$var_to_conf"
}

write_list_include_config() {
	local filepath="$1"

	#include config
	if [ -f "$filepath" ]; then
		echo "">>$TORRC_FILE
		echo "# included config from $filepath">>$TORRC_FILE
		echo "# ---------START---------">>$TORRC_FILE
		cat $filepath>>$TORRC_FILE
		echo "# ---------END---------">>$TORRC_FILE
	fi

}

parse_service_conf() {
	local name description
	local config="$1"
	local custom="$2"

	config_get name "$config" Name
	config_get description "$config" Description
	config_get_bool enabled "$config" Enabled 0

	if [ "$enabled" == "1" ]; then
		print_log_header "$name" "$description"

		write_param "$config" SocksPort SocksPort # "0"
		write_param "$config" ORPort ORPort # "9001"
		write_param "$config" BridgeRelay BridgeRelay
		write_param "$config" Nickname Nickname # "ddd"
		write_param "$config" ContactInfo ContactInfo # "fff [tor-relay.co]"
		write_param "$config" DirPort DirPort # "9030"
 		write_param "$config" DirFrontPage DirFrontPage #"/etc/tor/tor-exit-notice.html"

		write_param "$config" RelayBandwidthRate RelayBandwidthRate # "12 MBits"
		write_param "$config" RelayBandwidthBurst RelayBandwidthBurst # "13 MBits"
		write_param "$config" AccountingStart AccountingStart # "month 1 00:00"
		write_param "$config" AccountingMax AccountingMax # "5 GB"

		handle_list_param "$config" ExitPolicyReject "ExitPolicy reject" # "*:*"
		handle_list_param "$config" ExitPolicyAccept "ExitPolicy accept" # "*:*"
	fi
}

parse_hs_conf() {
	local name description public_port local_port enable_bool
	local config=$1
	local custom=$2
	config_get name "$config" Name
	config_get description "$config" Description

	config_get_bool enable_hs "$config" Enabled 0
	config_get public_port "$config" PublicPort
	config_get local_port "$config" LocalPort

	if [ "$enable_hs" = "1" ]; then

		mkdir -p $HS_DIR_PATH/
		mkdir -p $HS_DIR_PATH/$name
 		chown $TOR_USER:$TOR_USER $HS_DIR_PATH/
 		chown $TOR_USER:$TOR_USER $HS_DIR_PATH/$name
		chmod 700 $HS_DIR_PATH/
		chmod 700 $HS_DIR_PATH/$name/

		print_log_header "$name" "$description"
		echo "HiddenServiceDir $HS_DIR_PATH/$name" >>$TORRC_FILE
		echo "HiddenServicePort $public_port 127.0.0.1:$local_port">>$TORRC_FILE
		print_debug "HiddenServiceDir $HS_DIR_PATH/$name"
		print_debug "HiddenServicePort $public_port 127.0.0.1:$local_port"
	fi
}

check_conf() {
	tor -f $TORRC_FILE --verify-config
}

parse_client_conf() {
	local config=client
	local custom=$2

	#parse tor client specific
	write_param "$config" ClientOnly ClientOnly #"0" #0|1
	write_param "$config" ConnectionPadding ConnectionPadding #"1" #0|1|auto
	write_param "$config" ReducedConnectionPadding ReducedConnectionPadding #'0' #0|1

	#parse wifi related setting
	#write_param "$config" ReducedConnectionPadding ReducedConnectionPadding #'0' #0|1
	#write_param "$config" VirtualAddrNetwork VirtualAddrNetwork 10.192.0.0/10
	#write_param "$config" AutomapHostsOnResolve AutomapHostsOnResolve # 1
	#write_param "$config" TransPort TransPort # 9040
	#write_param "$config" TransListenAddress TransListenAddress # 192.168.250.1
	#write_param "$config" DNSPort DNSPort # 9053
	#write_param "$config" DNSListenAddress DNSListenAddress # 192.168.250.1

}

parse_wifi_conf() {
	local config=client
	local custom=$2

	config_get name "$config" Name
	config_get description "$config" Description

	#parse wifi related setting
	write_param "$config" ReducedConnectionPadding ReducedConnectionPadding #'0' #0|1
	write_param "$config" VirtualAddrNetwork VirtualAddrNetwork #10.192.0.0/10
	write_param "$config" AutomapHostsOnResolve AutomapHostsOnResolve # 1
	write_param "$config" TransPort TransPort # 9040
	write_param "$config" TransListenAddress TransListenAddress # 192.168.250.1
	write_param "$config" DNSPort DNSPort # 9053
	write_param "$config" DNSListenAddress DNSListenAddress # 192.168.250.1

	#TODO: nahradit get bool
	config_get enable_fw "$config" 	option EnableFirewallConf '1'
	config_get enable_dhcp "$config" EnableDhcpConf '1'
	config_get enable_wireless "$config" EnableWirelessConf '1'
	config_get enable_net "$config" EnableNetworkConf

}


parse_client_bridge_conf() {

	local config=$1
	local custom=$2

	config_get name "$config" Name
	config_get description "$config" Description

	echo "OOOOOOOOOOOOOOO $name"
	echo "OOOOOOOOOOOOOOO $description"

}



parse_common_conf() {
	local config=common
	local custom=$2
	local data_dir

	#parse common setting for tor
	write_param "$config" DisableDebuggerAttachment DisableDebuggerAttachment # "0"
	write_param "$config" ControlPort ControlPort # "9051"
	write_param "$config" CookieAuthentication CookieAuthentication # "1"
	write_param "$config" RunAsDaemon RunAsDaemon # "1"
	write_param "$config" SafeLogging SafeLogging

	#set DataDirectory
	write_param "$config" DataDirectory DataDirectory "/tmp/tor"
	config_get data_dir "$config" DataDirectory
	if [ ! -d "$data_dir" ]; then
		mkdir $data_dir
		chown $TOR_USER:$TOR_USER $data_dir
	fi
	write_param "$config" User User "$TOR_USER"

	config_list_foreach "$config" include_config write_list_include_config "aaa"
}

init_torrc() {
	echo "#HEADER">$TORRC_FILE
	echo "#generated file !">>$TORRC_FILE
	echo "PidFile /var/run/tor.pid">>$TORRC_FILE
}


start_service() {
	[ -f /var/run/tor.pid ] || {
		touch /var/run/tor.pid
		#chown tor:tor /var/run/tor.pid
		chown $TOR_USER:$TOR_USER /var/run/tor.pid
	}
	[ -d /var/lib/tor ] || {
		mkdir -m 0755 -p /var/lib/tor
		chmod 0700 /var/lib/tor
		chown $TOR_USER:$TOR_USER /var/lib/tor
	}
	[ -d /var/log/tor ] || {
		mkdir -m 0755 -p /var/log/tor
		chown $TOR_USER:$TOR_USER /var/log/tor
	}
	init_torrc
	config_load tor

	#hidden service config
	config_foreach parse_hs_conf hidden-service
	#normal config
	config_foreach parse_service_conf tor-service

	#client specific
	parse_client_conf

	#parse client pluggable config
	config_foreach parse_client_bridge_conf client-bridge

	#common configuration
	parse_common_conf

	#check conf before running
	#check_conf

	procd_open_instance
	#test_config
	#procd_set_param command /usr/sbin/tor --runasdaemon 0
	procd_set_param command /usr/sbin/tor -f $TORRC_FILE
	procd_set_param pidfile /var/run/tor.pid
	#procd_append_param command -f $TORRC_FILE
	#procd_set_param user tor
	procd_close_instance
}

stop_service()
{
	if [ -f /var/run/tor.pid ]; then
		kill $(cat /var/run/tor.pid)
	fi
}

reload_service() {
	stop
	start
}
