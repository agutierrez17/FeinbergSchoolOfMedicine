# Program written by Andrew J. Gutierrez - andrew.gutierrez@northwestern.edu

from datetime import date, datetime
import datetime as d
import os
import pandas as pd
import oracledb
import win32com.client as win32
import xlwings as xw
from time import sleep

def rgbToInt(rgb):
    colorInt = rgb[0] + (rgb[1] * 256) + (rgb[2] * 256 * 256)
    return colorInt

# Get today's date
today = date.today()
print()
print("Today is " + str(today))
print()

# Close any currently-open Excel files
os.system("taskkill /f /im excel.exe")

# Connect to ADEARPT database
print("Establishing database connection...")
print()
connect = oracledb.connect(user="rpt_rva7647", password="oct17_2023", host="evadeardb", port=1521, service_name="ADEARPT")

# Open Cursor
cursor = connect.cursor()

# Pull list of Gift Officer IDs from FSM Hierarchy table
print("Pulling the current list of Gift Officers...")
print()
cursor.execute("""
SELECT DISTINCT
"ID Number",
"Gift Officer",
E.LAST_NAME AS "Last Name",
CASE
  WHEN EXTRACT(MONTH FROM SYSDATE) IN ('9','10','11') THEN 'Q1'
  WHEN EXTRACT(MONTH FROM SYSDATE) IN ('12','1','2') THEN 'Q2'
  WHEN EXTRACT(MONTH FROM SYSDATE) IN ('3','4','5') THEN 'Q3'
  WHEN EXTRACT(MONTH FROM SYSDATE) IN ('6','7','8') THEN 'Q4'
  ELSE '' END AS "Quarter",
E.PREF_MAIL_NAME AS "Preferred Mail Name"
FROM FSM_HIERARCHY F
INNER JOIN ENTITY E ON F."ID Number" = E.ID_NUMBER
WHERE
"Gift Officer" IN (
'Christopherson, Andrew',
'Kreller, Mary',
'Sund, Jordan',
'Dillon, Terri',
'Langert, Nicole',
'Lough, Ashley',
'Fragoules, Eric',
'Melin-Rogovin, Michelle',
'Kuhn, Lawrence',
'Maurer,Vic',
'Monaghan, Meghan',
'Mauro, MaryPat',
'Burke, Jenn',
'McCreery, David',
'Praznowski, Kathleen',
'Scaparotti, Tiffany'
)
ORDER BY
"Gift Officer"
""")
rows = cursor.fetchall

# Loop through rows 
for row in rows():

    # Print Gift Officer info
    print("Now creating the %s Metrics Report for %s (%s)" % (str(row[3]),str(row[4]),str(row[0])))
    print()
    sleep(2)

    # Pull Commitment information for each gift officer
    print("Pulling Commitments information for " + str(row[1]) + '...')
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
SUBSTR(CONCAT('0000000000',G.PROPOSAL_ID),-10) AS "Proposal ID",
P.PROPOSAL_MANAGER_NAME AS "Proposal Manager",
G.YEAR_OF_GIVING AS "Fiscal Year",
TO_DATE(G.DATE_OF_RECORD_KEY,'YYYYMMDD') AS "Date(mmddyyyy)", 
G.NEW_GIFTS_AND_CMIT_AMT AS "New Gifts and Commitments",
AL.ALLOCATION_CODE AS "Allocation Code",
AL.LONG_NAME AS "Allocation Short Name",
A.APPEAL_CODE AS "Appeal Code",
PR.PROSPECT_MANAGER_NAME AS "Prospect Manager"
FROM DM_ARD.FACT_GIVING_TRANS@catrackstobi G
INNER JOIN CURRENT_FY ON G.YEAR_OF_GIVING = CURRENT_FY.CFY
LEFT OUTER JOIN DM_ARD.DIM_ENTITY@catrackstobi E ON G.ENTITY_ID_NUMBER = E.ID_NUMBER AND E.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_TYPE@catrackstobi T ON G.TRANSACTION_TYPE_SID = T.TRANSACTION_TYPE_SID
LEFT OUTER JOIN DM_ARD.DIM_APPEAL@catrackstobi A ON G.APPEAL_SID = A.APPEAL_SID
LEFT OUTER JOIN DM_ARD.DIM_ALLOCATION@catrackstobi AL ON G.ALLOCATION_SID = AL.ALLOCATION_SID
LEFT OUTER JOIN DM_ARD.DIM_REPORTING_AREA@catrackstobi RA ON G.REPORTING_AREA_SID = RA.REPORTING_AREA_SID
LEFT OUTER JOIN DM_ARD.DIM_PRIMARY_PLEDGE@catrackstobi PP ON G.PRIMARY_PLEDGE_SID = PP.PRIMARY_PLEDGE_SID 
LEFT OUTER JOIN DM_ARD.DIM_TRANSACTION_GROUP@catrackstobi TG ON G.TRANSACTION_GROUP_SID = TG.TRANSACTION_GROUP_SID
LEFT OUTER JOIN DM_ARD.DIM_PROPOSAL@catrackstobi P ON G.PROPOSAL_ID = P.PROPOSAL_ID AND P.CURRENT_INDICATOR = 'Y'
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT_ENTITY@catrackstobi PE ON E.ID_NUMBER = PE.ID_NUMBER AND PE.CURRENT_INDICATOR = 'Y' AND PE.PROSPECT_ACTIVE_IND = 'Y' AND PE.DELETED_FLAG = 'N'
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT@catrackstobi PR ON PE.PROSPECT_ID = PR.PROSPECT_ID AND PR.CURRENT_INDICATOR = 'Y'
WHERE
G.REPORTING_AREA_SID = '21' ---- FEINBERG
AND
G.APPEAL_SID NOT IN (17710,17711) ----- EXCLUDE AFFIL, HOSPF, BLANK APPEALS
AND
P.PROPOSAL_MANAGER_ID_NUMBER = '%s'
AND
G.ENTIRE_AMOUNT > 50000
AND
G.NEW_GIFTS_AND_CMIT_AMT > 0


