#  How To

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

Data Source and Processing

The data was collected via web scraping from retail chain websites,
based on the Decision on the publication of price lists and display of additional pricing as a direct price control measure in retail, Official Gazette 75/2025, dated May 2, 2025.

