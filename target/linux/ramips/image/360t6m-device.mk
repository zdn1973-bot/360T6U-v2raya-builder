define Device/360_t6m
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)

  DEVICE_VENDOR := 360
  DEVICE_MODEL := T6M
  DEVICE_DTS := mt7621_360_t6m

  SUPPORTED_DEVICES += 360,360t6m

  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k

  UBINIZE_OPTS := -E 5
  IMAGE_SIZE := 124928k

  IMAGES += firmware.bin

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata

  IMAGE/firmware.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size

  DEVICE_PACKAGES += kmod-mt7915e kmod-mt7915-firmware kmod-nf-tproxy kmod-nft-tproxy iptables-mod-tproxy v2raya luci-app-v2raya xray-core kmod-tun uboot-envtools
endef

TARGET_DEVICES += 360_t6m
