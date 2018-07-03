----50830

select --count(*)
     all_dates_turfs.date
    ,all_dates_turfs.regionid
    ,all_dates_turfs.regionname
    ,all_dates_turfs.foid
    ,all_dates_turfs.foname
    ,all_dates_turfs.teamid
    ,all_dates_turfs.teamname
    ,date_trunc('week', all_dates_turfs.date) as REPORTING_WEEK
    ,RECRUITMENTDIALS.RECRUITMENT_DIALS
    ,RECRUITMENTDIALS.RECRUITMENT_contacts
    ,ONE_ON_ONES.EVENT_11_FUTURE_SCHEDULED
    ,ONE_ON_ONES.EVENT_11_COMPLETED
    ,DVCDIALSATTEMPTS.DVC_DIAL_ATTEMPTS
    ,DVCDIALSATTEMPTS.DVC_DIAL_CONTACTS
    ,DVCKNOCKATTEMPTS.DVC_KNOCK_ATTEMPTS
    ,DVCKNOCKATTEMPTS.DVC_KNOCK_CONTACTS
    ,DVCACTUALDIALS.DVCDIALS
    ,DVCACTUALKNOCKS.DVCKNOCKS
    ,SIGNED_CTV.SIGNED_CTV
    ,SMALL_BUSINESS.SMALL_BUSINESS_SUPPORTING
    ,DVC_CONFIRMED_TEAM.DVC_TEAM_MEMBERS_CONFIRMED
    ,DVC_PROSPECT_TEAM.DVC_TEAM_MEMBERS_PROSPECT
    ,DVC_TEST_TEAM.DVC_TEAM_MEMBERS_TEST
    ,CO_CONFIRMED_TEAM.CO_TEAM_MEMBERS_CONFIRMED
    ,CO_PROSPECT_TEAM.CO_TEAM_MEMBERS_PROSPECT
    ,CO_TEST_TEAM.CO_TEAM_MEMBERS_TEST
  ----COUNTS BELOW ARE CUMULATIVE COUNTS FOR THAT DAY
    ,ACTIVES.ACTIVE_PAST_28_DAYS
    ,ACTIVES.ACTIVE_PAST_28_DAYS_WILL_DROP_IN_7
    ,ACTIVES.NONACTIVES_SCHEDULED_THIS_WEEK --this is literal calendar week as requested
  from
(
  select * from
  (
    SELECT column_0::date as date from VANSYNC_IL_GOV_2018.all_dates_general
  ) as dates
  cross JOIN
  (
    select * from
      (
        (
          select
            REGIONID
            , REGIONNAME
            , FOID
            , FONAME
            , TEAMID
            , TEAMNAME
          from
            VANSYNC_IL_GOV_2018.DNC_TURF
          group by
            REGIONID
            , REGIONNAME
            , FOID
            , FONAME
            , TEAMID
            , TEAMNAME
        )
        union all
        (
          select
            REGIONID
            , REGIONNAME
            , FOID
            , FONAME
            , null :: BIGINT  as TEAMID
            , null :: VARCHAR as TEAMNAME
          from
            VANSYNC_IL_GOV_2018.DNC_TURF
          group by
            REGIONID
            , REGIONNAME
            , FOID
            , FONAME
        )
      )

  ) as turfs
) as all_dates_turfs
LEFT JOIN
  (
-------------------------------
----recruitment dials
    -- 1 ) Recruitment Calls - ​attempts in MyCampaign by phone, attributed by “Pritzker Effective Organizer”, during
    -- the entirety of the current reporting week
    SELECT
        date(DATECANVASSED)                                       AS DATE
      , coalesce(count(CASE WHEN CONTACTTYPE = 'Phone'
      THEN CONTACTSCONTACTID
                       ELSE NULL END), 0)                         AS RECRUITMENT_DIALS
--,count(case when contacttype='Event' then contactscontactid else null end) as community_sign_ups --i should do this from ACs
      , coalesce(count(CASE WHEN RESULTSHORTNAME = 'Canvassed' AND CONTACTTYPE = 'Phone'
      THEN CONTACTSCONTACTID
                       ELSE NULL END), 0)                         AS RECRUITMENT_CONTACTS
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
    FROM
      VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_CONTACTHISTORY AS A
    WHERE A.STATECODE = 'IL'
    GROUP BY
      date(DATECANVASSED)
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
  )
    AS RECRUITMENTDIALS
      ON (
          ALL_DATES_TURFS.DATE = RECRUITMENTDIALS.DATE
          and ALL_DATES_TURFS.REGIONID = RECRUITMENTDIALS.REGIONID
          and ALL_DATES_TURFS.REGIONNAME = RECRUITMENTDIALS.REGIONNAME
          and ALL_DATES_TURFS.FOID = RECRUITMENTDIALS.FOID
          and ALL_DATES_TURFS.FONAME = RECRUITMENTDIALS.FONAME
          and (ALL_DATES_TURFS.TEAMID = RECRUITMENTDIALS.TEAMID OR (ALL_DATES_TURFS.teamid IS NULL AND RECRUITMENTDIALS.teamid IS NULL))
          and (ALL_DATES_TURFS.TEAMNAME =RECRUITMENTDIALS.TEAMNAME OR (ALL_DATES_TURFS.teamname IS NULL AND RECRUITMENTDIALS.teamname IS NULL))
      )
