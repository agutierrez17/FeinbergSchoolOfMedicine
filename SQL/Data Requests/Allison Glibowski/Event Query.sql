SELECT
"ID Number",
"Event ID",
"Event Name",
"Event Venue",
"Event State",
"Event Note",
"Active",
"Event Status",
"Fiscal Year",
"Event Type",
"Attendee Type",
"Attendee Status Code",
"Attendee Status Desc",
"Event Start Date",
"Event Stop Date"
FROM FSM_EVENTS
WHERE
"Event Name" LIKE 'FSMDEV FY%'
