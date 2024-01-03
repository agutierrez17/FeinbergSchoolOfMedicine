# Program written by Andrew J. Gutierrez - andrew.gutierrez@northwestern.edu

from datetime import date, datetime
import datetime as d
import oracledb
import getpass
import os
import win32com.client as win32
import locale
import shutil

# Set locale currency to USD
locale.setlocale(locale.LC_ALL, '')

# Get today's date
today = date.today() #  # date(2023,10,23)
print()
print("Today is " + str(today))
print()

# Get current day of week
if datetime.weekday(today) == 0:
    LastReportDate = today - d.timedelta(days = 5)
    print("Last Pipeline Report was run on: " + str(LastReportDate))
elif datetime.weekday(today) == 2:
    LastReportDate = today - d.timedelta(days = 2) #2
    print("Last Pipeline Report was run on: " + str(LastReportDate))

# Close any currently-open Excel files
print()
os.system("taskkill /f /im excel.exe")

# Connect to ADEARPT database
print("Establishing database connection...")
print()
connect = oracledb.connect(user="xxxxx", password="xxxxx", host="xxxxx", port=1521, service_name="xxxxx")

# Open Cursor
cursor = connect.cursor()

# Run FSM Commitments Report Total Query
print("Running FSM YTD Commitments total...")
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
SUM(G.NEW_GIFTS_AND_CMIT_AMT) 
FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G
INNER JOIN CURRENT_FY ON G.YEAR_OF_GIVING = CURRENT_FY.CFY
WHERE
G.REPORTING_AREA_SID = '21' ---- FEINBERG
AND
G.APPEAL_SID NOT IN (17710,17711) ----- EXCLUDE AFFIL, HOSPF, BLANK APPEALS

""")
row = cursor.fetchone()
commits = row[0]
print("FSM YTD Commitments total for %s: %s" % (str(today),locale.currency(int(round(commits)), grouping=True)[:-3]))
print()


# Run FSM Cash Report Total Query
print("Running FSM YTD Cash total...")
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
SUM(
CASE 
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('GC') THEN G.OUTRIGHT_GIFT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('YC') THEN G.PLEDGE_PAYMENT_AMOUNT
  WHEN TG.TRANSACTION_SUB_GROUP_CODE IN ('MC') THEN G.MATCHING_GIFT_AMOUNT
  ELSE 0 END
) 
FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G
INNER JOIN CURRENT_FY ON G.YEAR_OF_GIVING = CURRENT_FY.CFY
INNER JOIN DM_ARD.DIM_TRANSACTION_GROUP@catrackstobi TG ON G.TRANSACTION_GROUP_SID = TG.TRANSACTION_GROUP_SID AND TG.TRANSACTION_SUB_GROUP_CODE IN ('GC','YC','MC')
LEFT OUTER JOIN DM_ARD.DIM_ENTITY@catrackstobi E ON G.ENTITY_ID_NUMBER = E.ID_NUMBER AND E.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_TYPE@catrackstobi T ON G.TRANSACTION_TYPE_SID = T.TRANSACTION_TYPE_SID
LEFT OUTER JOIN DM_ARD.DIM_APPEAL@catrackstobi A ON G.APPEAL_SID = A.APPEAL_SID
LEFT OUTER JOIN DM_ARD.DIM_ALLOCATION@catrackstobi AL ON G.ALLOCATION_SID = AL.ALLOCATION_SID
LEFT OUTER JOIN DM_ARD.DIM_REPORTING_AREA@catrackstobi RA ON G.REPORTING_AREA_SID = RA.REPORTING_AREA_SID
WHERE
G.REPORTING_AREA_SID = '21' ---- FEINBERG
AND
G.APPEAL_SID NOT IN (17710,17711) ----- EXCLUDE AFFIL, HOSPF, BLANK APPEALS
""")
row = cursor.fetchone()
cash = row[0]
print("FSM YTD Cash total for %s: %s" % (str(today),locale.currency(int(round(cash)), grouping=True)[:-3]))
print()

# Close cursor
cursor.close()

# Open up Year-End Pipeline Report Excel file to input Cash and Commitment totals
print("Opening up Year-End Pipeline Excel file in background...")
print()
try:
    excel = win32.gencache.EnsureDispatch('Excel.Application')
except AttributeError as e:
    print(str(e))
    print("Caught an error with win32com...now deleting gen_py directory...")
    print()
    shutil.rmtree("xxxxxxx\\gen_py\\3.12\\00020813-0000-0000-C000-000000000046x0x1x9")
    excel = win32.gencache.EnsureDispatch('Excel.Application')
excel.Visible = False
wb = excel.Workbooks.Open("xxxxxxxxx\\Pipeline Report\\FY24 Year-end Pipeline - %s.xlsx" % (str(today)))
ws = wb.ActiveSheet

# Input FSM YTD Commitments total into cell D8
print("Inputting FSM YTD Commitments total...")
print()
ws.Cells(8, 4).Value = commits

# Input FSM YTD Cash total into cell D14
print("Inputting FSM YTD Cash total...")
print()
ws.Cells(14, 4).Value = cash

# Save Year-end Pipeline report
wb.Save()
print("Saved Year-end Pipeline report at xxxxxxxxx\\Pipeline Report\\FY24 Year-end Pipeline - %s.xlsx" % (str(today)))
print()

# Save Year-end Pipeline report as PDF
ws.ExportAsFixedFormat(0,"xxxxxxxxx\\Pipeline Report\\FY24 Year-end Pipeline - %s.pdf" % (str(today)))
print("Exporting Year-end Pipeline report to PDF...")
print()

#Close excel file
wb.Close(False)
wb = None
excel.Quit()

# Open up Long-term Pipeline Report Excel file
print("Opening up Long-Term Pipeline Excel file in background...")
print()
try:
    excel = win32.gencache.EnsureDispatch('Excel.Application')
except AttributeError as e:
    print(str(e))
    print("Caught an error with win32com...now deleting gen_py directory...")
    print()
    shutil.rmtree("xxxxxxx\\gen_py\\3.12\\00020813-0000-0000-C000-000000000046x0x1x9")
    excel = win32.gencache.EnsureDispatch('Excel.Application')
excel.Visible = False
wb = excel.Workbooks.Open("xxxxxxx\\Pipeline Report\\FY24 Long-term Pipeline %s.xlsx" % (str(today)))
ws = wb.ActiveSheet

# Save Long-term Pipeline report as PDF
ws.ExportAsFixedFormat(0,"xxxxxxxxx\\Pipeline Report\\FY24 Long-term Pipeline %s.pdf" % (str(today)))
print("Exporting Long-term Pipeline report to PDF...")
print()

#Close excel file
wb.Close(False)
wb = None
excel.Quit()

