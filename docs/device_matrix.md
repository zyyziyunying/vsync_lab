# Device Matrix

## 1. Baseline rules

- Physical Android devices only.
- Current experiment baseline: Android 10 / API 29.
- One row should represent one stable hardware + software combination. If the system image, refresh-rate mode, or thermal policy changes, add a new row instead of overwriting the old one.
- Prefer recording the refresh-rate and display details from `device_*.txt` under `artifacts/gfxinfo/`, because `collect_gfxinfo.ps1` already captures `getprop ro.product.model` and `dumpsys display`.

## 2. Priority coverage

The current learning target is still legacy Android 10 hardware. The repo discussion already identifies these chip families as the first priority:

| device_alias | model | soc | android_version | api | nominal_refresh_hz | observed_refresh_hz | status | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `rk3566_primary` | `TBD` | `RK3566` | `Android 10` | `29` | `TBD` | `TBD` | `planned` | Primary legacy platform to fill with real device details |
| `a133_primary` | `TBD` | `Allwinner A133` | `Android 10` | `29` | `TBD` | `TBD` | `planned` | Secondary legacy platform to fill with real device details |

## 3. Suggested recorded fields

When a real device is added, fill at least these columns or append them to the notes field:

| field | description |
| --- | --- |
| `device_alias` | Stable short name used in experiment logs |
| `model` | Commercial model name from `adb shell getprop ro.product.model` |
| `soc` | SoC / chipset family |
| `build_fingerprint` | `adb shell getprop ro.build.fingerprint` |
| `android_version` | Human-readable OS version |
| `api` | Android API level |
| `nominal_refresh_hz` | Panel nominal refresh rate |
| `observed_refresh_hz` | Refresh rate observed from `dumpsys display` or validated in-app |
| `resolution` | Physical resolution if relevant to the test |
| `thermal_power_mode` | Power mode, charger state, fan / thermal setup |
| `notes` | Known quirks, disabled services, developer-option switches, etc. |

## 4. Update rule

Before writing a new experiment result, make sure the device used by that run exists in this file. If not, add it first and then reference its `device_alias` from [experiment_log_template.md](experiment_log_template.md).
