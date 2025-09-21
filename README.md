# anvo_scrapy: 
Python web scraper for downloading open-source and permissibly licensed animal vocalizatons from websites like Xeno-Canto. 
Downloads by species common or latin name, limits by length or quality, and optionally organizes files by filter choices. Xeno-Canto files are typically stored as .mp3 files, so unless teh extension differes on the source website, this script will probably also store in .mp3 format. (If source file characteristics are different, downloaded files should match original.)

## Installation

### Prerequisites
- Python 3.6+
- Internet connection

### Setup

#### Clone or download the script
```bash
git clone https://github.com/laelume/anvo_scrapy
```

#### Install dependencies
```bash
pip install requirements.txt
```

#### Run the script

### From Command Line: 
```bash
python anvo_scrapy.py
```

### From Jupyter: 
Simply execute the script from within a Jupyter console or inside an editor like Codium:
```bash 
anvo_scrapy.ipynb
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
download_animal_sounds('warbler', limit=None, quality=None)
```
### Download high-quality kiwi sounds
```bash
download_animal_sounds('kiwi', quality='A')
```
### Download any quality owl sounds, no limit on how many files it downloads
```bash
download_animal_sounds('owl', limit=None, quality=None)
```

### Features

#### Flexible search: Common names, scientific names, or genus
#### Quality filtering: A-E ratings or unrated recordings
#### Duration limits: Filter by recording length
#### Auto-organization: Creates species/quality directory structure
#### Cross-platform: Works on Windows, macOS, Linux
#### Progress tracking: Shows download progress and final count
#### Rate limiting: Respects API limits with built-in delays

### Quality Ratings (from Xeno-Canto)

#### A: Excellent quality
#### B: Good quality
#### C: Average quality
#### D: Poor quality
#### E: Lowest quality
#### None: Include unrated recordings

### Rate Limiting
#### The script includes a 1-second delay between downloads to respect Xeno-Canto's server resources. For large downloads, consider breaking them into smaller batches.
