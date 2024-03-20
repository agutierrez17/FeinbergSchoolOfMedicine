# Program written by Andrew J. Gutierrez - andrew.gutierrez@northwestern.edu

import os
import pandas as pd
import oracledb
import getpass
import json

# Read FSM FASIS Report Excel file into DataFrame
print("Reading FSM FASIS Report Excel file into DataFrame...")
print()
parse_dates = ['last service date']
df = pd.read_excel(("xxxxxxxxxxxxxx\\Faculty Report\\FY24\\Faculty Giving Totals\\FSM FASIS Report.xlsx"), converters={'netid':str,'NPI':str,'emplid':str,'profile_xid':str}, parse_dates=parse_dates) 
df2 = df.astype(object).where(pd.notnull(df), None)
records = df2.values.tolist()

# Connect to ADEARPT database
print("Establishing database connection...")
print()
connect = oracledb.connect(user="xxxxxx", password="xxxxxx", host="xxxxx", port=1521, service_name="xxxxxx")
cursor = connect.cursor()

# Truncate FSM_FASIS_LIST database table
print("Truncating FSM_FASIS_List table...")
print()
cursor.execute("""TRUNCATE TABLE FSM_FASIS_LIST""")

# Insert values from DataFrame into FSM_FASIS_LIST database table
print("Inserting values from DataFrame into database table...")
print()
cursor.executemany("""
INSERT INTO FSM_FASIS_LIST
("name", "email", "netid", "NPI", "last service date", "degree", "dept/div", "category", "sub category", "basis", "rank", "emplid", "gender", "profile_xid")
VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14)
""", records)
connect.commit()

# Get count of records inserted
cursor.execute("SELECT COUNT(*) FROM FSM_FASIS_LIST")
result = cursor.fetchone()
print("Number of faculty records inserted: " + str(result[0]))

# Close cursor
cursor.close()
