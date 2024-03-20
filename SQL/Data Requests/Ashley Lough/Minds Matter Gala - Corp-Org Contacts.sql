with f_alloc as 
(--Donors to the given allocations
      SELECT DISTINCT
      "ID Number"
      FROM FSM_COMMITS
      WHERE
      "Allocation Code" IN (
      '3203000901101GFT', -- Darren Latimer Fund Neuro Onc
      '3203000940701GFT', -- Brain Tumor Research Gift Fund
      '3203002191001GFT', -- The Brain Tumor Institute
      '3203003625101GFT', -- Mathematical Neuro Oncology
      '3203003906201GFT', -- Wainwright Lab Research Gifts
      '3203005213501GFT', -- Neuro-Oncology Research Fund
      '3203005291301GFT', -- Nervous System Tumor Bank Gif
      '4104004854601END', -- Malnati Miller Endowed Profes
      '4104005557001END' -- Coblentz Family Endowed Fellow
      )
      AND
      MONTHS_BETWEEN(sysdate,"Gift Date") <= 62
      AND
      "Associated Code" IN ('P','C')
  ),
  
 assoc as ( 
SELECT
A.*,
ROW_NUMBER() OVER (PARTITION BY A.ID_NUMBER ORDER BY A.DATE_MODIFIED DESC) AS Rw
FROM (SELECT
R.ID_NUMBER,
R.RELATION_ID_NUMBER,
R.RELATION_NAME,
R.RELATION_TYPE_CODE,
R.RELATION_STATUS_CODE,
R.DATE_MODIFIED,
E.PREF_MAIL_NAME
FROM RELATIONSHIP R
INNER JOIN ENTITY E ON R.RELATION_ID_NUMBER = E.ID_NUMBER
INNER JOIN f_alloc F ON R.ID_NUMBER = F."ID Number"
WHERE
RELATION_TYPE_CODE IN ('OO','CT')
AND
E.DEATH_DT = '00000000'
AND
R.RELATION_STATUS_CODE IN ('A',' ')
AND
E.PERSON_OR_ORG = 'P'
) A   
),

--------------------------------------------------------------------------------------------------------------------------------------
/*  Restrictions 
    Define everyone who shoul NOT receive the mailing
    Select ID numbers of entities with certain record statuses, handling status codes, mailing list codes, etc
    and union them all together to create a list of those with restrictions specific to this mailing type
*/
--------------------------------------------------------------------------------------------------------------------------------------

        restrictions as

(  --exclude Purgeable, Deceased, and No Contact record statuses
   select    id_number
   from    entity e
  where    e.record_status_code in ('X', 'D', 'C')
  union

   --exclude Do Not Solicit, No Contact, Never Engaged, No Mail, No Mail Solicitation
   select    id_number
   from    handling h
  where    h.hnd_status_code = 'A'
    and    h.hnd_type_code in (/*'DNS', */'NC', 'NDR', 'NED' /*, 'NM' , 'NMS'*/) 
  union 

   --exclude All Communication, All Solicitation, Mail Communication, Mail Solicitation, Feinberg Alumni Annual Giving, No Alumni Communication
   select    id_number
   from    mailing_list ml
  where    ml.mail_list_status_code = 'A'
    and    ml.unit_code in (' ', 'FS', 'FSAG', 'FSAR')                                                /*Unit code defines how to apply the mail list code 
                                                                                                        (e.g. I want to be excluded from All Communication from Feinberg (FS))*/
    and    ml.mail_list_code in ('AC', 'AS', 'MC', 'MS', 'ENF10', 'NAC') 
    and    ml.mail_list_ctrl_code = 'EXC'                                                             --Those who want to be excluded from the mail list code
  union 

   --Exclude those with the handling code 'Opt in Only', unless they have opted in to this mailing type
(
   select    id_number
   from    handling h
  where    h.hnd_status_code='A'
    and    h.hnd_type_code ='OIO' 
  minus
   select    id_number
   from    mailing_list ml
  where    ml.mail_list_status_code = 'A'
    and    ml.unit_code in (' ', 'FS', 'FSAG', 'FSAR')
    and    ml.mail_list_code in ('AC', 'AS', 'MC', 'MS', 'ENF10', 'NAC') 
    and    ml.mail_list_ctrl_code = 'INC' 
)

   --Exclude trustees and their spouses
  union 
   select    af.id_number
   from    affiliation af
  where    af.affil_code in ('TR', 'TS')
    and    af.affil_status_code = 'C'                
  union
   --Exclude enrolled students
   select    af.id_number
   from    affiliation af
  where    af.affil_status_code = 'E'
    and    af.affil_level_code like 'A%'
)
--------------------------------------------------------------------------------------------------------------------------------------
/*  Contactable Population */
--------------------------------------------------------------------------------------------------------------------------------------
       , all_ids          as 
(  --select everyone from main population minus those in the restrictions
   select    "ID Number"
   from    f_alloc
  minus
   select    id_number
   from    restrictions
)

           , hh_list                    as 
(--identify who the primary entity in a household is, so that output is one row per household
--prioritize alumni, then use id_number as a tie-breaker
--modify what is included in the order by (and what gets left joined) depending on what makes sense for request
   select    "ID Number"
     from    (
                 select    all_ids."ID Number"
                         , rank() over(partition by dh.household_id_number 
                                           order by e.record_type_code
                                                  , e.id_number)                                        as rnk
                   from    all_ids
                   join    dm_ard.dim_household@catrackstobi dh
                     on    dh.id_number = all_ids."ID Number"
              left join    entity e 
                     on    e.id_number = all_ids."ID Number"
                  where    e.jnt_mailings_ind <> 'N'
                    and    e.jnt_gifts_ind <> 'N'
                  union
                 select    all_ids."ID Number"
                         , 1                                                                            as rnk
                   from    all_ids
                   join    entity e
                     on    e.id_number = all_ids."ID Number"
                  where    (e.jnt_mailings_ind = 'N' 
                     or    e.jnt_gifts_ind='N')
              )
    where    rnk = 1
)
--------------------------------------------------------------------------------------------------------------------------------------
/*  Additional Columns */
--------------------------------------------------------------------------------------------------------------------------------------
      
SELECT
f.*,
A.PREF_MAIL_NAME AS "Org Contact Name"
from hh_list H
INNER JOIN f_alloc f on H."ID Number" = f."ID Number"
join advance_nu_rpt.v_postal_list_template vpm on (vpm.id_number = H."ID Number")
JOIN assoc A on H."ID Number" = A.ID_NUMBER AND A.RW = 1
WHERE
VPM.record_type_desc IN ('Other Org.','Corporate Foundation','Corporation','Fnd (Private)','Fdn (Non-Alumni)')



