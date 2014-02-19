#
# Copyright (C) 2011 OpenWrt.org
#

. /lib/ar71xx.sh

PART_NAME=firmware
RAMFS_COPY_DATA=/lib/ar71xx.sh

CI_BLKSZ=65536
CI_LDADR=0x80060000

platform_find_partitions() {
	local first dev size erasesize name
	while read dev size erasesize name; do
		name=${name#'"'}; name=${name%'"'}
		case "$name" in
			vmlinux.bin.l7|vmlinux|kernel|linux|linux.bin|rootfs|filesystem)
				if [ -z "$first" ]; then
					first="$name"
				else
					echo "$erasesize:$first:$name"
					break
				fi
			;;
		esac
	done < /proc/mtd
}

platform_find_kernelpart() {
	local part
	for part in "${1%:*}" "${1#*:}"; do
		case "$part" in
			vmlinux.bin.l7|vmlinux|kernel|linux|linux.bin)
				echo "$part"
				break
			;;
		esac
	done
}

platform_do_upgrade_combined() {
	local partitions=$(platform_find_partitions)
	local kernelpart=$(platform_find_kernelpart "${partitions#*:}")
	local erase_size=$((0x${partitions%%:*})); partitions="${partitions#*:}"
	local kern_length=0x$(dd if="$1" bs=2 skip=1 count=4 2>/dev/null)
	local kern_blocks=$(($kern_length / $CI_BLKSZ))
	local root_blocks=$((0x$(dd if="$1" bs=2 skip=5 count=4 2>/dev/null) / $CI_BLKSZ))

	if [ -n "$partitions" ] && [ -n "$kernelpart" ] && \
	   [ ${kern_blocks:-0} -gt 0 ] && \
	   [ ${root_blocks:-0} -gt 0 ] && \
	   [ ${erase_size:-0} -gt 0 ];
	then
		local append=""
		[ -f "$CONF_TAR" -a "$SAVE_CONFIG" -eq 1 ] && append="-j $CONF_TAR"

		( dd if="$1" bs=$CI_BLKSZ skip=1 count=$kern_blocks 2>/dev/null; \
		  dd if="$1" bs=$CI_BLKSZ skip=$((1+$kern_blocks)) count=$root_blocks 2>/dev/null ) | \
			mtd -r $append -F$kernelpart:$kern_length:$CI_LDADR,rootfs write - $partitions
	fi
}

tplink_get_image_hwid() {
	get_image "$@" | dd bs=4 count=1 skip=16 2>/dev/null | hexdump -v -n 4 -e '1/1 "%02x"'
}

tplink_get_image_boot_size() {
	get_image "$@" | dd bs=4 count=1 skip=37 2>/dev/null | hexdump -v -n 4 -e '1/1 "%02x"'
}

seama_get_type_magic() {
	get_image "$@" | dd bs=1 count=4 skip=53 2>/dev/null | hexdump -v -n 4 -e '1/1 "%02x"'
}

cybertan_get_image_magic() {
	get_image "$@" | dd bs=8 count=1 skip=0  2>/dev/null | hexdump -v -n 8 -e '1/1 "%02x"'
}

cybertan_check_image() {
	local magic="$(cybertan_get_image_magic "$1")"
	local fw_magic="$(cybertan_get_hw_magic)"

	[ "$fw_magic" != "$magic" ] && {
		echo "Invalid image, ID mismatch, got:$magic, but need:$fw_magic"
		return 1
	}

	return 0
}

platform_do_upgrade_compex() {
	local fw_file=$1
	local fw_part=$PART_NAME
	local fw_mtd=$(find_mtd_part $fw_part)
	local fw_length=0x$(dd if="$fw_file" bs=2 skip=1 count=4 2>/dev/null)
	local fw_blocks=$(($fw_length / 65536))

	if [ -n "$fw_mtd" ] &&  [ ${fw_blocks:-0} -gt 0 ]; then
		local append=""
		[ -f "$CONF_TAR" -a "$SAVE_CONFIG" -eq 1 ] && append="-j $CONF_TAR"

		sync
		dd if="$fw_file" bs=64k skip=1 count=$fw_blocks 2>/dev/null | \
			mtd $append write - "$fw_part"
	fi
}

