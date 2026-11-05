# Braille Sign Generator for PrusaSlicer

Official PrusaSlicer 3.0+ plugin developed by **3DEMS**. Procedurally generate accessible, standardized tactile Braille signs and architectural plaques with embossed visual lettering and optional mounting holes directly in PrusaSlicer.

---

## 🌟 Why This Plugin?

Creating compliant tactile signage typically requires specialized CAD software, manual Braille dot mapping, and complex boolean operations.

**Braille Sign Generator** streamlines the entire workflow into a single click inside PrusaSlicer:
* **Instant Automatic Translation**: Type any text $\rightarrow$ automatically translated to Grade 1 Braille (letters, numbers with official `#` number prefix, accented vowels, and standard punctuation).
* **Official Regulatory Standards**: Fully compliant with federal and regional accessibility standards (**ADA** in North America / USA, **ONCE / Marburg Medium** in Spain & Europe, and **BANA** internationally).
* **Engineered for 3D Printing (FDM)**: Integrated anti-thin-wall dot stems ensure standard 0.4 mm nozzles slice every single dot reliably without thinning, slicing voids, or tactile degradation.
* **Dual-Color & Filament Change Ready**: Embossed high-contrast visual lettering allows pausing at layer height (`M600`) or multi-tool printing for maximum visual and tactile accessibility.

---

## 🚀 Key Features

* **📜 Standard Accessibility Dimensions**:
  * **North America / USA (ADA Standard)**: Dot height 0.6–0.9 mm, visual-to-tactile spacing $\ge 9.5\text{ mm}$ (3/8 in) compliant with federal Title III guidelines.
  * **Europe / Spain (ONCE - Marburg Medium)**: Spherical tactile domes (dia 1.6 mm, height 0.7 mm, dot pitch 2.5 mm, cell pitch 6.2 mm).
  * **International / Compact (BANA)**: Standard compact pitch for consumer labeling and industrial equipment.
* **🔘 Tactile Dot Profiles**: Choose between **Spherical Domes** (ergonomic, classic finger feel) or **Cylindrical Pins** (maximum vertical definition).
* **🎨 Multi-Color & Dual-Filament Ready**: Embossed high-contrast visual lettering allows pausing at layer height (`M600`) or multi-tool printing for high visual accessibility.
* **🔩 Integrated M3 Mounting Holes**: Optional counterbored 3.2 mm screw holes positioned on the perimeter for architectural installation.
* **⚡ 100% In-Memory Native Generation**: Lightning-fast procedural mesh generation directly onto the build plate without external dependencies.

---

## 📖 Quickstart Guide

1. Open PrusaSlicer and select the **Plater** tab.
2. From the top menu, choose **3DEMS** $\rightarrow$ **Braille Sign Generator**.
3. Type your sign text (e.g. `Restroom`, `Office 102`, `Exit`, `Conference Room`).
4. Select your standard (**ADA Standard** or **ONCE / Marburg**).
5. Click **OK** $\rightarrow$ The ready-to-slice tactile plaque appears on the build plate!

---

## Author & Marketplace
* **Author**: [3DEMS](https://github.com/3dems)
* **Author ID**: `9d2f6477-ddc2-4189-b873-d0026dd7a4ef`
* **Plugin ID**: `io.github.3dems.braille-sign-generator`
* **License**: AGPL-3.0-only
