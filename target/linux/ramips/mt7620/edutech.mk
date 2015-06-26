#
# Copyright (C) 2015 educationtek.com
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.#
define Profile/EDUTECH
NAME:= EDUTECH mt7620a DevBoard
PACKAGES:=\
kmod-usb-core kmod-usb-ohci kmod-usb2 kmod-ledtrig-netdev kmod-ledtrig-timer \
kmod-usb-acm
kmod-usb-net
kmod-usb-net-asix
kmod-usb-net-rndis
kmod-usb-serial kmod-usb-serial-option \
usb-modeswitch usb-modeswitch-data comgt
endef
define Profile/EDUTECH/Description
Package set for EDUTECH IOT Router
64MB DDR2 + 8MB Flash
endef
$(eval $(call Profile, EDUTECH))
