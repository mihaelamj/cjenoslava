// start of prompt
Analyze python code for parsing particular store:

here’s the explanation:

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

Then look at the swift implementation,
Fix it and change the UnifiedProduct, so that we have StoreDownloader

// end of prompt

# Cijene API

Servis za preuzimanje javnih podataka o cijenama proizvoda u trgovačkim lancima u Republici Hrvatskoj.

Preuzimanje podataka o cijenama proizvoda u trgovačkim lancima u Republici Hrvatskoj
temeljeno je na Odluci o objavi cjenika i isticanju dodatne cijene kao mjeri izravne
kontrole cijena u trgovini na malo, NN 75/2025 od 2.5.2025.

Trenutno podržani trgovački lanci:

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

## Softverska implementacija

Softver je izgrađen na Pythonu a sastoji se od dva dijela:

* Crawler - preuzima podatke s web stranica trgovačkih lanaca (`crawler`)
* Web servis - API koji omogućava pristup podacima o cijenama proizvoda (`service`) - **U IZRADI**

## Instalacija

Za instalaciju crawlera potrebno je imati instaliran Python 3.13 ili noviji. Preporučamo
korištenje `uv` za setup projekta:

```bash
git clone https://github.com/senko/cijene-api.git
cd cijene-api
uv sync --dev
```

## Korištenje

### Crawler

Za pokretanje crawlera potrebno je pokrenuti sljedeću komandu:

```bash
uv run -m crawler.cli.crawl /path/to/output-folder/
```

Ili pomoću Pythona direktno (u adekvatnoj virtualnoj okolini):

```bash
python -m crawler.cli.crawl /path/to/output-folder/
```

Crawler prima opcije `-l` za listanje podržanih trgovačkih lanaca, `-d` za
odabir datuma (default: trenutni dan), `-c` za odabir lanaca (default: svi) te
`-h` za ispis pomoći.

### Pokretanje u Windows okolini

**Napomena:** Za Windows korisnike - postavite vrijednost `PYTHONUTF8` environment varijable na `1` ili pokrenite python s `-X utf8` flag-om kako bi izbjegli probleme s character encodingom. Više detalja [na poveznici](https://github.com/senko/cijene-api/issues/9#issuecomment-2911110424).

### Web servis

Prije pokretanja servisa, kreirajte datoteku `.env` sa konfiguracijskim varijablama.
Primjer datoteke sa zadanim (default) vrijednostima može se naći u `.env.example`.

Nakon što ste kreirali `.env` datoteku, pokrenite servis koristeći:

```bash
uv run -m service.main
```

Servis će biti dostupan na `http://localhost:8000` (ako niste mijenjali port), a na
`http://localhost:8000/docs` je dostupna Swagger dokumentacija API-ja.

## Licenca

Ovaj projekt je licenciran pod [AGPL-3 licencom](LICENSE).

Podaci prikupljeni putem ovog projekta su javni i dostupni svima, temeljem
Odluke o objavi cjenika i isticanju dodatne cijene kao mjeri izravne
kontrole cijena u trgovini na malo, NN 75/2025 od 2.5.2025.
