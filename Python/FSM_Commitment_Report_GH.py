# Program written by Andrew J. Gutierrez - andrew.gutierrez@northwestern.edu

from datetime import date, datetime
import datetime as d
import os
import pandas as pd
import oracledb
import getpass
import win32com.client as win32
import shutil

# Get today's date
today = date.today() #  # date(2023,10,23)
print()
print("Today is " + str(today))
print()

# Close any currently-open Excel files
print()
os.system("taskkill /f /im excel.exe")

### Get user password
##print("Signing in to database...")
##userpwd = getpass.getpass("Enter ADEARPT password: ")

# Connect to ADEARPT database
print("Establishing database connection...")
print()
connect = oracledb.connect(user="xxxxx", password="xxxxx", host="xxxxx", port=1521, service_name="xxxxx")

# Open Cursor
cursor = connect.cursor()

# Run FSM Commitments Report Query
print("Running FSM YTD Commitments report...")
print()
cursor.execute("""
WITH CURRENT_FY AS
(SELECT CASE WHEN EXTRACT(MONTH FROM SYSDATE) >= 9
THEN EXTRACT(YEAR FROM SYSDATE)+1
ELSE EXTRACT(YEAR FROM SYSDATE)
END CFY
FROM DUAL
)

SELECT
E.ID_NUMBER AS "ID Number",
E.PREF_MAIL_NAME AS "Preferred Mail Name",
G.TRANS_ID_NUMBER AS "Transaction ID",
CASE WHEN G.TRANSACTION_GROUP_SID = 10 AND G.TRANSACTION_TYPE_SID = 0 THEN TG.TRANSACTION_SUB_GROUP_DESC WHEN G.PRIMARY_PLEDGE_SID > 0 AND G.TRANSACTION_TYPE_SID = 0 THEN PP.PLEDGE_TYPE_DESC ELSE T.TRANSACTION_TYPE_DESC END AS "Type of Transaction",
G.YEAR_OF_GIVING AS "Fiscal Year",
TO_DATE(G.DATE_OF_RECORD_KEY,'YYYYMMDD') AS "Date(mmddyyyy)", 
G.NEW_GIFTS_AND_CMIT_AMT AS "New Gifts and Commitments",
A.APPEAL_CODE AS "Appeal Code",
AL.ALLOCATION_CODE AS "Allocation Code",
AL.ALLOC_SHORT_NAME AS "Allocation Short Name",
RA.REPORTING_AREA_FULL_DESC AS "Reporting Area Long Name"
FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G
INNER JOIN CURRENT_FY ON G.YEAR_OF_GIVING = CURRENT_FY.CFY
LEFT OUTER JOIN DM_ARD.DIM_ENTITY@catrackstobi E ON G.ENTITY_ID_NUMBER = E.ID_NUMBER AND E.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_TYPE@catrackstobi T ON G.TRANSACTION_TYPE_SID = T.TRANSACTION_TYPE_SID
LEFT OUTER JOIN DM_ARD.DIM_APPEAL@catrackstobi A ON G.APPEAL_SID = A.APPEAL_SID
LEFT OUTER JOIN DM_ARD.DIM_ALLOCATION@catrackstobi AL ON G.ALLOCATION_SID = AL.ALLOCATION_SID
LEFT OUTER JOIN DM_ARD.DIM_REPORTING_AREA@catrackstobi RA ON G.REPORTING_AREA_SID = RA.REPORTING_AREA_SID
LEFT OUTER JOIN DM_ARD.DIM_PRIMARY_PLEDGE@catrackstobi PP ON G.PRIMARY_PLEDGE_SID = PP.PRIMARY_PLEDGE_SID 
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_GROUP@catrackstobi TG ON G.TRANSACTION_GROUP_SID = TG.TRANSACTION_GROUP_SID
WHERE
G.REPORTING_AREA_SID = '21' ---- FEINBERG
AND
G.APPEAL_SID NOT IN (17710,17711) ----- EXCLUDE AFFIL, HOSPF, BLANK APPEALS

ORDER BY
G.DATE_OF_RECORD_KEY DESC,
G.NEW_GIFTS_AND_CMIT_AMT DESC

""")
rows = cursor.fetchall()

# Turn result into DataFrame
columns=["ID Number","Preferred Mail Name","Transaction ID","Type of Transaction","Fiscal Year","Date(mmddyyyy)","New Gifts and Commitments","Appeal Code","Allocation Code","Allocation Short Name","Reporting Area Long Name"]
df = pd.DataFrame(rows,columns=columns)
#df['New Gifts and Commitments'] = df['New Gifts and Commitments'].map(locale.currency)

# Set DataFrame font size and style
df = df.style.set_properties(**{
    'font-size': '10pt',
    'font-family': 'Tahoma'
})

# Write DataFrame to FSM Commitments Excel file
print("Writing report to Excel file...")
print()
writer = pd.ExcelWriter("xxxxxxxxx\\BI Campaign Cash and Commitments Reports\\FY24\\FSM Commitment Report %s.xlsx" % (str(today)))
df.to_excel(writer,sheet_name='Sheet1')
writer.close()

# Open FSM Commitments file
print("Opening up the FSM Commitments Excel file in background...")
print()
try:
    excel = win32.gencache.EnsureDispatch('Excel.Application')
except AttributeError as e:
    print(str(e))
    print("Caught an error with win32com...now deleting gen_py directory...")
    print()
    shutil.rmtree("xxxxxxxxxxx\\gen_py\\3.12\\00020813-0000-0000-C000-000000000046x0x1x9")
    excel = win32.gencache.EnsureDispatch('Excel.Application')
    
excel.Visible = False
wb = excel.Workbooks.Open("xxxxxxxxxx\\BI Campaign Cash and Commitments Reports\\FY24\\FSM Commitment Report %s.xlsx" % (str(today)))
ws = wb.ActiveSheet

# Autofit all columns
ws.Columns.AutoFit()

# Remove first column
ws.Cells(1,1).EntireColumn.Delete()

# Format currency and date columns
ws.Columns("F").NumberFormat = 'mmm dd, yyyy'
ws.Columns("G").NumberFormat = '$#,##0.00'

# Save and close FSM Commitments file
wb.Save()
print("Saved new file xxxxxxx\\Pipeline Report\\FSM Commitment Report %s.xlsx" % (str(today)))
print()

# Close workboox
wb.Close(False)
wb = None
excel.Quit()

# Close Cursor
cursor.close()

