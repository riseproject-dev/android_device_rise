# SpacemiT K3 (RISC-V) — Android device support

This directory is the AOSP device config for the **SpacemiT K3** SoC
(`spacemit,x100`; 8× out-of-order RVA23 cores, RVV/RVH, A100 NPU, PowerVR
BXM-4-64 GPU, riscv64). It targets the **Muse Pico-ITX** board.

The RISE kernel target builds the K3 `Image`, its Pico-ITX DTB and the
modules needed by the Android product.

| Board | SoC | `compatible` | Bootloader media | Android media |
|---|---|---|---|---|
| **Muse Pico-ITX** | K3 / x100 | `spacemit,k3-pico-itx`, `spacemit,k3` | **SPI-NOR** | **UFS 2.2** |

> The board boots its bootloader from **SPI-NOR**, then Android from **UFS**
> (UFS 2.2, 128/256 GB — there is no eMMC). The UFS user LU carries the GPT;
> the bootloader lives on the NOR. See "Storage" below.

## One device, one product

The device is `k3`; the lunch product lives in `k3_pico_itx/`:

- `aosp_k3_pico_itx` — `lunch aosp_k3_pico_itx-trunk_staging-userdebug`

`device/rise/spacemit/k3/device.mk` inherits `device/rise/common` (SoC-agnostic
HALs, the Mesa GPU stack, A/B, codecs, webview, …) and adds the K3-specific
fstab, init, firmware, and storage/WiFi/BT wiring.

## Kernel

The Kleaf target is `spacemit_k3` in
`devices/rise/spacemit/spacemit_soc/`. It emits `k3-pico-itx.dtb` from
`common/arch/riscv/boot/dts/spacemit/`.

Build and stage the kernel prebuilt from the delivery root:

```sh
cd kernel_k3 && mkdir -p out && KERNEL_DIST="$(mktemp -d "$PWD/out/rise-dist.XXXXXX")" && tools/bazel run --config=fast //devices/rise/spacemit/spacemit_soc:spacemit_k3_dist -- --destdir="$KERNEL_DIST" && python3 ../manifest/stage-kernel.py k3 --dist="$KERNEL_DIST" --aosp=../aosp
```

The configuration fragment is
`devices/rise/spacemit/spacemit_soc/spacemit_k3.fragment`.
`TARGET_KERNEL_USE` defaults to `mainline`. Shared SoC drivers retain their
original kernel names.

The product imports `device/rise/spacemit/k3/mesa`; its existing userspace
prebuilts are unchanged while the Mesa update is pending.

## Functional bring-up status

The kernel and bootloader builds have completed in the RISE staging
workspace. The complete RISE Android image build and hardware validation
remain pending.

| Function | Kernel | Firmware | Notes |
|---|---|---|---|
| **Display** | `spacemit-drm.ko` + `spacemit-inno-dp.ko` + `phy-k3-inno-dp.ko` | — | eDP 40-pin (2.5K) + USB-C DP (4K, DP-Alt-Mode). K3 display modules. |
| **GPU** | upstream **open-source** `drm/imagination` (`DRM_POWERVR`); BVNC **36.56.104.183** (BXM-4-64) | `powervr/rogue_36.56.104.183_v1.fw` | userspace = Mesa (≥26.1) `powervr_dri.so`. Firmware from the Imagination linux-firmware repo. |
| **USB** | `dwc3` + `phy-k3-usb2`/`phy-k3-usb3` + `fusb301` (Type-C) | — | USB2 host + USB3 portA(DRD)/portD + FUSB301 TCPC (irq `gpio 2/21`). |
| **WiFi** | `rtw89_8852be` (RTL8852BE, PCIe) | `rtw89/rtw8852b_fw.bin` | M.2 module; PCIe brought up (K3 PCIe PHY + RC). |
| **Bluetooth** | `btusb` + `btrtl` (RTL8852B, USB) | `rtl_bt/rtl8852bu_*` | standard Android BT HAL (USB HCI, no UART transport). |
| **Storage (UFS)** | `ufs-spacemit.ko` (`spacemit,k3-ufshcd`) | — | boot device; loaded from the vendor_boot ramdisk. |
| **Audio (DP)** | `snd-soc-k3-ri2s` + `adma-spacemit` (RCPU domain) → DP codec | — | DP-audio over the DisplayPort (Linux-direct, no RT-coprocessor firmware). |

**Known gaps (need the board, or further work):**

- **Analog audio (ES8326)** is wired in the K3 device tree through
  `i2c3@f0614000`, I2S1 and `sound_card1`. The kernel exports `snd-soc-es8326`
  and the Android product includes the board mixer controls. Playback and
  headset routing still require testing on the board.
- All of the above is compile/integration-level; **runtime validation requires
  the hardware** (PCIe link-up, UFS enumeration, DP link-training, etc.).

## Storage (UFS, not eMMC)

`androidboot.boot_devices` points at the UFS host (`soc/c0e00000.ufshc`); the
fstab uses bus-agnostic `/dev/block/by-name/*` (resolved off the GPT PARTLABEL
on the UFS user LU). `ufs-spacemit.ko` is force-loaded early via
`BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD` so UFS probes before first-stage
mount. The bootloader (U-Boot 2026.07) already has UFS + the K3 controller.

## Bootloader staging

Built from **upstream-based U-Boot 2026.07 + OpenSBI** through
`release_android.sh` and `config/boards/spacemit-k3.yaml`. Outputs are staged
to `vendor/rise/spacemit/k3/bootloader/` (`u-boot-release.itb`, `fw_dynamic`,
`env`, `factory/{FSBL,bootinfo_*}`).

## Flashing

Use `flash_pico_itx.sh` (staged to `PRODUCT_OUT`). The board enters flashing
mode via the **FDL** button; flashing is over the **DRD Type-C** port with the
official `Titan` tool or `fastboot`. Bootloader → SPI-NOR, Android → UFS.

```sh
./flash_pico_itx.sh --android-media=ufs      # Android to UFS (default for this board)
./flash_pico_itx.sh --help                   # all modes
```

> The flash flow (GPT to UFS, U-Boot fastboot SCSI backend) is self-flagged
> UNVALIDATED in the script — it needs board validation.

## See also

- `flash_pico_itx.sh` — the flash tool.
