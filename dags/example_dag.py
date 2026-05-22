from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from bronze.data_ingestion import from_json_to_bronze


def hello_qversity():
    print("Hello from Qversity v2!")
    print("This is a placeholder DAG.")
    print("Replace this with your actual pipeline logic.")
    return "Pipeline started"


default_args = {
    "owner": "qversity",
    "depends_on_past": False,
    "start_date": datetime(2026, 1, 1),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

dag = DAG(
    "qversity_fintech_pipeline",
    default_args=default_args,
    description="Qversity v2 Fintech/Banking ELT Pipeline",
    schedule_interval=None,
    catchup=False,
    tags=["qversity", "fintech"],
)

# ---------------------------------------------------------------
# Task 1: Placeholder - Download JSON from S3 and load to Bronze
# ---------------------------------------------------------------
schema_creation_task = BashOperator(
    task_id= "create_schemas",
    bash_command='cd /opt/airflow/dbt && dbt run-operation bootstrap_schemas',
    dag=dag,
)
hello_task = PythonOperator(
    task_id="hello_qversity",
    python_callable=from_json_to_bronze,
    dag=dag,
)
load_bronze_table = BashOperator(
    task_id="load_bronze_table",
    bash_command='cd /opt/airflow/dbt && dbt run --profiles-dir /opt/airflow/dbt --models bronze',
    dag=dag,
)

# ---------------------------------------------------------------
# Task 2: Placeholder - PySpark tasks
# Replace with your actual PySpark scripts
# ---------------------------------------------------------------
spark_placeholder = BashOperator(
    task_id="spark_placeholder",
    # bash_command='spark-submit --packages org.postgresql:postgresql:42.7.3 /opt/airflow/spark/spark_job.py',
    # bash_command='spark-submit /opt/airflow/spark/spark_job.py',
    bash_command="""
spark-submit \
  --jars /opt/spark/jars/postgresql.jar \
  --driver-class-path /opt/spark/jars/postgresql.jar \
  /opt/airflow/spark/spark_job.py
""",
    dag=dag,
)

# ---------------------------------------------------------------
# Task 3: Placeholder - dbt run (Silver + Gold models)
# ---------------------------------------------------------------
dbt_placeholder = BashOperator(
    task_id="dbt_placeholder",
    bash_command='cd /opt/airflow/dbt && dbt build --profiles-dir /opt/airflow/dbt --select silver',
    dag=dag,
)

# ---------------------------------------------------------------
# Task 4: Placeholder - dbt test
# ---------------------------------------------------------------
dbt_gold_place_holder = BashOperator(
    task_id="dbt_gold_placeholder",
    bash_command='cd /opt/airflow/dbt && dbt build --profiles-dir /opt/airflow/dbt --select gold',
    dag=dag,
)

# Task dependencies: Bronze -> PySpark -> dbt run -> dbt test
schema_creation_task >> hello_task >> load_bronze_table >> spark_placeholder >> dbt_placeholder >> dbt_gold_place_holder


