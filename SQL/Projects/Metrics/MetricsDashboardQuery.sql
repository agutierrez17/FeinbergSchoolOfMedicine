SELECT DISTINCT
    s.ID_NUMBER               AS pm_id_number,
    s.name        AS name,
    s.level_1_sup_id,
    s.level_1_sup_name,
    s.level_2_sup_id,
    s.level_2_sup_name,
    s.level_3_sup_id,
    s.level_3_sup_name,
    --pm.office_,
    --s.office_code,
    (SELECT tof.SHORT_DESC
        FROM TMS_OFFICE tof
        WHERE tof.OFFICE_CODE = s.office_code) office_,
    metrics.full_name_title,
    metrics.last_name,
    metrics.last_name_title,
    metrics.FY,
    metrics.quarter,
    metrics.major_gifts_committments_goal,
    metrics.major_gifts_committments_cnt,
    metrics.major_gifts_solicitations_goal,
    metrics.major_gifts_solicitations_cnt,
    metrics.major_gift_dollars_raised_goal,
    metrics.major_gift_dollars_raised_cnt,
    metrics.visits_goal,
    metrics.visits_cnt,
    metrics.qualification_visits_goal,
    metrics.qualification_visits_cnt,
    metrics.proposal_assists_goal,
    metrics.proposal_assists_cnt,
    metrics.major_gft_dollars_raise_g_num,
    metrics.major_gft_dollars_raise_g_cnt,
    metrics.proposal_ast_dls_raised_goal,
    metrics.proposal_ast_dls_raised_count,
    metrics.proposal_ast_num_com_goal,
    metrics.proposal_ast_nun_com_cnt,
    metrics.non_visit_contact_goal,
    metrics.non_visit_contact_cnt,
    metrics.gift_planning_consul_goal,
    metrics.gift_planning_consul_cnt,
    metrics.comittments_under_100K,
    metrics.solicitations_under_100K,
    metrics.dollars_raised,
    metrics.prop_ast_com_under_100K,
    metrics.prop_ast_dlrs_rsd_under_100K

  /* STATS */

    FROM  (select
                s.id_number AS id_number,
                s.name ,
                s.OFFICE_CODE,
                senior_staff1.id_number  AS level_1_sup_id,
                senior_staff1.NAME          AS level_1_sup_name,
                senior_staff2.id_number  AS level_2_sup_id,
                senior_staff2.NAME          AS level_2_sup_name,
                senior_staff3.id_number  AS level_3_sup_id,
                senior_staff3.NAME          AS level_3_sup_name
                FROM staff s
                LEFT OUTER JOIN staff senior_staff1 ON s.SENIOR_STAFF = senior_staff1.ID_NUMBER
                LEFT OUTER JOIN staff senior_staff2 ON senior_staff1.SENIOR_STAFF = senior_staff2.ID_NUMBER
                LEFT OUTER JOIN staff senior_staff3 ON senior_staff2.SENIOR_STAFF = senior_staff3.ID_NUMBER
                where s.ACTIVE_IND = 'Y'
    ) s

    LEFT OUTER JOIN (SELECT DISTINCT
       a.PROSPECT_ID,
       staffer.ID_NUMBER,
       staffer.PREF_MAIL_NAME                          prospect_manager,
       a.ASSIGNMENT_TYPE,
       (SELECT tat.short_desc
        FROM TMS_ASSIGNMENT_TYPE tat
        WHERE tat.ASSIGNMENT_TYPE = a.ASSIGNMENT_TYPE) type_assignment,
       (SELECT tof.SHORT_DESC
        FROM TMS_OFFICE tof
        WHERE tof.OFFICE_CODE = a.OFFICE_CODE)         office_,
       a.PROPOSAL_ID                                   assigned_proposal,
       a.PROGRAM_CODE                                  assigned_program,
       a.START_DATE                                    assigned_start
     FROM assignment a
       LEFT OUTER JOIN entity staffer ON staffer.ID_NUMBER = a.ASSIGNMENT_ID_NUMBER
     WHERE a.ACTIVE_IND = 'Y' AND a.ASSIGNMENT_TYPE IN ('PM')
    ) pm ON pm.id_number = s.id_number

    LEFT OUTER JOIN (
                      SELECT DISTINCT
                        m.id_number                          AS id_number,
                        e.first_name || ' ' || e.last_name   AS full_name_title,
                        e.last_name                          AS last_name,
                        e.last_name || ' ' || m.id_number    AS last_name_title,
                        to_char(fiscal_year)                 AS FY,
                        quarter                              AS quarter,
                        nvl(maj_gft_comm_goal, 0)            AS major_gifts_committments_goal,
                        nvl(maj_gft_comm_cnt, 0)             AS major_gifts_committments_cnt,
                        nvl(maj_gft_sol_goal, 0)             AS major_gifts_solicitations_goal,
                        nvl(maj_gft_sol_cnt, 0)              AS major_gifts_solicitations_cnt,
                        maj_gft_dol_goal                     AS major_gift_dollars_raised_goal,
                        maj_gft_dol_cnt                      AS major_gift_dollars_raised_cnt,
                        nvl(visits_goal, 0)                  AS visits_goal,
                        nvl(visits_cnt, 0)                   AS visits_cnt,
                        nvl(qual_visits_goal, 0)             AS qualification_visits_goal,
                        nvl(qual_visits_cnt, 0)              AS qualification_visits_cnt,
                        nvl(prop_assist_goal, 0)             AS proposal_assists_goal,
                        nvl(prop_assist_cnt, 0)              AS proposal_assists_cnt,
                        maj_gft_dol_goal                     AS major_gft_dollars_raise_g_num,
                        maj_gft_dol_cnt                      AS major_gft_dollars_raise_g_cnt,
                        prop_ast_dls_goal                    AS proposal_ast_dls_raised_goal,
                        prop_ast_dls_cnt                     AS proposal_ast_dls_raised_count,
                        nvl(prop_ast_com_goal, 0)            AS proposal_ast_num_com_goal,
                        nvl(prop_ast_com_cnt, 0)             AS proposal_ast_nun_com_cnt,
                        nvl(non_vst_con_goal, 0)             AS non_visit_contact_goal,
                        nvl(non_vst_con_cnt, 0)              AS non_visit_contact_cnt,
                        nvl(gft_plan_con_goal, 0)            AS gift_planning_consul_goal,
                        nvl(gft_plan_con_cnt, 0)             AS gift_planning_consul_cnt,
                        nvl(com_under_100K_cnt, 0)           AS comittments_under_100K,
                        nvl(sol_under_100K_cnt, 0)           AS solicitations_under_100K,
                        nvl(dlrs_rsd_under_100K_cnt, 0)      AS dollars_raised,
                        nvl(prop_ast_under_100K_cnt, 0)      AS prop_ast_com_under_100K,
                        nvl(prop_ast_dlrs_under_100K_cnt, 0) AS prop_ast_dlrs_rsd_under_100K

                      FROM nu_gft_trp_officer_metrics m
                      LEFT OUTER JOIN entity e ON e.id_number = m.id_number
                      -- WHERE  m.ID_NUMBER='0000562844' AND fiscal_year=2017
                            where  fiscal_year>=2016
                      ORDER BY e.last_name ASC, m.id_number, m.quarter ASC
                    ) metrics ON metrics.id_number = s.ID_NUMBER
 WHERE
 s.ID_NUMBER = '0000783839'
 AND
 FY = '2024'
 
 ORDER BY
 QUARTER
