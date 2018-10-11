#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Mon Aug  6 18:26:02 2018

@author: pj
"""


import stem
from stem import CircStatus
from stem.control import Controller
import stem.connection
import stem.socket

# sys utils
from urllib2 import urlopen
from json import load
import subprocess

import pprint
import argparse
import sys


def call_cmd(cmd):
    assert isinstance(cmd, list)
    task = subprocess.Popen(cmd, shell=False, stdout=subprocess.PIPE)
    data = task.stdout.read()
    return data


def uci_get(path):
    return call_cmd(["uci", "get", "%s" % path]).rstrip()


def uci_get_bool(path, default):
    ret = uci_get(path)
    if ret in ('1', 'on', 'true', 'yes', 'enabled'):
        return True
    elif ret in ('0', 'off', 'false', 'no', 'disabled'):
        return False
    else:
        return default


def uci_set(path, val):
    return call_cmd(["uci", "set", "%s=%s" % (path, val)])


class SysUtils:
    def __init__(self):
        self.ip_detectors = [{"url": "http://jsonip.com",
                              "json_field_ipv4": "ip"},
                            {"url": "http://httpbin.org/ip",
                             "json_field_ipv4": "origin"},
                            {"url": "https://api.ipify.org/?format=json",
                             "json_field_ipv4": "ip"}]

    def get_public_ip(self, item_id=0):
        try:
            return load(urlopen(self.ip_detectors[item_id]["url"]))[self.ip_detectors[item_id]["json_field_ipv4"]]
        except IndexError:
            return None

    def get_wan_ip(self, test_ip=""):
        route_line = call_cmd(["ip", "route", "get", "8.8.8.8"])
        return route_line.splitlines()[0].strip().split()[6]


class TorUtils:
    def __init__(self, controller_port=9051, auth_pass=None):
        self._controller_port = controller_port
        self._auth_pass = auth_pass

    def get_circuits(self):
        ret = []
        with Controller.from_port(port=self._controller_port) as controller:
            controller.authenticate(self._auth_pass)
            for circ in sorted(controller.get_circuits()):
                if circ.status != CircStatus.BUILT:
                    continue
                # print("")
                # print("Circuit %s (%s)" % (circ.id, circ.purpose))
                # print("Circuit %s" % str(circ.created))
                circ_list = []
                for i, entry in enumerate(circ.path):
                    # div = '+' if (i == len(circ.path) - 1) else '|'
                    fingerprint, nickname = entry
                    desc = controller.get_network_status(fingerprint, None)
                    address = desc.address if desc else 'unknown'
                    country = controller.get_info("ip-to-country/%s" % address, 'unknown')
                    # print(" %s- %s (%s, %s, %s)" % (div, fingerprint, nickname, address,country))
                    circ_list.append([fingerprint, nickname, address, country])
                    # tmp=sorted(controller.get_circuits())
                ret.append({"purpose": circ.purpose,
                                "id": circ.id,
                                "created": str(circ.created),
                                "relays": circ_list})
            return ret

    def get_hs_list(self):
        with Controller.from_port(port=self._controller_port) as controller:
            controller.authenticate(self._auth_pass)
            hs_list = controller.get_hidden_service_conf()
            return hs_list

    def test_connection(self):
        try:
          control_socket = stem.socket.ControlPort(port=self._controller_port)
          return True
        except stem.SocketError as exc:
          print 'Unable to connect to port 9051 (%s)' % exc
          return False

    def get_readinfo(self):
        """ Return number of read/written bytes to tor network """
        with Controller.from_port(port=self._controller_port) as controller:
            controller.authenticate(self._auth_pass)  # provide the password here if you set one
            bytes_read = controller.get_info("traffic/read")
            bytes_written = controller.get_info("traffic/written")
            return bytes_read, bytes_written


def main_cli(argv):
    global abc
    parser = argparse.ArgumentParser(description='Tor-conf utility')
    parser.add_argument('-fp', '--f', nargs='+',
                        help='Get public IP')
    parser.add_argument('-tpi', '--test-public-ip', default=False,
                        action='store_true',
                        help='Test if we are behind NAT.')
    parser.add_argument('-tc', '--test-tor', default=False,
                        action='store_true',
                        help='Test if Tor is active.')
    parser.add_argument('-hsl', '--hidden-services', default=False,
                        action='store_true',
                        help='Show list of hidden services.')
    parser.add_argument('-cl', '--circuits-list', default=False,
                        action='store_true',
                        help='Show list of hidden services.')
    parser.add_argument('-st', '--show-statistics', default=False,
                        action='store_true',
                        help='Show download/upload statistics via tor.')
    args = parser.parse_args(argv)
    su = SysUtils()
    tu = TorUtils()

    if len(argv) == 0:
        parser.print_help()

    if args.test_public_ip:
        pub_ip = su.get_public_ip()
        wan_ip = su.get_wan_ip()
        if pub_ip != wan_ip:
            print ""
            print "Info: You are probably behind NAT"
            print "Public IP: %s" % pub_ip
            print "WAN IP: %s" % wan_ip
        else:
            print "You have probably public IP."
            print "Public IP: %s" % pub_ip

    if args.circuits_list:
        circuits = tu.get_circuits()
        for circuit in circuits:
            print ""
            print "ID %s (%s,%s)" % (circuit["id"],
                                    circuit["purpose"],
                                    circuit["created"])
            for relay in circuit["relays"]:
                print relay

    if args.hidden_services:
        hs = tu.get_hs_list()
        for conf_path, v in hs.items():
            port_private, ip, port_public = v["HiddenServicePort"][0]
            with open(conf_path + "/hostname", 'r') as f:
                output = f.read()
            onion_addr = output.strip()
            print port_private, ip, port_public, onion_addr, conf_path

    if args.show_statistics:
        if tu.test_connection():
            down, upload = tu.get_readinfo()
            print "Tor statistics"
            print "Download: %s bytes" % down
            print "Upload: %s bytes" % upload
        else:
            print "Tor is not connected. No statistic aviable."

    if args.test_tor:
        if tu.test_connection() is True:
            print "Tor is working"
        else:
            print "Tor isn't working"

main_cli(sys.argv[1:])
