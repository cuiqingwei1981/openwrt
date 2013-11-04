#
# Copyright (C) 2009-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/WNDR4300
	NAME:=NETGEAR WNDR4300
	PACKAGES:=kmod-usb-core kmod-usb-ohci kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/WNDR4300/Description
	Package set optimized for the NETGEAR WNDR4300
endef

$(eval $(call Profile,WNDR4300))


