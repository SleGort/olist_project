"""
Fetches the dataset from Kaggle and uploads to Azure 
"""
import os
import kagglehub
import pandas as pd
from sqlalchemy import create_engine, inspect   
from dotenv import load_dotenv

load_dotenv()

def data_already_loaded(engine):
    inspector = inspect(engine)
    return "olist_orders_dataset" in inspector.get_table_names()

def main():
    # 1. Connect to azure account
    engine = create_engine(
        "mssql+pyodbc:///?odbc_connect="
        f"Driver={{ODBC Driver 18 for SQL Server}};"
        f"Server={os.environ['AZURE_SQL_SERVER']};"
        f"Database={os.environ['AZURE_SQL_DATABASE']};"
        f"Uid={os.environ['AZURE_USERNAME']};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
        "Authentication=ActiveDirectoryInteractive"
    )
    
    # 2. Check whether the dataset is loaded
    if data_already_loaded(engine):
        print("Dataset already loaded, exiting.")
        engine.dispose()
        return
    
    # 3. Fetch the dataset from kaggle
    path = kagglehub.dataset_download("olistbr/brazilian-ecommerce")

    # 4. Load the dataset into azure cloud
    for filename in os.listdir(path):
        if not filename.endswith(".csv"):
            continue
        table_name = filename.removesuffix(".csv")
        df = pd.read_csv(os.path.join(path, filename))
        df.to_sql(table_name, engine, if_exists="replace", index=False)
        print(f"Loaded {table_name} ({len(df)} rows)")
        
    # 5. Close connection
    engine.dispose()

if __name__ == "__main__":
    main()
