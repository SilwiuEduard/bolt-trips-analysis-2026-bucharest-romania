from azure.storage.blob import BlobServiceClient
import os
import pyarrow.parquet as pq
from dotenv import load_dotenv

load_dotenv()
connect_str = os.getenv('AZURE_STORAGE_CONNECTION_STRING')
if not connect_str:
    print('No connection string')
    exit(1)

blob_client = BlobServiceClient.from_connection_string(connect_str).get_blob_client(container='bronze', blob='orders_2026_W40.parquet')
with open('azure_W40.parquet', 'wb') as f:
    f.write(blob_client.download_blob().readall())

print('Schema for order_created_timestamp:', pq.read_schema('azure_W40.parquet').field('order_created_timestamp').type)
