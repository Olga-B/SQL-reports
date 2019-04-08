Select
distinct answername
,sum((select count(distinct vanid)
      From 
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
                  and surveyquestionname ilike '%biz%'  
                    )
    ) recent_survey
where recent_survey.answer_order = 1 and recent_survey.vanid = collected.vanid)) SB
,sum((select --count(distinct assignedactivist.vanid)
from vansync_il_gov_2018.dnc_contactsactivistcodes_myc assignedactivist
join vansync_il_gov_2018.activistcodes on assignedactivist.activistcodeid = activistcodes.activistcodeid
join vansync_il_gov_2018.dnc_contacts_myc myc on (myc.vanid = assignedactivist.vanid and myc.votervanid is not null)
where activistcodes.activistcodename = 'Signed General CTV' and assignedactivist.vanid = collected.vanid
and date_trunc('week',(assignedactivist.datecreated::date)) = date_trunc('week',(current_date - interval '1 day')))) CTVs
from
(Select *
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
                  and surveyquestionname ilike '%collected by%'  
                    )
    ) recent_survey
where recent_survey.answer_order = 1) collected
group by 1
order by 1;
--CTVs
select --count(distinct assignedactivist.vanid)
collected.region
,assignedactivist.vanid
,assignedactivist.datecreated
,assignedactivist.
,activistcodes.activistcodename
from vansync_il_gov_2018.dnc_contactsactivistcodes_myc assignedactivist
join vansync_il_gov_2018.activistcodes on assignedactivist.activistcodeid = activistcodes.activistcodeid
join (Select *
from
    (Select csr.vanid       
    ,csr.surveyquestionid
    ,answers.surveyresponsename region
    ,row_number () over (partition by csr.vanid, csr.surveyquestionid
                         order by csr.datecanvassed desc) answer_order
    From vansync_il_gov_2018.dnc_contactssurveyresponses_myc csr    
    join vansync_il_gov_2018.dnc_surveyresponses answers
    on csr.surveyquestionid = answers.surveyquestionid and csr.surveyresponseid = answers.surveyresponseid
    where exists (select * 
                  from vansync_il_gov_2018.dnc_surveyquestions questions
                  where answers.surveyquestionid = questions.surveyquestionid 
                  and surveyquestionname ilike '%collected by%'  
                    )
    ) recent_survey
where recent_survey.answer_order = 1) collected on collected.vanid = assignedactivist.vanid
where activistcodes.activistcodename = 'Signed General CTV' 
and date_trunc('week',(assignedactivist.datecreated::date)) = date_trunc('week',(current_date - interval '1 day'))
and not exists(select * from vansync_il_gov_2018.dnc_contacts_myc myc where myc.vanid = assignedactivist.vanid and myc.votervanid is null )
order by 1