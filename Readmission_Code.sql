---Checking table columns
SELECT * FROM 
  hospital.patient.readmission_data LIMIT 10;

--- Readmission rate overview
SELECT
  COUNT(*) AS total_patients,
  SUM(CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END) AS total_readmissions,
  ROUND(SUM(CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS readmission_rate_percent
FROM hospital.patient.readmission_data;

--- Readmission by admission type 
SELECT
  `Admission Type`,
  COUNT(*) AS total_patients,
  SUM(CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END) AS readmissions,
  ROUND(SUM(CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS readmission_rate_percent
FROM hospital.patient.readmission_data
GROUP BY `Admission Type`
ORDER BY readmission_rate_percent DESC;


--- Readmission by Age Goup
SELECT
  CASE 
    WHEN Age < 30 THEN '<30'
    WHEN Age BETWEEN 30 AND 49 THEN '30-49'
    WHEN Age BETWEEN 50 AND 69 THEN '50-69'
    ELSE '70+' 
  END AS age_bucket,
  COUNT(*) AS total_patients,
  SUM(CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END) AS readmissions,
  ROUND(SUM(CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS readmission_rate_percent
FROM hospital.patient.readmission_data
GROUP BY age_bucket
ORDER BY readmission_rate_percent DESC;

--- Readmission by Gender
SELECT
  Gender,
  COUNT(*) AS total_patients,
  SUM(CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END) AS readmissions,
  ROUND(SUM(CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS readmission_rate_percent
FROM hospital.patient.readmission_data
GROUP BY Gender
ORDER BY readmission_rate_percent DESC;


--- Factors Associated with Readmission (Averages)
SELECT
  Readmission,
  ROUND(AVG(`Length of Stay`), 2) AS avg_length_of_stay,
  ROUND(AVG(`Number of Diagnoses`), 2) AS avg_diagnoses,
  ROUND(AVG(`Blood Pressure`), 2) AS avg_blood_pressure,
  ROUND(AVG(`Blood Sugar Levels`), 2) AS avg_blood_sugar,
  ROUND(AVG(`Previous Admissions`), 2) AS avg_previous_admissions
FROM hospital.patient.readmission_data
GROUP BY Readmission;

---  Top Risk Factors for Readmission (Simple Flags)
SELECT
  `Patient ID`,
  Age,
  Gender,
  `Admission Type`,
  `Length of Stay`,
  `Number of Diagnoses`,
  `Blood Pressure`,
  `Blood Sugar Levels`,
  `Previous Admissions`,
  Readmission,
  CASE 
    WHEN `Length of Stay` > 20 THEN 'Long Stay >20'
    ELSE 'Normal Stay'
  END AS stay_flag,
  CASE 
    WHEN `Blood Sugar Levels` > 140 THEN 'High Sugar >140'
    ELSE 'Normal Sugar'
  END AS sugar_flag,
  CASE 
    WHEN `Previous Admissions` > 2 THEN 'Frequent Admissions >2'
    ELSE 'Few Admissions'
  END AS admission_flag
FROM hospital.patient.readmission_data
WHERE Readmission = 'Yes';

--- Correlation 
SELECT
  ROUND(AVG(CASE WHEN Readmission = 'Yes' THEN `Length of Stay` ELSE NULL END), 2) AS avg_stay_readmitted,
  ROUND(AVG(CASE WHEN Readmission = 'No' THEN `Length of Stay` ELSE NULL END), 2) AS avg_stay_not_readmitted,
  ROUND(AVG(CASE WHEN Readmission = 'Yes' THEN `Blood Sugar Levels` ELSE NULL END), 2) AS avg_sugar_readmitted,
  ROUND(AVG(CASE WHEN Readmission = 'No' THEN `Blood Sugar Levels` ELSE NULL END), 2) AS avg_sugar_not_readmitted
FROM hospital.patient.readmission_data;


---- Combined code 
SELECT
  `Patient ID`,
  Age,
  Gender,
  `Admission Type`,
  `Length of Stay`,
  `Number of Diagnoses`,
  `Blood Pressure`,
  `Blood Sugar Levels`,
  `Previous Admissions`,
  Readmission,

  -- Age bucket
  CASE 
    WHEN Age < 30 THEN '<30'
    WHEN Age BETWEEN 30 AND 49 THEN '30-49'
    WHEN Age BETWEEN 50 AND 69 THEN '50-69'
    ELSE '70+' 
  END AS age_bucket,

  -- Stay flag
  CASE 
    WHEN `Length of Stay` > 20 THEN 'Long Stay >20'
    ELSE 'Normal Stay'
  END AS stay_flag,

  -- Sugar flag
  CASE 
    WHEN `Blood Sugar Levels` > 140 THEN 'High Sugar >140'
    ELSE 'Normal Sugar'
  END AS sugar_flag,

  -- Admission flag
  CASE 
    WHEN `Previous Admissions` > 2 THEN 'Frequent Admissions >2'
    ELSE 'Few Admissions'
  END AS admission_flag,

  -- Readmission rate by admission type
  COUNT(*) OVER (
    PARTITION BY `Admission Type`
  ) AS total_patients_by_admission_type,
  SUM(
    CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END
  ) OVER (
    PARTITION BY `Admission Type`
  ) AS readmissions_by_admission_type,
  ROUND(
    SUM(
      CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END
    ) OVER (
      PARTITION BY `Admission Type`
    ) * 100.0 / COUNT(*) OVER (
      PARTITION BY `Admission Type`
    ), 2
  ) AS readmission_rate_percent_by_admission_type,

  -- Readmission rate by age bucket
  COUNT(*) OVER (
    PARTITION BY 
      CASE 
        WHEN Age < 30 THEN '<30'
        WHEN Age BETWEEN 30 AND 49 THEN '30-49'
        WHEN Age BETWEEN 50 AND 69 THEN '50-69'
        ELSE '70+' 
      END
  ) AS total_patients_by_age_bucket,
  SUM(
    CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END
  ) OVER (
    PARTITION BY 
      CASE 
        WHEN Age < 30 THEN '<30'
        WHEN Age BETWEEN 30 AND 49 THEN '30-49'
        WHEN Age BETWEEN 50 AND 69 THEN '50-69'
        ELSE '70+' 
      END
  ) AS readmissions_by_age_bucket,
  ROUND(
    SUM(
      CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END
    ) OVER (
      PARTITION BY 
        CASE 
          WHEN Age < 30 THEN '<30'
          WHEN Age BETWEEN 30 AND 49 THEN '30-49'
          WHEN Age BETWEEN 50 AND 69 THEN '50-69'
          ELSE '70+' 
        END
    ) * 100.0 / COUNT(*) OVER (
      PARTITION BY 
        CASE 
          WHEN Age < 30 THEN '<30'
          WHEN Age BETWEEN 30 AND 49 THEN '30-49'
          WHEN Age BETWEEN 50 AND 69 THEN '50-69'
          ELSE '70+' 
        END
    ), 2
  ) AS readmission_rate_percent_by_age_bucket,

  -- Readmission rate by gender
  COUNT(*) OVER (
    PARTITION BY Gender
  ) AS total_patients_by_gender,
  SUM(
    CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END
  ) OVER (
    PARTITION BY Gender
  ) AS readmissions_by_gender,
  ROUND(
    SUM(
      CASE WHEN Readmission = 'Yes' THEN 1 ELSE 0 END
    ) OVER (
      PARTITION BY Gender
    ) * 100.0 / COUNT(*) OVER (
      PARTITION BY Gender
    ), 2
  ) AS readmission_rate_percent_by_gender

FROM hospital.patient.readmission_data;









