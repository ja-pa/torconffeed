#
# Copyright (C) 2018 CZ.NIC, z. s. p. o. (https://www.nic.cz/)
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tor-conf
PKG_VERSION:=0.0.1
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=v$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

PKG_MAINTAINER:=Jan Pavlinec <jan.pavlinec@nic.cz>
PKG_LICENSE:=GPL-3.0

PKG_INSTALL:=0

include $(INCLUDE_DIR)/package.mk

define Package/tor-conf
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=Tor uci configuration
	DEPENDS:=+python +python-base +python-stem +tor
endef

#DEPENDS:=+python +tor +python-stem

define Package/$(PKG_NAME)/description
  Configuration for tor via uci
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/tor
endef

define Build/Compile
endef

define Build/Install
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/tor

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/tor.sh $(1)/etc/init.d/tor.sh

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/tor-utils.sh $(1)/usr/bin/tor-utils.sh
	$(INSTALL_BIN) ./files/tor-helper.py $(1)/usr/bin/tor-helper.py

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) ./files/tor.conf $(1)/etc/config/tor
endef

#define Package/$(PKG_NAME)/postinst
#endef

$(eval $(call BuildPackage,tor-conf))
