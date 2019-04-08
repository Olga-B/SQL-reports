select
'R'||trim(to_char(effective.regionname,'00')) region
--,effective.foname org_code
,signups.datetimeoffsetbegin::date event_date
,eventstatuscodes.eventstatusname current_status
,count(signups.eventsignupid)
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
and roles.eventcalendarid = events.eventcalendarid 
--and roles.eventrolename in ('Canvasser', 'Dialer','Phone')
and roles.eventcalendarname in ('DVC Canvass','Outreach Event','Phone Bank','Small Biz Canvass'))
where /*eventstatuscodes.eventstatusname in ('Confirmed', 'Scheduled','Left Message','Confirmed Twice')
and  */events.dateoffsetbegin::date in ('2018-08-25', '2018-08-26')
and signups.datesuppressed is null
group by 1,2,3
order by 1,2
;

select 
effective.foname
,count(case when eventtype.eventcalendarname = 'DVC Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-25' and reported.statusdate = '2018-08-25' and eventstatuscodes.eventstatusname = 'Completed' then signups.eventsignupid else null end) as "DVC Canvass Shifts Completed and Entered Saturday"
,count(case when eventtype.eventcalendarname = 'DVC Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-26' and reported.statusdate = '2018-08-26' and eventstatuscodes.eventstatusname = 'Completed' then signups.eventsignupid else null end) as "DVC Canvass Shifts Completed and Entered Sunday"
,count(case when eventtype.eventcalendarname = 'Small Biz Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-25' and reported.statusdate = '2018-08-25' and eventstatuscodes.eventstatusname = 'Completed' then signups.eventsignupid else null end) as "SB Shifts Completed and Entered Saturday"
,count(case when eventtype.eventcalendarname = 'Small Biz Canvass' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-26' and reported.statusdate = '2018-08-26' and eventstatuscodes.eventstatusname = 'Completed' then signups.eventsignupid else null end) as "SB Shifts Completed and Entered Sunday"
,(select count(distinct case when biz_support ilike '%confirm%' and biz_action is not null and biz_support_date = '2018-08-25' then vanid else null end) biz
from jb4gov.CTV_Biz_CB
where collected_orgcode = effective.foname) as "SB IDed Saturday"
,(select count(distinct case when biz_support ilike '%confirm%' and biz_action is not null and biz_support_date = '2018-08-26' then vanid else null end) biz
from jb4gov.CTV_Biz_CB
where collected_orgcode = effective.foname) as "SB IDed Sunday"
,count(case when eventtype.eventcalendarname = 'Outreach Event' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-25' and reported.statusdate = '2018-08-25' and eventstatuscodes.eventstatusname = 'Completed' then signups.eventsignupid else null end) as "Outreach Canvass Shifts Completed and Entered Saturday"
,count(case when eventtype.eventcalendarname = 'Outreach Event' and roles.eventrolename = 'Canvasser' and events.dateoffsetbegin::date = '2018-08-26' and reported.statusdate = '2018-08-26' and eventstatuscodes.eventstatusname = 'Completed' then signups.eventsignupid else null end) as "Outreach Canvass Shifts Completed and Entered Sunday"
,count(case when eventtype.eventcalendarname = 'Phone Bank' and roles.eventrolename = 'Phonebanker' and events.dateoffsetbegin::date = '2018-08-25' and reported.statusdate = '2018-08-25' and eventstatuscodes.eventstatusname = 'Completed' then signups.eventsignupid else null end) as "Phone Bank Shifts Completed and Entered Saturday"
,count(case when eventtype.eventcalendarname = 'Phone Bank' and roles.eventrolename = 'Phonebanker' and events.dateoffsetbegin::date = '2018-08-26' and reported.statusdate = '2018-08-26' and eventstatuscodes.eventstatusname = 'Completed' then signups.eventsignupid else null end) as "Phone Bank Shifts Completed and Entered Sunday"
,count(case when eventtype.eventcalendarname = 'Phone Bank' and roles.eventrolename = 'Dialer' and events.dateoffsetbegin::date = '2018-08-25' and reported.statusdate = '2018-08-25' and eventstatuscodes.eventstatusname = 'Completed' then signups.eventsignupid else null end) as "Dialer Shifts Completed and Entered Saturday"
,count(case when eventtype.eventcalendarname = 'Phone Bank' and roles.eventrolename = 'Dialer' and events.dateoffsetbegin::date = '2018-08-26' and reported.statusdate = '2018-08-26' and eventstatuscodes.eventstatusname = 'Completed' then signups.eventsignupid else null end) as "Dialer Shifts Completed and Entered Sunday"
,(select count(distinct case when ctv_date = '2018-08-25' then vanid else null end) ctv from jb4gov.ctv_biz_cb where collected_orgcode - effective.foname) "CTVs entered on Saturday"
,(select count(distinct case when ctv_date = '2018-08-26' then vanid else null end) ctv from jb4gov.ctv_biz_cb where collected_orgcode - effective.foname) "CTVs entered on Sunday"
,count(case when reported.statusdate = '2018-08-25' and eventstatuscodes.eventstatusname = 'Scheduled' then signups.eventsignupid else null end) as "Shifts Scheduled and Entered on Saturday"
,count(case when reported.statusdate = '2018-08-26' and eventstatuscodes.eventstatusname = 'Scheduled' then signups.eventsignupid else null end) as "Shifts Scheduled and Entered on Sunday"
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
and roles.eventrolename in ('Canvasser', 'Dialer','Phonebanker'))
join vansync_il_gov_2018.dnc_eventcalendars eventtype
on (eventtype.eventcalendarid = events.eventcalendarid and eventtype.eventcalendarname in ('DVC Canvass','Outreach Event','Phone Bank','Small Biz Canvass'))
join (select eventsignupid
        ,min(datecreated)::date statusdate from vansync_il_gov_2018.dnc_eventsignupsstatuses
        where exists(select * from vansync_il_gov_2018.eventstatuscodes where eventstatuscodes.eventstatusid = dnc_eventsignupsstatuses.eventstatusid 
        and statecode = 'IL' 
        and eventstatuscodes.eventstatusname in ('Completed','Scheduled'))
        group by 1) reported on reported.eventsignupid = signups.eventsignupid
where /*events.dateoffsetbegin in ('2018-08-25', '2018-08-26')
and */signups.datesuppressed is null
group by 1--,2
order by 1--,2
;