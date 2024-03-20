# Program written by Andrew J. Gutierrez - andrew.gutierrez@northwestern.edu

import http.client, urllib.parse
from datetime import datetime
import json
import pandas as pd
import oracledb
import csv
import win32com.client as win32
import shutil

row_list = []

# Bing API Key
headers = {'Ocp-Apim-Subscription-Key': 'xxxxxxxxxxxxxxxxxxxx'}

# Create, open, and truncate TXT file
filename = 'xxxxxx/WebSearch/Results.txt'
f = open(filename, "w+")
f.close()

# Connect to ADEARPT database
print("Establishing database connection...")
print()
connect = oracledb.connect(user="xxxxxx", password="xxxxxx", host="xxxxx", port=1521, service_name="xxxxx")

# Open Cursor
cursor = connect.cursor()

# Run Distinguished Alumni Candidate Query
print("Running Distinguished Alumni Candidate query...")
print()
cursor.execute("""
SELECT
'2019 Distinguished' AS "List",
'' AS "Org",
F."ID Number",
F."Preferred Mail Name",
--F."Prominent Person Notes ",
--F."Backup Link(s)",
F."Primary Employer Name",
F."Primary Employment Job Title",
ADDR.STREET1 AS "Pref Addr 1",
ADDR.City AS "Pref City",
ADDR.state_code AS "Pref State",
CASE WHEN addr.zipcode = ' ' THEN addr.foreign_cityzip ELSE addr.zipcode END AS "Pref Zip",
tms_country.short_desc AS "Pref Country",
--F."Reunion_Year",
RPT_RVA7647.FSMDEGREESLIST(F."ID Number") AS "Feinberg Degrees",
DS2.LIFETIME_GIFT_CREDIT_AMOUNT AS "FSM Lifetime Giving",
DS.LIFETIME_GIFT_CREDIT_AMOUNT AS "Total Lifetime Giving"

FROM xxxxxx."FSM_ALUMS_2019" F
INNER JOIN ENTITY E ON F."ID Number" = E.ID_NUMBER AND E.RECORD_STATUS_CODE NOT IN ('D')
LEFT OUTER JOIN address addr ON addr.id_number = e.id_number AND addr.addr_pref_ind = 'Y' --only preferred addresses
LEFT OUTER JOIN tms_country ON tms_country.country_code = addr.country_code
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi DS ON E.ID_NUMBER = DS.ENTITY_KEY AND DS.REPORTING_AREA = 'NA' AND DS.ANNUAL_FUND_FLAG = 'N' -- ALL NU LIFETIME GIVING
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi DS2 ON E.ID_NUMBER = DS2.ENTITY_KEY AND DS2.REPORTING_AREA = 'FS' AND DS2.ANNUAL_FUND_FLAG = 'N' -- FEINBERG LIFETIME GIVING

WHERE
F."Primary Employment Job Title" LIKE '%Professor%' 
OR
F."Primary Employment Job Title" LIKE '%Dean%'
OR
F."Primary Employment Job Title" LIKE '%Prof%' 


UNION


SELECT DISTINCT
'Society Members' AS "List",
"Org",
"Matched ID" AS "ID Number",
"CATracks Pref Mail Name" AS "Preferred Mail Name",
--NULL AS "Prominent Person Notes",
--NULL AS "Backup Link(s)",
--CASE WHEN "Institution 2" IS NOT NULL THEN "Institution 2" ELSE "Institution 1" END AS "Primary Employer Name",
A.COMPANY_NAME_1 AS "Primary Employer Name",
A.BUSINESS_TITLE AS "Primary Employment Job Title",
ADDR.STREET1 AS "Pref Addr 1",
ADDR.City AS "Pref City",
ADDR.state_code AS "Pref State",
CASE WHEN addr.zipcode = ' ' THEN addr.foreign_cityzip ELSE addr.zipcode END AS "Pref Zip",
tms_country.short_desc AS "Pref Country",
RPT_RVA7647.FSMDEGREESLIST(F."Matched ID") AS "Feinberg Degrees",
DS2.LIFETIME_GIFT_CREDIT_AMOUNT AS "FSM Lifetime Giving",
DS.LIFETIME_GIFT_CREDIT_AMOUNT AS "Total Lifetime Giving"

FROM xxxxxxx."FSM_ALUMNI_PROF_STUDIES" F
INNER JOIN ENTITY E ON F."Matched ID" = E.ID_NUMBER AND E.RECORD_STATUS_CODE NOT IN ('D')
LEFT OUTER JOIN ADDRESS A ON E.ID_NUMBER = A.ID_NUMBER AND A.ADDR_TYPE_CODE = 'B' AND A.ADDR_STATUS_CODE = 'A'
LEFT OUTER JOIN address addr ON addr.id_number = e.id_number AND addr.addr_pref_ind = 'Y' --only preferred addresses
LEFT OUTER JOIN tms_country ON tms_country.country_code = addr.country_code
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi DS ON E.ID_NUMBER = DS.ENTITY_KEY AND DS.REPORTING_AREA = 'NA' AND DS.ANNUAL_FUND_FLAG = 'N' -- ALL NU LIFETIME GIVING
LEFT OUTER JOIN DM_ARD.FACT_DONOR_SUMMARY@catrackstobi DS2 ON E.ID_NUMBER = DS2.ENTITY_KEY AND DS2.REPORTING_AREA = 'FS' AND DS2.ANNUAL_FUND_FLAG = 'N' -- FEINBERG LIFETIME GIVING

WHERE
("Feinberg Degrees" LIKE '%4;%' OR "Feinberg Degrees" LIKE '%9;%')
AND
"Deceased" IS NULL

ORDER BY
"ID Number"
""")
rows = cursor.fetchall()
for row in rows:
    List = row[0]
    Org = row[1]
    ID = row[2]
    Name = row[3]
    Employer = ''  if row[4] is None else row[4]
    Title = row[5]
    Addr = row[6]
    City = '' if row[7] is None else row[7]
    State = '' if row[8] is None else row[8]
    ZIP = row[9]
    Country = row[10]
    Degrees = row[11]
    FSMGive = row[12]
    NUGive = row[13]
    SearchParam = str(Name) + '+Northwestern+' + City + '+' + State + '+' + Employer
    print(SearchParam)    
    
    params = urllib.parse.urlencode({
        # Request parameters
        'q': '%s' % (SearchParam),
        'count': 5,
        'offset': '0',
        'mkt': 'en-us',
        'safeSearch': 'Moderate',

    })

    try:
        conn = http.client.HTTPSConnection('api.bing.microsoft.com')
        conn.request("GET", "/v7.0/search?%s" % params, "{body}", headers)
        response = conn.getresponse()
        data = json.load(response)
        #print(data)
        conn.close()
    except Exception as e:
        print("[Errno {0}]m{1}".format(e.errno, e.strerror))

    Url = 'No News'
    title = 'No News'
    content = 'No News'
    dates = 'No News'

    Url1 = 'No News'
    title1 = 'No News'
    content1 = 'No News'
    dates1 = 'No News'

    Url2 = 'No News'
    title2 = 'No News'
    content2 = 'No News'
    dates2 = 'No News'

    Url3 = 'No News'
    title3 = 'No News'
    content3 = 'No News'
    dates3 = 'No News'

    Url4 = 'No News'
    title4 = 'No News'
    content4 = 'No News'
    dates4 = 'No News'

    try:
        Url = data["webPages"]["value"][0]["url"]
        title = data["webPages"]["value"][0]["name"]
        content = data["webPages"]["value"][0]["snippet"]
        dates = data["webPages"]["value"][0]["dateLastCrawled"]

        Url1 = data["webPages"]["value"][1]["url"]
        title1 = data["webPages"]["value"][1]["name"]
        content1 = data["webPages"]["value"][1]["snippet"]
        dates1 = data["webPages"]["value"][1]["dateLastCrawled"]

        Url2 = data["webPages"]["value"][2]["url"]
        title2 = data["webPages"]["value"][2]["name"]
        content2 = data["webPages"]["value"][2]["snippet"]
        dates2 = data["webPages"]["value"][2]["dateLastCrawled"]

        Url3 = data["webPages"]["value"][3]["url"]
        title3 = data["webPages"]["value"][3]["name"]
        content3 = data["webPages"]["value"][3]["snippet"]
        dates3 = data["webPages"]["value"][3]["dateLastCrawled"]

        Url4 = data["webPages"]["value"][4]["url"]
        title4 = data["webPages"]["value"][4]["name"]
        content4 = data["webPages"]["value"][4]["snippet"]
        dates4 = data["webPages"]["value"][4]["dateLastCrawled"]

    except UnicodeDecodeError:
        print("UnicodeDecodeError")
    except IndexError:
        print("IndexError")
    except KeyError:
        print("KeyError")

    try:
        Urla = u''.join((Url)).encode("utf-8", "ignore").strip()
        titlea = u''.join((title)).encode("utf-8", "ignore").strip()
        contenta = u''.join((content)).encode("utf-8", "ignore").strip()

        Urlb = u''.join((Url1)).encode("utf-8", "ignore").strip()
        titleb = u''.join((title1)).encode("utf-8", "ignore").strip()
        contentb = u''.join((content1)).encode("utf-8", "ignore").strip()

        Urlc = u''.join((Url2)).encode("utf-8", "ignore").strip()
        titlec = u''.join((title2)).encode("utf-8", "ignore").strip()
        contentc = u''.join((content2)).encode("utf-8", "ignore").strip()

        Urld = u''.join((Url3)).encode("utf-8", "ignore").strip()
        titled = u''.join((title3)).encode("utf-8", "ignore").strip()
        contentd = u''.join((content3)).encode("utf-8", "ignore").strip()

        Urle = u''.join((Url4)).encode("utf-8", "ignore").strip()
        titlee = u''.join((title4)).encode("utf-8", "ignore").strip()
        contente = u''.join((content4)).encode("utf-8", "ignore").strip()

    except UnicodeDecodeError:
        print("UnicodeDecodeError")
    except IndexError:
        print("IndexError")
    except KeyError:
        print("KeyError")

    text = str(titlea) + ' - ' + str(contenta)
    text += str(titleb) + ' - ' + str(contentb)
    text += str(titlec) + ' - ' + str(contentc)
    text += str(titled) + ' - ' + str(contentd)
    text += str(titlee) + ' - ' + str(contente)
    text = text.replace('\xe2\x80\x99',"'")

    urls = str(Urla) + '; '
    urls += str(Urlb) + '; '
    urls += str(Urlc) + '; '
    urls += str(Urld) + '; '
    urls += str(Urle) + '; '

    #print(text)
    #print(urls)

    data0 = (List,Org,ID,Name,Employer,Title,Addr,City,State,ZIP,Country,Degrees,FSMGive,NUGive,text,urls)
    row_list.append(data0)

    Urla = 'BLANK'
    titlea = 'BLANK'
    contenta = 'BLANK'
    
    Urlb = 'BLANK'
    titleb = 'BLANK'
    contentb = 'BLANK'
    
    Urlc = 'BLANK'
    titlec = 'BLANK'
    contentc = 'BLANK'
    
    Urld = 'BLANK'
    titled = 'BLANK'
    contentd = 'BLANK'
    
    Urle = 'BLANK'
    titlee = 'BLANK'
    contente = 'BLANK'

