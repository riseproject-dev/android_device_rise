#!/bin/sh
# Flash bootloader + Android images onto a Zhihe A210 board over fastboot.
#
# Same bootloader staging plus the Android boot chain 
# (boot/init_boot/vendor_boot, both A/B slots), vbmeta
# (+ chained vbmeta_vendor_dlkm/vbmeta_system_dlkm), and super
# (system/vendor/vendor_dlkm/system_dlkm).

FAIL="###### Images flashing failed ######"

usage() {
    echo "Usage: $0 [--wipe] [fastboot-serial]"
    echo "Preserve userdata by default; --wipe erases it."
}

wipe=false
serial=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --wipe) wipe=true ;;
        --help|-h) usage; exit 0 ;;
        -*) usage >&2; exit 2 ;;
        *)
            if [ -n "$serial" ]; then
                usage >&2
                exit 2
            fi
            serial="$1"
            ;;
    esac
    shift
done

FASTBOOT="${FASTBOOT:-$(command -v fastboot 2>/dev/null || true)}"
if [ -z "$FASTBOOT" ] || [ ! -x "$FASTBOOT" ]; then
    echo "fastboot not found (set FASTBOOT or add it to PATH)" >&2
    exit 1
fi

if [ -n "$serial" ]; then
    set -- -s "$serial"
else
    set --
fi

if "$FASTBOOT" "$@" getvar product 2>&1 | grep -q "product: a2"; then
    echo "###### Start flash images ######"
else
    echo "###### Start the flashing tool"
    if [ -e bootzero-rvbl.bin ]; then
        "$FASTBOOT" "$@" flash ram bootzero-rvbl.bin || { echo "$FAIL"; exit 1; }
        "$FASTBOOT" "$@" reboot || { echo "$FAIL"; exit 1; }
        "$FASTBOOT" "$@" flash ram spl-with-fit-rvbl.bin || { echo "$FAIL"; exit 1; }
        "$FASTBOOT" "$@" reboot || { echo "$FAIL"; exit 1; }
    else
        "$FASTBOOT" "$@" flash ram spl-with-fit-rvbl.bin || { echo "$FAIL"; exit 1; }
        "$FASTBOOT" "$@" reboot || { echo "$FAIL"; exit 1; }
    fi
    echo "###### Wait for the flashing tool to be ready"
    sleep 5
fi

echo "###### Flash gpt"
"$FASTBOOT" "$@" flash gpt emmc-gpt_primary.img || { echo "$FAIL"; exit 1; }
echo "###### Flash loader"
"$FASTBOOT" "$@" flash mmc0boot0 emmc_boot-loader.img || { echo "$FAIL"; exit 1; }
echo "###### Flash partition uboot_env"
"$FASTBOOT" "$@" flash uboot_env emmc-uboot_env.img || { echo "$FAIL"; exit 1; }

echo "###### Flash boot (both slots)"
"$FASTBOOT" "$@" flash boot_a boot.img || { echo "$FAIL"; exit 1; }
"$FASTBOOT" "$@" flash boot_b boot.img || { echo "$FAIL"; exit 1; }
echo "###### Flash init_boot (both slots)"
"$FASTBOOT" "$@" flash init_boot_a init_boot.img || { echo "$FAIL"; exit 1; }
"$FASTBOOT" "$@" flash init_boot_b init_boot.img || { echo "$FAIL"; exit 1; }
echo "###### Flash vendor_boot (both slots)"
"$FASTBOOT" "$@" flash vendor_boot_a vendor_boot.img || { echo "$FAIL"; exit 1; }
"$FASTBOOT" "$@" flash vendor_boot_b vendor_boot.img || { echo "$FAIL"; exit 1; }
echo "###### Flash vbmeta (both slots)"
"$FASTBOOT" "$@" flash vbmeta_a vbmeta.img || { echo "$FAIL"; exit 1; }
"$FASTBOOT" "$@" flash vbmeta_b vbmeta.img || { echo "$FAIL"; exit 1; }
echo "###### Flash vbmeta_vendor_dlkm (both slots)"
"$FASTBOOT" "$@" flash vbmeta_vendor_dlkm_a vbmeta_vendor_dlkm.img || { echo "$FAIL"; exit 1; }
"$FASTBOOT" "$@" flash vbmeta_vendor_dlkm_b vbmeta_vendor_dlkm.img || { echo "$FAIL"; exit 1; }
echo "###### Flash vbmeta_system_dlkm (both slots)"
"$FASTBOOT" "$@" flash vbmeta_system_dlkm_a vbmeta_system_dlkm.img || { echo "$FAIL"; exit 1; }
"$FASTBOOT" "$@" flash vbmeta_system_dlkm_b vbmeta_system_dlkm.img || { echo "$FAIL"; exit 1; }
echo "###### Flash super"
"$FASTBOOT" "$@" flash super super.img || { echo "$FAIL"; exit 1; }

if [ "$wipe" = true ]; then
    echo "###### Erase userdata"
    "$FASTBOOT" "$@" erase userdata || { echo "$FAIL"; exit 1; }
fi
echo "###### Erase misc, select slot a"
"$FASTBOOT" "$@" erase misc || { echo "$FAIL"; exit 1; }
"$FASTBOOT" "$@" set_active a || { echo "$FAIL"; exit 1; }

echo "###### Images flashed success ######"
