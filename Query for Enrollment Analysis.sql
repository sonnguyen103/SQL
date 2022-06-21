select 
p.entrance_year, p.person_id, p.first_name, p.middle_name, p.last_name, s.sex,  
p.ethnicity_text, 
case
when s.hispanic = 'Yes' then 'Yes'
else 'No or Unrepored'
end as is_hispanic, 
case 
when s.race = 'White' then 'White'
when s.race = 'Asian' then 'Asian'
when s.race = 'Black or African American' then 'Black or African American'
else 'Other Races or Unreported' 
end as race,
p.us_citizen, p.is_dpu_international,
s.birth_city, s.birth_state, s.BIRTH_COUNTRY, s.primary_citizenship, s.citizenship, 
case 
when s.is_first_generation_college = 1 then 'Yes'
else 'No or Unreported'
end as is_first_generation_college,
case 
when s.is_english_a_second_language = 1 then 'Yes'
when s.is_english_a_second_language = 0 then 'No'
else 'Unreported'
end as is_english_a_second_language,
s.academic_interest, s.school_1_institution, s.geomarket, 
SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) region_code,
case
when SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) = 'IN' then 'Indiana'
when SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) = 'IL' then 'Illinois'
when SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) = 'INT' then 'International'
when SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) in ('IA','KS','MI','MN','MO','ND','NE','OH','SD','WI') then 'Midwest (excl. Indiana and Illinois)'
when SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) in ('CT','MA','ME','NH','NJ','NY','PA','RI','VT') then 'Northeast'
when SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) in ('AL','AR','DC','DE','FL','GA','KY','LA','MD','MS','NC','OK','SC','TN','TX','VA','WV') then 'South'
when SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) in ('AK','AZ','CA','CO','HI','ID','MT','NM','NV','OR','UT','WA','WY') then 'West'
else null
end as region,
case 
when SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) = 'IN' then SUBSTR(s.geomarket, INSTR(s.geomarket,' ')+1,LENGTH(s.geomarket))
else null
end as region_detail_indiana,
case
when SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) = 'IL' then SUBSTR(s.geomarket, INSTR(s.geomarket,' ')+1,LENGTH(s.geomarket))
else null
end as region_detail_illinois,
case
when SUBSTR(s.geomarket, 0, INSTR(s.geomarket,'-')-1) = 'INT' then SUBSTR(s.geomarket, INSTR(s.geomarket,' ')+1,LENGTH(s.geomarket))
else null
end as region_detail_international,
s.parent_income,
CASE
when (s.parent_income > 0) and (s.parent_income < 50000) then 'Lower Middle Class < $50k'
when (s.parent_income >= 50000) and (s.parent_income < 150000) then 'Middle Class b/w $50k and $150k'
when (s.parent_income >= 150000) and (s.parent_income < 300000) then 'Upper Middle Class b/w $150k and $300k'
when (s.parent_income >= 300000) then 'Affluent > $300k'
else 'Unreported'
end as economic_status
from xxad_personmaster_v p
join slt_student s 
on p.person_id = s.eservices_id
and sysdate between s.date_from and s.date_to
where p.last_admission_decision_text = 'Admitted'
and p.last_student_decision_text = 'Deposit Paid'
and p.entrance_year in (2016, 2017, 2018, 2019, 2020, 2021)
order by p.entrance_year ASC
