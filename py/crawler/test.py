import datetime
import logging
import re
from typing import List, Dict, Optional
from dataclasses import dataclass
from decimal import Decimal
import httpx
from bs4 import BeautifulSoup


## Current Code Structure
## What Downloads:
##      fetch_text() - Downloads HTML pages, CSV files, JSON data
##      fetch_binary() - Downloads ZIP archives
##      get_zip_contents() - Downloads and extracts ZIP files
##      Methods like
##          get_index(),
##          get_store_csv_url() // Used only in KTC
##          that fetch data from URLs

## What Parses:
##      parse_csv() - Converts CSV text into Product objects
##      parse_xml() - Converts XML into Product objects
##      parse_index() - Extracts URLs from HTML pages
##      parse_store_info() - Extracts store details from filenames/URLs

## Various field mapping and data cleaning methods
## The issue is that downloading and parsing are often mixed together in the same methods, making ## the code harder to understand and test.
##


logger = logging.getLogger(__name__)

# Data Models
@dataclass
class Product:
    product_id: str
    name: str
    brand: str
    price: Decimal
    unit_price: Optional[Decimal] = None
    category: str = ""
    barcode: str = ""

@dataclass
class Store:
    store_id: str
    name: str
    address: str
    city: str
    products: List[Product]

@dataclass
class RawData:
    """Container for raw downloaded data before parsing"""
    content: str
    url: str
    content_type: str
    encoding: str = "utf-8"

# ============================================================================
# DOWNLOADER - Only responsible for fetching data
# ============================================================================

class DataDownloader:
    """Handles all data downloading operations"""
    
    def __init__(self, timeout: float = 30.0):
        self.client = httpx.Client(timeout=timeout, follow_redirects=True)
        
    def download_text(self, url: str, encoding: str = "utf-8") -> RawData:
        """Download text content from URL"""
        logger.info(f"Downloading text from: {url}")
        
        try:
            response = self.client.get(url)
            response.raise_for_status()
            
            content = response.content.decode(encoding) if encoding else response.text
            
            return RawData(
                content=content,
                url=url,
                content_type="text",
                encoding=encoding
            )
            
        except Exception as e:
            logger.error(f"Failed to download {url}: {e}")
            raise
    
    def download_csv_files_for_date(self, base_url: str, date: datetime.date) -> List[RawData]:
        """Download all CSV files for a specific date"""
        logger.info(f"Finding CSV files for date: {date}")
        
        # Step 1: Download the index page
        index_data = self.download_text(base_url)
        
        # Step 2: Extract CSV URLs from index (this is minimal parsing for navigation)
        csv_urls = self._extract_csv_urls_from_index(index_data.content, date)
        
        # Step 3: Download all CSV files
        csv_files = []
        for url in csv_urls:
            csv_data = self.download_text(url, encoding="windows-1250")  # Common for Croatian sites
            csv_files.append(csv_data)
            
        logger.info(f"Downloaded {len(csv_files)} CSV files")
        return csv_files
    
    def _extract_csv_urls_from_index(self, html_content: str, date: datetime.date) -> List[str]:
        """Extract CSV URLs from HTML index page"""
        soup = BeautifulSoup(html_content, "html.parser")
        csv_links = []
        
        date_str = date.strftime("%Y%m%d")  # YYYYMMDD format
        
        for link in soup.select('a[href$=".csv"]'):
            href = link.get("href")
            if href and date_str in href:
                csv_links.append(href)
                
        return csv_links

# ============================================================================
# PARSER - Only responsible for parsing downloaded data
# ============================================================================