LEFT JOIN
  (
    ---2 ) 1:1s - ​shifts completed in the 1-on-1 event type, intro, maintenance and escalation, attributed by “Pritzker
    ---Effective Organizer”
    SELECT
      EVENT_DATE
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
      , count(CASE WHEN (EVENTNAME = '1-on-1'
              AND
                (EVENTSTATUS_LAST = 'Scheduled'
                 or EVENTSTATUS_LAST = 'Left Message'
                 or EVENTSTATUS_LAST = 'Confirmed'
                 or EVENTSTATUS_LAST = 'Confirmed Twice'
                )
              AND EVENT_DATE >= current_date
                        )THEN EVENTSIGNUPID
              ELSE NULL END)                                      AS EVENT_11_FUTURE_SCHEDULED
    ---all completed shifts
      , count(CASE WHEN (EVENTNAME = '1-on-1'
              AND EVENTSTATUS_LAST = 'Completed'
              AND EVENT_DATE <= current_date)
              THEN EVENTSIGNUPID
              ELSE NULL END)                                      AS EVENT_11_COMPLETED

    FROM VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_EVENTS_INDIVIDUAL_SHIFTS
    WHERE DATESUPPRESSED IS NULL
    GROUP BY EVENT_DATE
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
    ) as ONE_ON_ONES
        ON (ALL_DATES_TURFS.regionid = ONE_ON_ONES.regionid
         AND ALL_DATES_TURFS.regionname = ONE_ON_ONES.regionname
         AND ALL_DATES_TURFS.foid = ONE_ON_ONES.foid
         AND ALL_DATES_TURFS.foname = ONE_ON_ONES.foname
         AND (ALL_DATES_TURFS.teamid = ONE_ON_ONES.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND ONE_ON_ONES.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = ONE_ON_ONES.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND ONE_ON_ONES.teamname IS NULL))
         AND ALL_DATES_TURFS.date = ONE_ON_ONES.event_date)
LEFT JOIN
  (
-------------------------------
----DVC dials - ATTEMPTS
    ---4 ) DVC Calls - ​attempts in MyVoters by phone, attributed by “Pritzker Effective Organizer”
    SELECT
        date(DATECANVASSED)                                       AS DATE
      , coalesce(count(CASE WHEN CONTACTTYPE = 'Phone'
      THEN CONTACTSCONTACTID
                       ELSE NULL END), 0)                         AS DVC_DIAL_ATTEMPTS
--,count(case when contacttype='Event' then contactscontactid else null end) as community_sign_ups --i should do this from ACs
      , coalesce(count(CASE WHEN RESULTSHORTNAME = 'Canvassed' AND CONTACTTYPE = 'Phone'
      THEN CONTACTSCONTACTID
                       ELSE NULL END), 0)                         AS DVC_DIAL_CONTACTS
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
    FROM
      VANSYNC_IL_GOV_2018.ZZ_VOTERFILE_CONTACTHISTORY AS A
    WHERE A.STATECODE = 'IL'
    GROUP BY
      date(DATECANVASSED)
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
  )
    AS DVCDIALSATTEMPTS
      ON (ALL_DATES_TURFS.regionid = DVCDIALSATTEMPTS.regionid
         AND ALL_DATES_TURFS.regionname = DVCDIALSATTEMPTS.regionname
         AND ALL_DATES_TURFS.foid = DVCDIALSATTEMPTS.foid
         AND ALL_DATES_TURFS.foname = DVCDIALSATTEMPTS.foname
         AND (ALL_DATES_TURFS.teamid = DVCDIALSATTEMPTS.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND DVCDIALSATTEMPTS.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = DVCDIALSATTEMPTS.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND DVCDIALSATTEMPTS.teamname IS NULL))
         AND ALL_DATES_TURFS.date = DVCDIALSATTEMPTS.date)
LEFT JOIN
  (
-------------------------------
----DVC knocks - ATTEMPTS
    ---3 ) Door Attempts - ​(Not statewide - only within DVC turfs)​ - attempts in MyVoters by walk, attributed by
    ---“Pritzker Effective Organizer”,
    SELECT
        date(DATECANVASSED)                                       AS DATE
      , coalesce(count(CASE WHEN CONTACTTYPE = 'Walk'
      THEN CONTACTSCONTACTID
                       ELSE NULL END), 0)                         AS DVC_KNOCK_ATTEMPTS
