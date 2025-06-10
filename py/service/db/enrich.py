#!/usr/bin/env python3
import asyncio
import argparse
import logging
from decimal import Decimal
from pathlib import Path
from csv import DictReader
from time import time
from typing import List, Dict

from service.config import settings
from service.db.models import Product

logger = logging.getLogger("enricher")

db = settings.get_db()


async def read_csv(file_path: Path) -> List[Dict[str, str]]:
    """
    Read a CSV file and return a list of dictionaries.

    Args:
        file_path: Path to the CSV file.

    Returns:
        List of dictionaries where each dictionary represents a row in the CSV.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            reader = DictReader(f)  # type: ignore
            return [row for row in reader]
    except Exception as e:
        logger.error(f"Error reading {file_path}: {e}")
        return []


def convert_unit_and_quantity(unit: str, quantity_str: str) -> tuple[str, Decimal]:
    """
    Convert unit and quantity according to business rules.

    Args:
        unit: Original unit from CSV.
        quantity_str: Original quantity string from CSV.

    Returns:
        Tuple of (converted_unit, converted_quantity).

    Raises:
        ValueError: If unit is not supported or quantity cannot be parsed.
    """
    try:
        quantity = Decimal(quantity_str)
    except (ValueError, TypeError):
        raise ValueError(f"Invalid quantity: {quantity_str}")

    unit = unit.strip().lower()

    if unit == "g":
        return "kg", quantity / Decimal("1000")
    elif unit == "ml":
        return "L", quantity / Decimal("1000")
    elif unit == "l":
        return "L", quantity
    elif unit == "par":
        return "kom", quantity
    elif unit in ["kg", "kom", "m"]:
        return unit, quantity
    else:
        raise ValueError(f"Unsupported unit: {unit}")


async def enrich_products(csv_path: Path) -> None:
    """
    Enrich product information from CSV file.

    Args:
        csv_path: Path to the CSV file containing product enrichment data.
    """

    if not csv_path.exists():
        raise ValueError(f"CSV file does not exist: {csv_path}")

    data = await read_csv(csv_path)
    if not data:
        raise ValueError(f"CSV file is empty or could not be read: {csv_path}")

    csv_columns = set(data[0].keys())
    if csv_columns != {"barcode", "brand", "name", "unit", "quantity"}:
        raise ValueError("CSV file headers do not match expected columns")

    logger.info(
        f"Starting product enrichment from {csv_path} with {len(data)} products"
    )
    t0 = time()

    # Get existing products by EAN
    existing_products = {
        product.ean: product
        for product in await db.get_products_by_ean(
            list(set(row["barcode"] for row in data))
        )
    }

    updated_count = 0
    for row in data:
        product = existing_products.get(row["barcode"])

        if not product:
            # This shouldn't happen but we can gracefully handle it
            await db.add_ean(row["barcode"])
            product = Product(
                ean=row["barcode"],
                brand="",
                name="",
                quantity=Decimal(0),
                unit="kom",
            )

        if product.brand or product.name:
            continue

        unit, qty = convert_unit_and_quantity(row["unit"], row["quantity"])
        updated_product = Product(
            ean=row["barcode"],
            brand=row["brand"],
            name=row["name"],
            quantity=qty,
            unit=unit,
        )

        was_updated = await db.update_product(updated_product)
        if was_updated:
            updated_count += 1

    t1 = time()
    dt = int(t1 - t0)
    logger.info(
        f"Enriched {updated_count} products from {csv_path.name} in {dt} seconds"
    )


async def enrich_stores(csv_path: Path) -> None:
    """
    Enrich store information from CSV file.

    Args:
        csv_path: Path to the CSV file containing store enrichment data.
    """
    logger.info("Store enrichment is not yet implemented")
    # TODO: Implement store enrichment in the future


async def main():
    """
    Data enrichment tool for the price service API.

    This script enriches existing database records with additional information
    from CSV files. Currently supports product enrichment with plans for
    store enrichment in the future.

    Database connection settings are loaded from the service configuration.
    """
    parser = argparse.ArgumentParser(
        description=main.__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "csv_file", type=Path, help="Path to the CSV file containing enrichment data"
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "-p", "--products", action="store_true", help="Enrich product information"
    )
    group.add_argument(
        "-s",
        "--stores",
        action="store_true",
        help="Enrich store information (not yet implemented)",
    )

    parser.add_argument(
        "-d", "--debug", action="store_true", help="Enable debug logging"
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.debug else logging.INFO,
        format="%(asctime)s:%(name)s:%(levelname)s:%(message)s",
    )

    await db.connect()
    await db.create_tables()

    try:
        if args.products:
            await enrich_products(args.csv_file)
        elif args.stores:
            await enrich_stores(args.csv_file)
    finally:
        await db.close()


if __name__ == "__main__":
    asyncio.run(main())
