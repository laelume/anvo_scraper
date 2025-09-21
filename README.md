## anvo_scrapr: 
R package for downloading open-source and permissibly licensed animal vocalizatons from websites like Xeno-Canto. 
Downloads by species common or latin name, limits by length or quality, and optionally organizes files by filter choices. 

##### **Note**: Xeno-Canto files are typically stored as .mp3 files, so unless the file extension differes on the source website, this script will probably also store audio in .mp3 format. (If source file characteristics are different, downloaded files should match original.)

### Installation
##### Prerequisites
- R 4.0+
- Internet connection

### Setup

#### 1. Install from GitHub (Recommended for now)

##### Make sure you have devtools for R 
```bash
install.packages("devtools")
```
##### Install package
```bash
devtools::install_github("laelume/anvo_scrapr")
```
##### Load the package in R
```bash
library(anvoscrapr)
```
#### 2. Manual install and load
##### A. Clone, or
```bash
git clone https://github.com/laelume/anvo_scrapr
```
##### B. Download the script
```bash
download.file("https://raw.githubusercontent.com/laelume/anvo_scrapr/main/anvo_scrapr.R", "anvo_scrapr.R")
```
##### Install dependencies
```bash
install.packages(c("httr", "jsonlite"))
```
##### Load script
```bash
source("anvo_scrapr.R")
```
#### 3. Remote install
##### Get remotes package
```bash
install.packages("remotes")
```
##### Install from github using remotes
```bash
remotes::install_github("laelume/anvo_scrapr")
```

## How To Use: 

### Scientific name search
```bash
download_animal_sounds('Corvus', quality='A', limit=20)
```
### Short recordings only
```bash
download_animal_sounds('cardinal', max_duration_minutes=0.5)
```
### Custom organization
```bash
download_animal_sounds('eagle', output_dir='raptors', quality='B')
```
### Bulk download, any quality
```bash
download_animal_sounds('warbler', limit=NULL, quality=NULL)
```
### Download high-quality kiwi sounds
```bash
download_animal_sounds('kiwi', quality='A')
```
### Download any quality owl sounds, no limit on how many files it downloads
```bash
download_animal_sounds('owl', limit=None, quality=NULL)
```

#### Features

##### - Flexible search: Common names, scientific names, or genus
##### - Quality filtering: A-E ratings or unrated recordings
##### - Duration limits: Filter by recording length
##### - Auto-organization: Creates species/quality directory structure
##### - Cross-platform: Works on Windows, macOS, Linux
##### - Progress tracking: Shows download progress and final count
##### - Rate limiting: Respects API limits with built-in delays

#### Quality Ratings (from Xeno-Canto)

##### A: Excellent quality
##### B: Good quality
##### C: Average quality
##### D: Poor quality
##### E: Lowest quality
#### None: Include unrated recordings

#### Rate Limiting
##### The script includes a 1-second delay between downloads to respect Xeno-Canto's server resources. For large downloads, consider breaking them into smaller batches.
