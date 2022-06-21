---------- Algorithm ----------

----- Create request data from course request, course request history and special permission tables
----- Group this data by semester, person, and course requested 
----- For a list of repetitive requests of the same course from one student, create five checkpoints for this list
----- Put this list into a unique category (decision tree is: "Special Permission Request", if not then "Top Two Priority And Primary", if not then "Top Two Priority And Alternate", if not then "Remaining Priority And Primary", if not then "Remaining Priority And Alternate") based on checkpoints
----- Doing so makes course request become unique
----- Join this newly created request data with course offering data
----- Group the whole thing by course offering data 
----- Count different types of request

select (select semester_text from xxreg_semestercontrol sc where sysdate between sc.date_from and sc.date_to and sc.semester_code = crs.semester_code and rownum = 1) semester, crs.program_code, crs.course_number, min(crs.section_count) section_count, 
min(crs.enrolled) enrolled, min(crs.enrollment_limit) enrollment_limit,
count(rqst.course_request_category) unique_request,
sum(case when rqst.course_request_category like '%Primary Choice%' then 1 else 0 end) primary_request,
sum(case when rqst.course_request_category like '%Alternate Choice%' then 1 else 0 end) alternate_request,
sum(case when rqst.course_request_category = 'Special Permission' then 1 else 0 end) special_permission_request,
sum(case when rqst.course_request_category = 'Top Two Priority, Primary Choice' then 1 else 0 end) top_two_priority_and_primary,
sum(case when rqst.course_request_category = 'Top Two Priority, Alternate Choice' then 1 else 0 end) top_two_priority_and_alternate,
sum(case when rqst.course_request_category = 'Remaining Priority, Primary Choice' then 1 else 0 end) remaining_priority_and_primary,
sum(case when rqst.course_request_category = 'Remaining Priority, Alternate Choice' then 1 else 0 end) remaining_priority_and_alternate

from (select semester_code, program_code, course_number, count(course_number_section) section_count,
sum(number_currently_enrolled) enrolled, sum(final_enrollment_limit) enrollment_limit
from xxreg_courseoffering 
where substr(course_number_section,4,1) <> 'L'
and program_code <> 'ARMY' and program_code <> 'A S'
and semester_code = [Term==menu::xxapps::select semester_code,semester_text from xxreg_semestercontrol where sysdate between date_from and date_to and semester_code in (select distinct semester_code from xxreg_courseoffering) order by semester_code desc]

group by semester_code, program_code, course_number) crs

