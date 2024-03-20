CREATE OR REPLACE VIEW RPT_RVA7647.FSM_EVENTS AS

-----Participants
Select
PPT.ID_NUMBER AS "ID Number",
EP.EVENT_ID AS "Event ID",
EP.EVENT_NAME AS "Event Name",
EP.VENUE AS "Event Venue",
EP.VENUE_STATE AS "Event State",
EP.NOTE AS "Event Note",
EP.ACTIVE_IND AS "Active",
ES.FULL_DESC AS "Event Status",
REPLACE(SUBSTR(REPLACE(EP.EVENT_NAME,'FSMDEV FY ','FSMDEV FY'),INSTR(EP.EVENT_NAME, ' FY', 1),5),'FY','20') AS "Fiscal Year",
tms_et.short_desc As "Event Type",
'Participant' AS "Attendee Type",
ppn.participation_status_code AS "Attendee Status Code",
tms_ps.short_desc AS "Attendee Status Desc",
ep.event_start_Datetime AS "Event Start Date",
ep.event_stop_Datetime AS "Event Stop Date",
ROW_NUMBER() OVER (PARTITION BY PPT.ID_NUMBER ORDER BY ep.event_start_Datetime DESC) AS Rw
From ep_participant ppt
Inner Join ep_event ep
  On ep.event_id = ppt.event_id
Left Join ep_participation ppn
  On ppn.registration_id = ppt.registration_id
Left Join tms_event_type tms_et
  On tms_et.event_type = ep.event_type
Left Join tms_event_participant_status tms_ps
  On tms_ps.participant_status_code = ppn.participation_status_code
Left Join ADVANCE.TMS_EVENT_STATUS ES
     On ep.event_status_code = ES.event_status_code
Where 
ppn.participation_status_code In (' ', 'P', 'A', 'V') -- Blank, Participated, Accepted, Virtual
AND
EP.EVENT_NAME LIKE 'FSMDEV FY%'
AND
PPT.ID_NUMBER NOT IN (' ')

UNION

-----Invitations
Select
PPT.ID_NUMBER AS "ID Number",
EP.EVENT_ID AS "Event ID",
EP.EVENT_NAME AS "Event Name",
EP.VENUE AS "Event Venue",
EP.VENUE_STATE AS "Event State",
EP.NOTE AS "Event Note",
EP.ACTIVE_IND AS "Active",
ES.FULL_DESC AS "Event Status",
REPLACE(SUBSTR(REPLACE(EP.EVENT_NAME,'FSMDEV FY ','FSMDEV FY'),INSTR(EP.EVENT_NAME, ' FY', 1),5),'FY','20') AS "Fiscal Year",
tms_et.short_desc As "Event Type",
'Invitee' AS "Attendee Type",
ppn.invitation_code AS "Attendee Status Code",
tms_ps.short_desc AS "Attendee Status Desc",
ep.event_start_Datetime AS "Event Start Date",
ep.event_stop_Datetime AS "Event Stop Date",
ROW_NUMBER() OVER (PARTITION BY PPT.ID_NUMBER ORDER BY ep.event_start_Datetime DESC) AS Rw
From EP_PARTICIPANT_INVITE ppt
Inner Join ep_event ep
  On ep.event_id = ppt.event_id
Left Join EP_EVENT_INVITATION ppn
  On ppn.invitation_id = ppt.invitation_id
Left Join tms_event_type tms_et
  On tms_et.event_type = ep.event_type
Left Join tms_event_invitation_status tms_ps
  On tms_ps.invitation_status_code = ppn.invitation_code
Left Join ADVANCE.TMS_EVENT_STATUS ES
     On ep.event_status_code = ES.event_status_code
Where 
EP.EVENT_NAME LIKE 'FSMDEV FY%'
AND
PPT.ID_NUMBER NOT IN (' ')

UNION

-----Registrations
Select
PPN.CONTACT_ID_NUMBER AS "ID Number",
EP.EVENT_ID AS "Event ID",
EP.EVENT_NAME AS "Event Name",
EP.VENUE AS "Event Venue",
EP.VENUE_STATE AS "Event State",
EP.NOTE AS "Event Note",
EP.ACTIVE_IND AS "Active",
ES.FULL_DESC AS "Event Status",
REPLACE(SUBSTR(REPLACE(EP.EVENT_NAME,'FSMDEV FY ','FSMDEV FY'),INSTR(EP.EVENT_NAME, ' FY', 1),5),'FY','20') AS "Fiscal Year",
tms_et.short_desc As "Event Type",
'Registrant' AS "Attendee Type",
ppn.registration_status_code AS "Attendee Status Code",
tms_ps.short_desc AS "Attendee Status Desc",
ep.event_start_Datetime AS "Event Start Date",
ep.event_stop_Datetime AS "Event Stop Date",
ROW_NUMBER() OVER (PARTITION BY PPN.CONTACT_ID_NUMBER ORDER BY ep.event_start_Datetime DESC) AS Rw
From ep_event ep
INNER Join EP_REGISTRATION ppn
  On ep.event_id = ppn.event_id
Left Join tms_event_type tms_et
  On tms_et.event_type = ep.event_type
Left Join tms_event_registration_status tms_ps
  On tms_ps.registration_status_code = ppn.registration_status_code
Left Join ADVANCE.TMS_EVENT_STATUS ES
     On ep.event_status_code = ES.event_status_code
Where 
EP.EVENT_NAME LIKE 'FSMDEV FY%'
AND
PPN.CONTACT_ID_NUMBER NOT IN (' ')
;
