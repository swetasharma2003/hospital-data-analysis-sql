show databases;
use hospital_db;
show tables;
select * from encounters;
desc encounters;
select * from patients;


-- a. How many total encounters occurred each year?

SELECT 
    YEAR(start) AS year,
    COUNT(*) AS total_encounters
FROM encounters
GROUP BY YEAR(start)
ORDER BY year;

 -- For each year, what percentage of all encounters belonged to each encounter class 
 -- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?
 
 SELECT 
    YEAR(start) AS year,
    encounterclass,
    COUNT(*) * 100.0 / 
        SUM(COUNT(*)) OVER (PARTITION BY YEAR(start)) AS percentage
FROM encounters
GROUP BY YEAR(start), encounterclass
ORDER BY year, encounterclass;

-- c. What percentage of encounters were over 24 hours versus under 24 hours?

SELECT 
    ROUND(SUM(CASE 
        WHEN TIMESTAMPDIFF(HOUR,start, stop) > 24 THEN 1 
        ELSE 0
    END) * 100.0 / COUNT(*), 2) AS over_24_hours_percentage,

    ROUND(SUM(CASE 
        WHEN TIMESTAMPDIFF(HOUR,start,stop) <= 24 THEN 1 
        ELSE 0 
    END) * 100.0 / COUNT(*), 2) AS under_24_hours_percentage

FROM encounters;

-- How many encounters had zero payer coverage, and what percentage of total encounters does this represent?

select count(*) as zero_encounter_count, 
(count(*)*100/(select count(*) from encounters)) as percentage 
from encounters where payer_coverage=0.00;

-- What are the top 10 most frequent procedures performed and the average base cost for each?

with enc_CTE as (Select distinct(proc)as proc_name,count(*) as count_proc from encounters group by proc having count(*)>1)

select proc_name, count_proc from enc_CTE order by count_proc desc limit 10;


select proc, count(*) as frequency, avg(base_encounter_cost) from encounters group by proc order by frequency desc limit 10;


-- c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?

select proc, count(*) as performed, 
avg(base_encounter_cost) as highest_avg_cost 
from encounters 
group by proc order by highest_avg_cost desc limit 10;

-- What is the average total claim cost for encounters, broken down by payer?

select payer, round(avg(Total_claim_cost),2) 
as avg_claim_cost from encounters group by payer;

-- a. How many unique patients were admitted each quarter over time?

select year(start) as year, 
quarter(start) as quarter, 
count(distinct id) as unique_patients from encounters 
group by year, 
quarter;

-- How many patients were readmitted within 30 days of a previous encounter?

WITH cte AS (
    SELECT 
        id,
        start,
        LAG(start) OVER (
            PARTITION BY id 
            ORDER BY start
        ) AS prev_date
    FROM encounters
)
SELECT 
    COUNT(DISTINCT id) AS readmitted_patients
FROM cte
WHERE prev_date IS NOT NULL
AND DATEDIFF(start, prev_date)<=30;

-- Which patients had the most readmissions?

with final as (select id, count(*) as readmission_count from encounters group by id)
select * from final where readmission_count=(select max(readmission_count) from final);






