platform_check_image() {
	local board=$(ar71xx_board_name)
	local magic="$(get_magic_word "$1")"
	local magic_long="$(get_magic_long "$1")"

	[ "$ARGC" -gt 1 ] && return 1

	case "$board" in
	all0315n | \
	all0258n | \
	cap4200ag)
		platform_check_image_allnet "$1" && return 0
		return 1
		;;
	alfa-ap96 | \
	alfa-nx | \
	ap113 | \
	ap121 | \
	ap121-mini | \
	ap136-010 | \
	ap136-020 | \
	ap135-020 | \
	ap96 | \
	db120 | \
	hornet-ub | \
	bxu2000n-2-a1 | \
	zcn-1523h-2 | \
	zcn-1523h-5)
		[ "$magic_long" != "68737173" -a "$magic_long" != "19852003" ] && {
			echo "Invalid image type."
			return 1
		}
		return 0
		;;
	ap81 | \
	ap83 | \
	ap132 | \
	dir-505-a1 | \
	dir-600-a1 | \
	dir-615-c1 | \
	dir-615-e4 | \
	dir-825-c1 | \
	dir-835-a1 | \
	dragino2 | \
	ew-dorin | \
	ew-dorin-router | \
	hornet-ub-x2 | \
	mzk-w04nu | \
	mzk-w300nh | \
	tew-632brp | \
	tew-712br | \
	tew-732br | \
	wrt400n | \
	airrouter | \
	bullet-m | \
	nanostation-m | \
	rocket-m | \
	rw2458n | \
	wndap360 | \
	wzr-hp-g300nh2 | \
	wzr-hp-g300nh | \
	wzr-hp-g450h | \
	wzr-hp-ag300h | \
	whr-g301n | \
	whr-hp-g300n | \
	whr-hp-gn | \
	wlae-ag300n | \
	nbg460n_550n_550nh | \
	unifi | \
	unifi-outdoor | \
	carambola2 )
		[ "$magic" != "2705" ] && {
			echo "Invalid image type."
			return 1
		}
		return 0
		;;

	dir-825-b1 | \
	tew-673gru)
		dir825b_check_image "$1" && return 0
		;;

	mynet-rext|\
	wrt160nl)
		cybertan_check_image "$1" && return 0
		return 1
		;;

	mynet-n600 | \
	mynet-n750)
		[ "$magic_long" != "5ea3a417" ] && {
			echo "Invalid image, bad magic: $magic_long"
			return 1
		}

		local typemagic=$(seama_get_type_magic "$1")
		[ "$typemagic" != "6669726d" ] && {
			echo "Invalid image, bad type: $typemagic"
			return 1
		}

		return 0;
		;;
	mr600 | \
	mr600v2 | \
	om2p | \
	om2p-hs | \
	om2p-lc)
		platform_check_image_openmesh "$magic_long" "$1" && return 0
		return 1
		;;

	archer-c7 | \
	tl-mr10u | \
	tl-mr11u | \
	tl-mr13u | \
	tl-mr3020 | \
	tl-mr3040 | \
	tl-mr3040-v2 | \
	tl-mr3220 | \
	tl-mr3220-v2 | \
	tl-mr3420 | \
	tl-mr3420-v2 | \
	tl-wa7510n | \
	tl-wa750re | \
	tl-wa850re | \
	tl-wa801nd-v2 | \
	tl-wa901nd | \
	tl-wa901nd-v2 | \
	tl-wa901nd-v3 | \
	tl-wdr3500 | \
	tl-wdr4300 | \
	tl-wdr4900-v2 | \
	tl-wr703n | \
	tl-wr710n | \
	tl-wr720n-v3 | \
	tl-wr741nd | \
	tl-wr741nd-v4 | \
	tl-wr841n-v1 | \
	tl-wr841n-v7 | \
	tl-wr841n-v8 | \
	tl-wr842n-v2 | \
	tl-wr941nd | \
	tl-wr1041n-v2 | \
	tl-wr1043nd | \
	tl-wr1043nd-v2 | \
	tl-wr2543n)
		[ "$magic" != "0100" ] && {
			echo "Invalid image type."
			return 1
		}

		local hwid
		local imageid

		hwid=$(tplink_get_hwid)
		imageid=$(tplink_get_image_hwid "$1")

		[ "$hwid" != "$imageid" ] && {
			echo "Invalid image, hardware ID mismatch, hw:$hwid image:$imageid."
			return 1
		}

		local boot_size

		boot_size=$(tplink_get_image_boot_size "$1")
		[ "$boot_size" != "00000000" ] && {
			echo "Invalid image, it contains a bootloader."
			return 1
		}

		return 0
		;;
	uap-pro)
		[ "$magic_long" != "19852003" ] && {
			echo "Invalid image type."
			return 1
		}
		return 0
		;;
	wndr3700 | \
	wnr612-v2)
		local hw_magic

		hw_magic="$(ar71xx_get_mtd_part_magic firmware)"
		[ "$magic_long" != "$hw_magic" ] && {
			echo "Invalid image, hardware ID mismatch, hw:$hw_magic image:$magic_long."
			return 1
		}
		return 0
		;;
	routerstation | \
	routerstation-pro | \
	ls-sr71 | \
	pb42 | \
	pb44 | \
	all0305 | \
	eap7660d | \
	ja76pf | \
	ja76pf2 | \
	jwap003 | \
	wp543 | \
	wpe72)
		[ "$magic" != "4349" ] && {
			echo "Invalid image. Use *-sysupgrade.bin files on this board"
			return 1
		}

		local md5_img=$(dd if="$1" bs=2 skip=9 count=16 2>/dev/null)
		local md5_chk=$(dd if="$1" bs=$CI_BLKSZ skip=1 2>/dev/null | md5sum -); md5_chk="${md5_chk%% *}"

		if [ -n "$md5_img" -a -n "$md5_chk" ] && [ "$md5_img" = "$md5_chk" ]; then
			return 0
		else
			echo "Invalid image. Contents do not match checksum (image:$md5_img calculated:$md5_chk)"
			return 1
		fi
		return 0
		;;
	esac

	echo "Sysupgrade is not yet supported on $board."
	return 1
}

