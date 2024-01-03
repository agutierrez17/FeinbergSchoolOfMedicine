# Program written by Andrew J. Gutierrez - andrew.gutierrez@northwestern.edu

from datetime import date, datetime
import datetime as d
import random
import smtplib
import pandas as pd
import oracledb
import getpass
import tinys3
import sys
import os
import email
import email.mime.application
import mimetypes
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import win32com.client as win32
import locale
import shutil
#from email.MIMEImage import MIMEImage

# need these to send attachments
from email.mime.base import MIMEBase
from email import encoders

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

# Open up Year-End Pipeline Report Excel file to scrape totals for email
print()
print("Opening up Year-End Pipeline Excel file in background...")
print()
excel = win32.gencache.EnsureDispatch('Excel.Application')
excel.Visible = False
wb = excel.Workbooks.Open("xxxxxx\\Pipeline Report\\FY24 Year-end Pipeline - %s.xlsx" % (str(today)))
ws = wb.ActiveSheet

# Scrape cell D8 for Feinberg YTD Commitments
FSMCommits = locale.currency(int(round(ws.Cells(8, 4).Value)), grouping=True)[:-3]
print("FSM YTD Commitments: " + str(FSMCommits))

# Scrape last cell in Column B for Projected NM Year End Total
lastrow = ws.UsedRange.Rows.Count
ProjectedNMTotal = locale.currency(int(round(ws.Cells(lastrow, 2).Value)), grouping=True)[:-3]
print("Projected NM Year End Total: " + str(ProjectedNMTotal))
print()
excel.Quit()

# Connect to ADEARPT database
print("Establishing database connection...")
print()
connect = oracledb.connect(user="xxxxx", password="xxxx", host="xxxxx", port=1521, service_name="xxxxx")

# Open Cursor
cursor = connect.cursor()

# Run FSM New Major Gifts Query
print("Running FSM New Major Gifts report...")
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
G.ENTITY_ID_NUMBER,
TO_DATE(G.DATE_OF_RECORD_KEY,'YYYYMMDD') AS "Date(mmddyyyy)",
E.PREF_MAIL_NAME AS "Preferred Mail Name",
G.NEW_GIFTS_AND_CMIT_AMT AS "New Gifts and Commitments",
CASE WHEN G.TRANSACTION_GROUP_SID = 10 AND G.TRANSACTION_TYPE_SID = 0 THEN TG.TRANSACTION_SUB_GROUP_DESC WHEN G.PRIMARY_PLEDGE_SID > 0 AND G.TRANSACTION_TYPE_SID = 0 THEN PP.PLEDGE_TYPE_DESC ELSE T.TRANSACTION_TYPE_DESC END AS "Type of Transaction",
CASE WHEN DAR.LAST_NAME IS NOT NULL THEN P.PROPOSAL_TITLE ELSE AL.LONG_NAME END AS "Gift Reason",
CASE WHEN DAR.LAST_NAME IS NOT NULL THEN CONCAT(CONCAT(' (', + DAR.LAST_NAME), ')') ELSE ' ' END AS "Proposal Manager"

FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G
INNER JOIN CURRENT_FY ON G.YEAR_OF_GIVING = CURRENT_FY.CFY
LEFT OUTER JOIN DM_ARD.DIM_ENTITY@catrackstobi E ON G.ENTITY_ID_NUMBER = E.ID_NUMBER AND E.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_TYPE@catrackstobi T ON G.TRANSACTION_TYPE_SID = T.TRANSACTION_TYPE_SID
LEFT OUTER JOIN DM_ARD.DIM_APPEAL@catrackstobi A ON G.APPEAL_SID = A.APPEAL_SID
LEFT OUTER JOIN DM_ARD.DIM_ALLOCATION@catrackstobi AL ON G.ALLOCATION_SID = AL.ALLOCATION_SID
LEFT OUTER JOIN DM_ARD.DIM_REPORTING_AREA@catrackstobi RA ON G.REPORTING_AREA_SID = RA.REPORTING_AREA_SID
LEFT OUTER JOIN DM_ARD.DIM_PRIMARY_PLEDGE@catrackstobi PP ON G.PRIMARY_PLEDGE_SID = PP.PRIMARY_PLEDGE_SID 
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_GROUP@catrackstobi TG ON G.TRANSACTION_GROUP_SID = TG.TRANSACTION_GROUP_SID
LEFT OUTER JOIN DM_ARD.DIM_PROPOSAL@catrackstobi P ON G.PROPOSAL_ID = P.PROPOSAL_ID AND P.CURRENT_INDICATOR = 'Y' AND P.DELETED_FLAG = 'N'
LEFT OUTER JOIN RPT_RVA7647.FSM_DAR_STAFF DAR ON P.PROPOSAL_MANAGER_ID_NUMBER = DAR.ID_NUMBER

WHERE
G.REPORTING_AREA_SID = '21' ---- FEINBERG
AND
G.APPEAL_SID NOT IN (17710,17711) ----- EXCLUDE AFFIL, HOSPF, BLANK APPEALS
AND
G.NEW_GIFTS_AND_CMIT_AMT >= 100000
AND
G.DATE_OF_RECORD_KEY >= '%s'

