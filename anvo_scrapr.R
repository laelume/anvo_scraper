#!/usr/bin/env Rscript
# anvo_scrapr.R
# R package for downloading open-source and permissibly licensed animal vocalizations

# Load required libraries
suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
})

# Function to download animal sounds from Xeno-Canto
download_animal_sounds <- function(species, 
                                 limit = 50, 
                                 quality = NULL, 
                                 max_duration_minutes = 5, 
                                 base_dir = "xenocanto", 
                                 output_dir = NULL) {
  #' Download animal sound recordings from Xeno-Canto database
  #' 
  #' @param species Character string - search term (common name, scientific name, or genus)
  #' @param limit Integer or NULL - maximum number of files to download (NULL for unlimited)
  #' @param quality Character or NULL - quality filter ('A', 'B', 'C', 'D', 'E', or NULL for any quality)
  #' @param max_duration_minutes Numeric or NULL - maximum recording length in minutes (NULL for any duration)
  #' @param base_dir Character - base download directory
  #' @param output_dir Character or NULL - custom subdirectory name (defaults to species name)
  
  # Base URL for Xeno-Canto API
  base_url <- "https://xeno-canto.org/api/2/recordings"
  
  # Build query - use species as search term
  query_parts <- c(species)
  if (!is.null(quality)) {
    query_parts <- c(query_parts, paste0("q:", quality))
  }
  
  # Make API request
  response <- GET(base_url, query = list(query = paste(query_parts, collapse = " "), page = 1))
  
  # Check if request was successful
  if (status_code(response) != 200) {
    stop("Failed to fetch data from Xeno-Canto API")
  }
  
  # Parse JSON response
  data <- fromJSON(content(response, "text"))
  
  # Construct path: base_dir/species/[quality if specified]
  if (is.null(output_dir)) {
    output_dir <- species
  }
  
  if (!is.null(quality)) {
    download_dir <- file.path(base_dir, output_dir, quality)
  } else {
    download_dir <- file.path(base_dir, output_dir)
  }
  
  # Create directory if it doesn't exist
  dir.create(download_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Format path for OS-appropriate clickable link
  abs_path <- normalizePath(download_dir, mustWork = FALSE)
  if (Sys.info()["sysname"] == "Windows") {
    clickable_path <- paste0("file:///", gsub("\\\\", "/", abs_path))
  } else {
    clickable_path <- paste0("file://", abs_path)
  }
  
  cat("Saving to:", clickable_path, "\n")
  
  downloaded <- 0
  max_duration_seconds <- NULL
  if (!is.null(max_duration_minutes)) {
    max_duration_seconds <- max_duration_minutes * 60
  }
  
  # Loop through recordings
  for (i in 1:nrow(data$recordings)) {
    recording <- data$recordings[i, ]
    
    # Handle limit
    if (!is.null(limit) && downloaded >= limit) {
      break
    }
    
    # Get length for all recordings
    length_str <- ifelse(is.na(recording$length), "0:00", recording$length)
    
    # Check duration only if max_duration_seconds is set
    if (!is.null(max_duration_seconds)) {
      if (grepl(":", length_str)) {
        time_parts <- strsplit(length_str, ":")[[1]]
        if (length(time_parts) == 2) {
          total_seconds <- as.numeric(time_parts[1]) * 60 + as.numeric(time_parts[2])
        } else {
          total_seconds <- 0
        }
      } else {
        total_seconds <- 0
      }
      
      if (total_seconds > max_duration_seconds) {
        cat("Skipping", recording$id, ":", length_str, "exceeds", max_duration_minutes, "min limit\n")
        next
      }
    }
    
    # Get file URL
    file_url <- recording$file
    if (!startsWith(file_url, "http")) {
      file_url <- paste0("https:", file_url)
    }
    
    # Get file extension from URL
    parsed_url <- basename(file_url)
    file_extension <- tools::file_ext(parsed_url)
    if (file_extension == "") {
      file_extension <- "mp3"
    }
    
    # Construct filename: XC[id] - [English name] - [Genus species].[extension]
    xc_id <- recording$id
    english_name <- recording$en
    genus_name <- recording$gen
    species_name <- recording$sp
    full_scientific <- paste(genus_name, species_name)
    
    filename <- paste0("XC", xc_id, " - ", english_name, " - ", full_scientific, ".", file_extension)
    
    # Clean filename for filesystem compatibility
    filename <- gsub("[^[:alnum:][:space:]\\-_\\.]", "", filename)
    
    # Download file
    tryCatch({
      download.file(file_url, file.path(download_dir, filename), mode = "wb", quiet = TRUE)
      cat("Downloaded:", filename, "(", length_str, ")\n")
      downloaded <- downloaded + 1
      Sys.sleep(1)  # Rate limiting
    }, error = function(e) {
      cat("Failed to download", filename, ":", e$message, "\n")
    })
  }
  
  # Print summary
  cat("\nDownload complete! Saved", downloaded, "files to:", clickable_path, "\n")
}

# Help functions
show_help <- function() {
  cat("
anvo_scrapr - Animal Vocalization Scraper (R Version)
======================================================

DESCRIPTION:
    Downloads bird and wildlife sound recordings from Xeno-Canto database
    with flexible filtering by species, quality, and duration.

USAGE:
    Rscript anvo_scrapr.R [OPTIONS]
    
    Or in R console:
    source('anvo_scrapr.R')
    download_animal_sounds('species_name', ...)

PARAMETERS:
    --species, -s          Species name (required)
                          Examples: 'kiwi', 'wild turkey', 'Corvus', 'Apteryx mantelli'
    
    --quality, -q          Quality filter (optional)
                          Options: A, B, C, D, E, or leave empty for any quality
                          A = Excellent, B = Good, C = Average, D = Poor, E = Lowest
    
    --limit, -l            Maximum number of files to download (optional)
                          Examples: 10, 50, or 'unlimited' for no limit
                          Default: 50
    
    --duration, -d         Maximum recording length in minutes (optional)
                          Examples: 2, 5.5, or 'unlimited' for any duration
                          Default: 5
    
    --base-dir, -b         Base download directory (optional)
                          Default: 'xenocanto'
    
    --output-dir, -o       Custom subdirectory name (optional)
                          Default: uses species name

EXAMPLES:
    Rscript anvo_scrapr.R -s kiwi -q A -l 10
    Rscript anvo_scrapr.R --species owl --limit unlimited --quality B
    Rscript anvo_scrapr.R -s Corvus -q A -l 20 -d 2

R CONSOLE EXAMPLES:
    download_animal_sounds('kiwi', quality='A', limit=10)
    download_animal_sounds('owl', limit=NULL, quality='B')
    download_animal_sounds('cardinal', max_duration_minutes=0.5)

SPECIAL COMMANDS:
    Rscript anvo_scrapr.R --help          Show this help
    Rscript anvo_scrapr.R --examples      Show usage examples
    Rscript anvo_scrapr.R --qualities     Show quality rating info
")
}

show_examples <- function() {
  cat("
USAGE EXAMPLES:
==============

Command Line Examples:
    Rscript anvo_scrapr.R -s kiwi
    # Downloads up to 50 kiwi recordings, max 5 minutes each, any quality

    Rscript anvo_scrapr.R -s robin -q A
    # Downloads excellent quality robin recordings only

    Rscript anvo_scrapr.R -s owl -l unlimited -q B
    # Downloads all good quality owl recordings, no limit

    Rscript anvo_scrapr.R -s cardinal -d 0.5
    # Downloads cardinal recordings under 30 seconds

R Console Examples:
    download_animal_sounds('kiwi')
    # Basic download with defaults

    download_animal_sounds('robin', quality='A')
    # High quality only

    download_animal_sounds('owl', limit=NULL, quality='B')
    # Unlimited download, good quality

    download_animal_sounds('cardinal', max_duration_minutes=0.5)
    # Short recordings only

    download_animal_sounds('Corvus', quality='A', limit=20)
    # Scientific name search - 20 excellent quality Corvus recordings

    download_animal_sounds('eagle', output_dir='raptors', quality='B')
    # Custom organization - saves to xenocanto/raptors/B/

    download_animal_sounds('warbler', quality='A', limit=15, 
                          max_duration_minutes=3, base_dir='bird_sounds')
    # Multiple filters

    download_animal_sounds('loon', limit=NULL, max_duration_minutes=NULL)
    # Any quality, any duration, unlimited
")
}

show_qualities <- function() {
  cat("
QUALITY RATINGS:
===============

Xeno-Canto uses letter grades to rate recording quality:

A - Excellent Quality
    - Clear, crisp recordings
    - Minimal background noise
    - High audio fidelity

B - Good Quality
    - Clear recordings with minor imperfections
    - Some background noise acceptable

C - Average Quality
    - Decent recordings with moderate issues
    - Background noise present but manageable

D - Poor Quality
    - Recordings with significant issues
    - Substantial background noise or distortion

E - Lowest Quality
    - Poor recordings with major problems
    - Heavy interference or very poor conditions

NULL (no quality filter):
    - Includes all recordings regardless of rating
    - Also includes unrated recordings

RECOMMENDATION:
For best results, use quality 'A' or 'B' for clear recordings.
Use NULL quality filter if you want maximum variety of recordings.
")
}

# Command line argument parsing
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) == 0) {
    cat("anvo_scrapr - Animal Vocalization Scraper (R Version)\n")
    cat("Use --help for detailed instructions\n\n")
    cat("Quick start:\n")
    cat("Rscript anvo_scrapr.R -s kiwi -q A\n")
    cat("Rscript anvo_scrapr.R --examples\n")
    return(NULL)
  }
  
  # Handle special commands first
  if ("--help" %in% args) {
    show_help()
    return(NULL)
  }
  
  if ("--examples" %in% args) {
    show_examples()
    return(NULL)
  }
  
  if ("--qualities" %in% args) {
    show_qualities()
    return(NULL)
  }
  
  # Parse arguments
  parsed <- list(
    species = NULL,
    quality = NULL,
    limit = 50,
    duration = 5,
    base_dir = "xenocanto",
    output_dir = NULL
  )
  
  i <- 1
  while (i <= length(args)) {
    arg <- args[i]
    
    if (arg %in% c("-s", "--species")) {
      if (i + 1 <= length(args)) {
        parsed$species <- args[i + 1]
        i <- i + 2
      } else {
        stop("Species name required after ", arg)
      }
    } else if (arg %in% c("-q", "--quality")) {
      if (i + 1 <= length(args)) {
        quality <- toupper(args[i + 1])
        if (quality %in% c("A", "B", "C", "D", "E")) {
          parsed$quality <- quality
        } else {
          stop("Quality must be A, B, C, D, or E")
        }
        i <- i + 2
      } else {
        stop("Quality value required after ", arg)
      }
    } else if (arg %in% c("-l", "--limit")) {
      if (i + 1 <= length(args)) {
        limit_val <- args[i + 1]
        if (tolower(limit_val) == "unlimited") {
          parsed$limit <- NULL
        } else {
          parsed$limit <- as.numeric(limit_val)
        }
        i <- i + 2
      } else {
        stop("Limit value required after ", arg)
      }
    } else if (arg %in% c("-d", "--duration")) {
      if (i + 1 <= length(args)) {
        duration_val <- args[i + 1]
        if (tolower(duration_val) == "unlimited") {
          parsed$duration <- NULL
        } else {
          parsed$duration <- as.numeric(duration_val)
        }
        i <- i + 2
      } else {
        stop("Duration value required after ", arg)
      }
    } else if (arg %in% c("-b", "--base-dir")) {
      if (i + 1 <= length(args)) {
        parsed$base_dir <- args[i + 1]
        i <- i + 2
      } else {
        stop("Base directory required after ", arg)
      }
    } else if (arg %in% c("-o", "--output-dir")) {
      if (i + 1 <= length(args)) {
        parsed$output_dir <- args[i + 1]
        i <- i + 2
      } else {
        stop("Output directory required after ", arg)
      }
    } else {
      stop("Unknown argument: ", arg)
    }
  }
  
  return(parsed)
}

# Main function for command line usage
main <- function() {
  tryCatch({
    args <- parse_args()
    
    if (is.null(args)) {
      return(invisible())
    }
    
    if (is.null(args$species)) {
      cat("Error: Species name is required!\n")
      cat("Use: Rscript anvo_scrapr.R --help for detailed instructions\n\n")
      cat("Quick example:\n")
      cat("Rscript anvo_scrapr.R -s kiwi -q A\n")
      return(invisible())
    }
    
    # Download sounds
    cat("anvo_scrapr - Downloading", args$species, "sounds...\n")
    cat(paste(rep("=", 50), collapse=""), "\n")
    
    download_animal_sounds(
      species = args$species,
      limit = args$limit,
      quality = args$quality,
      max_duration_minutes = args$duration,
      base_dir = args$base_dir,
      output_dir = args$output_dir
    )
    
  }, error = function(e) {
    cat("Error:", e$message, "\n")
  })
}

# Run main function if script is called from command line
if (!interactive()) {
  main()
}

# R console examples: 
# source("anvo_scrapr.R")
# download_animal_sounds('kiwi', quality='A', limit=10)

# Command line examples: 
# Get help
# Rscript anvo_scrapr.R --help

# See examples
# Rscript anvo_scrapr.R --examples

# See quality info
# Rscript anvo_scrapr.R --qualities

# Download with parameters
# Rscript anvo_scrapr.R --species owl --quality B --limit unlimited
# Rscript anvo_scrapr.R -s kiwi -q A -l 10