--,count(case when contacttype='Event' then contactscontactid else null end) as community_sign_ups --i should do this from ACs
      , coalesce(count(CASE WHEN RESULTSHORTNAME = 'Canvassed' AND CONTACTTYPE = 'Walk'
      THEN CONTACTSCONTACTID
                       ELSE NULL END), 0)                         AS DVC_KNOCK_CONTACTS
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
    FROM
      VANSYNC_IL_GOV_2018.ZZ_VOTERFILE_CONTACTHISTORY AS A
    WHERE A.STATECODE = 'IL'
    GROUP BY
      date(DATECANVASSED)
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
  )
    AS DVCKNOCKATTEMPTS
      ON (ALL_DATES_TURFS.regionid = DVCKNOCKATTEMPTS.regionid
         AND ALL_DATES_TURFS.regionname = DVCKNOCKATTEMPTS.regionname
         AND ALL_DATES_TURFS.foid = DVCKNOCKATTEMPTS.foid
         AND ALL_DATES_TURFS.foname = DVCKNOCKATTEMPTS.foname
         AND (ALL_DATES_TURFS.teamid = DVCKNOCKATTEMPTS.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND DVCKNOCKATTEMPTS.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = DVCKNOCKATTEMPTS.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND DVCKNOCKATTEMPTS.teamname IS NULL))
         AND ALL_DATES_TURFS.date = DVCKNOCKATTEMPTS.date)
LEFT JOIN
-------------------------
------DVC ACTUAL DIALS WITH HOUSEHOLDING BY PHONE
(
---dialstable
        SELECT
          DATECANVASSED_DATE as date
          ,regionid
          ,regionname
          ,foid
          ,foname
          ,teamid
          ,teamname
          , count(*) AS DVCDIALS
        FROM
          (
---dialsprep
            SELECT
                date(DATECANVASSED)                                          AS DATECANVASSED_DATE
                ,regionid
                ,regionname
                ,foid
                ,foname
                ,teamid
                ,teamname
            FROM
              VANSYNC_IL_GOV_2018.ZZ_VOTERFILE_CONTACTHISTORY AS A
              LEFT JOIN VANSYNC_IL_GOV_2018.ANALYTICS_PERSON_IL AS B
                ON A.VANID = B.VOTEBUILDER_IDENTIFIER AND A.STATECODE = B.STATE_CODE
----get only knocks to people on file
            WHERE A.STATECODE = 'IL' AND B.IS_CURRENT_REG = TRUE AND CONTACTTYPE = 'Phone'
            GROUP BY
---primary_phone_id would need to be replaced if im using a file export
              date(DATECANVASSED), A.CANVASSEDBYID, PRIMARY_PHONE_ID
               ,regionid
              ,regionname
              ,foid
              ,foname
              ,teamid
              ,teamname
          ) AS DIALSPREP
        GROUP BY DATECANVASSED_DATE
          ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
      ) AS DVCACTUALDIALS
    ON (ALL_DATES_TURFS.regionid = DVCACTUALDIALS.regionid
         AND ALL_DATES_TURFS.regionname = DVCACTUALDIALS.regionname
         AND ALL_DATES_TURFS.foid = DVCACTUALDIALS.foid
         AND ALL_DATES_TURFS.foname = DVCACTUALDIALS.foname
         AND (ALL_DATES_TURFS.teamid = DVCACTUALDIALS.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND DVCACTUALDIALS.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = DVCACTUALDIALS.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND DVCACTUALDIALS.teamname IS NULL))
         AND ALL_DATES_TURFS.date = DVCACTUALDIALS.date)
-------------------------
------DVC ACTUAL KNOCKS - WITH HOUSEHOLDING BY ADDRESS
LEFT JOIN
    (
---knocktable
        SELECT
          DATECANVASSED_DATE AS DATE
          ,regionid
          ,regionname
          ,foid
          ,foname
          ,teamid
          ,teamname
          , count(*) AS DVCKNOCKS
        FROM
          (
---knockprep
            SELECT
                date(DATECANVASSED)                                          AS DATECANVASSED_DATE
                ,regionid
                ,regionname
                ,foid
                ,foname
                ,teamid
                ,teamname
            FROM
              VANSYNC_IL_GOV_2018.ZZ_VOTERFILE_CONTACTHISTORY AS A
              LEFT JOIN VANSYNC_IL_GOV_2018.ANALYTICS_PERSON_IL AS B
                ON A.VANID = B.VOTEBUILDER_IDENTIFIER AND A.STATECODE = B.STATE_CODE
----get only knocks to people on file
            WHERE A.STATECODE = 'IL' AND B.IS_CURRENT_REG = TRUE AND CONTACTTYPE = 'Walk'
            GROUP BY
---primary_voting_address_id would need to be replaced if im using a file export
              date(DATECANVASSED), A.CANVASSEDBYID, PRIMARY_VOTING_ADDRESS_ID
              ,regionid
              ,regionname
              ,foid
              ,foname
              ,teamid
              ,teamname
          ) AS KNOCKPREP
        GROUP BY DATECANVASSED_DATE
          ,regionid
          ,regionname
          ,foid
          ,foname
          ,teamid
          ,teamname
      ) AS DVCACTUALKNOCKS
    ON (ALL_DATES_TURFS.regionid = DVCACTUALKNOCKS.regionid
         AND ALL_DATES_TURFS.regionname = DVCACTUALKNOCKS.regionname
         AND ALL_DATES_TURFS.foid = DVCACTUALKNOCKS.foid
         AND ALL_DATES_TURFS.foname = DVCACTUALKNOCKS.foname
         AND (ALL_DATES_TURFS.teamid = DVCACTUALKNOCKS.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND DVCACTUALKNOCKS.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = DVCACTUALKNOCKS.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND DVCACTUALKNOCKS.teamname IS NULL))
         AND ALL_DATES_TURFS.date = DVCACTUALKNOCKS.date)

