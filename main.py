import psycopg2
from dotenv import load_dotenv
import os
import pandas as pd
import glob
import shutil
load_dotenv()
conn = psycopg2.connect(
host="localhost",
database="postgres",  
user= os.getenv("DATABASE_USER"),
password=os.getenv("DATABASE_PASSWORD"), 
port=5432
)
cursor = conn.cursor()
cursor.execute("SET search_path TO project")

dsn = "postgresql://{user}:{password}@localhost:5432/postgres".format(
    user=os.getenv("DATABASE_USER"),
    password=os.getenv("DATABASE_PASSWORD")
)

# Загрузка данных в stg
def txt2sql(path, table_name, sep=';', decimal=','):
    df = pd.read_csv(path, sep=sep, decimal=decimal)
    df.to_sql(name=table_name, con=dsn, schema="project", if_exists="replace", index=False)
    print("ОК")

def excel2sql(path, table_name):
    df = pd.read_excel(path)
    df.to_sql(name=table_name, con=dsn, schema="project", if_exists="replace", index=False)
    print("ОК")

# Создание stg,dwh,per_fraud таблиц
try:
    with open("sql/01.sql", "r", encoding="utf-8") as file:
        cursor.execute(file.read())
    conn.commit()
    print("Таблица ОК")
except Exception as e:
    conn.rollback()
    print(f"Ошибка: {e}")
    exit()

# Ищем файл в data
transaction_files = sorted(glob.glob("data/transactions_*.txt"))
dates = []
for f in transaction_files:
    date = os.path.basename(f).split("_")[1].replace(".txt", "")
    dates.append(date)

print("ОК")

# Цикл обработки дат
for date in dates:
    print(f"Дата: {date}")
    transactions_file = f"data/transactions_{date}.txt"
    terminals_file = f"data/terminals_{date}.xlsx"
    passport_file = f"data/passport_blacklist_{date}.xlsx"

# Проверить что файлы все есть
    if not (os.path.exists(transactions_file) and os.path.exists(terminals_file) and os.path.exists(passport_file)):
        print(f"Есть ошибка даты {date}.")
        continue

# Загрузка файлов в stg
    try:
        txt2sql(transactions_file, "stg_transactions", sep=';', decimal=',')
        excel2sql(terminals_file, "stg_terminals")
        excel2sql(passport_file, "stg_passport_blacklist")
    except Exception as e:
        print(f"Ошибка {date}: {e}")
        continue 

# Копия файла из БД
    try:
        with open("sql/stg1.sql", "r", encoding="utf-8") as file:
            cursor.execute(file.read())
        conn.commit()
        print("ОК")
    except Exception as e:
        conn.rollback()
        print(f" Ошибка при копировании: {e}")
        continue

# Загрузка файлов в dwh (SDC1)
    try:
        with open("sql/02.sql", "r", encoding="utf-8") as file:
            cursor.execute(file.read())
        conn.commit()
        print("SCD1 загружена")
    except Exception as e:
        conn.rollback()
        print(f"Ошибка : {e}")
        continue

# Загрузка файлов в dwh (SDC2)
    try:
        with open("sql/dwh2.sql", "r", encoding="utf-8") as file:
            cursor.execute(file.read())
        conn.commit()
        print("SCD2 загружена")
    except Exception as e:
        conn.rollback()
        print(f"Ошибка: {e}")
        continue

# Витрина отчетности   
    try:
        with open("sql/rep_fraud.sql", "r", encoding="utf-8") as file:
            cursor.execute(file.read())
        conn.commit()
        print("ОК")
    except Exception as e:
        conn.rollback()
        print(f"Ошибка: {e}")

# Архив
    try:
        for source_file in [transactions_file, terminals_file, passport_file]:
            filename = os.path.basename(source_file)
            backup_path = os.path.join("archive", filename + ".backup")
            shutil.move(source_file, backup_path)
            print(f"  {filename} в архиве/{filename}.backup")
    except Exception as e:
        print(f"Ошибка {date}: {e}")

# Итоговая
print("Обработали 3 дня")

print("Отчет (rep_fraud):")
try:
    cursor.execute("SELECT event_dt, fio, event_type FROM rep_fraud ORDER BY event_dt LIMIT 5;")
    for row in cursor.fetchall():
        print(row)
except Exception as e:
    print(f"Ошибка таблицы: {e}")

cursor.close()
conn.close()


