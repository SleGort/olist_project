"""
Runs sanity checks before EDA.
"""

from sqlalchemy import create_engine, inspect

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
    engine = create_engine(...)

    # 2. Try to read into polars and pandas try / except blocks?
    # TODO

    existing = set(inspect(engine).get_table_names())
    missing = EXPECTED_TABLES - existing

    # 3. Close connection
    engine.dispose()
    
    # 4. If all is good then print "Ready for EDA!" 
    if missing:
        print(f"Missing {len(missing)} table(s): {missing}")
        return 0
    else:
        print("Ready for EDA!")   
    
    return 1

if __name__ == "__main__":
    main()
