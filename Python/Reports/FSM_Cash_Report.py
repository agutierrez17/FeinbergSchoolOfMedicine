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
connect = oracledb.connect(user="xxxxx", password="xxxxxx", host="xxxxx", port=1521, service_name="xxxxxxx")

# Open Cursor
cursor = connect.cursor()

# Run FSM Cash Report Query
print("Running FSM YTD Cash report...")
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
TO_CHAR(TO_DATE(G.DATE_OF_RECORD_KEY,'YYYYMMDD'),'Mon DD, YYYY') AS "Date(mmddyyyy)", 
CASE 
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('GC') THEN G.OUTRIGHT_GIFT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('YC') THEN G.PLEDGE_PAYMENT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('MC') THEN G.MATCHING_GIFT_AMOUNT
  ELSE 0 END AS "Cash",
AL.ALLOCATION_CODE AS "Allocation Code",
AL.LONG_NAME AS "Allocation Long Name",
RA.REPORTING_AREA_FULL_DESC AS "Reporting Area Long Name",
A.APPEAL_CODE AS "Appeal Code"
FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G
INNER JOIN CURRENT_FY ON G.YEAR_OF_GIVING = CURRENT_FY.CFY
INNER JOIN DM_ARD.DIM_TRANSACTION_GROUP@catrackstobi TG ON G.TRANSACTION_GROUP_SID = TG.TRANSACTION_GROUP_SID AND TG.TRANSACTION_SUB_GROUP_CODE IN ('GC','YC','MC')
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
"Cash" DESC
""")
rows = cursor.fetchall()

# Turn result into DataFrame
columns=["ID Number","Preferred Mail Name","Transaction ID","Type of Transaction","Fiscal Year","Date(mmddyyyy)","Cash","Allocation Code","Allocation Long Name","Reporting Area Long Name","Appeal Code"]
df = pd.DataFrame(rows,columns=columns)
#df['Cash'] = df['Cash'].map(locale.currency)

# Set DataFrame font size and style
df = df.style.set_properties(**{
    'font-size': '10pt',
    'font-family': 'Tahoma'
})

# Write DataFrame to FSM Cash Excel file
print("Writing report to Excel file...")
print()
writer = pd.ExcelWriter("xxxxxx\\BI Campaign Cash and Commitments Reports\\FY24\\FSM Cash Report %s.xlsx" % (str(today)))
df.to_excel(writer,sheet_name='Sheet1')
writer.close()

# Open FSM Cash file
print("Opening up the FSM Cash file in background...")
print()
try:
    excel = win32.gencache.EnsureDispatch('Excel.Application')
except AttributeError as e:
    print(str(e))
    print("Caught an error with win32com...now deleting gen_py directory...")
    print()
    shutil.rmtree("xxxxxxxxxx\\gen_py\\3.12\\00020813-0000-0000-C000-000000000046x0x1x9")
    excel = win32.gencache.EnsureDispatch('Excel.Application')
excel.Visible = False
wb = excel.Workbooks.Open("xxxxxxxxx\\BI Campaign Cash and Commitments Reports\\FY24\\FSM Cash Report %s.xlsx" % (str(today)))
ws = wb.ActiveSheet

# Autofit all columns
ws.Columns.AutoFit()

# Remove first column
ws.Cells(1,1).EntireColumn.Delete()

# Format currency and date columns
ws.Columns("F").NumberFormat = 'mmm dd, yyyy'
ws.Columns("G").NumberFormat = '$#,##0.00'

# Save and close FSM Cash file
wb.Save()
wb.Close(False)
wb = None
excel.Quit()
print("Saved new file xxxxxxxx\\BI Campaign Cash and Commitments Reports\\FY24\\FSM Cash Report %s.xlsx" % (str(today)))
print()

# Close Cursor
cursor.close()

