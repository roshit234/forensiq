### 🔬 [ForensIQ — Digital Forensic Field Assistant](https://github.com/roshit234/forensiq)

An **offline-first Flutter application** designed to support presumptive drug testing through image-based color analysis and cryptographic evidence logging.

**Key Features**
- 📷 **Camera-Based Evidence Capture:** Direct camera capture with image-quality validation, blur detection, and exposure checks.
- 🎨 **Color Calibration:** Reference-chart sampling and per-channel Ordinary Least Squares (OLS) linear regression to compensate for lighting and camera color variations.
- 🧪 **Colorimetric Classification:** Uses RGB Euclidean color distance and deterministic rules to classify observed reaction colors.
- 🔐 **Evidence Integrity:** SHA-256 image hashing with associated timestamps, location data, and locally stored evidence records.
- 📱 **Offline-First Design:** Supports field workflows without requiring continuous internet connectivity.

**Tech Stack:** Flutter • Dart • Image Processing • Linear Regression • RGB Color Analysis • SHA-256