------------------------
--'Signed General CTV'
LEFT JOIN
    (
      --6 ) Commit to Vote Cards - ​people who’ve had the Activist Code “Signed General CTV”, who have a MyVoters
      -- profile, attributed by response to “Collected By:” Survey Question,
      select
        ac.datecreated::date as date
        ,t.regionid
        ,t.regionname
        ,t.foid
        ,t.foname
        ,t.teamid
        ,t.teamname
        ,count(ac.mycampaignid) as SIGNED_CTV

from
  VANSYNC_IL_GOV_2018.zz_mycampaign_activistcodes as ac
  LEFT JOIN vansync_il_gov_2018.zz_mycampaign_collected_by_attribution as t
    ON ac.MYCAMPAIGNID=t.MYCAMPAIGNID
  where ACTIVISTCODENAME = 'Signed General CTV'
    and ac.vanid is not null and t.foid is not null
group by t.regionid
  ,t.regionname
  ,t.foid
  ,t.foname
  ,t.teamid
  ,t.teamname
  ,ac.datecreated::date
      ) AS SIGNED_CTV
    ON (ALL_DATES_TURFS.regionid = SIGNED_CTV.regionid
         AND ALL_DATES_TURFS.regionname = SIGNED_CTV.regionname
         AND ALL_DATES_TURFS.foid = SIGNED_CTV.foid
         AND ALL_DATES_TURFS.foname = SIGNED_CTV.foname
         AND (ALL_DATES_TURFS.teamid = SIGNED_CTV.teamid  OR (ALL_DATES_TURFS.teamid IS NULL AND SIGNED_CTV.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = SIGNED_CTV.teamname  OR (ALL_DATES_TURFS.teamname IS NULL AND SIGNED_CTV.teamname IS NULL))
         AND ALL_DATES_TURFS.date = SIGNED_CTV.date)
LEFT JOIN
  (
      ---5 ) Small Businesses Supporting - ​(Not statewide - only by CO FOs)​ - The number of people who meet both of
      -- the following criteria, attributed by “Collected by:” SQ
      -- ●Marked with the “Confirmed Support” responses to the “Small Biz Support” Survey Question
      -- ●Marked with at least one response to the “Small Biz Action” Survey Question
      select a.date
        ,t.regionid
        ,t.regionname
        ,t.foid
        ,t.foname
        ,t.teamid
        ,t.teamname
        ,count(a.mycampaignid) as SMALL_BUSINESS_SUPPORTING
    from
    (
      ---date is pulling from the 'Small Biz Support' SQ datecanvassed
      ---myc id is distinct here since this metric requires both 'Small Biz Support'
        --_AND at least one action. This is not going to count repeat actions
        --this could be changed to not be distinct on action and then left join to confirmed support
        --but I'm not sure that's what you want
      select  distinct mycampaignid, datecanvassed::date as date
      from VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_SURVEYQUESTIONRESPONSES
      where SURVEYQUESTIONLONGNAME = 'Small Biz Support'
        and surveyresponsename = 'Confirmed Support'
        and most_recent_response=true
    ) as a
    left join
    (
      select  distinct mycampaignid
      from VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_SURVEYQUESTIONRESPONSES
      where SURVEYQUESTIONLONGNAME = 'Small Biz Action'
        and most_recent_response=true
    ) as b
      ON a.mycampaignid = b.mycampaignid
    LEFT JOIN vansync_il_gov_2018.zz_mycampaign_collected_by_attribution as t
        ON a.MYCAMPAIGNID=t.MYCAMPAIGNID
    GROUP BY a.date
        ,t.regionid
        ,t.regionname
        ,t.foid
        ,t.foname
        ,t.teamid
        ,t.teamname
    ) AS SMALL_BUSINESS
  ON (ALL_DATES_TURFS.regionid = SMALL_BUSINESS.regionid
         AND ALL_DATES_TURFS.regionname = SMALL_BUSINESS.regionname
         AND ALL_DATES_TURFS.foid = SMALL_BUSINESS.foid
         AND ALL_DATES_TURFS.foname = SMALL_BUSINESS.foname
         AND (ALL_DATES_TURFS.teamid = SMALL_BUSINESS.teamid  OR (ALL_DATES_TURFS.teamid IS NULL AND SMALL_BUSINESS.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = SMALL_BUSINESS.teamname  OR (ALL_DATES_TURFS.teamname IS NULL AND SMALL_BUSINESS.teamname IS NULL))
         AND ALL_DATES_TURFS.date = SMALL_BUSINESS.date)
LEFT JOIN
    (
    select  datecanvassed::date as date
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
      ,count(distinct(mycampaignid)) as DVC_TEAM_MEMBERS_CONFIRMED
    from VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_SURVEYQUESTIONRESPONSES
    where (
            SURVEYQUESTIONLONGNAME = 'DVC Team Leader'
            OR SURVEYQUESTIONLONGNAME = 'DVC PB Captain'
            OR SURVEYQUESTIONLONGNAME = 'DVC Vol Rec Captain'
            OR SURVEYQUESTIONLONGNAME = 'DVC Canvass Captain'
          )
      and surveyresponsename = 'Confirmed'
      and most_recent_response=true
  GROUP BY datecanvassed::date
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
  ) as DVC_CONFIRMED_TEAM
  ON (ALL_DATES_TURFS.regionid = DVC_CONFIRMED_TEAM.regionid
         AND ALL_DATES_TURFS.regionname = DVC_CONFIRMED_TEAM.regionname
         AND ALL_DATES_TURFS.foid = DVC_CONFIRMED_TEAM.foid
         AND ALL_DATES_TURFS.foname = DVC_CONFIRMED_TEAM.foname
         AND (ALL_DATES_TURFS.teamid = DVC_CONFIRMED_TEAM.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND DVC_CONFIRMED_TEAM.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = DVC_CONFIRMED_TEAM.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND DVC_CONFIRMED_TEAM.teamname IS NULL))
         AND ALL_DATES_TURFS.date = DVC_CONFIRMED_TEAM.date)
