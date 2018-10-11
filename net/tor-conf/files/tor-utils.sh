#!/bin/sh

set_tor_interface() {
	#create tor wifi
	section=tor_turris
	ipaddr=192.168.250.1
	netmask='255.255.255.0'
	ts=$(uci get network.$section )
	if [ -z "$ts" ]; then
		uci set network.$section=interface
		uci set network.$section.enabled='1'
		uci set network.$section.type='bridge'
		uci set network.$section.proto='static'
		uci set network.$section.ipaddr=$ipaddr
		uci set network.$section.netmask=$netmask
		uci set network.$section.ifname='tor_turris_0 torr_turris_1'
		uci commit network
	fi
}

set_tor_dhcp() {

	dhcp_name=tor_turris
	t_dhcp=$(uci get dhcp.$dhcp_nam )
	if  [ -z "$t_dhcp" ]; then
		uci set dhcp.$dhcp_name=dhcp
		uci set dhcp.$dhcp_name.interface='tor_turris'
		uci set dhcp.$dhcp_name.start='200'
		uci set dhcp.$dhcp_name.limit='50'
		uci set dhcp.$dhcp_name.leasetime='1h'
		uci set dhcp.$dhcp_name.ignore='0'
		uci add_list dhcp.$dhcp_name.dhcp_option='6,192.168.250.1'
	fi
}



set_tor_wireless() {
	iface=0
	tor_iface=tor_iface_0
	ifname=tor_turris_0
	network=tor_turris
	ssid=TurrisTor

	passwd=12345678
	#tw=$(uci get wireless.@wifi-iface[$iface_num].disabled)
	twt=$(uci get wireless.$tor_iface)

	#varaditt iface
	#if [ "$tw" == "0" ] && [ -z "$tw" ]; then
	#fi
	if [ -z "$twt" ] || [ "$twt" == "0" ]; then
		uci set wireless.$tor_iface=wifi-iface
		uci set wireless.$tor_iface.disabled= '0'
		uci set wireless.$tor_iface.device='radio0'
		uci set wireless.$tor_iface.mode='ap'
		uci set wireless.$tor_iface.ssid=$ssid
		uci set wireless.$tor_iface.encryption='psk2+tkip+aes'
		uci set wireless.$tor_iface.key=$passwd
		uci set wireless.$tor_iface.ifname=$ifname
		uci set wireless.$tor_iface.network=$network
		uci set wireless.$tor_iface.isolate='1'
		uci commit wireless
	fi
}

set_tor_firewall() {

	zone_name=tor_turris
	t_zone=$(uci get firewall.tor_turris)
	if  [ -z "$t_zone" ]; then
		uci set firewall.tor_turris=zone
		uci set firewall.tor_turris.enabled='1'
		uci set firewall.tor_turris.name='tor_turris'
		uci set firewall.tor_turris.input='REJECT'
		uci set firewall.tor_turris.forward='REJECT'
		uci set firewall.tor_turris.output='ACCEPT'
		uci set firewall.tor_turris.syn_flood=1
		uci set firewall.tor_turris.conntrack=1
		uci add_list firewall.tor_turris.network='tor_turris'
	fi

	rule_name=tor_dhcp_request
	t_rule=$(uci get firewall.$rule_name)

	if [ -z "$t_zone" ]; then
		uci set firewall.$rule_name=rule
		uci set firewall.$rule_name.name='Allow-TOR-DHPC-Request'
		uci set firewall.$rule_name.src='tor_turris'
		uci set firewall.$rule_name.proto='udp'
		uci set firewall.$rule_name.dest_port='67'
		uci set firewall.$rule_name.target='ACCEPT'
	fi

	rule_name=tor_transparent_proxy
	t_rule=$(uci get firewall.$rule_name)

	if [ -z "$t_zone" ]; then
		uci set firewall.$rule_name=rule
		uci set firewall.$rule_name.name='Allow-TOR-Trasparent-Proxy'
		uci set firewall.$rule_name.src='tor_turris'
		uci set firewall.$rule_name.proto='tcp'
		uci set firewall.$rule_name.dest_port='9040'
		uci set firewall.$rule_name.target='ACCEPT'
	fi

	rule_name=tor_DNS_proxy
	t_rule=$(uci get firewall.$rule_name)
	if [ -z "$t_zone" ]; then
		uci set firewall.$rule_name=rule

		uci set firewall.$rule_name.name 'Allow-TOR-DNS-Proxy'
		uci set firewall.$rule_name.src='tor_turris'
		uci set firewall.$rule_name.proto='udp'
		uci set firewall.$rule_name.dest_port='9053'
		uci set firewall.$rule_name.target='ACCEPT'
	fi

	redirect_name=tor_dns_redirect
	t_redirect=$(uci get firewall.$redirect_name)
	if [ -z "$t_redirect" ]; then
		uci set firewall.$redirect_name=redirect

		uci set firewall.$redirect_name.name='TOR-DNS-Redirect'
		uci set firewall.$redirect_name.src='tor_turris'
		uci set firewall.$redirect_name.src_dport='53'
		uci set firewall.$redirect_name.dest_port='9053'
		uci set firewall.$redirect_name.proto='udp'
		uci set firewall.$redirect_name.target='DNAT'
		uci set firewall.$redirect_name.reflection='0'
	fi

	redirect_name=tor_traffic_redirect
	t_redirect=$(uci get firewall.$redirect_name)
	if [ -z "$t_redirect" ]; then
		uci set firewall.$redirect_name=redirect

		uci set firewall.$redirect_name.name='TOR-Traffic-Redirect'
		uci set firewall.$redirect_name.src='tor_turris'
		uci set firewall.$redirect_name.src_dip='!192.168.1.0/24'
		uci set firewall.$redirect_name.dest_port='9040'
		uci set firewall.$redirect_name.proto='tcp'
		uci set firewall.$redirect_name.target='DNAT'
		uci set firewall.$redirect_name.reflection='0'
	fi

	rule_name=deny_TOR_LAN_ACCESS
	t_rule=$(uci get firewall.$rule_name)
	if [ -z "$t_zone" ]; then
		uci set firewall.$rule_name=rule
		uci set firewall.$rule_name.name='Deny-TOR-LAN-Access'
		uci set firewall.$rule_name.src='tor_turris'
		uci set firewall.$rule_name.dest='lan'
		uci set firewall.$rule_name.proto='all'
		uci set firewall.$rule_name.target='DROP'
	fi
	uci commit firewall
}

enable_tor_wifi() {
	set_tor_interface
	set_tor_wireless
	set_tor_firewall
	set_tor_dhcp
}


get_public_ip() {
	dig +short myip.opendns.com @resolver1.opendns.com
}

get_default_route() {
	route |grep default|awk '{print $8}'|head -n 1
}

get_interface_ip() {
	interface="$1"
	ip addr|grep $interface|awk '{print $2}'|tail -n 1|awk -F'/' '{print $1}'
}


#------------------#
enable_tor_wifi
