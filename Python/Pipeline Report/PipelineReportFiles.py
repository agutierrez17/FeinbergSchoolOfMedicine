# Program written by Andrew J. Gutierrez - andrew.gutierrez@northwestern.edu

from datetime import date, datetime
import datetime as d
import shutil
import os

# Get today's date
today = date.today() # date(2023,10,16) #
print()
print("Today is " + str(today))
print()

# Get current day of week
if datetime.weekday(today) == 0:
    LastReportDate = today - d.timedelta(days = 5)
    print("Last Pipeline Report was run on: " + str(LastReportDate))
elif datetime.weekday(today) == 2:
    LastReportDate = today - d.timedelta(days = 2) # 2
    print("Last Pipeline Report was run on: " + str(LastReportDate))

# Close any currently-open Excel files
print()
os.system("taskkill /f /im excel.exe")

# Move FSM Commitments file to Extra Working Reports / FY24 folder
try:
    shutil.move("xxxxxxx\\Pipeline Report\\FSM Commitment Report %s.xlsx" % (str(LastReportDate)), "xxxxxxx\\Pipeline Report\\Extra working reports - JF\\FY24\\FSM Commitment Report %s.xlsx" % (str(LastReportDate)))
    print("Moved FSM Commitment Report %s to the Extra Working Reports folder" % (str(LastReportDate)))
    print()
except OSError as e:
    print("FSM Commitment Report %s is not present in the directory" % (str(LastReportDate)))
    print()

# Move Long-Term Pipeline PDF file to Previous Months / FY24 folder
try:
    shutil.move("xxxxxxxx\\Pipeline Report\\FY24 Long-term Pipeline %s.pdf" % (str(LastReportDate)), "xxxxxxx\\Pipeline Report\\Previous Months\\FY24\\FY24 Long-term Pipeline %s.pdf" % (str(LastReportDate)))
    print("Moved FY24 Long-term Pipeline %s PDF file to the Previous Months folder" % (str(LastReportDate)))
    print()
except OSError as e:
    print("FY24 Long-term Pipeline %s PDF file is not present in the directory" % (str(LastReportDate)))
    print()

# Move Year-End Pipeline PDF file to Previous Months / FY24 folder
try:
    shutil.move("xxxxxxx\\Pipeline Report\\FY24 Year-end Pipeline - %s.pdf" % (str(LastReportDate)), "xxxxxxxx\\Pipeline Report\\Previous Months\\FY24\\FY24 Year-end Pipeline - %s.pdf" % (str(LastReportDate)))
    print("Moved FY24 Year-end Pipeline - %s PDF file to the Previous Months folder" % (str(LastReportDate)))
    print()
except OSError as e:
    print("FY24 Year-end Pipeline - %s PDF file is not present in the directory" % (str(LastReportDate)))
    print()

# Copy previous Long-Term Pipeline excel file to make current day's file
try:
    shutil.copy2("xxxxxxx\\Pipeline Report\\FY24 Long-term Pipeline %s.xlsx" % (str(LastReportDate)), "xxxxxxx\\Pipeline Report\\FY24 Long-term Pipeline %s.xlsx" % (str(today)))
    print("Created new file FY24 Long-term Pipeline %s.xlsx" % (str(today)))
    print()
except:
    ("Unable to create new file FY24 Long-term Pipeline %s.xlsx" % (str(today)))

# Move Long-Term Pipeline excel file to Previous Months / FY24 folder
try:
    shutil.move("xxxxxxx\\Pipeline Report\\FY24 Long-term Pipeline %s.xlsx" % (str(LastReportDate)), "xxxxxx\\Pipeline Report\\Extra working reports - JF\\FY24\\FY24 Long-term Pipeline %s.xlsx" % (str(LastReportDate)))
    print("Moved FY24 Long-term Pipeline %s Excel file to the Extra Working Reports folder" % (str(LastReportDate)))
    print()
except OSError as e:
    print("FY24 Long-term Pipeline %s Excel file is not present in the directory" % (str(LastReportDate)))
    print()

# Copy previous Year-End Pipeline excel file to make current day's file
try:
    shutil.copy2("xxxxxx\\Pipeline Report\\FY24 Year-end Pipeline - %s.xlsx" % (str(LastReportDate)), "xxxxxx\\Pipeline Report\\FY24 Year-end Pipeline - %s.xlsx" % (str(today)))
    print("Created new file FY24 Year-end Pipeline - %s.xlsx" % (str(today)))
    print()
except:
    ("Unable to create new file FY24 Year-end Pipeline - %s.xlsx" % (str(today)))

# Move Long-Term Pipeline excel file to Extra Working Reports / FY24
try:
    shutil.move("xxxxxx\\Pipeline Report\\FY24 Year-end Pipeline - %s.xlsx" % (str(LastReportDate)), "xxxxxxx\\Pipeline Report\\Extra working reports - JF\\FY24\\FY24 Year-end Pipeline - %s.xlsx" % (str(LastReportDate)))
    print("Moved FY24 Year-end Pipeline - %s Excel file to the Extra Working Reports folder" % (str(LastReportDate)))
    print()
except OSError as e:
    print("FY24 Year-end Pipeline - %s Excel file is not present in the directory" % (str(LastReportDate)))
    print()