LEFT JOIN
  (
  select  datecanvassed::date as date
    ,regionid
    ,regionname
    ,foid
    ,foname
    ,teamid
    ,teamname
    ,count(distinct(mycampaignid)) as DVC_TEAM_MEMBERS_PROSPECT
    from VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_SURVEYQUESTIONRESPONSES
    where (
            SURVEYQUESTIONLONGNAME = 'DVC Team Leader'
            OR SURVEYQUESTIONLONGNAME = 'DVC PB Captain'
            OR SURVEYQUESTIONLONGNAME = 'DVC Vol Rec Captain'
            OR SURVEYQUESTIONLONGNAME = 'DVC Canvass Captain'
          )
      and surveyresponsename = 'Prospect'
      and most_recent_response=true
  GROUP BY datecanvassed::date
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
  ) as DVC_PROSPECT_TEAM
  ON (ALL_DATES_TURFS.regionid = DVC_PROSPECT_TEAM.regionid
         AND ALL_DATES_TURFS.regionname = DVC_PROSPECT_TEAM.regionname
         AND ALL_DATES_TURFS.foid = DVC_PROSPECT_TEAM.foid
         AND ALL_DATES_TURFS.foname = DVC_PROSPECT_TEAM.foname
         AND (ALL_DATES_TURFS.teamid = DVC_PROSPECT_TEAM.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND DVC_PROSPECT_TEAM.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = DVC_PROSPECT_TEAM.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND DVC_PROSPECT_TEAM.teamname IS NULL))
         AND ALL_DATES_TURFS.date = DVC_PROSPECT_TEAM.date)
LEFT JOIN
  (
  select  datecanvassed::date as date
    ,regionid
    ,regionname
    ,foid
    ,foname
    ,teamid
    ,teamname
    ,count(distinct(mycampaignid)) as DVC_TEAM_MEMBERS_TEST
    from VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_SURVEYQUESTIONRESPONSES
    where (
            SURVEYQUESTIONLONGNAME = 'DVC Team Leader'
            OR SURVEYQUESTIONLONGNAME = 'DVC PB Captain'
            OR SURVEYQUESTIONLONGNAME = 'DVC Vol Rec Captain'
            OR SURVEYQUESTIONLONGNAME = 'DVC Canvass Captain'
          )
      and (surveyresponsename = 'Test 1' or surveyresponsename = 'Test 2')
      and most_recent_response=true
  GROUP BY datecanvassed::date
      ,regionid
      ,regionname
      ,foid
      ,foname
      ,teamid
      ,teamname
  ) as DVC_TEST_TEAM
  ON (ALL_DATES_TURFS.regionid = DVC_TEST_TEAM.regionid
         AND ALL_DATES_TURFS.regionname = DVC_TEST_TEAM.regionname
         AND ALL_DATES_TURFS.foid = DVC_TEST_TEAM.foid
         AND ALL_DATES_TURFS.foname = DVC_TEST_TEAM.foname
         AND (ALL_DATES_TURFS.teamid = DVC_TEST_TEAM.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND DVC_TEST_TEAM.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = DVC_TEST_TEAM.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND DVC_TEST_TEAM.teamname IS NULL))
         AND ALL_DATES_TURFS.date = DVC_TEST_TEAM.date)
