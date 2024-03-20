# Program written by Andrew J. Gutierrez - andrew.gutierrez@northwestern.edu

import oracledb
import getpass
import pandas as pd
from datetime import date, datetime
import datetime as d
import win32com.client as win32
import shutil

# Get today's date
today = date.today()
print()
print("Today is " + str(today))
print()
LastReportDate = today - d.timedelta(days = 7)
print("Running report of IMO/IHO gifts made since " + str(LastReportDate))
print()

### Get user password
##print("Signing in to database...")
##print()
##userpwd = getpass.getpass("Enter ADEARPT password: ")

# Connect to ADEARPT database
print("Establishing database connection...")
print()
connect = oracledb.connect(user="xxxxx", password="xxxxxx", host="xxxxx", port=1521, service_name="xxxxxx")

# Open Cursor
cursor = connect.cursor()
result = connect.cursor()

# Execute Procedure
print("Executing Tribute Card procedure...")
print()
cursor.callproc('rpt_btaylor.WT0L1220',[LastReportDate,result])
rows = result.fetchall()

# Turn result into DataFrame
columns=["ID_NUMBER","RECEIPT_NUM","XSEQUENCE","TYPE","PREF_MAIL_NAME","LAST_NAME","EXTENSION","FIRST_NAME","MIDDLE_NAME","CITY","STATE","AREA_CODE","PHONE","PREF_NAME_SORT","PERSON_OR_ORG","CLASS_YEAR","SCHOOL","ST1","ST2","ST3","ST4","ST5","ST6","ZIP","COUNTRY","RECORD_TYPE_DESC","RECORD_STATUS_DESC","RECORD_STATUS_CODE","HON_MEM","ALLOCATION","GIFT_YEAR_OF_GIVING","GIFT_DATE_OF_RECORD","GIFT_ASSOCIATED_AMOUNT","PLEDGE_PLEDGE_NUMBER","TRANSACTION_TYPE","PAYMENT_TYPE","PLEDGE_PAYMENT_IND","t_name","ANONYMOUS","ALLOC_SCHOOL","ALLOCATION_CODE","RECORD_STATUS_DISPLAY","GIFT_RECEIPT_NUMBER","BATCH_NUM","ALLOC_DIVISION","CHARITY_CODE","CHARITY_DESC","SOFT_CREDIT"]
df = pd.DataFrame(rows,columns=columns)

# Set DataFrame font size and style
df_style = df.style.set_properties(**{
    'font-size': '9pt',
    'font-family': 'Segoe UI'
})

# Write DataFrame to Tribute Cards Excel File
print("Writing report to Excel file...")
print()
writer = pd.ExcelWriter("xxxxxxxxxx\\Tribute Card Reports\\Tribute Card- Files\\FY23TribCards_%s.xlsx" % (str(today)))
df_style.to_excel(writer,sheet_name='Cursor')
writer.close()

# Open Tribute Cards file
print("Opening up the Tribute Cards file in background...")
print()
try:
    excel = win32.gencache.EnsureDispatch('Excel.Application')
except AttributeError as e:
    print(str(e))
    print("Caught an error with win32com...now deleting gen_py directory...")
    print()
    shutil.rmtree("xxxxxxxxxxxxxxxx\\gen_py\\3.12\\00020813-0000-0000-C000-000000000046x0x1x9")
    excel = win32.gencache.EnsureDispatch('Excel.Application')
excel.Visible = False
wb = excel.Workbooks.Open("xxxxxxxxxxxx\\Tribute Card Reports\\Tribute Card- Files\\FY23TribCards_%s.xlsx" % (str(today)))
ws = wb.ActiveSheet

# Autofit all columns
ws.Columns.AutoFit()

# Format currency and date columns
ws.Columns("AG").NumberFormat = 'mm/dd/yyyy'
ws.Columns("AH").NumberFormat = '#,##0.00'
ws.Columns("AW").NumberFormat = '#,##0.00'

# Save and close Tribute Cards file
wb.Save()
wb.Close(False)
wb = None
excel.Quit()
print("Saved new file xxxxxxxxxx\\Tribute Card Reports\\Tribute Card- Files\\FY23TribCards_%s.xlsx" % (str(today)))
print()