ORDER BY
G.NEW_GIFTS_AND_CMIT_AMT DESC
""" % (str(row[0])))
    commits = cursor.fetchall()

    # Create DataFrame with Commitment information
    print("Creating DataFrame from Commitments report...")
    print()
    columns=["ID Number","Preferred Mail Name","Transaction ID","Type of Transaction","Proposal ID","Proposal Manager","Fiscal Year","Date(mmddyyyy)","New Gifts and Commitments","Allocation Code","Allocation Short Name","Appeal Code","Prospect Manager"]
    df = pd.DataFrame(commits,columns=columns)

    # Pull Cash information for each gift officer
    print("Pulling Cash information for " + str(row[1]) + '...')
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
T.TRANSACTION_TYPE_DESC AS "Type of Transaction",
PP.PROPOSAL_ID AS "Proposal ID",
P.PROPOSAL_MANAGER_NAME AS "Proposal Manager",
G.YEAR_OF_GIVING AS "Fiscal Year",
TO_DATE(G.DATE_OF_RECORD_KEY,'YYYYMMDD') AS "Date(mmddyyyy)", 
G.PLEDGE_PAYMENT_AMOUNT AS "Cash",
AL.ALLOCATION_CODE AS "Allocation Code",
AL.LONG_NAME AS "Allocation Short Name",
A.APPEAL_CODE AS "Appeal Code",
PR.PROSPECT_MANAGER_NAME AS "Prospect Manager"

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
LEFT OUTER JOIN DM_ARD.DIM_PROPOSAL@catrackstobi P ON PP.PROPOSAL_ID = P.PROPOSAL_ID AND P.CURRENT_INDICATOR = 'Y' AND PP.PROPOSAL_ID NOT IN (' ')
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT_ENTITY@catrackstobi PE ON E.ID_NUMBER = PE.ID_NUMBER AND PE.CURRENT_INDICATOR = 'Y' AND PE.PROSPECT_ACTIVE_IND = 'Y' AND PE.DELETED_FLAG = 'N'
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT@catrackstobi PR ON PE.PROSPECT_ID = PR.PROSPECT_ID AND PR.CURRENT_INDICATOR = 'Y'
WHERE
G.REPORTING_AREA_SID = '21' ---- FEINBERG
AND
G.APPEAL_SID NOT IN (17710,17711) ----- EXCLUDE AFFIL, HOSPF, BLANK APPEALS
AND
P.PROPOSAL_MANAGER_ID_NUMBER = '%s'
AND
G.PLEDGE_PAYMENT_AMOUNT >= 10000

ORDER BY
"Cash" DESC
""" % (str(row[0])))
    cash = cursor.fetchall()

    # Create DataFrame with Cash information
    print("Creating DataFrame from Cash report...")
    print()
    columns=["ID Number","Preferred Mail Name","Transaction ID","Type of Transaction","Proposal ID","Proposal Manager","Fiscal Year","Date(mmddyyyy)","Cash","Allocation Code","Allocation Short Name","Appeal Code","Prospect Manager"]
    df2 = pd.DataFrame(cash,columns=columns)