class DataParser:
    """Handles all data parsing operations"""
    
    def __init__(self):
        self.price_columns = {
            "price": ("MPC", True),
            "unit_price": ("Cijena po jedinici", False),
        }
        
        self.product_columns = {
            "product_id": ("Šifra", True),
            "name": ("Naziv", True),
            "brand": ("Marka", False),
            "category": ("Kategorija", False),
            "barcode": ("Barkod", False),
        }
    
    def parse_csv_to_products(self, csv_data: RawData) -> List[Product]:
        """Parse CSV content into Product objects"""
        logger.info(f"Parsing CSV from: {csv_data.url}")
        
        products = []
        lines = csv_data.content.strip().split('\n')
        
        if not lines:
            return products
            
        # Parse header
        header = [col.strip() for col in lines[0].split(';')]
        
        # Parse data rows
        for line_num, line in enumerate(lines[1:], 2):
            try:
                row_data = dict(zip(header, line.split(';')))
                product = self._parse_product_row(row_data)
                if product:
                    products.append(product)
                    
            except Exception as e:
                logger.warning(f"Failed to parse line {line_num}: {e}")
                continue
                
        logger.info(f"Parsed {len(products)} products from CSV")
        return products
    
    def parse_store_info_from_url(self, url: str) -> Store:
        """Extract store information from CSV filename/URL"""
        logger.debug(f"Parsing store info from: {url}")
        
        # Example filename: "supermarket_zagreb_main_store_001_20240515.csv"
        filename = url.split('/')[-1]
        
        # Use regex to extract store information
        pattern = r"(\w+)_([^_]+)_([^_]+)_store_(\d+)_\d+\.csv"
        match = re.search(pattern, filename)
        
        if not match:
            raise ValueError(f"Cannot parse store info from filename: {filename}")
            
        store_type, city, location, store_id = match.groups()
        
        return Store(
            store_id=store_id,
            name=f"{store_type.title()} {city.title()}",
            address=f"{location.replace('_', ' ').title()}, {city.title()}",
            city=city.title(),
            products=[]  # Will be populated later
        )
    
    def _parse_product_row(self, row: Dict[str, str]) -> Optional[Product]:
        """Parse a single CSV row into a Product"""
        try:
            # Extract required fields
            product_id = row.get("Šifra", "").strip()
            name = row.get("Naziv", "").strip()
            
            if not product_id or not name:
                return None
                
            # Parse price
            price_str = row.get("MPC", "0").replace(",", ".").strip()
            price = Decimal(price_str) if price_str else Decimal("0")
            
            # Parse optional fields
            brand = row.get("Marka", "").strip()
            category = row.get("Kategorija", "").strip()
            barcode = row.get("Barkod", "").strip()
            
            # Parse unit price if available
            unit_price = None
            unit_price_str = row.get("Cijena po jedinici", "").replace(",", ".").strip()
            if unit_price_str:
                unit_price = Decimal(unit_price_str)
            
            return Product(
                product_id=product_id,
                name=name,
                brand=brand,
                price=price,
                unit_price=unit_price,
                category=category,
                barcode=barcode
            )
            
        except Exception as e:
            logger.warning(f"Error parsing product row: {e}")
            return None

# ============================================================================
# CRAWLER - Orchestrates downloading and parsing
# ============================================================================

class StoreCrawler:
    """Main crawler that orchestrates downloading and parsing"""
    
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.downloader = DataDownloader()
        self.parser = DataParser()
    
    def crawl_stores_for_date(self, date: datetime.date) -> List[Store]:
        """Main method that coordinates the entire crawling process"""
        logger.info(f"Starting crawl for date: {date}")
        
        try:
            # STEP 1: DOWNLOAD - Get all raw data
            csv_files = self.downloader.download_csv_files_for_date(self.base_url, date)
            
            if not csv_files:
                logger.warning(f"No CSV files found for date {date}")
                return []
            
            # STEP 2: PARSE - Convert raw data to structured objects
            stores = []
            for csv_data in csv_files:
                try:
                    # Parse store information from URL/filename
                    store = self.parser.parse_store_info_from_url(csv_data.url)
                    
                    # Parse products from CSV content
                    products = self.parser.parse_csv_to_products(csv_data)
                    
                    # Combine store + products
                    store.products = products
                    stores.append(store)
                    
                except Exception as e:
                    logger.error(f"Failed to process {csv_data.url}: {e}")
                    continue
            
            logger.info(f"Successfully crawled {len(stores)} stores")
            return stores
            
        except Exception as e:
            logger.error(f"Crawl failed: {e}")
            raise

# ============================================================================
# USAGE EXAMPLE
# ============================================================================

def main():
    """Example usage showing clear separation of concerns"""
    logging.basicConfig(level=logging.INFO)
    
    # Initialize crawler
    crawler = StoreCrawler("https://example-store.hr/price-lists")
    
    # Crawl data for today
    today = datetime.date.today()
    stores = crawler.crawl_stores_for_date(today)
    
    # Display results
    for store in stores:
        print(f"\nStore: {store.name} ({store.store_id})")
        print(f"Address: {store.address}")
        print(f"Products: {len(store.products)}")
        
        # Show first few products
        for product in store.products[:3]:
            print(f"  - {product.name} ({product.brand}): €{product.price}")

if __name__ == "__main__":
    main()