LEFT JOIN
  (
  select
    A.DATE
    , T.REGIONID
    , T.REGIONNAME
    , T.FOID
    , T.FONAME
    , T.TEAMID
    , T.TEAMNAME
    , count(A.MYCAMPAIGNID) as CO_TEAM_MEMBERS_CONFIRMED
  from
    (
      select distinct
        MYCAMPAIGNID
        , DATECANVASSED :: DATE as DATE
      from VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_SURVEYQUESTIONRESPONSES
      where (
              SURVEYQUESTIONLONGNAME = 'CO Team Leader'
              or SURVEYQUESTIONLONGNAME = 'CO PB Captain'
              or SURVEYQUESTIONLONGNAME = 'CO Outreach Captain'
              or SURVEYQUESTIONLONGNAME = 'CO SB Captain'
            )
            and SURVEYRESPONSENAME = 'Confirmed'
            and MOST_RECENT_RESPONSE = true
    ) as A
    left join VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_COLLECTED_BY_ATTRIBUTION as T
      on A.MYCAMPAIGNID = T.MYCAMPAIGNID
  group by A.DATE
    , T.REGIONID
    , T.REGIONNAME
    , T.FOID
    , T.FONAME
    , T.TEAMID
    , T.TEAMNAME
)
as CO_CONFIRMED_TEAM
  ON (ALL_DATES_TURFS.regionid = CO_CONFIRMED_TEAM.regionid
         AND ALL_DATES_TURFS.regionname = CO_CONFIRMED_TEAM.regionname
         AND ALL_DATES_TURFS.foid = CO_CONFIRMED_TEAM.foid
         AND ALL_DATES_TURFS.foname = CO_CONFIRMED_TEAM.foname
         AND (ALL_DATES_TURFS.teamid = CO_CONFIRMED_TEAM.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND CO_CONFIRMED_TEAM.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = CO_CONFIRMED_TEAM.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND CO_CONFIRMED_TEAM.teamname IS NULL))
         AND ALL_DATES_TURFS.date = CO_CONFIRMED_TEAM.date)
LEFT JOIN
  (
  select
    A.DATE
    , T.REGIONID
    , T.REGIONNAME
    , T.FOID
    , T.FONAME
    , T.TEAMID
    , T.TEAMNAME
    , count(A.MYCAMPAIGNID) as CO_TEAM_MEMBERS_PROSPECT
  from
    (
      select distinct
        MYCAMPAIGNID
        , DATECANVASSED :: DATE as DATE
      from VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_SURVEYQUESTIONRESPONSES
      where (
              SURVEYQUESTIONLONGNAME = 'CO Team Leader'
              or SURVEYQUESTIONLONGNAME = 'CO PB Captain'
              or SURVEYQUESTIONLONGNAME = 'CO Outreach Captain'
              or SURVEYQUESTIONLONGNAME = 'CO SB Captain'
            )
            and SURVEYRESPONSENAME = 'Prospect'
            and MOST_RECENT_RESPONSE = true
    ) as A
    left join VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_COLLECTED_BY_ATTRIBUTION as T
      on A.MYCAMPAIGNID = T.MYCAMPAIGNID
  group by A.DATE
    , T.REGIONID
    , T.REGIONNAME
    , T.FOID
    , T.FONAME
    , T.TEAMID
    , T.TEAMNAME
)
as CO_PROSPECT_TEAM
  ON (ALL_DATES_TURFS.regionid = CO_PROSPECT_TEAM.regionid
         AND ALL_DATES_TURFS.regionname = CO_PROSPECT_TEAM.regionname
         AND ALL_DATES_TURFS.foid = CO_PROSPECT_TEAM.foid
         AND ALL_DATES_TURFS.foname = CO_PROSPECT_TEAM.foname
         AND (ALL_DATES_TURFS.teamid = CO_PROSPECT_TEAM.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND CO_PROSPECT_TEAM.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = CO_PROSPECT_TEAM.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND CO_PROSPECT_TEAM.teamname IS NULL))
         AND ALL_DATES_TURFS.date = CO_PROSPECT_TEAM.date)
