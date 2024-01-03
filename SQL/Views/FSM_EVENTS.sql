CREATE OR REPLACE VIEW RPT_RVA7647.FSM_EVENTS AS

Select
PPT.ID_NUMBER,
EP.EVENT_ID,
EP.EVENT_NAME,
tms_et.short_desc As event_type,
ppn.participation_id,
ppn.participation_status_code,
tms_ps.short_desc As participation_status,
ep.event_start_Datetime,
ep.event_stop_Datetime,
ROW_NUMBER() OVER (PARTITION BY PPT.ID_NUMBER ORDER BY ep.event_start_Datetime DESC) AS Rw
From ep_participant ppt
Inner Join ep_event ep
  On ep.event_id = ppt.event_id
Inner Join ep_participation ppn
  On ppn.registration_id = ppt.registration_id
Left Join tms_event_type tms_et
  On tms_et.event_type = ep.event_type
Left Join tms_event_participant_status tms_ps
  On tms_ps.participant_status_code = ppn.participation_status_code
Where ppn.participation_status_code In (' ', 'P', 'A', 'V') -- Blank, Participated, Accepted, Virtual

;
