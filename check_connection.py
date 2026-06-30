"""
Runs sanity checks before EDA.
"""

import pandas as pd
import polars as pl
from sqlalchemy import inspect
from ingest import get_engine

EXPECTED_TABLES = {
    "olist_customers_dataset",
    "olist_geolocation_dataset",
    "olist_order_items_dataset",
    "olist_order_payments_dataset",
    "olist_order_reviews_dataset",
    "olist_orders_dataset",
    "olist_products_dataset",
    "olist_sellers_dataset",
    "product_category_name_translation",
}

def main():

    # 1. Connect to azure account
    engine = get_engine()

    # 2. Try to read into polars and pandas
    try:
        pd.read_sql("SELECT TOP 1 * FROM olist_orders_dataset", engine)
        pl.read_database("SELECT TOP 1 * FROM olist_orders_dataset", engine)
    except Exception as e:
        print(f"Failed to read data: {e}")
        engine.dispose()
        return

    existing = set(inspect(engine).get_table_names())
    missing = EXPECTED_TABLES - existing

    # 3. Close connection
    engine.dispose()
    
    # 4. If no missing tables then print "Ready for EDA!" 
    if missing:
        print(f"Missing {len(missing)} table(s): {missing}")
        return 0
    else:
        print("Ready for EDA!")   
    
    return 1

if __name__ == "__main__":
    main()
