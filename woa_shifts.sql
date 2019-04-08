
--USE ME WOA PTG shifts scheduled -- any vols including team members -- replacing role_types table with separate roles and eventcalendar
select 
effective.foname
,count(case when eventtype.eventcalendarname = 'DVC Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-25' then signups.eventsignupid else null end) as "DVC Canvass Shifts Scheduled Saturday"
,count(case when eventtype.eventcalendarname = 'DVC Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-26' then signups.eventsignupid else null end) as "DVC Canvass Shifts Scheduled Sunday"
,count(case when eventtype.eventcalendarname = 'Small Biz Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-25' then signups.eventsignupid else null end) as "SB Shifts Scheduled Saturday"
,count(case when eventtype.eventcalendarname = 'Small Biz Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-26' then signups.eventsignupid else null end) as "SB Shifts Scheduled Sunday"
,count(case when eventtype.eventcalendarname = 'Phone Bank' and roles.eventrolename = 'Dialer' and events.dateoffsetbegin::date = '2018-08-25' then signups.eventsignupid else null end) as "Dialer Shifts Scheduled Saturday"
,count(case when eventtype.eventcalendarname = 'Phone Bank' and roles.eventrolename = 'Dialer' and events.dateoffsetbegin::date = '2018-08-26' then signups.eventsignupid else null end) as "Dialer Shifts Scheduled Sunday"
,count(case when eventtype.eventcalendarname = 'Outreach Event' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-25' then signups.eventsignupid else null end) as "Outreach Canvass Shifts Scheduled Saturday"
,count(case when eventtype.eventcalendarname = 'Outreach Event' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-26' then signups.eventsignupid else null end) as "Outreach Canvass Shifts Scheduled Sunday"
from
vansync_il_gov_2018.dnc_eventsignups signups 
left join vansync_il_gov_2018.dnc_activityregions effective 
on effective.vanid = signups.vanid
join vansync_il_gov_2018.eventstatuscodes
on (
	exists (
	select * from 
	vansync_il_gov_2018.dnc_eventsignupsstatuses currentstatus
	where currentstatus.eventsignupseventstatusid = signups.currenteventsignupseventstatusid 
	and currentstatus.eventsignupid = signups.eventsignupid
	and currentstatus.statecode = signups.statecode
	and currentstatus.eventstatusid = eventstatuscodes.eventstatusid
	)
	)
join vansync_il_gov_2018.dnc_events events
on (events.eventid = signups.eventid 
and events.statecode = signups.statecode
and events.datesuppressed is null)
join vansync_il_gov_2018.dnc_eventroles roles
on (roles.eventroleid = signups.eventroleid 
and roles.eventrolename in ('Canvasser', 'Dialer'))
join vansync_il_gov_2018.dnc_eventcalendars eventtype
on (eventtype.eventcalendarid = events.eventcalendarid and eventtype.eventcalendarname in ('DVC Canvass','Outreach Event','Phone Bank','Small Biz Canvass'))
where eventstatuscodes.eventstatusname in ('Confirmed', 'Scheduled','Left Message','Confirmed Twice')
and  events.dateoffsetbegin::date in ('2018-08-25', '2018-08-26')
and signups.datesuppressed is null
group by 1--,2
order by 1--,2
;

/* old don't use me --WOA shifts scheduled -- any vols including team members
select 
effective.foname
,count(case when eventtype.eventcalendarname = 'DVC Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-25' then signups.eventsignupid else null end) as "DVC Canvass Shifts Scheduled Saturday"
,count(case when eventtype.eventcalendarname = 'DVC Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-26' then signups.eventsignupid else null end) as "DVC Canvass Shifts Scheduled Sunday"
,count(case when eventtype.eventcalendarname = 'Small Biz Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-25' then signups.eventsignupid else null end) as "SB Shifts Scheduled Saturday"
,count(case when eventtype.eventcalendarname = 'Small Biz Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-26' then signups.eventsignupid else null end) as "SB Shifts Scheduled Sunday"
,count(case when eventtype.eventcalendarname = 'Phone Bank' and roles.eventrolename = 'Dialer' and events.dateoffsetbegin::date = '2018-08-25' then signups.eventsignupid else null end) as "Dialer Shifts Scheduled Saturday"
,count(case when eventtype.eventcalendarname = 'Phone Bank' and roles.eventrolename = 'Dialer' and events.dateoffsetbegin::date = '2018-08-26' then signups.eventsignupid else null end) as "Dialer Shifts Scheduled Sunday"
,count(case when eventtype.eventcalendarname = 'Outreach Event' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-25' then signups.eventsignupid else null end) as "Outreach Canvass Shifts Scheduled Saturday"
,count(case when eventtype.eventcalendarname = 'Outreach Event' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-26' then signups.eventsignupid else null end) as "Outreach Canvass Shifts Scheduled Sunday"
/*effective.foname
,signups.eventsignupid
,signups.vanid
,events.dateoffsetbegin::date event_date
,eventtype.eventcalendarname
,roles.eventrolename
,eventstatuscodes.eventstatusname
from
vansync_il_gov_2018.dnc_eventsignups signups 
left join vansync_il_gov_2018.dnc_activityregions effective 
on effective.vanid = signups.vanid
join vansync_il_gov_2018.eventstatuscodes
on (
	exists (
	select * from 
	vansync_il_gov_2018.dnc_eventsignupsstatuses currentstatus
	where currentstatus.eventsignupseventstatusid = signups.currenteventsignupseventstatusid 
	and currentstatus.eventsignupid = signups.eventsignupid
	and currentstatus.statecode = signups.statecode
	and currentstatus.eventstatusid = eventstatuscodes.eventstatusid
	)
	)
join vansync_il_gov_2018.dnc_events events
on (events.eventid = signups.eventid 
and events.statecode = signups.statecode
and events.datesuppressed is null)
join vansync_il_gov_2018.eventroletypes roles
on (roles.eventroleid = signups.eventroleid 
and eventtype.eventcalendarid = events.eventcalendarid 
and roles.eventrolename in ('Canvasser', 'Dialer')
and eventtype.eventcalendarname in ('DVC Canvass','Outreach Event','Phone Bank','Small Biz Canvass'))
where /*not exists ( --Team Members or fellows
Select *
from
    (Select csr.vanid       
    ,csr.surveyquestionid
    ,answers.surveyresponsename answername
    ,row_number () over (partition by csr.vanid, csr.surveyquestionid
                         order by csr.datecanvassed desc) answer_order
    From vansync_il_gov_2018.dnc_contactssurveyresponses_myc csr    
    join vansync_il_gov_2018.dnc_surveyresponses answers
    on csr.surveyquestionid = answers.surveyquestionid and csr.surveyresponseid = answers.surveyresponseid
    where exists (select * 
                  from vansync_il_gov_2018.dnc_surveyquestions questions
                  where answers.surveyquestionid = questions.surveyquestionid 
                  and (
                       (surveyquestionname ilike 'co %' or surveyquestionname ilike 'dvc %') 
                       --and (surveyquestionname ilike '%captain%' or surveyquestionname ilike '%leader%')
                        or surveyquestionname ilike '%jb summer fellow%')   
                    )
    ) recent_survey
where recent_survey.answer_order = 1 
and (recent_survey.answername ilike '%confirmed%' or recent_survey.answername ilike '%full%' or recent_survey.answername ilike '%part%') 
and recent_survey.vanid = signups.vanid
    )
and eventstatuscodes.eventstatusname in ('Confirmed', 'Scheduled','Left Message','Confirmed Twice')
and  events.dateoffsetbegin::date in ('2018-08-25', '2018-08-26')
and signups.datesuppressed is null
group by 1--,2
order by 1--,2
;