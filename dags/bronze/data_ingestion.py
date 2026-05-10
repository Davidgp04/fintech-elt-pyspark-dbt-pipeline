import json
import requests
from datetime import datetime
import psycopg2
from psycopg2.extras import execute_values
from dotenv import load_dotenv
import os

load_dotenv()


S3_URL = f"https://{os.getenv('S3_BUCKET')}.s3.amazonaws.com/{os.getenv('S3_KEY')}"

def ingest_data_from_s3():
    """ This function fetches the JSON data from the S3 URL and saves it locally. In a real implementation, you would also include logic to load this data into your Bronze layer (e.g., PostgreSQL). """
    response = requests.get(S3_URL)
    response.raise_for_status()
    return response.json()


def from_json_to_bronze():
    # This function would contain logic to read the JSON file and load it into your Bronze layer
    """ This Function reads the JSON file and loads it into the Bronze layer (PostgreSQL) """
    with psycopg2.connect(
        host=os.getenv("POSTGRES_HOST"),
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
        port=os.getenv("POSTGRES_PORT"),
        dbname=os.getenv("POSTGRES_DB"),
    ) as conn:
        with conn.cursor() as cursor:
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS public_bronze.raw_fintech_data (
                    id SERIAL PRIMARY KEY,
                    data JSONB,
                    load_timestamp TIMESTAMPTZ DEFAULT NOW()
                );
            """)
            data = ingest_data_from_s3()
            records = [(json.dumps(record),) for record in data]
            execute_values(
                cursor,
                """
                INSERT INTO public_bronze.raw_fintech_data (data) VALUES %s;
            """, records)
        conn.commit()
    print("Data loaded into Bronze layer successfully!")
if __name__ == "__main__":
    from_json_to_bronze()