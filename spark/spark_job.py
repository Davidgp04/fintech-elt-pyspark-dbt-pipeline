from pyspark.sql import SparkSession
import os
from dotenv import load_dotenv
from pyspark.sql.types import StructType, StructField, StringType, DoubleType
from pyspark.sql.functions import from_json, col
load_dotenv()

# Building Spark Session with PostgreSQL JDBC driver

jdbc_url = f"jdbc:postgresql://{os.getenv('POSTGRES_HOST')}:{os.getenv('POSTGRES_PORT')}/{os.getenv('POSTGRES_DB')}"

table_name = "bronze.bronze_raw_fintech"

# properties = {
#     "user": os.getenv('POSTGRES_USER'),
#     "password": os.getenv('POSTGRES_PASSWORD'),
#     "driver": "org.postgresql.Driver"
# }
# spark = SparkSession.builder \
#     .appName("PostgreSQLExample") \
#     .config(
#         "spark.jars.packages",
#         "org.postgresql:postgresql:42.7.3"
#     ) \
#     .config(
#         "spark.driver.extraClassPath",
#         "/Users/davidgrisales/.ivy2/jars/org.postgresql_postgresql-42.7.3.jar"
#     ) \
#     .getOrCreate()

properties = {
    "user": os.getenv('POSTGRES_USER'),
    "password": os.getenv('POSTGRES_PASSWORD'),
    "driver": "org.postgresql.Driver"
}

spark = (
    SparkSession.builder
    .appName("PostgreSQLExample")
    .master("local[*]")
    # .config(
    #     "spark.jars",
    #     "/opt/spark/jars/postgresql.jar"
    # )
    # .config(
    #     "spark.driver.extraClassPath",
    #     "/opt/spark/jars/postgresql.jar"
    # )
    # .config("spark.executor.extraClassPath", 
    #         "/opt/spark/jars/postgresql.jar")
    .getOrCreate()
)
df = spark.read.jdbc(
    url=jdbc_url,
    table=table_name,
    properties=properties
)

df.printSchema()
df.show(5)

# input("Session created and data loaded. Press Enter to continue with the deflattening process...")

# Deflattening the JSON data and writing to Silver layer

from pyspark.sql.types import StructType, StructField, StringType, DoubleType
from pyspark.sql.functions import from_json, col
schema = StructType([
    StructField("lat", DoubleType(), True),
    StructField("lon", DoubleType(), True),
    StructField("city", StringType(), True),
    StructField("email", StringType(), True),
    StructField("loans", StringType(), True), # json
    StructField("accounts", StringType(), True), # json
    StructField("transactions", StringType(), True), # json
    StructField("digital_engagement", StringType(), True), # json
    StructField("credit_info", StringType(), True), # json
    StructField("gender", StringType(), True),
    StructField("status", StringType(), True),
    StructField("address", StringType(), True),
    StructField("country", StringType(), True),
    StructField("last_name", StringType(), True),
    StructField("first_name", StringType(), True),
    StructField("kyc_status", StringType(), True),
    StructField("risk_score", DoubleType(), True),
    StructField("customer_id", StringType(), True),
    StructField("nationality", StringType(), True),
    StructField("phone_number", StringType(), True),
    StructField("date_of_birth", StringType(), True),
    StructField("customer_segment", StringType(), True),
    StructField("registration_date", StringType(), True),
    StructField("relationship_manager", StringType(), True)
])
# df_parsed = spark.read.json(df.rdd.map(lambda row: row.data), schema=schema)
df_parsed = df.withColumn("data_parsed", from_json(col("data"), schema)).select("data_parsed.*")
df_parsed.printSchema() 

# Removing duplicates based on customer_id
df_parsed = df_parsed.select("*").dropDuplicates(["customer_id"])

# debug=input(f"{df_parsed.count()} records after parsing and deduplication. Press Enter to continue with the deflattening process...")
# Exploding the loans, accounts, and transactions JSON arrays into separate DataFrames and writing to Silver layer

from pyspark.sql.functions import explode, from_json, col
from pyspark.sql.types import ArrayType, StructType, StructField, StringType, DoubleType
df_with_array_loan = df_parsed.withColumn("loans_array", from_json(col("loans"), ArrayType(StructType([
    StructField("loan_id", StringType(), True),
    StructField("type", StringType(), True),
    StructField("status", StringType(), True),
    StructField("currency", StringType(), True),
    StructField("end_date", StringType(), True),
    StructField("principal", DoubleType(), True),
    StructField("start_date", StringType(), True),
    StructField("term_months", DoubleType(), True),
    StructField("days_past_due", DoubleType(), True),
    StructField("interest_rate", DoubleType(), True),
    StructField("collateral_type", StringType(), True),
    StructField("monthly_payment", DoubleType(), True),
    StructField("outstanding_balance", DoubleType(), True)
]))))
df_exploded_loans = df_with_array_loan.withColumn("loan", explode(col("loans_array")))
df_final_loans= df_exploded_loans.select(
    "customer_id",
    "loan.*")

# Similar logic is applied to transactions and accounts, and then all DataFrames are written to the Silver layer in PostgreSQL using JDBC.
df_with_array_transaction = df_parsed.withColumn("transactions_array", from_json(col("transactions"), ArrayType(StructType([
    StructField("transaction_id", StringType(), True),
    StructField("date", StringType(), True),
    StructField("type", StringType(), True),
    StructField("amount", DoubleType(), True),
    StructField("status", StringType(), True),
    StructField("channel", StringType(), True),
    StructField("category", StringType(), True),
    StructField("currency", StringType(), True),
    StructField("merchant", StringType(), True),
    StructField("account_id", StringType(), True),
    StructField("description", StringType(), True),
]))))
df_exploded_transactions = df_with_array_transaction.withColumn("transaction", explode(col("transactions_array")))
df_final_transactions= df_exploded_transactions.select(
    "customer_id",
    "transaction.*")

# Similar logic is applied to accounts, and then all DataFrames are written to the Silver layer in PostgreSQL using JDBC.

df_with_array_account = df_parsed.withColumn("accounts_array", from_json(col("accounts"), ArrayType(StructType([
    StructField("account_id", StringType(), True),
    StructField("status", StringType(), True),
    StructField("balance", DoubleType(), True),
    StructField("currency", StringType(), True),
    StructField("branch_code", StringType(), True),
    StructField("opened_date", StringType(), True),
    StructField("account_type", StringType(), True),
    StructField("credit_limit", DoubleType(), True),
    StructField("interest_rate", DoubleType(), True),
]))))
df_exploded_accounts = df_with_array_account.withColumn("account", explode(col("accounts_array")))
df_final_accounts= df_exploded_accounts.select(
    "customer_id",
    "account.*")

# Removing the original JSON array columns from the main DataFrame before writing to Silver layer

columns_to_exclude = ["loans", "accounts", "transactions",]
# columns_to_select = [col for col in df_parsed.columns if col not in columns_to_exclude]
df_final_parsed = df_parsed.drop(*columns_to_exclude)

# Writing the deflattened DataFrames to Silver layer in PostgreSQL using JDBC

tables_to_write = [
    (df_final_parsed, "silver.stg_customers"),
    (df_final_loans, "silver.stg_loans"),
    (df_final_transactions, "silver.stg_transactions"),
    (df_final_accounts, "silver.stg_accounts"),
]
for df, table in tables_to_write:
    df.write.jdbc(
        url=jdbc_url,
        table=table,
        mode="overwrite",       # creates the table if it doesn't exist
        properties=properties
    )