left join 
-- determine types of request by putting them into unique category based on a decision tree
(select semester_code, person_id, program_code, course_number, case when is_special_permission = 'Y' then 'Special Permission'
when is_special_permission = 'N' and is_top_two_priority_and_primary = 'Y' then 'Top Two Priority, Primary Choice'
when is_special_permission = 'N' and is_top_two_priority_and_primary = 'N' and is_top_two_priority_and_alternate = 'Y' then 'Top Two Priority, Alternate Choice'
when is_special_permission = 'N' and is_top_two_priority_and_primary = 'N' and is_top_two_priority_and_alternate = 'N' and is_remaining_priority_and_primary = 'Y' then 'Remaining Priority, Primary Choice'
when is_special_permission = 'N' and is_top_two_priority_and_primary = 'N' and is_top_two_priority_and_alternate = 'N' and is_remaining_priority_and_primary = 'N' and is_remaining_priority_and_alternate = 'Y' then 'Remaining Priority, Alternate Choice'
end as course_request_category

-- for a list of repetitive requests of the same course from one student, create five checkpoints for this list
from (select semester_code, person_id, program_code, course_number, listagg(priority||alternate_code,','),
case when instr(listagg(priority||alternate_code,','),'1*') > 0 or instr(listagg(priority||alternate_code,','),'2*') > 0 
then 'Y' else 'N'
end as is_top_two_priority_and_primary,
case when (instr(listagg(priority),'1') > 0 or instr(listagg(priority),'2') > 0) and (instr(listagg(priority||alternate_code,','),'1*') = 0 and instr(listagg(priority||alternate_code,','),'2*') = 0)
then 'Y' else 'N'
end as is_top_two_priority_and_alternate,
case when instr(listagg(priority||alternate_code,','),'3*') > 0 or instr(listagg(priority||alternate_code,','),'4*') > 0 or instr(listagg(priority||alternate_code,','),'5*') > 0 or instr(listagg(priority||alternate_code,','),'6*') > 0 or instr(listagg(priority||alternate_code,','),'7*') > 0 or instr(listagg(priority||alternate_code,','),'8*') > 0 or instr(listagg(priority||alternate_code,','),'9*') > 0 or instr(listagg(priority||alternate_code,','),'10*') > 0 or instr(listagg(priority||alternate_code,','),'11*') > 0 or instr(listagg(priority||alternate_code,','),'12*') > 0
then 'Y' else 'N'
end as is_remaining_priority_and_primary,
case when (instr(listagg(priority),'3') > 0 or instr(listagg(priority),'4') > 0 or  instr(listagg(priority),'5') > 0 or instr(listagg(priority),'6') > 0 or instr(listagg(priority),'7') > 0 or instr(listagg(priority),'8') > 0 or instr(listagg(priority),'9') > 0 or instr(listagg(priority),'10') > 0 or instr(listagg(priority),'11') > 0 and instr(listagg(priority),'12') > 0) and (instr(listagg(priority||alternate_code,','),'3*') = 0 or instr(listagg(priority||alternate_code,','),'4*') = 0 or instr(listagg(priority||alternate_code,','),'5*') = 0 and instr(listagg(priority||alternate_code,','),'6*') = 0 and instr(listagg(priority||alternate_code,','),'7*') = 0 and instr(listagg(priority||alternate_code,','),'8*') = 0 and instr(listagg(priority||alternate_code,','),'9*') = 0 and instr(listagg(priority||alternate_code,','),'10*') = 0 and instr(listagg(priority||alternate_code,','),'11*') = 0 and instr(listagg(priority||alternate_code,','),'12*') = 0)
then 'Y' else 'N'
end as is_remaining_priority_and_alternate,
case when instr(listagg(priority),0) > 0 
then 'Y' else 'N'
end as is_special_permission

-- students' requests from course request, course request history and special permission tables 
from (select person_id, o1.program_code, o1.course_number, priority, nvl(alternate_code,'*') alternate_code, r1.semester_code
from xxcs_courserequest_h r1
left join xxreg_courseoffering o1
on r1.courseoffering_id = o1.courseoffering_id
union
select person_id, o2.program_code, o2.course_number, priority, nvl(alternate_code,'*') alternate_code,
case when substr((select max(semester_code) from xxcs_courserequest_h),9,2) = 20 then to_number(substr((select max(semester_code) from xxcs_courserequest_h),1,8)||40)
when substr((select max(semester_code) from xxcs_courserequest_h),9,2) = 40 then to_number(substr((select max(semester_code) from xxcs_courserequest_h),1,4)+1||substr((select max(semester_code) from xxcs_courserequest_h),5,4)+1||20)
end as semester_code
from xxcs_courserequest r2
left join xxreg_courseoffering o2
on r2.courseoffering_id = o2.courseoffering_id
union
select p.person_id, o.program_code, o.course_number, 0 priority, 'Special Permission' alternate_code, o.semester_code
from xxreg_coursespecialperm p
left join xxreg_courseoffering o
on p.courseoffering_id = o.courseoffering_id) 
group by semester_code, person_id, program_code, course_number)) rqst

on crs.semester_code = rqst.semester_code
and crs.program_code||crs.course_number = rqst.program_code||rqst.course_number
and rqst.semester_code = [Term==menu::xxapps::select semester_code,semester_text from xxreg_semestercontrol where sysdate between date_from and date_to and semester_code in (select distinct semester_code from xxreg_courseoffering) order by semester_code desc]

group by crs.semester_code, crs.program_code, crs.course_number

order by program_code asc, course_number asc