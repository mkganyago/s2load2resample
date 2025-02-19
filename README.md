# Automatic Sentinel-2 Data Loading & Resampling in R

## Overview
This repository contains two functions, namely, `s2load2resample1C` and `s2load2resample2A` to load and resample Sentinel-2 satellite imagery (Level-1C and Level-2A products) into a consistent resolution raster stack using `terra` and `xml` R-packages. Bands are resampled to either 10m or 20m resolution and returned in spectral order. Supports .SAFE format images (unzipped) downloaded from Copernicus Browser (https://browser.dataspace.copernicus.eu/)

---

## `s2load2resample1C`

### Description
Loads Sentinel-2 Level-1C (Top-of-Atmosphere reflectance) data, resamples bands to a target resolution (either 10m or 20m), and returns a stacked `SpatRaster`.

### Arguments
- **`xml_path`**: Path to `MTD_MSIL1C.xml` metadata file within the `.SAFE` directory.
- **`resample_to`**: Target resolution (`"10m"` or `"20m"`). Default: `"10m"`.

### Details
- **Bands Processed**:
  - 10m: B2 (Blue), B3 (Green), B4 (Red), B8 (NIR).
  - 20m: B5, B6, B7 (Vegetation Red Edge), B8A (Narrow NIR), B11, B12 (SWIR).
- **Resampling**: Uses bilinear interpolation. Lower-resolution bands are upsampled to match higher resolution if needed.

### Value
A `SpatRaster` stack with bands ordered as: `B2, B3, B4, B5, B6, B7, B8, B8A, B11, B12`.

---

## `s2load2resample2A`

### Description
Loads Sentinel-2 Level-2A (surface reflectance) data, resamples bands, and returns a stacked `SpatRaster`.

### Arguments
- **`xml_path`**: Path to `MTD_MSIL2A.xml` metadata file within the `.SAFE` directory.
- **`resample_to`**: Target resolution (`"10m"` or `"20m"`). Default: `"10m"`.

### Details
- **Directory Structure**: Assumes the `.SAFE` directory contains a `GRANULE` subfolder with one granule. Uses bands from `IMG_DATA/R10m` and `IMG_DATA/R20m`.
- **Bands Processed**: Same as Level-1C but from atmospherically corrected data.

### Value
A `SpatRaster` stack with bands ordered as: `B2, B3, B4, B5, B6, B7, B8, B8A, B11, B12`.

---

## Dependencies
- **Packages**: `xml2` (XML parsing), `terra` (raster handling), `gtools` (band sorting).
- The functions auto-install missing packages if needed.

## Usage
```R
# Level-1C (resampled to 10m by default)
l1c_stack_10m <- s2load2resample1C("S2A_MSIL1C_20210101T100432_N0209_R022_T32TQR_20210101T120000.SAFE/MTD_MSIL1C.xml")

# Level-2A (resampled to 20m)
l2a_stack_20m <- s2load2resample2A("S2A_MSIL2A_20210101T100432_N0214_R022_T32TQR_20210101T120000.SAFE/MTD_MSIL2A.xml", resample_to = "20m")
```
