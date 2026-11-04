# Braille Sign Generator for PrusaSlicer

Official PrusaSlicer 3.0+ plugin developed by **3DEMS**. Generate accessible, standardized tactile Braille signs and plaques with embossed visual lettering and optional mounting holes directly in PrusaSlicer.

---

## 🌟 Why This Plugin?

Creating compliant tactile signage typically requires specialized CAD software, manual Braille dot mapping, and complex boolean operations.

**Braille Sign Generator** streamlines the entire workflow into a single click inside PrusaSlicer:
* Type your text $\rightarrow$ automatically translated to Grade 1 Braille (letters, numbers, Spanish accented vowels `á`, `é`, `í`, `ó`, `ú`, `ü`, `ñ`, and punctuation).
* Fully compliant with regional accessibility legislation (**ADA** in the US, **ONCE / Marburg Medium** in Spain & Europe, and **BANA** internationally).
* Specially engineered **anti-thin-wall dot stems**: 0.4 mm nozzles slice every single dot reliably without thinning, slicing voids, or tactile degradation.

---

## 🚀 Key Features

* **📜 Official Regulatory Standards**:
  * **América / EE.UU. (ADA Standard)**: Compliant with federal accessibility standards (Title III ADA), dot height 0.6–0.9 mm, visual-to-tactile spacing $\ge 9.5\text{ mm}$ (3/8 in).
  * **Europa / España (ONCE - Marburg Medium)**: Spherical tactile domes (dia 1.6 mm, height 0.7 mm, dot pitch 2.5 mm, cell pitch 6.2 mm).
  * **Internacional / Compacto (BANA)**: Standard compact pitch for consumer labeling and industrial equipment.
* **🎨 Multi-Color & Dual-Filament Ready**: Embossed high-contrast visual lettering allows pausing at layer height (`M600`) or multi-tool printing for high visual accessibility.
* **🔘 Dot Geometries**: Choose between **Spherical Domes** (ergonomic, finger-friendly) or **Truncated Cones** (maximum printability on FDM).
* **🔩 Integrated M3 Mounting Holes**: Optional counterbored 3.2 mm screw holes positioned on the perimeter for architectural installation.
* **🛡️ Chamfered Ergonomic Edges**: Smooth beveled plate border prevents sharp corners.
* **⚡ 100% In-Memory Native Generation**: Lightning-fast procedural mesh generation directly onto the build plate.

---

## 🇪🇸 Descripción en Español

Plugin oficial para PrusaSlicer 3.0+ desarrollado por **3DEMS**. Genera placas y señalética accesible en sistema Braille con texto en relieve:
* **Normativas oficiales integradas**: Compatible con el estándar **ONCE (Marburg Medium)** en España y Europa, y con la normativa **ADA** en EE.UU.
* **Traducción automática**: Convierte texto con acentos (`á`, `é`, `í`, `ó`, `ú`, `ü`, `ñ`), números con prefijo numérico (#) y signos de puntuación.
* **Diseño optimizado para FDM**: Geometría de cúpula con cuello cilíndrico que garantiza que boquillas estándar de 0.4 mm laminen todos los puntos sin omisiones ni paredes finas.
* **Apto para doble color**: Texto visual en relieve para cambios de filamento en altura (`M600`) o impresoras multimaterial.

---

## 📖 Quickstart / Cómo usarlo

1. Open PrusaSlicer and select the Plater view.
2. In the top menu, click **3DEMS** $\rightarrow$ **Braille Sign Generator**.
3. Type your sign text (e.g. `Office 102`, `Baño mujeres`, `Exit`).
4. Select your standard (**ONCE / Marburg** or **ADA Standard**).
5. Click **OK** $\rightarrow$ Ready-to-slice tactile plaque appears on the bed!

---

## Author & Marketplace
* **Author**: [3DEMS](https://github.com/3dems)
* **Author ID**: `9d2f6477-ddc2-4189-b873-d0026dd7a4ef`
* **Plugin ID**: `io.github.3dems.braille-sign-generator`
* **License**: AGPL-3.0-only