platform_do_upgrade() {
	local board=$(ar71xx_board_name)

	case "$board" in
	routerstation | \
	routerstation-pro | \
	ls-sr71 | \
	all0305 | \
	eap7660d | \
	pb42 | \
	pb44 | \
	ja76pf | \
	ja76pf2 | \
	jwap003)
		platform_do_upgrade_combined "$ARGV"
		;;
	wp543|\
	wpe72)
		platform_do_upgrade_compex "$ARGV"
		;;
	all0258n )
		platform_do_upgrade_allnet "0x9f050000" "$ARGV"
		;;
	all0315n )
		platform_do_upgrade_allnet "0x9f080000" "$ARGV"
		;;
	cap4200ag)
		platform_do_upgrade_allnet "0xbf0a0000" "$ARGV"
		;;
	dir-825-b1 |\
	tew-673gru)
		platform_do_upgrade_dir825b "$ARGV"
		;;
	mr600 | \
	mr600v2 | \
	om2p | \
	om2p-hs | \
	om2p-lc)
		platform_do_upgrade_openmesh "$ARGV"
		;;
	uap-pro)
		MTD_CONFIG_ARGS="-s 0x180000"
		default_do_upgrade "$ARGV"
		;;
	*)
		default_do_upgrade "$ARGV"
		;;
	esac
}

disable_watchdog() {
	killall watchdog
	( ps | grep -v 'grep' | grep '/dev/watchdog' ) && {
		echo 'Could not disable watchdog'
		return 1
	}
}

append sysupgrade_pre_upgrade disable_watchdog
