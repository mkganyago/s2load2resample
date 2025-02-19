# Install/load libraries
if (!require("xml2")) { 
  install.packages("xml2")
  library(xml2)
}

if (!require("terra")) { 
  install.packages("terra")
  library(terra)
}

if (!require("gtools")) { 
  install.packages("gtools")
  library(gtools)
}

# Function to load and resample Sentinel-2 level 1C
s2load2resample1C <- function(xml_path, resample_to = "10m") {

  # Check if the XML file exists
  if (!file.exists(xml_path)) {
    stop("The specified MTD_MSIL1C.xml file does not exist.")
  }
  
  # Parse the XML file
  xml_content <- read_xml(xml_path)
  
  # Extract all IMAGE_FILE nodes
  image_files_nodes <- xml_find_all(xml_content, ".//IMAGE_FILE")
  image_files <- xml_text(image_files_nodes)
  
  # Construct full paths by appending .jp2 and prepending the base directory
  base_dir <- dirname(xml_path)
  image_files_full_paths <- file.path(base_dir, paste0(image_files, ".jp2"))
  
  # Define band groups
  bands_10m <- grep("_B(02|03|04|08)\\.jp2$", image_files_full_paths, value = TRUE)
  bands_20m <- grep("_B(05|06|07|8A|11|12)\\.jp2$", image_files_full_paths, value = TRUE)
  
  # Validate that all requested bands are available
  missing_10m <- setdiff(bands_10m, image_files_full_paths)
  missing_20m <- setdiff(bands_20m, image_files_full_paths)
  
  if (length(missing_10m) > 0) {
    stop(paste("The following 10m bands are missing:", paste(missing_10m, collapse = ", ")))
  }
  if (length(missing_20m) > 0) {
    stop(paste("The following 20m bands are missing:", paste(missing_20m, collapse = ", ")))
  }
  
  # Load the bands as SpatRaster stacks
  s2_10m <- rast(mixedsort(bands_10m))
  s2_20m <- rast(mixedsort(bands_20m))
  
  # Resampling logic
  if (resample_to == "10m") {
    # Resample 20m bands to 10m resolution
    s2_20m_resampled <- terra::resample(x = s2_20m, y = s2_10m, method = "bilinear")
    s2_stack_10m <- terra::rast(c(s2_10m, s2_20m_resampled))
    # Rename the stacked all spectral bands
    names(s2_stack_10m) <- c("B2","B3","B4","B8","B5","B6","B7","B8A","B11","B12")
    # Sort the names in sequence
    sorted_names <- gtools::mixedsort(names(s2_stack_10m))
    return(s2_stack_10m[[sorted_names]])
  } else if (resample_to == "20m") {
    # Resample 10m bands to 20m resolution
    s2_10m_resampled <- terra::resample(s2_10m, s2_20m, method = "bilinear")
    s2_stack_20m <- terra::rast(c(s2_10m_resampled,s2_20m))
    # Rename the stacked all spectral bands
    names(s2_stack_20m) <- c("B2","B3","B4","B8","B5","B6","B7","B8A","B11","B12")
    # Sort the names in sequence
    sorted_names <- gtools::mixedsort(names(s2_stack_20m))
    return(s2_stack_20m[[sorted_names]])
  } else {
    stop("Invalid resampling resolution specified. Use '10m' or '20m'.")
  }
}
#---------------------------------------------------------------
# Function to load and resample Sentinel-2 Level 2A
s2load2resample2A <- function(xml_path, resample_to = "10m") {
  if (!file.exists(xml_path)) {
    stop("The specified MTD_MSIL2A.xml file does not exist.")
  }
  
  base_dir <- dirname(xml_path)
  granule_path <- list.dirs(file.path(base_dir, "GRANULE"), recursive = FALSE)
  if (length(granule_path) == 0) stop("No GRANULE folder found inside the SAFE directory.")
  
  r10m_path <- file.path(granule_path, "IMG_DATA", "R10m")
  r20m_path <- file.path(granule_path, "IMG_DATA", "R20m")
  
  if (!dir.exists(r10m_path) || !dir.exists(r20m_path)) {
    stop("R10m or R20m directories not found in the expected path.")
  }
  
  # Print available files to check manually if needed
#  cat("R10m files:\n", paste(list.files(r10m_path), collapse = "\n"), "\n")
#  cat("R20m files:\n", paste(list.files(r20m_path), collapse = "\n"), "\n")
  
  # Load bands flexibly
  bands_10m <- list.files(r10m_path, pattern = "B02|B03|B04|B08", full.names = TRUE)
  bands_20m <- list.files(r20m_path, pattern = "B05|B06|B07|B8A|B11|B12", full.names = TRUE)
  
  if (length(bands_10m) != 4) {
    stop("Expected 4 bands in R10m (B02, B03, B04, B08), but found: ", length(bands_10m))
  }
  
  if (length(bands_20m) != 6) {
    stop("Expected 6 bands in R20m (B05, B06, B07, B8A, B11, B12), but found: ", length(bands_20m))
  }
  
  # Load rasters
  s2_10m <- rast(gtools::mixedsort(bands_10m))
  s2_20m <- rast(gtools::mixedsort(bands_20m))
  
  # Rename bands
  names(s2_10m) <- c("B2", "B3", "B4", "B8")
  names(s2_20m) <- c("B5", "B6", "B7", "B8A", "B11", "B12")
  
  # Resampling logic
  if (resample_to == "10m") {
    s2_20m_resampled <- terra::resample(s2_20m, s2_10m, method = "bilinear")
    s2_stack_10m <- terra::rast(c(s2_10m, s2_20m_resampled))
    sorted_stack <- s2_stack_10m[[mixedsort(names(s2_stack_10m))]]
    return(sorted_stack)
  } else if (resample_to == "20m") {
    s2_10m_resampled <- terra::resample(s2_10m, s2_20m, method = "bilinear")
    s2_stack_20m <- terra::rast(c(s2_10m_resampled, s2_20m))
    sorted_stack <- s2_stack_20m[[mixedsort(names(s2_stack_20m))]]
    return(sorted_stack)
  } else {
    stop("Invalid resampling resolution specified. Use '10m' or '20m'.")
  }
}
