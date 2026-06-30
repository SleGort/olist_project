"""
Fetches the dataset from Kaggle and uploads to Azure
"""
import os
import struct
import urllib
import kagglehub
import pandas as pd
from sqlalchemy import create_engine, inspect, event
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential

load_dotenv()

def get_engine():
    # Standard ODBC connection string — no credentials here, auth is handled via Entra token below
    connection_string = (
        f"Driver={{ODBC Driver 18 for SQL Server}};"
        f"Server=tcp:{os.environ['AZURE_SQL_SERVER']}.database.windows.net,1433;"
        f"Database={os.environ['AZURE_SQL_DATABASE']};"
        "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    )
    # The connection string is embedded as a URL query parameter
    params = urllib.parse.quote(connection_string)
    engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

    # DefaultAzureCredential picks up the active `az login` session automatically
    credential = DefaultAzureCredential()

    @event.listens_for(engine, "do_connect")
    def provide_token(dialect, conn_rec, cargs, cparams):
        # Fires before every new connection. The ODBC driver expects the Entra token
        # as a binary struct (UTF-16-LE encoded, length-prefixed) at attribute key 1256.
        token = credential.get_token("https://database.windows.net/.default").token
        token_bytes = token.encode("UTF-16-LE")
        token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)
        cparams["attrs_before"] = {1256: token_struct}

    return engine

def data_already_loaded(engine):
    inspector = inspect(engine)
    return "olist_orders_dataset" in inspector.get_table_names()

def main():
    # 1. Connect to azure account
    engine = get_engine()
    
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
