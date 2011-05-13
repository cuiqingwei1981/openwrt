BOARDNAME:=PCEngines alix2
FEATURES:=squashfs pci usb gpio
ALIX2_GPIO = $(if $(findstring 2.6.32,$(LINUX_VERSION)),gpio-cs5535,gpio-cs5535-new)
DEFAULT_PACKAGES += kmod-ata-via-sata \
			kmod-crypto-hw-geode kmow-crypto-ocf \
			kmod-$(ALIX2_GPIO) kmod-gpio-nsc \
			kmod-wdt-geode kmod-hwmon-core kmod-hwmon-lm90 \
			kmod-via-rhine kmod-leds-alix \
			kmod-i2c-core kmod-i2c-gpio \
			kmod-i2c-algo-bit kmod-i2c-algo-pca kmod-i2c-algo-pcf \
			kmod-i2c-scx200-acb \
			kmod-usb-core kmod-usb2 kmod-usb-uhci \
			kmod-cfg80211 kmod-mac80211 \
			kmod-mppe kmod-pppoe kmod-pppoa kmod-pppo2ltp \
			kmod-ath kmod-ath5k kmod-ath9k \
			bridge ppp ppp-mod-pppoa \
			libopenssl ocf-crypto-headers zlib hwclock hostapd

CS5535_MASK:=0x0a400000

CFLAGS += -Os -pipe -march=k6-2 -fno-align-functions -fno-align-loops -fno-align-jumps \
	  -fno-align-labels

define Target/Description
	Build firmware images for PCEngines alix2 board
endef

define KernelPackage/$(GEOS_GPIO)/install
     sed -i -r -e 's/$$$$$$$$/ mask=$(CS5535_MASK)/' $(1)/etc/modules.d/??-$(GEOS_GPIO)
endef
