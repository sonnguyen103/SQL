select crd.academic_year, crd.person_id, crd.dept_code, crd.school_code, crd.dept_name, 
crd.faculty_credits_taught, round(crd.faculty_credits_issued/decode(crd.faculty_credits_taught,0,null,crd.faculty_credits_taught),2) actual_credit_weighted_avg_enrollments, crd.faculty_credits_issued,
case when crd.faculty_credits_taught is not null then nvl(tl.teaching_load,3) else null end as assumed_teaching_load, 
exp.expected_avg_enrollments_for_school, 
case when crd.faculty_credits_taught is not null then nvl(tl.teaching_load,3)*exp.expected_avg_enrollments_for_school else null end as expected_credits_issued
from (select academic_year, person_id, min(dept_code) dept_code, min(school_code) school_code, min(dept_name) dept_name, 
sum(credit) faculty_credits_taught, sum(credits_issued) faculty_credits_issued
from (
select substr(c.semester_code,1,8) academic_year, c.courseoffering_id,
c.instructor1_person_id person_id, c.credit, c.faculty_load_credit,
m.dept_code, decode(m.dept_code,'MUS','SOM',null,'No Department And School Matched','CLA') school_code, d.dept_name,
e.number_enrolled, c.credit*e.number_enrolled credits_issued
from xxapm_course_warehouse c

left join (select person_id, min(dept_code) dept_code
from xxapm_department_member_mv
where dept_code not in ('GER','A S','H S','HONR')
group by person_id) m
on c.instructor1_person_id = m.person_id

left join xxapm_department_mv d
on m.dept_code = d.dept_code

left join (select courseoffering_id, count(person_id) number_enrolled 
from xxapm_student_enrollments_mv
group by courseoffering_id) e
on c.courseoffering_id = e.courseoffering_id

order by academic_year desc, dept_code asc, person_id asc, courseoffering_id desc
) 
group by academic_year, person_id) crd

left join (select person_id, date_from, nvl(date_to,to_date('31-DEC-4712')) date_to, teaching_load 
from xxapm_faculty_status_mv) tl
on crd.person_id = tl.person_id 
and (to_date('15-JAN-'||substr(crd.academic_year,5,8)) between tl.date_from and tl.date_to)

left join (select academic_year, school_code, sum(credits_issued) total_credits_issued, sum(credit) total_credits_taught,
round(sum(credits_issued)/decode(sum(credit),0,null,sum(credit)),2) expected_avg_enrollments_for_school
from (
select substr(c.semester_code,1,8) academic_year, c.courseoffering_id,
c.instructor1_person_id person_id, c.credit, c.faculty_load_credit,
m.dept_code, decode(m.dept_code,'MUS','SOM',null,'No Department And School Matched','CLA') school_code, d.dept_name,
e.number_enrolled, c.credit*e.number_enrolled credits_issued
from xxapm_course_warehouse c

left join (select person_id, min(dept_code) dept_code
from xxapm_department_member_mv
where dept_code not in ('GER','A S','H S','HONR')
group by person_id) m
on c.instructor1_person_id = m.person_id

left join xxapm_department_mv d
on m.dept_code = d.dept_code

left join (select courseoffering_id, count(person_id) number_enrolled 
from xxapm_student_enrollments_mv
group by courseoffering_id) e
on c.courseoffering_id = e.courseoffering_id

order by academic_year desc, dept_code asc, person_id asc, courseoffering_id desc
)
group by academic_year, school_code
order by academic_year desc, school_code asc
) exp
on crd.academic_year = exp.academic_year
and crd.school_code = exp.school_code

where crd.school_code <> 'No Department And School Matched'
order by academic_year desc, dept_code asc, person_id asc