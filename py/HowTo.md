# Prices API

A service for retrieving public data on product prices in retail chains in the Republic of Croatia.

Retrieving product price data in Croatian retail chains is based on the **Decision on the Publication of Price Lists and Display of Additional Prices as a Measure of Direct Price Control in Retail Trade**, Official Gazette (NN) 75/2025, dated May 2, 2025.

Currently supported retail chains:

* Konzum  
* Lidl  
* Plodine  
* Spar  
* Tommy  
* Studenac  
* Kaufland  
* Eurospin  
* dm  
* KTC  
* Metro  
* Trgocentar  
* Žabac  
* Vrutak  
* Ribola  
* NTL  

## Software Implementation

The software is built in Python and consists of two parts:

* **Crawler** – fetches data from the websites of retail chains (`crawler`)  
* **Web Service** – API for accessing product price data (`service`) – **IN DEVELOPMENT**

## Installation

To install the crawler, Python 3.13 or newer is required. We recommend using `uv` for setting up the project:

```bash
git clone https://github.com/senko/cijene-api.git
cd cijene-api
uv sync --dev
```

## Usage

### Crawler

To run the crawler, execute the following command:

uv run -m crawler.cli.crawl /path/to/output-folder/

Or using Python directly (in a suitable virtual environment):

python -m crawler.cli.crawl /path/to/output-folder/

The crawler accepts the following options:
    •    -l – list supported retail chains
    •    -d – choose date (default: current day)
    •    -c – select chains (default: all)
    •    -h – display help

## Running on Windows

Note: For Windows users – set the PYTHONUTF8 environment variable to 1 or run Python with the -X utf8 flag to avoid character encoding issues. More details available at:
https://github.com/senko/cijene-api/issues/9#issuecomment-2911110424

## Web Service

Before running the service, create a .env file with configuration variables.
A sample file with default values can be found in .env.example.

After creating the .env file, start the service using:

uv run -m service.main

The service will be available at http://localhost:8000 (unless the port is changed).
API documentation (Swagger) will be accessible at http://localhost:8000/docs.

License

This project is licensed under the AGPL-3 license (see LICENSE file).

The data collected through this project is public and available to everyone, based on the Decision on the Publication of Price Lists and Display of Additional Prices as a Measure of Direct Price Control in Retail Trade, Official Gazette (NN) 75/2025, dated May 2, 2025.

## How To

The ZIP archive contains CSV files with pricing data for that day.

Archive Structure

The folder structure inside the ZIP archive, for each retail chain:

<chain>/
<chain>/stores.csv
<chain>/products.csv
<chain>/prices.csv

Explanation:
    •    stores.csv - list of store locations for the retail chain
    •    products.csv - list of unique products sold by the retail chain
    •    prices.csv - list of product prices per store (references product and store IDs)

The archive contains data for the following retail chains: Konzum, Spar, Studenac, Plodine, Lidl, Tommy, Kaufland, Eurospin, dm, KTC, Metro, Trgocentar, Žabac, Vrutak, Ribola, NTL.

CSV File Formats

All files are in UTF-8 format, without BOM, and use a comma (,) as the separator.
The first line of each file contains the column headers.

Stores: stores.csv

Columns:
    •    store_id - store identifier (within a specific retail chain)
    •    type - store type (e.g., supermarket, hypermarket)
    •    address - store address
    •    city - city where the store is located
    •    zipcode - store postal code

Products: products.csv

Columns:
    •    product_id - product identifier (within a specific retail chain)
    •    barcode - product EAN code if available, or a code in the format <chain>:<product_id>
    •    name - product name
    •    brand - product brand
    •    category - product category
    •    unit - unit of measure
    •    quantity - quantity (number of items, weight, or volume)

Note: EAN codes are not always available, so in those cases, a code in the format <chain>:<product_id> is used. The product_id is unique within a retail chain but not across different chains.

Prices: prices.csv

Columns:
    •    store_id - store identifier (within a specific retail chain)
    •    product_id - product identifier (within a specific retail chain)
    •    price - product price
    •    unit_price - price per unit of measure (if available, otherwise empty)
    •    best_price_30 - best price in the last 30 days (if available, otherwise empty)
    •    anchor_price - price as of May 2, 2025 (if available, otherwise empty)
    •    special_price - discounted price (if available, otherwise empty)

## Data Source and Processing

The data was collected via web scraping from retail chain websites,
based on the Decision on the publication of price lists and display of additional pricing as a direct price control measure in retail, Official Gazette 75/2025, dated May 2, 2025.