# Pull Proposal information for each gift officer
    print("Pulling Proposal information for " + str(row[1]) + '...')
    cursor.execute("""
WITH CURRENT_FY AS
(SELECT CASE WHEN EXTRACT(MONTH FROM SYSDATE) >= 9
THEN EXTRACT(YEAR FROM SYSDATE)+1
ELSE EXTRACT(YEAR FROM SYSDATE)
END CFY
FROM DUAL
)

SELECT DISTINCT
PE.ID_NUMBER AS "ID Number",
SUBSTR(CONCAT('0000000000',P.PROPOSAL_ID),-10) AS "Proposal ID",
PR.PROSPECT_NAME AS "Prospect Name",
P.PROPOSAL_MANAGER_NAME AS "Proposal Manager",
P.PROPOSAL_ASSIST_NAMES_ALL AS "All Proposal Assists",

CASE 
WHEN (P.ASK_AMT = 0) Then ('$0') 
WHEN (P.ASK_AMT >0 ) and (P.ASK_AMT < 10000) Then ('<$10K') 
WHEN ((P.ASK_AMT >= 10000) and (P.ASK_AMT < 25000)) Then ('$10K-$24K') 
WHEN ((P.ASK_AMT >= 25000) and (P.ASK_AMT < 50000)) Then ('$25K-$49K') 
WHEN ((P.ASK_AMT >= 50000) and (P.ASK_AMT < 100000)) Then ('$50K-$99K') 
WHEN ((P.ASK_AMT >= 100000) and (P.ASK_AMT < 250000)) Then ('$100K-$249K') 
WHEN((P.ASK_AMT >= 250000) and (P.ASK_AMT < 500000)) Then ('$250K-$499K') 
WHEN ((P.ASK_AMT >= 500000) and (P.ASK_AMT < 1000000)) Then ('$500K-$999K') 
WHEN ((P.ASK_AMT >= 1000000) and (P.ASK_AMT < 2000000)) Then ('$1M-$1.9M') 
WHEN ((P.ASK_AMT >= 2000000) and (P.ASK_AMT < 5000000)) Then ('$2M-$4.9M') 
WHEN ((P.ASK_AMT >= 5000000) and (P.ASK_AMT < 10000000)) Then ('$5M-$9.9M') 
WHEN ((P.ASK_AMT >= 10000000) and (P.ASK_AMT < 25000000)) Then ('$10M-$24.9M')
WHEN ((P.ASK_AMT >= 25000000) and (P.ASK_AMT < 50000000)) Then ('$25M-$49.9M')
WHEN ((P.ASK_AMT >= 50000000) and (P.ASK_AMT < 100000000)) Then ('$50M-$99.9M') 
WHEN (P.ASK_AMT >= 100000000) Then ('$100M+') 
ELSE (' ') END AS "Ask Amt Band",
P.PROPOSAL_TYPE_DESC AS "Proposal Type",
PR.STAGE_DESC AS "Stage",
P.PROPOSAL_STATUS_DESC AS "Current Status",
P.ACTIVE_IND AS "Proposal Active Ind",
TO_DATE(CASE WHEN P.INITIAL_CONTRIBUTION_DATE_KEY = 0 THEN 18000101 ELSE P.INITIAL_CONTRIBUTION_DATE_KEY END,'YYYYMMDD') AS "Ask Date(mmddyyyy)",
TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD') AS "Close Date(mmddyyyy)",
SUBSTR(P.SUBMIT_TYPE_DESC,1,4) AS "Probability",
P.ASK_AMT AS "Ask Amount",
P.ORIGINAL_ASK_AMT AS "Planned Ask Amount",
P.ANTICIPATED_AMT AS "Anticipated Commitment",
P.INITIAL_CONTRIBUTION_AMT AS "Anticipated FY Cash",
P.FUNDING_TYPE_DESC AS "Payment Schedule",
P.GRANTED_AMT AS "Granted Amount",
P.DESCRIPTION AS "Proposal Description"

FROM DM_ARD.DIM_PROPOSAL@catrackstobi P
INNER JOIN CURRENT_FY ON CASE WHEN EXTRACT(MONTH FROM TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD')) >= 9 THEN EXTRACT(YEAR FROM TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD'))+1 ELSE EXTRACT(YEAR FROM TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD')) END = CURRENT_FY.CFY
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT@catrackstobi PR ON P.PROSPECT_ID = PR.PROSPECT_ID AND PR.CURRENT_INDICATOR = 'Y' AND PR.DELETED_FLAG = 'N'
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT_ENTITY@catrackstobi PE ON PR.PROSPECT_ID = PE.PROSPECT_ID AND PE.CURRENT_INDICATOR = 'Y' AND PE.PROSPECT_ACTIVE_IND = 'Y' AND PE.DELETED_FLAG = 'N' AND PE.PRIMARY_IND = 'Y'

WHERE
P.CURRENT_INDICATOR = 'Y'
AND
P.DELETED_FLAG = 'N'
AND
P.PROPOSAL_MANAGER_ID_NUMBER = '%s'

ORDER BY
P.ASK_AMT DESC
""" % (str(row[0])))
    proposals = cursor.fetchall()

    # Create DataFrame with Proposal information
    print("Creating DataFrame from Cash report...")
    print()
    columns=["ID Number","Proposal ID","Prospect Name","Proposal Manager","All Proposal Assists","Ask Amt Band","Proposal Type","Stage","Current Status","Proposal Active Ind","Ask Date(mmddyyyy)","Close Date(mmddyyyy)","Probability","Ask Amount","Planned Ask Amount","Anticipated Commitment","Anticipated FY Cash","Payment Schedule","Granted Amount","Proposal Description"]
    df3 = pd.DataFrame(proposals,columns=columns)

    # Pull Proposal Assist information for each gift officer
    print("Pulling Proposal Assist information for " + str(row[1]) + '...')
    cursor.execute("""
WITH CURRENT_FY AS
(SELECT CASE WHEN EXTRACT(MONTH FROM SYSDATE) >= 9
THEN EXTRACT(YEAR FROM SYSDATE)+1
ELSE EXTRACT(YEAR FROM SYSDATE)
END CFY
FROM DUAL
)

SELECT DISTINCT
PE.ID_NUMBER AS "ID Number",
SUBSTR(CONCAT('0000000000',P.PROPOSAL_ID),-10) AS "Proposal ID",
PR.PROSPECT_NAME AS "Prospect Name",
P.PROPOSAL_MANAGER_NAME AS "Proposal Manager",
P.PROPOSAL_ASSIST_NAMES_ALL AS "All Proposal Assists",

CASE 
WHEN (P.ASK_AMT = 0) Then ('$0') 
WHEN (P.ASK_AMT >0 ) and (P.ASK_AMT < 10000) Then ('<$10K') 
WHEN ((P.ASK_AMT >= 10000) and (P.ASK_AMT < 25000)) Then ('$10K-$24K') 
WHEN ((P.ASK_AMT >= 25000) and (P.ASK_AMT < 50000)) Then ('$25K-$49K') 
WHEN ((P.ASK_AMT >= 50000) and (P.ASK_AMT < 100000)) Then ('$50K-$99K') 
WHEN ((P.ASK_AMT >= 100000) and (P.ASK_AMT < 250000)) Then ('$100K-$249K') 
WHEN((P.ASK_AMT >= 250000) and (P.ASK_AMT < 500000)) Then ('$250K-$499K') 
WHEN ((P.ASK_AMT >= 500000) and (P.ASK_AMT < 1000000)) Then ('$500K-$999K') 
WHEN ((P.ASK_AMT >= 1000000) and (P.ASK_AMT < 2000000)) Then ('$1M-$1.9M') 
WHEN ((P.ASK_AMT >= 2000000) and (P.ASK_AMT < 5000000)) Then ('$2M-$4.9M') 
WHEN ((P.ASK_AMT >= 5000000) and (P.ASK_AMT < 10000000)) Then ('$5M-$9.9M') 
WHEN ((P.ASK_AMT >= 10000000) and (P.ASK_AMT < 25000000)) Then ('$10M-$24.9M')
WHEN ((P.ASK_AMT >= 25000000) and (P.ASK_AMT < 50000000)) Then ('$25M-$49.9M')
WHEN ((P.ASK_AMT >= 50000000) and (P.ASK_AMT < 100000000)) Then ('$50M-$99.9M') 
WHEN (P.ASK_AMT >= 100000000) Then ('$100M+') 
ELSE (' ') END AS "Ask Amt Band",
P.PROPOSAL_TYPE_DESC AS "Proposal Type",
PR.STAGE_DESC AS "Stage",
P.PROPOSAL_STATUS_DESC AS "Current Status",
P.ACTIVE_IND AS "Proposal Active Ind",
TO_DATE(CASE WHEN P.INITIAL_CONTRIBUTION_DATE_KEY = 0 THEN 18000101 ELSE P.INITIAL_CONTRIBUTION_DATE_KEY END,'YYYYMMDD') AS "Ask Date(mmddyyyy)",
TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD') AS "Close Date(mmddyyyy)",
SUBSTR(P.SUBMIT_TYPE_DESC,1,4) AS "Probability",
P.ASK_AMT AS "Ask Amount",
P.ORIGINAL_ASK_AMT AS "Planned Ask Amount",
P.ANTICIPATED_AMT AS "Anticipated Commitment",
P.INITIAL_CONTRIBUTION_AMT AS "Anticipated FY Cash",
P.FUNDING_TYPE_DESC AS "Payment Schedule",
P.GRANTED_AMT AS "Granted Amount",
P.DESCRIPTION AS "Proposal Description"

FROM DM_ARD.DIM_PROPOSAL@catrackstobi P
INNER JOIN CURRENT_FY ON CASE WHEN EXTRACT(MONTH FROM TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD')) >= 9 THEN EXTRACT(YEAR FROM TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD'))+1 ELSE EXTRACT(YEAR FROM TO_DATE(CASE WHEN P.STOP_DATE_KEY = 0 THEN 18000101 ELSE P.STOP_DATE_KEY END,'YYYYMMDD')) END = CURRENT_FY.CFY
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT@catrackstobi PR ON P.PROSPECT_ID = PR.PROSPECT_ID AND PR.CURRENT_INDICATOR = 'Y' AND PR.DELETED_FLAG = 'N'
LEFT OUTER JOIN DM_ARD.DIM_PROSPECT_ENTITY@catrackstobi PE ON PR.PROSPECT_ID = PE.PROSPECT_ID AND PE.CURRENT_INDICATOR = 'Y' AND PE.PROSPECT_ACTIVE_IND = 'Y' AND PE.DELETED_FLAG = 'N' AND PE.PRIMARY_IND = 'Y'

WHERE
P.CURRENT_INDICATOR = 'Y'
AND
P.DELETED_FLAG = 'N'
AND
P.PROPOSAL_ASSIST_NAMES_ALL LIKE '%%%s%%'
AND
P.STOP_DATE_KEY <> '0'

ORDER BY
P.ASK_AMT DESC
""" % (str(row[4])))
    proposals_a = cursor.fetchall()

    # Create DataFrame with Proposal information
    print("Creating DataFrame from Cash report...")
    print()
    columns=["ID Number","Proposal ID","Prospect Name","Proposal Manager","All Proposal Assists","Ask Amt Band","Proposal Type","Stage","Current Status","Proposal Active Ind","Ask Date(mmddyyyy)","Close Date(mmddyyyy)","Probability","Ask Amount","Planned Ask Amount","Anticipated Commitment","Anticipated FY Cash","Payment Schedule","Granted Amount","Proposal Description"]
    df4 = pd.DataFrame(proposals_a,columns=columns)

    # Pull Contact Report information for each gift officer
    print("Pulling Contact Report information for " + str(row[1]) + '...')
    cursor.execute("""
WITH CURRENT_FY AS
(SELECT CASE WHEN EXTRACT(MONTH FROM SYSDATE) >= 9
THEN EXTRACT(YEAR FROM SYSDATE)+1
ELSE EXTRACT(YEAR FROM SYSDATE)
END CFY
FROM DUAL
)

SELECT DISTINCT
C.ID_NUMBER AS "CATracks ID",
E2.PREF_MAIL_NAME AS "Contacted Name",
SUBSTR(CONCAT('0000000000',C.REPORT_ID),-10) AS "Report ID",
TMS_CTYPE.short_desc AS "Contact Type",
TMS_CPURP.short_desc AS "Contact Purpose",
C.CONTACT_DATE AS "Contact Date",
C.DESCRIPTION AS "Description",
CASE WHEN (SELECT COUNT(DISTINCT ID_NUMBER) FROM ADVANCE.CONTACT_RPT_CREDIT CRC WHERE CRC.REPORT_ID = C.REPORT_ID) > 1 THEN '2 credit entities' ELSE E.PREF_MAIL_NAME END AS "Credit Name"

FROM CONTACT_REPORT C
INNER JOIN CURRENT_FY ON CASE WHEN EXTRACT(MONTH FROM C.CONTACT_DATE) >= 9 THEN EXTRACT(YEAR FROM C.CONTACT_DATE)+1 ELSE EXTRACT(YEAR FROM C.CONTACT_DATE) END = CURRENT_FY.CFY
INNER JOIN FSM_DAR_STAFF ON C.AUTHOR_ID_NUMBER = FSM_DAR_STAFF.ID_NUMBER
INNER JOIN ENTITY E ON FSM_DAR_STAFF.ID_NUMBER = E.ID_NUMBER
INNER JOIN ENTITY E2 ON C.ID_NUMBER = E2.ID_NUMBER
INNER JOIN tms_contact_rpt_purpose tms_cpurp On tms_cpurp.contact_purpose_code = c.contact_purpose_code
INNER JOIN tms_contact_rpt_type tms_ctype On tms_ctype.contact_type = c.contact_type

WHERE
C.AUTHOR_ID_NUMBER = '%s'

ORDER BY
C.CONTACT_DATE DESC
""" % (str(row[0])))
    contacts = cursor.fetchall()

    # Create DataFrame with Contact Report information
    print("Creating DataFrame from Contact Reports...")
    print()
    columns=["CATracks ID","Contacted Name","Report ID","Contact Type","Contact Purpose","Contact Date","Description","Credit Name"]
    df5 = pd.DataFrame(contacts,columns=columns)

    # Pull Notes information for each gift officer
    print("Pulling Notes information for " + str(row[1]) + '...')
    cursor.execute("""
WITH CURRENT_FY AS
(SELECT CASE WHEN EXTRACT(MONTH FROM SYSDATE) >= 9
THEN EXTRACT(YEAR FROM SYSDATE)+1
ELSE EXTRACT(YEAR FROM SYSDATE)
END CFY
FROM DUAL
)

SELECT DISTINCT
N.ID_NUMBER AS "ID Number",
E2.PREF_MAIL_NAME AS "Name",
N.NOTE_DATE AS "Date",
e.report_name As "Author",
N.DESCRIPTION AS "Description"
FROM NOTES N
INNER JOIN CURRENT_FY ON CASE WHEN EXTRACT(MONTH FROM N.NOTE_DATE) >= 9 THEN EXTRACT(YEAR FROM N.NOTE_DATE)+1 ELSE EXTRACT(YEAR FROM N.NOTE_DATE) END = CURRENT_FY.CFY
INNER JOIN FSM_DAR_STAFF ON N.AUTHOR_ID_NUMBER = FSM_DAR_STAFF.ID_NUMBER
INNER JOIN ENTITY E ON N.AUTHOR_ID_NUMBER = E.ID_NUMBER
INNER JOIN ENTITY E2 ON N.ID_NUMBER = E2.ID_NUMBER
Inner Join tms_note_type tms_ntype On tms_ntype.note_type = n.note_type

WHERE
N.AUTHOR_ID_NUMBER = '%s'
""" % (str(row[0])))
    notes = cursor.fetchall()

    # Create DataFrame with Notes information
    print("Creating DataFrame from Notes...")
    print()
    columns=["ID Number","Name","Date","Author","Description"]
    df6 = pd.DataFrame(notes,columns=columns)

    # Write Commitments, Proposals, and Contact Reports DataFrames to Gift Officer Metrics Excel file
    print("Writing Commitments, Proposals, and Contact Reports to the Metrics file...")
    writer = pd.ExcelWriter("Q:\\Data and Reporting\\Reports\\Metrics\\%s_%s Metrics_%s.xlsx" % (row[2], row[3],str(today)))
    df.to_excel(writer,sheet_name='Cash and Commitments')
    df3.to_excel(writer,sheet_name='Proposals and Proposal Assists')
    df5.to_excel(writer,sheet_name='Contact Reports and Notes')
    writer.close()

    # Write Cash DataFrame to Cash and Commitments tab using xlwings
    print("Writing Cash to the Cash and Commitments tab...")
    app = xw.App(visible=False)
    wb = xw.Book("Q:\\Data and Reporting\\Reports\\Metrics\\%s_%s Metrics_%s.xlsx" % (row[2], row[3],str(today)))  
    ws = wb.sheets['Cash and Commitments']
    lastrow1 = ws.range('A' + str(ws.cells.last_cell.row)).end('up').row + 3 # get the last row in the spreadsheet
    ws.range('B' + str(lastrow1)).options(index=False).value = df2 # write the DataFrame

    # Write Proposal Assists to the Proposals tab using xlwings
    print("Writing Proposal Assists to the Proposals tab...")
    ws = wb.sheets['Proposals and Proposal Assists']
    lastrow2 = ws.range('A' + str(ws.cells.last_cell.row)).end('up').row + 3 # get the last row in the spreadsheet
    ws.range('B' + str(lastrow2)).options(index=False).value = df4 # write the DataFrame

    # Write Notes to the Contact Reports tab using xlwings
    print("Writing Notes to the Contact Reports tab...")
    print()
    ws = wb.sheets['Contact Reports and Notes']
    lastrow3 = ws.range('A' + str(ws.cells.last_cell.row)).end('up').row + 3 # get the last row in the spreadsheet
    ws.range('B' + str(lastrow3)).options(index=False).value = df6 # write the DataFrame

    #Close workbook
    wb.save()
    wb.close()
    app.quit()

    # Open Gift Officer Metrics file using win32com
    print("Opening up the Metrics file in background...")
    try:
        excel = win32.gencache.EnsureDispatch('Excel.Application')
    except AttributeError as e:
        print(str(e))
        print("Caught an error with win32com...now deleting gen_py directory...")
        print()
        shutil.rmtree("C:\\Users\\rva7647\\AppData\\Local\\Temp\\gen_py\\3.12\\00020813-0000-0000-C000-000000000046x0x1x9")
        excel = win32.gencache.EnsureDispatch('Excel.Application')
    excel.Visible = False
    wb = excel.Workbooks.Open("Q:\\Data and Reporting\\Reports\\Metrics\\%s_%s Metrics_%s.xlsx" % (row[2], row[3],str(today)))

    ###### Edit the Commitments tab ########
    print("Editing the Cash and Commitments tab...")
    ws = wb.Sheets['Cash and Commitments']

    # Remove first column
    ws.Cells(1,1).EntireColumn.Delete()

    # Insert new row
    ws.Cells(1,1).EntireRow.Insert()
    ws.Cells(1,1).Value = "New Gifts and Commitments"
    ws.Cells(1,1).Font.Bold = True
    ws.Range("A%s:M%s" % (lastrow1 + 1, lastrow1 + 1)).Font.Bold = True

    # Align cells
    ws.Range("A2:M2").HorizontalAlignment = 1
    ws.Range("A%s:M%s" % (lastrow1 + 1, lastrow1 + 1)).HorizontalAlignment = 1

    # Set header fill color to gray
    ws.Range("A2:M2").Interior.Color = rgbToInt((217,217,217))
    ws.Range("A%s:M%s" % (lastrow1 + 1, lastrow1 + 1)).Interior.Color = rgbToInt((217,217,217))

    # Format currency and date columns
    ws.Columns("H").NumberFormat = 'mmm dd, yyyy'
    ws.Columns("I").NumberFormat = '$#,##0.00'

    # Add in Cash section
    ws.Cells(lastrow1,1).Value = "Cash"
    ws.Cells(lastrow1,1).Font.Bold = True

    # Autofit all columns
    ws.Columns.AutoFit()

    # Add borders
    lastrow = ws.UsedRange.Rows.Count
    ws.Range("A3:M%s" % (lastrow1 -2)).Borders(2).Weight = 2
    ws.Range("A3:M%s" % (lastrow1 -2)).Borders(4).Weight = 2
    ws.Range("A%s:M%s" % (lastrow1 + 1, lastrow)).Borders(2).Weight = 2
    ws.Range("A%s:M%s" % (lastrow1 + 1, lastrow)).Borders(3).Weight = 2
    ws.Range("A%s:M%s" % (lastrow1 + 1, lastrow)).Borders(4).Weight = 2
    
    ###### Edit the Proposals tab ########
    print("Editing the Proposals and Proposal Assists tab...")
    ws = wb.Sheets['Proposals and Proposal Assists']

    # Delete the first column
    ws.Cells(1,1).EntireColumn.Delete()

    # Insert new row
    ws.Cells(1,1).EntireRow.Insert()
    ws.Cells(1,1).Value = "Proposals"
    ws.Cells(1,1).Font.Bold = True
    ws.Range("A%s:T%s" % (lastrow2 + 1, lastrow2 + 1)).Font.Bold = True

    # Align cells
    ws.Range("A2:T2").HorizontalAlignment = 1
    ws.Range("A%s:T%s" % (lastrow2 + 1, lastrow2 + 1)).HorizontalAlignment = 1

    # Set header fill color to gray
    ws.Range("A2:T2").Interior.Color = rgbToInt((217,217,217))
    ws.Range("A%s:T%s" % (lastrow2 + 1, lastrow2 + 1)).Interior.Color = rgbToInt((217,217,217))

    # Format currency and date columns
    ws.Columns("K").NumberFormat = 'mmm dd, yyyy'
    ws.Columns("L").NumberFormat = 'mmm dd, yyyy'
    ws.Columns("N").NumberFormat = '$#,##0.00'
    ws.Columns("O").NumberFormat = '$#,##0.00'
    ws.Columns("P").NumberFormat = '$#,##0.00'
    ws.Columns("Q").NumberFormat = '$#,##0.00'
    ws.Columns("S").NumberFormat = '$#,##0.00'

    # Add in Proposal Assists section
    ws.Cells(lastrow2,1).Value = "Proposal Assists"
    ws.Cells(lastrow2,1).Font.Bold = True

    # Autofit all columns
    ws.Columns.AutoFit()

    # Loop through Close Date, Payment Schedule, and Description columns to highlight blank values and/or dates past due
    lastrow = ws.UsedRange.Rows.Count
    i = 3
    for i in range(i,lastrow2): # Close Date, Proposals section
        if str(ws.Cells(i,12).Value) < str(today) and ws.Cells(i,10).Value == 'Y':
            ws.Cells(i,12).Interior.Color = 65535.0
    for i in range(i,lastrow2): # Payment Schedule, Proposals section
        if ws.Cells(i,18).Value in (""," "):
            ws.Cells(i,18).Interior.Color = 65535.0
    for i in range(i,lastrow2): # Description, Proposals section
        if ws.Cells(i,20).Value in (""," "):
            ws.Cells(i,20).Interior.Color = 65535.0

    i = lastrow2 + 3
    for i in range(i,lastrow + 1): # Close Date, Proposals section
        if str(ws.Cells(i,12).Value) < str(today) and ws.Cells(i,10).Value == 'Y':
            ws.Cells(i,12).Interior.Color = 65535.0
    for i in range(i,lastrow + 1): # Payment Schedule, Proposal Assists section
        if ws.Cells(i,18).Value in (""," "):
            ws.Cells(i,18).Interior.Color = 65535.0
    for i in range(i,lastrow + 1): # Description, Proposal Assists section
        if ws.Cells(i,20).Value in (""," "):
            ws.Cells(i,20).Interior.Color = 65535.0

    # Add borders
    ws.Range("A3:T%s" % (lastrow2 -2)).Borders(2).Weight = 2
    ws.Range("A3:T%s" % (lastrow2 -2)).Borders(3).Weight = 2
    ws.Range("A3:T%s" % (lastrow2 -2)).Borders(4).Weight = 2
    ws.Range("A%s:T%s" % (lastrow2 + 1, lastrow)).Borders(2).Weight = 2
    ws.Range("A%s:T%s" % (lastrow2 + 1, lastrow)).Borders(3).Weight = 2
    ws.Range("A%s:T%s" % (lastrow2 + 1, lastrow)).Borders(4).Weight = 2


    ###### Edit the Contact Reports tab ########
    print("Editing the Contact Reports and Notes tab...")
    ws = wb.Sheets['Contact Reports and Notes']

    # Delete the first column
    ws.Cells(1,1).EntireColumn.Delete()

    # Insert new row
    ws.Cells(1,1).EntireRow.Insert()
    ws.Cells(1,1).Value = "Contact Reports"
    ws.Cells(1,1).Font.Bold = True
    ws.Range("A%s:E%s" % (lastrow3 + 1, lastrow3 + 1)).Font.Bold = True

    # Align cells
    ws.Range("A2:H2").HorizontalAlignment = 1
    ws.Range("A%s:E%s" % (lastrow3 + 1, lastrow3 + 1)).HorizontalAlignment = 1

    # Set header fill color to gray
    ws.Range("A2:H2").Interior.Color = rgbToInt((217,217,217))
    ws.Range("A%s:E%s" % (lastrow3 + 1, lastrow3 + 1)).Interior.Color = rgbToInt((217,217,217))

    # Format currency and date columns
    lastrow = ws.UsedRange.Rows.Count
    ws.Columns("F").NumberFormat = 'mm/dd/yyyy'
    ws.Range("C%s:C%s" % (lastrow3 + 1, lastrow)).NumberFormat = 'mm/dd/yyyy'

    # Add in Notes section
    ws.Cells(lastrow3,1).Value = "Notes"
    ws.Cells(lastrow3,1).Font.Bold = True

    # Autofit all columns
    ws.Columns.AutoFit()

    # Add borders
    ws.Range("A3:H%s" % (lastrow3 -2)).Borders(2).Weight = 2
    ws.Range("A3:H%s" % (lastrow3 -2)).Borders(3).Weight = 2
    ws.Range("A3:H%s" % (lastrow3 -2)).Borders(4).Weight = 2
    ws.Range("A%s:E%s" % (lastrow3 + 1, lastrow)).Borders(2).Weight = 2
    ws.Range("A%s:E%s" % (lastrow3 + 1, lastrow)).Borders(3).Weight = 2
    ws.Range("A%s:E%s" % (lastrow3 + 1, lastrow)).Borders(4).Weight = 2

    # Save and close Metrics file
    wb.Save()
    print()
    print("Saved new file Q:\\Data and Reporting\\Reports\\Metrics\\%s_%s Metrics_%s.xlsx" % (row[2], row[3],str(today)))
    print()

    # Close workboox
    wb.Close(False)
    wb = None
    excel.Quit()

    #print(garbage)
    sleep(5)

# Close Cursor
cursor.close()
