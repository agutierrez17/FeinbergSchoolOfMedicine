# Program written by Andrew J. Gutierrez - andrew.gutierrez@northwestern.edu

from datetime import date, datetime
import datetime as d
import os
import win32com.client as win32

# Get today's date
today = date.today()
print()
print("Today is " + str(today))
print()

# Set file paths
working_directory = os.fspath('xxxxxxxxxx\\Tribute Card Information\\Tribute Card Reports\\Tribute Cards - Sent')
template_name = os.fspath('xxxxxxxxx\\Tribute Card Information\\Tribute Card Templates\\MailMerge Tribute Card Template - November 2023.docx')
data_source_name = os.fspath('xxxxxxxx\\Tribute Card Information\\Tribute Cards_FY24 2.xlsx')
doc_final_name = os.fspath('Tribute Cards %s.docx' % today)
destination_folder = os.path.join(working_directory, 'Destination')

# Open Merge Template
wordApp = win32.Dispatch('Word.Application')
wordApp.Visible = True

sourceDoc = wordApp.Documents.Open(template_name)
mail_merge = sourceDoc.MailMerge
mail_merge.OpenDataSource(data_source_name)

record_count = mail_merge.DataSource.RecordCount

# Run Merge
for i in range(1, record_count + 1):
    mail_merge.DataSource.ActiveRecord = i
    mail_merge.DataSource.FirstRecord = 1
    mail_merge.DataSource.LastRecord = record_count + 1

    mail_merge.Destination = 0
    mail_merge.Execute(False)

    targetDoc = wordApp.ActiveDocument
    targetDoc.SaveAs(os.path.join(destination_folder, doc_final_name))
    targetDoc.Close(False)
    targetDoc = None

# Close Document
sourceDoc.MailMerge.MainDocumentType = -1
sourceDoc.Close(False)
wordApp.Quit()
            
