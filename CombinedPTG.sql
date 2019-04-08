Select
effective.regionname
,effective.foname
,sum((select count(*)
from dnc_contactscontacts_myc cc
left join contacttypecodes ctype on ctype.contacttypeid = cc.contacttypeid 
where ctype.description ilike 'phone'
and (date_trunc('week',(cc.datecanvassed::date)) = date_trunc('week',(current_date - interval '1 day')))
and cc.vanid = effective.vanid
)
) 
RecruitmentCallsCompletedThisWeek
,sum(
(select count(distinct vanid)
from
	(Select csr.vanid
     	,csr.surveyquestionid
     	,answers.surveyresponsename answername
     	,row_number () over (partition by csr.vanid, csr.surveyquestionid
                             order by csr.datecanvassed desc) answer_order
     From vansync_il_gov_2018.dnc_contactssurveyresponses_myc csr
     join vansync_il_gov_2018.dnc_surveyresponses answers
     on csr.surveyquestionid = answers.surveyquestionid 
     and csr.surveyresponseid = answers.surveyresponseid
    join vansync_il_gov_2018.dnc_surveyquestions questions
     on answers.surveyquestionid = questions.surveyquestionid 
     where ((surveyquestionname ilike 'co %') 
     and (surveyquestionname ilike '%captain%' or surveyquestionname ilike '%leader%'))				
        ) recent_survey
where recent_survey.answer_order = 1 and 
  recent_survey.answername ilike '%confirmed%' and recent_survey.vanid = effective.vanid
  )
  ) COTeam_members_confirmed
,sum(
(select count(distinct vanid)
from
	(Select csr.vanid
     	,csr.surveyquestionid
     	,answers.surveyresponsename answername
     	,row_number () over (partition by csr.vanid, csr.surveyquestionid
                             order by csr.datecanvassed desc) answer_order
     From vansync_il_gov_2018.dnc_contactssurveyresponses_myc csr
     join vansync_il_gov_2018.dnc_surveyresponses answers
     on csr.surveyquestionid = answers.surveyquestionid 
     and csr.surveyresponseid = answers.surveyresponseid
    join vansync_il_gov_2018.dnc_surveyquestions questions
     on answers.surveyquestionid = questions.surveyquestionid 
     where ((surveyquestionname ilike 'dvc %'
     ) 
     and (surveyquestionname ilike '%captain%' or surveyquestionname ilike '%leader%'))					
        ) recent_survey
where recent_survey.answer_order = 1 and 
  recent_survey.answername ilike '%confirmed%' and recent_survey.vanid = effective.vanid
  )
  ) DVCTeam_members_confirmed
from 
dnc_activityregions effective
group by 1,2
order by 1,2;

select
recent_survey.vanid
,case when recent_survey.surveyquestionname ilike 'co %' then 'CO Team' else
	when recent_survey.surveyquestionname ilike 'dvc %' then 'DVC Team' else
	when recent_survey.surveyquestionname ilike '%jb summer fellow%' then 'Summer Fellow' else null
from
	(Select csr.vanid
     	,questions.surveyquestionname
     	,answers.surveyresponsename answername
     	,row_number () over (partition by csr.vanid, questions.surveyquestionname
                             order by csr.datecanvassed desc) answer_order
     From vansync_il_gov_2018.dnc_contactssurveyresponses_myc csr
     join vansync_il_gov_2018.dnc_surveyresponses answers
     on csr.surveyquestionid = answers.surveyquestionid 
     and csr.surveyresponseid = answers.surveyresponseid
    join vansync_il_gov_2018.dnc_surveyquestions questions
     on answers.surveyquestionid = questions.surveyquestionid 
     where ((surveyquestionname ilike 'co %') 
     and (surveyquestionname ilike '%captain%' or surveyquestionname ilike '%leader%'))				
        ) recent_survey
where recent_survey.answer_order = 1 and 
  recent_survey.answername ilike '%confirmed%'