# Turn results into DataFrame
columns=["List","Org","ID Number","Name","Employer","Job Title","Address","City","State","ZIP","Country","Feinberg Degrees","FSM Lifetime Giving","Total Lifetime Giving","Search Text","Search URLs"]
df = pd.DataFrame(row_list,columns=columns)

# Set DataFrame font size and style
df = df.style.set_properties(**{
    'font-size': '10pt',
    'font-family': 'Tahoma'
})

# Write DataFrame to Excel file
print("Writing report to Excel file...")
print()
writer = pd.ExcelWriter("xxxxxxx\\Distinguished Alumni Candidates List 2024.xlsx")
df.to_excel(writer,sheet_name='Sheet1')
writer.close()

# Open Faculty Commitment Report file
print("Opening up the Excel file in background...")
print()
try:
    excel = win32.gencache.EnsureDispatch('Excel.Application')
except AttributeError as e:
    print(str(e))
    print("Caught an error with win32com...now deleting gen_py directory...")
    print()
    shutil.rmtree("xxxxxxxxxxxx\\gen_py\\3.12\\00020813-0000-0000-C000-000000000046x0x1x9")
    excel = win32.gencache.EnsureDispatch('Excel.Application')
excel.Visible = False
wb = excel.Workbooks.Open("xxxxxxx\\Distinguished Alumni Candidates List 2024.xlsx")
ws = wb.ActiveSheet

# Autofit all columns
ws.Columns.AutoFit()

# Remove first column
ws.Cells(1,1).EntireColumn.Delete()

# Format currency and date columns
ws.Columns("M").NumberFormat = '$#,##0.00'
ws.Columns("N").NumberFormat = '$#,##0.00'

# Save and close Faculty Commitment file
wb.Save()
print("Saved new file xxxxxx\\Distinguished Alumni Candidates List 2024.xlsx")
print()

# Close workboox
wb.Close(False)
wb = None
excel.Quit()

# Close cursor
cursor.close()