# Create new DataFrame from original
df2 = df[['ID_NUMBER','PREF_MAIL_NAME','ST1','ST2','HON_MEM','ALLOCATION','GIFT_DATE_OF_RECORD','ANONYMOUS','ALLOCATION_CODE']].copy()
df2.insert(df2.columns.get_loc("HON_MEM") + 1, 'IMO/IHO', ['' for i in range(df2.shape[0])])
df2.insert(df2.columns.get_loc("ALLOCATION_CODE") + 1, 'Allocation Long name', ['' for i in range(df2.shape[0])])

# Populate IMO/IHO Column
for i in range(df2.shape[0]):
    if 'Honor of' in df2['HON_MEM'][i]:
        df2['IMO/IHO'][i] = df2['HON_MEM'][i].split('Honor of ')[1]
        df2['HON_MEM'][i] = df2['HON_MEM'][i].split(' %s' % (df2['IMO/IHO'][i]))[0]
        #print(df2['IMO/IHO'][i])
        #print(df2['HON_MEM'][i])
    if 'Memory of' in df2['HON_MEM'][i]:
        df2['IMO/IHO'][i] = df2['HON_MEM'][i].split('Memory of ')[1]
        df2['HON_MEM'][i] = df2['HON_MEM'][i].split(' %s' % (df2['IMO/IHO'][i]))[0]
        #print(df2['IMO/IHO'][i])
        #print(df2['HON_MEM'][i])

# Get long allocation names
for i in range(df2.shape[0]):
    #print (df2['ALLOCATION_CODE'][i])
    cursor.execute("""SELECT LONG_NAME FROM ADVANCE.ALLOCATION T WHERE ALLOCATION_CODE = '%s'""" % (df2['ALLOCATION_CODE'][i]))
    row = cursor.fetchone()[0]
    #print(row)
    df2['Allocation Long name'][i] = row
    #print(df2['Allocation Long name'][i])

# Close cursor
cursor.close()

# Set DataFrame font size and style
df2_style = df2.style.set_properties(**{
    'font-size': '9pt',
    'font-family': 'Segoe UI'
})

# Create final DataFrame
df3 = df2[['GIFT_DATE_OF_RECORD','ID_NUMBER','PREF_MAIL_NAME','ST1','ST2','Allocation Long name','HON_MEM','IMO/IHO','ANONYMOUS']].copy()
df3.insert(df3.columns.get_loc("GIFT_DATE_OF_RECORD") + 1, '', ['' for i in range(df3.shape[0])])

# Set DataFrame font size and style
df3_style = df3.style.set_properties(**{
    'font-size': '9pt',
    'font-family': 'Segoe UI'
})

# Write DataFrame to Tribute Cards "macro" Excel File
print("Writing report to Excel file...")
print()
writer = pd.ExcelWriter("xxxxxxxxxxxx\\Tribute Card Reports\\Tribute Card- Files\\FY23TribCards_%smacros.xlsx" % (str(today)))
df2_style.to_excel(writer,sheet_name='Cursor')
df3_style.to_excel(writer,sheet_name='Sheet1')
writer.close()

# Open Tribute Cards "macro" file
print("Opening up the Tribute Cards macro file in background...")
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
wb = excel.Workbooks.Open("xxxxxxxxxx\\Tribute Card Reports\\Tribute Card- Files\\FY23TribCards_%smacros.xlsx" % (str(today)))
ws = wb.ActiveSheet

# Autofit all columns
ws.Columns.AutoFit()

# Format currency and date columns
ws.Columns("I").NumberFormat = 'mm/dd/yyyy'

# Switch to Sheet1 tab 
wb.Worksheets("Sheet1").Activate()
ws = wb.ActiveSheet
ws.Columns.AutoFit()
ws.Columns("B").NumberFormat = 'mm/dd/yyyy'

# Save and close Tribute Cards macros file
wb.Save()
wb.Close(False)
wb = None
excel.Quit()
print("Saved new file xxxxxxxxxxxxxx\\Tribute Card Reports\\Tribute Card- Files\\FY23TribCards_%smacros.xlsx" % (str(today)))
print()