LEFT JOIN
  (
  select
    A.DATE
    , T.REGIONID
    , T.REGIONNAME
    , T.FOID
    , T.FONAME
    , T.TEAMID
    , T.TEAMNAME
    , count(A.MYCAMPAIGNID) as CO_TEAM_MEMBERS_TEST
  from
    (
      select distinct
        MYCAMPAIGNID
        , DATECANVASSED :: DATE as DATE
      from VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_SURVEYQUESTIONRESPONSES
      where (
              SURVEYQUESTIONLONGNAME = 'CO Team Leader'
              or SURVEYQUESTIONLONGNAME = 'CO PB Captain'
              or SURVEYQUESTIONLONGNAME = 'CO Outreach Captain'
              or SURVEYQUESTIONLONGNAME = 'CO SB Captain'
            )
            and (SURVEYRESPONSENAME = 'Test 1' OR SURVEYRESPONSENAME = 'Test 2')
            and MOST_RECENT_RESPONSE = true
    ) as A
    left join VANSYNC_IL_GOV_2018.ZZ_MYCAMPAIGN_COLLECTED_BY_ATTRIBUTION as T
      on A.MYCAMPAIGNID = T.MYCAMPAIGNID
  group by A.DATE
    , T.REGIONID
    , T.REGIONNAME
    , T.FOID
    , T.FONAME
    , T.TEAMID
    , T.TEAMNAME
)
as CO_TEST_TEAM
  ON (ALL_DATES_TURFS.regionid = CO_TEST_TEAM.regionid
         AND ALL_DATES_TURFS.regionname = CO_TEST_TEAM.regionname
         AND ALL_DATES_TURFS.foid = CO_TEST_TEAM.foid
         AND ALL_DATES_TURFS.foname = CO_TEST_TEAM.foname
         AND (ALL_DATES_TURFS.teamid = CO_TEST_TEAM.teamid OR (ALL_DATES_TURFS.teamid IS NULL AND CO_TEST_TEAM.teamid IS NULL))
         AND (ALL_DATES_TURFS.teamname = CO_TEST_TEAM.teamname OR (ALL_DATES_TURFS.teamname IS NULL AND CO_TEST_TEAM.teamname IS NULL))
         AND ALL_DATES_TURFS.date = CO_TEST_TEAM.date)