ORDER BY
G.NEW_GIFTS_AND_CMIT_AMT DESC
""" % (str(LastReportDate).replace('-','')))
rows = cursor.fetchall()
MajorBookingsString = ""
for row in rows:
    ID = row[0]
    GiftDate = row[1]
    Name = row[2]
    Amount = row[3]
    GiftType = row[4]
    GiftReason = row[5]
    GiftManager = row[6]
    print(locale.currency(int(round(Amount)), grouping=True)[:-3] + " " + GiftType + " from " + Name + " - " + GiftReason + GiftManager)
    MajorBookingsString = MajorBookingsString + '<li class="x_x_ContentPasted0 x_ContentPasted0" style="list-style:disc">' + locale.currency(int(round(Amount)), grouping=True)[:-3] + " " + GiftType + " from " + Name + " - " + GiftReason + GiftManager + "<BR><BR>"

# Close cursor
cursor.close()

# Set Major Bookings text (empty vs. non-empty)
if MajorBookingsString == "":
    MajorBookingsText = "There were no major bookings over the last few days."
else:
    MajorBookingsText = "Here are the major bookings from the last few days:"

# Sender's email address
me = "andrew.gutierrez@northwestern.edu"

# Recipient's email address
toaddr = "andrew.gutierrez@northwestern.edu"

# Create message container - the correct MIME type is multipart/alternative
msg = MIMEMultipart()

# Add Subject Line Here
msg['Subject'] = "Pipeline and Long-Term Pipeline Reports - %s" % (today)
print()
print("Email subject: " + msg['Subject'])
print()

msg['From'] = 'Andrew James Gutierrez <andrew.gutierrez@northwestern.edu>'
msg['To'] = toaddr
print("Sent to: " + toaddr)
print()

# Enter the body of the message here
text = """
test
"""

html = """\
<html>
<head></head>
<body style='font-size:12.0pt;font-family:"Aptos",sans-serif;color:black'>
Good morning Alan,
<BR>
<BR>
Today's Pipeline and Long-term Pipeline Reports are attached. %s
<BR>
<BR>
%s
<BR>
<BR>
FSM YTD (FY24): %s
<BR>
<BR>
Projected NM Year End Total (FY24): %s
<BR>
<BR>
Thanks,
<BR>
<BR>
<span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'><b>Andrew J. Gutierrez</b></span>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'>Associate Director, Operations</span>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'>Northwestern University</span>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'>Feinberg School of Medicine</span>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'>Development and Alumni Relations</span>
<BR>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'>420 East Superior Street, 9<sup>th</sup> Floor</span>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'>Chicago, Illinois 60611</span>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'>312.503.0655 office</span>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'>312.503.6743 fax</span>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'><a href="mailto:andrew.gutierrez@northwestern.edu">andrew.gutierrez@northwestern.edu</a></span>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'><a href="https://www.feinberg.northwestern.edu/">feinberg.northwestern.edu</a></span>
<BR><span style = 'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#333333'><b>To make an online gift, please visit <a href="https://secure.ard.northwestern.edu/s/1479/282-giving/form-bc.aspx?sid=1479&gid=282&pgid=25569&cid=42757&appealcode=FSMOG&utm_campaign=OC21&utm_content=FSMOG&utm_medium=referral&utm_source=fsm">giving.northwestern.edu/feinberg</a>.</b></span>
</body>
</html>
""" % (MajorBookingsText, MajorBookingsString, FSMCommits, ProjectedNMTotal)

# Record the MIME types of both parts - text/plain and text/html
part1 = MIMEText (text, 'plain')
part2 = MIMEText (html, 'html')

# Attach parts into message container
# According to RFC 2046, the last part of a multipart message, in this case the HTML message, is best and preferred
# msg.attach(part1)
msg.attach(part2)

# UNCOMMENT WHEN ATTACHING ITEMS #
# msg.attach(att)

# SECTION FOR ATTACHMENTS #
filename1 = "xxxxxx\\Pipeline Report\\FY24 Year-end Pipeline - %s.pdf" % (str(today))
filename2 = "xxxxxxx\\Pipeline Report\\FY24 Long-term Pipeline %s.pdf" % (str(today))
attachments = [filename1, filename2]

### Open PDF File in Binary Mode
for file in attachments:
    with open(file, "rb") as attachment:
        # Add file as application/octet-strem
        # Email client can usually download this automatically as attachment
        part = MIMEBase("application", "octet-strem")
        part.set_payload(attachment.read())

        # Encode file in ASCII characters to send by email
        encoders.encode_base64(part)

        # Add header as key/value pair to attachment part
        part.add_header(
        "Content-Disposition",
        "attachment; filename=%s" % (str(file).replace("xxxxxx\\Pipeline Report\\","")),
        )

        # Add attachment to message and convert message to string
        msg.attach(part)
        text = msg.as_string()

        print("Attached file: " + str(file).replace("xxxxxx\\Pipeline Report\\",""))

# Enter username and password for SMTP Server connection
print()
username = input("Enter username: ")
pw = input("Enter password: ")

# CONNECT TO SMTP SERVER
try:
    s = smtplib.SMTP_SSL('xxxxx',587)
    s.login(username, pw)
    print()
    print("Connected to SMTP server")
    print()
except:
    print("Error: unable to connect to SMTP server")

# SEND EMAIL MESSAGE
try:
    s.sendmail(me, toaddr, msg.as_string())
    s.quit()
    print("Successfully sent email")
    print()
except Exception as E:
    print("Error: unable to send email")
    print(str(E))
    s.quit()



