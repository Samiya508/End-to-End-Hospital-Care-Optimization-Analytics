create database if not exists healthcare;
use healthcare;

select * from medications;
describe medications;
ALTER TABLE outcomes MODIFY patient_id varchar(50) NOT NULL; 
ALTER TABLE patients ADD PRIMARY KEY (patient_id);
ALTER TABLE outcomes
ADD CONSTRAINT fk_patients3
FOREIGN KEY (patient_id) REFERENCES patients(patient_id);

CREATE TABLE diagnoses (
    patient_id varchar(50),
    visit_date DATE,
    visit_type VARCHAR(20) ,
    primary_diagnosis VARCHAR(255) ,
    primary_icd10 VARCHAR(200) ,
    secondary_diagnoses VARCHAR(255),
	secondary_icd10 VARCHAR(200) ,
    provider_specialty VARCHAR(100) ,
    CONSTRAINT fk_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

CREATE TABLE lab_results (
    patient_id varchar(50),
    test_date DATE,
    test_name VARCHAR(20) ,
    value float,
    unit VARCHAR(200) ,
    reference_low float,
	reference_high float,
    flag VARCHAR(100) ,
    is_abnormal int,
    delta_from_normal int,
    CONSTRAINT fk_patient1 FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

-- 1. Find all emergency room visits
SELECT patient_id, visit_date, primary_diagnosis 
FROM diagnoses 
WHERE visit_type = 'Emergency';

-- 2. Count total encounters by specialtyQuestion: How many visits did each provider specialty handle? Sort the list with the highest volume first.sqlSELECT provider_specialty, COUNT(*) AS total_visits
SELECT provider_specialty, COUNT(*) AS total_visits
FROM diagnoses
GROUP BY provider_specialty
ORDER BY total_visits DESC;

-- 3. List patients with critical high/low lab resultsQuestion: Find all lab records where the result was flagged as abnormal (is_abnormal is true).sqlSELECT patient_id, test_date, test_name, value, unit, flag

SELECT patient_id, test_date, test_name, value, unit, flag
FROM lab_results
WHERE is_abnormal = TRUE;


-- 4. Find a specific patient's lab history

SELECT test_date, test_name, value, unit, flag
FROM lab_results
WHERE patient_id = "P0000005"
ORDER BY test_date DESC;

-- 5.Show all patient visits that occurred during the first quarter of 2026 (January 1st to March 31st).alter
SELECT patient_id, visit_date, visit_type
FROM diagnoses
WHERE visit_date BETWEEN '2026-01-01' AND '2026-03-31';

 -- 6.Calculate the average value of all 'Hemoglobin' tests recorded in the database.
 
 SELECT AVG(value) AS average_hemoglobin, unit
FROM lab_results
WHERE test_name = 'Hemoglobin'
GROUP BY unit;

--  7.Find all visits where the primary ICD-10 code starts with 'I10' (which represents Essential Hypertension).

SELECT patient_id, primary_diagnosis, primary_icd10
FROM diagnoses
WHERE primary_icd10 LIKE 'I10%';

-- 8 List all lab results where the numeric variation (delta_from_normal) is negative, meaning the patient's value dropped below the healthy baseline.
SELECT patient_id, test_name, value, reference_low, delta_from_normal
FROM lab_results
WHERE delta_from_normal < 0;

-- 9 Write a query  primary diagnosis alongside its secondary (complicating) diagnoses.
SELECT 
    patient_id, 
    primary_diagnosis , 
    secondary_diagnoses 
FROM diagnoses;

-- 10  Find patients who had a visit and a lab on the same day
SELECT 
    e.patient_id, 
    e.visit_date, 
    e.visit_type, 
    l.test_name, 
    l.value
FROM diagnoses e
INNER JOIN lab_results l 
    ON e.patient_id = l.patient_id 
    AND e.visit_date = DATE(l.test_date);

-- 11 CTE 1 (Financials & Operational Outcomes):
-- Aggregate total_charges_usd and calculate true hospital length of stay (DATEDIFF(day, admission_date, discharge_date)).
WITH cte_financials_operational AS (
    SELECT 
        patient_id,
        STR_TO_DATE(admission_date, '%Y-%m-%d') AS clean_admission_date,
        STR_TO_DATE(discharge_date, '%Y-%m-%d') AS clean_discharge_date,
        total_charges_usd,
        DATEDIFF(
            STR_TO_DATE(discharge_date, '%Y-%m-%d'), 
            STR_TO_DATE(admission_date, '%Y-%m-%d')
        ) AS calculated_los_days,
        icu_admission,
        in_hospital_death,
        discharge_disposition
    FROM outcomes
)
    SELECT 
        patient_id,
        clean_admission_date,
        clean_discharge_date,
        calculated_los_days,
        total_charges_usd,
        -- Looks forward to find the clean admission date of the patient's next visit
        LEAD(clean_admission_date) OVER (
            PARTITION BY patient_id 
            ORDER BY clean_admission_date ASC
        ) AS next_admission_date
    FROM cte_financials_operational
;