LEFT JOIN
  (

  -----NONE OF THESE DAYS SHOULD BE ADDED TOGETHER TO GET COUNTS FOR A PARTICULAR WEEK.
  ----- YOU SHOULD TO WITH THE #s FOR TODAY
  select
    all_dates_turfs.date
    ,all_dates_turfs.regionid
    ,all_dates_turfs.regionname
    ,all_dates_turfs.foid
    ,all_dates_turfs.foname
    ,all_dates_turfs.teamid
    ,all_dates_turfs.teamname
    -- 7 ) Active Vols  - ​Completed 1 action shift in the las
    -- t 28 days (Phone Bank, DVC Canvass, Small Biz Canvass, Outreach Event), roles: Canvasser, MyC Phone Banker,
    -- MyV Phone Banker, attributed by “Pritzker Effective Organizer”
    --THIS SHOULD BE PULLED INTO A REPORT FOR TODAYS DATE
    ,count(DISTINCT CASE
             WHEN (EVENTSTATUS_LAST = 'Completed' AND EVENT_DATE >= (DATE - INTERVAL '28 days') AND
                   EVENT_DATE <= DATE
             )
               THEN MYCAMPAIGNID ELSE NULL END)
                 AS ACTIVE_PAST_28_DAYS
    -- ○At Risk of Dropping = Number of actives dropping in the next 7 days aka number of soon-to-be
    -- inactives not scheduled in the next 7 days, attributed by “Pritzker Effective Organizer”
    ,count(DISTINCT CASE
             WHEN (
                  (EVENTSTATUS_LAST = 'Completed' AND EVENT_DATE >= (DATE - INTERVAL '28 days')
                   AND EVENT_DATE < (DATE - INTERVAL '21 days') AND
                   EVENT_DATE <= DATE)
               AND
                  (NOT ((EVENTSTATUS_LAST = 'Scheduled' OR EVENTSTATUS_LAST = 'Confirmed' OR EVENTSTATUS_LAST = 'Confirmed Twice')
                   AND EVENT_DATE >= (DATE)
                   AND EVENT_DATE < (DATE + INTERVAL '7 days') AND
                   EVENT_DATE >= DATE))
             )
               THEN MYCAMPAIGNID ELSE NULL END)
                 AS ACTIVE_PAST_28_DAYS_WILL_DROP_IN_7
     -- ○Number of non-actives scheduled this week - inactives + never actives = non-actives, attributed
    -- by “Pritzker Effective Organizer”
    ,count(DISTINCT CASE
             WHEN (
                  (NOT(EVENTSTATUS_LAST = 'Completed' AND EVENT_DATE >= (DATE - INTERVAL '28 days') AND
                   EVENT_DATE <= DATE))
                  AND
                    (
                    (
                      EVENTSTATUS_LAST = 'Scheduled'
                    OR EVENTSTATUS_LAST = 'Confirmed'
                    OR EVENTSTATUS_LAST = 'Confirmed Twice'
                    OR EVENTSTATUS_LAST = 'Left Message'
                    )
                    AND EVENT_DATE >= (DATE_TRUNC('week', DATE))
                    AND EVENT_DATE <= ((DATE_TRUNC('week', DATE))+7)
                    AND
                   EVENT_DATE >= DATE
                  )
                  )
               THEN MYCAMPAIGNID ELSE NULL END)
                 AS NONACTIVES_SCHEDULED_THIS_WEEK
  from
  (
    select * from
    (
      SELECT column_0::date as date from VANSYNC_IL_GOV_2018.all_dates_general
    ) as dates
    cross JOIN
    (
      select * from
        (
          (
            select
              REGIONID
              , REGIONNAME
              , FOID
              , FONAME
              , TEAMID
              , TEAMNAME
            from
              VANSYNC_IL_GOV_2018.DNC_TURF
            group by
              REGIONID
              , REGIONNAME
              , FOID
              , FONAME
              , TEAMID
              , TEAMNAME
          )

        )

    ) as turfs
  ) as all_dates_turfs
  LEFT JOIN
  (
  select
      event_date
    , eventname
    , mycampaignid
    , eventstatus_last
    , regionid
    , regionname
    , foid
    , foname
    , teamid
    , teamname
  from VANSYNC_IL_GOV_2018.zz_mycampaign_events_individual_shifts
  where (eventname='DVC Canvass'
        or eventname='Phone Bank'
        or eventname='Outreach Event'
        or eventname='Small Biz Canvass'
        )
  ) as all_myc_action
  ON (
      all_myc_action.regionid = all_dates_turfs.regionid
      AND all_myc_action.regionname = all_dates_turfs.regionname
      AND all_myc_action.foid = all_dates_turfs.foid
      AND all_myc_action.foname = all_dates_turfs.foname
      AND all_myc_action.teamid = all_dates_turfs.teamid
      AND all_myc_action.teamname = all_dates_turfs.teamname
     )
  group by
    all_dates_turfs.date
    ,all_dates_turfs.regionid
    ,all_dates_turfs.regionname
    ,all_dates_turfs.foid
    ,all_dates_turfs.foname
    ,all_dates_turfs.teamid
    ,all_dates_turfs.teamname
    ) AS ACTIVES
  ON (ALL_DATES_TURFS.regionid = ACTIVES.regionid
         AND ALL_DATES_TURFS.regionname = ACTIVES.regionname
         AND ALL_DATES_TURFS.foid = ACTIVES.foid
         AND ALL_DATES_TURFS.foname = ACTIVES.foname
         AND ALL_DATES_TURFS.teamid = ACTIVES.teamid
         AND ALL_DATES_TURFS.teamname = ACTIVES.teamname
         AND ALL_DATES_TURFS.date = ACTIVES.date)


-------WHERE
--where ALL_DATES_TURFS.TEAMID is null
--where SIGNED_CTV.SIGNED_CTV is not null
;





--





-- eventname
-- DVC Canvass
-- Phone Bank
-- Community Event
-- GOTV
-- Office
-- Training
-- Small Biz Canvass
-- 1-on-1
-- Organizing Event
-- Outreach Event
-- Petitioning
-- Candidate Event
-- Primary PB -Archived




-- 8 ) Team Members Confirmed ​- The number of people with the Survey Response “Confirmed” to the Team
-- Member Survey Questions. CO organizers will only get credit for using the CO Survey Questions, and DVC
-- organizers will only get credit for using the DVC Survey Questions. SQs are as follows:
--
-- DVC
-- ●Team Leader
-- ●Phone Bank Captain
-- ●Volunteer Recruitment Captain
-- ●Canvass Captain
--
-- CO
-- ●Team Leader
-- ●Outreach Captain
-- ●Small Business Captain
-- ●Phone Bank Captain
--
-- ●Additional info
-- ○Team Member Prospects - the number of people with the Survey Response “Prospect” to any of
-- the Survey Questions above
-- ○Team Members in Testing - the number of people with the Survey Response “Test 1” or “Test 2”
-- to any of the Survey Questions above









-- 'Small Biz Action'
-- 'Small Biz Support'
--
-- 'DVC Canvass Captain'
-- 'DVC PB Captain'
-- 'DVC Team Leader'
--
-- 'CO Additional Captns'
-- 'CO PB Captain'
-- 'CO Team Leader'







