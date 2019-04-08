select 'Region'||to_char(effective.regionname,'00') region
,effective.foname org_code
,team_sqs.vanid
,team_sqs.vol_name
,team_sqs.question
,team_sqs.prospect
,team_sqs.testing_1
,team_sqs.testing_2
,shifts.first_maint1on1_date
,shifts.last_maint1on1_date
,shifts.total_maint1on1
,shifts.last_escalation_date
,team_sqs.confirmed
,shifts.last_action_shift
,shifts.next_action_shift
,shifts.last_host_date
,'awareness' flag
,shifts.as_completed_within29days
,team_sqs.dropped
,team_sqs.changed_role
from
(Select csr.vanid
        ,myc.lastname||', '||myc.firstname vol_name
     	,questions.surveyquestionname question
     	,listagg(case when answers.surveyresponsename ilike '%prospect%' then csr.datecanvassed::date else null end) Prospect
        ,listagg(case when answers.surveyresponsename ilike '%test 1%' then csr.datecanvassed::date else null end) Testing_1
        ,listagg(case when answers.surveyresponsename ilike '%test 2%' then csr.datecanvassed::date else null end) Testing_2
        ,listagg(case when answers.surveyresponsename ilike '%confirm%' then csr.datecanvassed::date else null end) Confirmed
        ,listagg(case when answers.surveyresponsename ilike '%drop%' then csr.datecanvassed::date else null end) Dropped
        ,listagg(case when answers.surveyresponsename ilike '%change%' then csr.datecanvassed::date else null end) Changed_Role
        /*,row_number () over (partition by csr.vanid, questions.surveyquestionname
                             order by csr.datecanvassed desc) answer_order*/
     From vansync_il_gov_2018.dnc_contactssurveyresponses_myc csr
     join vansync_il_gov_2018.dnc_contacts_myc myc on csr.vanid = myc.vanid
     join vansync_il_gov_2018.dnc_surveyresponses answers
     on csr.surveyquestionid = answers.surveyquestionid 
     and csr.surveyresponseid = answers.surveyresponseid
    join vansync_il_gov_2018.dnc_surveyquestions questions
     on answers.surveyquestionid = questions.surveyquestionid 
     where questions.surveyquestionname ilike 'dvc %'
      or questions.surveyquestionname ilike 'co %'
     --or questions.surveyquestionname ilike '%summer fellow%' 				
    group by 1,2,3
       order by 2,3 ) team_sqs
left join vansync_il_gov_2018.dnc_activityregions effective
on effective.vanid = team_sqs.vanid  
left join
(select distinct signups.vanid
,max(case 
        when lower(eventstatuscodes.eventstatusname) in ('completed', 'walk in')
            and roles.eventrolename in ('Canvasser', 'Phonebanker','MyC Phone Banker','Dialer')
        then events.dateoffsetbegin::date else null end) last_action_shift  
,min(case 
        when lower(eventstatuscodes.eventstatusname) in ('confirmed twice', 'confirmed','left message','scheduled')
            and roles.eventrolename in ('Canvasser', 'Phonebanker','MyC Phone Banker','Dialer')
        then events.dateoffsetbegin::date else null end) next_action_shift  
,max(case 
        when lower(eventstatuscodes.eventstatusname) = 'completed'
            and roles.eventrolename ilike '%host%'
        then events.dateoffsetbegin::date else null end) last_host_date 
,min(case 
        when lower(eventstatuscodes.eventstatusname) in ('completed', 'walk in')
            and roles.eventrolename ilike '%maintenance%'
        then events.dateoffsetbegin::date else null end) first_maint1on1_date
,max(case 
        when lower(eventstatuscodes.eventstatusname) in ('completed', 'walk in')
            and roles.eventrolename ilike '%maintenance%'
        then events.dateoffsetbegin::date else null end) last_maint1on1_date   
,count(case 
        when lower(eventstatuscodes.eventstatusname) in ('completed', 'walk in')
            and roles.eventrolename ilike '%maintenance%'
        then signups.eventsignupid else null end) total_maint1on1 
,max(case 
        when lower(eventstatuscodes.eventstatusname) in ('completed', 'walk in')
            and roles.eventrolename ilike '%escalation%'
        then events.dateoffsetbegin::date else null end) last_escalation_date      
,count(distinct case 
                when events.dateoffsetbegin::date > (current_date - interval '29 days')
                and events.dateoffsetbegin::date < current_date 
                and lower(eventstatuscodes.eventstatusname) in ('completed', 'walk in')
                and roles.eventrolename in ('Canvasser', 'Phonebanker','MyC Phone Banker','Dialer')  
                then signups.eventsignupid else null end) as_completed_within29days  
from
vansync_il_gov_2018.dnc_eventsignups signups
join vansync_il_gov_2018.eventstatuscodes
on (
	exists (
	select * from 
	vansync_il_gov_2018.dnc_eventsignupsstatuses
	where dnc_eventsignupsstatuses.eventsignupseventstatusid = signups.currenteventsignupseventstatusid and dnc_eventsignupsstatuses.eventsignupid = signups.eventsignupid
	and vansync_il_gov_2018.dnc_eventsignupsstatuses.statecode = signups.statecode
	and vansync_il_gov_2018.dnc_eventsignupsstatuses.eventstatusid = eventstatuscodes.eventstatusid
	)
	)
join vansync_il_gov_2018.dnc_events events 
on (signups.eventid = events.eventid 
    and signups.statecode = events.statecode
    and events.datesuppressed is null 
    --maybe limit: and events.datetimeoffsetbegin::date > (current_date - interval '29 days')
    )
join vansync_il_gov_2018.dnc_eventroles roles
on (roles.eventroleid = signups.eventroleid 
	--and roles.eventrolename in ('Canvasser', 'Phonebanker','MyC Phone Banker','Dialer')
	)
where signups.datesuppressed is null
group by 1) shifts
on shifts.vanid = team_sqs.vanid;
