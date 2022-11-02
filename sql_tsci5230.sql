/*CREATE table jw_patients as SELECT * FROM patients;
CREATE table jw_admissions as SELECT * FROM admissions;
CREATE table jw_transfers as select * FROM transfers;

CREATE TABLE jw_demographics as
SELECT
  subject_id,
  COUNT(DISTINCT ethnicity) as ethnicity_demo,
  cast(array_agg(ethnicity) as character(20)) as ethnicity_combo,
  MAX(language) as language_demo,
  MAX(deathtime) as death,
  COUNT(*) as admits,
  COUNT(edregtime) as num_ED,
  avg(DATE_PART('day', dischtime - admittime)) as LOS
FROM jw_admissions GROUP BY subject_id

CREATE TABLE jw_demographics1 as

SELECT demo.*, pt.gender, anchor_age, anchor_year, anchor_year_group
FROM jw_demographics AS demo
LEFT JOIN sl_patients AS pt
ON demo.subject_id = pt.subject_id*/


/*CREATE table jw_inputevents AS
SELECT *
FROM inputevents;

CREATE table jw_d_items AS
SELECT *
FROM d_items;*/

/*DROP table jw_dlabitems*/
/*CREATE table jw_dlabitems AS
SELECT*
FROM d_labitems*/

/*CREATE table jw_labevents AS
SELECT*
FROM labevents*/
--Drop table jw_Antibiotic_Cr;
CREATE table jw_Antibiotic_Cr AS

WITH q0 AS
(SELECT 
GENERATE_SERIES(MIN(admittime), MAX(dischtime), INTERVAL '1 Day') AS Day
FROM jw_admissions), q1 AS
(SELECT hadm_id, Day::date 
FROM q0
INNER JOIN jw_admissions as adm ON q0.Day BETWEEN adm.admittime::date and adm.dischtime::date )
, q2 AS

(SELECT hadm_id, item.abbreviation, starttime::date, endtime::date
FROM jw_d_items AS item 
INNER JOIN jw_inputevents AS inp ON item.itemid = inp.itemid
WHERE (label LIKE '%anco%'
OR label LIKE '%iperacillin%'
OR label LIKE '%rtapenem%'
OR label LIKE '%evofloxacin%'
OR label LIKE '%efepime%')
AND category = 'Antibiotics')

,q3 AS
(SElECT abbreviation,  q1.* 
FROM q1 LEFT JOIN q2
ON q1.hadm_id = q2.hadm_id AND 
q1.Day BETWEEN starttime::date and endtime::date)

,q4 AS
(SELECT hadm_id, day,
SUM(CASE WHEN abbreviation = 'Vancomycin' THEN 1 ELSE 0 END) AS Vanc,
SUM(CASE WHEN abbreviation LIKE '%Zosyn%' THEN 1 ELSE 0 END) AS Zosyn,
SUM(CASE WHEN abbreviation NOT LIKE '%Zosyn%' 
	AND abbreviation != 'Vancomycin' THEN 1 ELSE 0 END) AS Other
FROM q3
GROUP BY hadm_id, day)

,q5 AS
(SELECT
       avg(cast(value AS numeric)) OVER (Partition By hadm_id, charttime::date) AS AverageCr, 
       --max(cast(value AS numeric)) AS MaxCr, 
       first_value(cast(value AS numeric))OVER (Partition By hadm_id, charttime::date ORDER BY charttime Desc) AS LastCr,
       hadm_id, 
       charttime,
 		cast(value AS numeric),
 		row_number() OVER (Partition By hadm_id, charttime::date ORDER BY charttime),
 		flag
       --sum(CASE WHEN flag is not null THEN 1
          --ELSE 0 END) AS AbnormalCount
FROM jw_dlabitems as items
INNER JOIN jw_labevents AS events
ON items.itemid = events.itemid
WHERE label LIKE '%reatinine%'
AND fluid = 'Blood'
--GROUP BY hadm_id, charttime::date
 ORDER BY hadm_id, charttime
)

,q6 AS
(SELECT 
      avg(value) AS AverageCr, 
      max(value) AS MaxCr, 
      max(LastCr) AS LastCr,
       hadm_id, 
       charttime::date AS charttime, 
       sum(CASE WHEN flag is not null THEN 1
          ELSE 0 END) AS AbnormalCount 
FROM q5
 GROUP BY hadm_id, charttime::date)


SELECT q4.*, AverageCr, MaxCr, AbnormalCount, LastCr,
CASE 
	WHEN vanc >0 and zosyn >0 THEN 'Vanc&Zosyn'
	WHEN vanc >0 and other >0 THEN 'Vanc&Other' 
	WHEN vanc >0 THEN 'Vanc'
	WHEN zosyn >0 OR other >0 THEN 'Other'
	WHEN vanc+zosyn+other = 0 THEN 'None'
	ELSE 'Undefined' END AS Antibiotic
FROM q4
LEFT JOIN q6 ON q4.hadm_id = CAST(q6.hadm_id AS bigint)
AND q4.day = q6.charttime






