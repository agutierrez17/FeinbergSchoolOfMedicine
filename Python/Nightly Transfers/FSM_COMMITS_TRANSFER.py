# Program written by Andrew J. Gutierrez - andrew.gutierrez@northwestern.edu

from datetime import date, datetime
import datetime as d
import oracledb

# Get today's date
today = date.today() #  # date(2023,10,23)
print()
print("Today is " + str(today))
print()

# Connect to ADEARPT database
print("Establishing database connection...")
print()
connect = oracledb.connect(user="xxxxxx", password="xxxxxx", host="xxxxxx", port=xxxxx, service_name="xxxxxxx")

# Open Cursor
cursor = connect.cursor()

# Run FSM Commitments Transfer procedure
print("Running FSM Commitments Transfer procedure...")
print()
cursor.execute("""
begin
  -- Call the procedure
  FSM_COMMITS_TRANSFER;
end;
""")

print("Procedure successfully run...")

# Close Cursor
cursor.close()

