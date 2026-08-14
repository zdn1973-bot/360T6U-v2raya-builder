name: Build ImmortalWrt 360T6M v2rayA

on:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-24.04

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y build-essential clang flex bison g++ gawk gcc-multilib gettext git libncurses-dev libssl-dev python3 python3-dev python3-pip python3-setuptools rsync unzip zlib1g-dev file wget curl device-tree-compiler ccache libelf-dev libxml-parser-perl swig time

      - name: Clone ImmortalWrt
        run: |
          rm -rf source
          git clone --depth=1 --branch=openwrt-23.05 https://github.com/immortalwrt/immortalwrt.git source
          cd source
          git log -1 --oneline

      - name: Copy DTS
        run: |
          test -f target/linux/ramips/dts/mt7621_360_t6m.dts
          mkdir -p source/target/linux/ramips/dts
          cp target/linux/ramips/dts/mt7621_360_t6m.dts source/target/linux/ramips/dts/mt7621_360_t6m.dts

      - name: Fix green LED
        working-directory: source
        run: |
          sed -i 's/GPIO_ACTIVE_HIGH/GPIO_ACTIVE_LOW/g' target/linux/ramips/dts/mt7621_360_t6m.dts
          sed -i '/label = "green:system";/a\		default-state = "on";' target/linux/ramips/dts/mt7621_360_t6m.dts

      - name: Update feeds
        working-directory: source
        run: |
          ./scripts/feeds update -a
          ./scripts/feeds install -a

      - name: Copy device definition
        run: |
          test -f target/linux/ramips/image/360t6m-device.mk
          cat target/linux/ramips/image/360t6m-device.mk >> source/target/linux/ramips/image/mt7621.mk

      - name: Verify DTS
        working-directory: source
        run: |
          set -e

          grep -q 'compatible = "360,360t6m"' target/linux/ramips/dts/mt7621_360_t6m.dts
          grep -q 'model = "360T6M"' target/linux/ramips/dts/mt7621_360_t6m.dts

          grep -q 'label = "wan"' target/linux/ramips/dts/mt7621_360_t6m.dts
          grep -q 'label = "lan1"' target/linux/ramips/dts/mt7621_360_t6m.dts
          grep -q 'label = "lan2"' target/linux/ramips/dts/mt7621_360_t6m.dts
          grep -q 'label = "lan3"' target/linux/ramips/dts/mt7621_360_t6m.dts

          grep -q 'compatible = "mediatek,mt76"' target/linux/ramips/dts/mt7621_360_t6m.dts
          grep -q 'GPIO_ACTIVE_LOW' target/linux/ramips/dts/mt7621_360_t6m.dts
          grep -q 'default-state = "on"' target/linux/ramips/dts/mt7621_360_t6m.dts

          grep -q 'label = "kernel"' target/linux/ramips/dts/mt7621_360_t6m.dts
          grep -q 'label = "ubi"' target/linux/ramips/dts/mt7621_360_t6m.dts

          echo "DTS verification successful"

      - name: Check DTS syntax
        working-directory: source
        run: |
          dtc -I dts -O dtb -i target/linux/ramips/dts -o /tmp/360t6m.dtb target/linux/ramips/dts/mt7621_360_t6m.dts
          test -s /tmp/360t6m.dtb
          echo "DTS compilation successful"

      - name: Configure feeds and target
        working-directory: source
        run: |
          ./scripts/feeds update -a
          ./scripts/feeds install -a

          echo 'CONFIG_TARGET_ramips=y' > .config
          echo 'CONFIG_TARGET_ramips_mt7621=y' >> .config
          echo 'CONFIG_TARGET_ramips_mt7621_DEVICE_360_t6m=y' >> .config

          echo 'CONFIG_PACKAGE_kmod-nf-tproxy=y' >> .config
          echo 'CONFIG_PACKAGE_kmod-nft-tproxy=y' >> .config
          echo 'CONFIG_PACKAGE_iptables-mod-tproxy=y' >> .config
          echo 'CONFIG_PACKAGE_v2raya=y' >> .config
          echo 'CONFIG_PACKAGE_luci-app-v2raya=y' >> .config
          echo 'CONFIG_PACKAGE_xray-core=y' >> .config
          echo 'CONFIG_PACKAGE_kmod-tun=y' >> .config
          echo 'CONFIG_PACKAGE_curl=y' >> .config
          echo 'CONFIG_PACKAGE_ca-bundle=y' >> .config
          echo 'CONFIG_PACKAGE_ca-certificates=y' >> .config

          make defconfig

      - name: Verify configuration
        working-directory: source
        run: |
          set -e

          grep -q '^CONFIG_TARGET_ramips=y$' .config
          grep -q '^CONFIG_TARGET_ramips_mt7621=y$' .config
          grep -q '^CONFIG_TARGET_ramips_mt7621_DEVICE_360_t6m=y$' .config

          grep -q '^CONFIG_PACKAGE_kmod-nf-tproxy=y$' .config
          grep -q '^CONFIG_PACKAGE_kmod-nft-tproxy=y$' .config
          grep -q '^CONFIG_PACKAGE_iptables-mod-tproxy=y$' .config
          grep -q '^CONFIG_PACKAGE_v2raya=y$' .config
          grep -q '^CONFIG_PACKAGE_luci-app-v2raya=y$' .config
          grep -q '^CONFIG_PACKAGE_xray-core=y$' .config

          echo "Configuration verified successfully"

      - name: Download sources
        working-directory: source
        run: |
          make download -j2 V=s

      - name: Build
        working-directory: source
        run: |
          make -j$(nproc) V=s

      - name: Show output
        working-directory: source
        run: |
          find bin/targets/ramips/mt7621 -type f -print | sort

      - name: Upload firmware
        uses: actions/upload-artifact@v4
        with:
          name: ImmortalWrt-360T6M-v2raya
          path: source/bin/targets/ramips/mt7621/**/*
          if-no-files-found: error
          retention-days: 30
