-- !preview conn=DBI::dbConnect(RPostgres::Postgres(),dbname = 'postgres',host = 'db.zgqkukklhncxcctlqpvg.supabase.co', port = 5432, user = 'student',password = 'tsci5230')

/*SELECT *
FROM patients
limit 10*/
/*DROP table tv_demographics*/

CREATE table tv_demographics as
SELECT subject_id,--admittime, dischtime, ethnicity,
       COUNT(DISTINCT ethnicity) as ethnicity_demo,
       cast(array_agg(ethnicity) as character(20)) as ethnicity_combo,
       max(language) as language_demo,
       max(deathtime) as death,
       COUNT(*) as admits,
       COUNT(edregtime) as num_ED,
       avg(DATE_PART('day', dischtime - admittime)) as los
       --language, deathtime, los, edregtime
FROM jw_admissions GROUP BY subject_id

SELECT COUNT(*), language_demo
FROM jw_demographics
GROUP BY language_demo

SELECT subject_id FROM jw_demographics
EXCEPT
SELECT subject_id FROM jw_patients


SELECT *
FROM sl_demographics as demo
LEFT JOIN sl_patients as pt
ON demo.subject_id = pt.subject_id


CREATE table sl_demopgrahics1 as
SELECT demo.*, pt.gender, anchor_age,
      anchor_year, anchor_year_group
FROM sl_demographics as demo
LEFT JOIN
/*Demographics <- group_by(admissions, subject_id)%>%
  mutate(los = difftime(dischtime, admittime))%>%
  summarise(admits = n(),
            ethnic = length(unique(ethnicity)),
            ethnicity_combo = paste(sort(unique(ethnicity)), collapse = ":"),
            # language0 <- length(unique(language)),
            # language_combo <- paste(sort(unique(language)), collapse = ":")
            language = tail(language, 1),
            dod = max(deathtime, na.rm = TRUE),
            los = median(los),
            numED = length(na.omit(edregtime)))*/



/*SELECT subject_id
FROM mh_demographics
EXCEPT
SELECT subject_id
FROM mh_patients*/
