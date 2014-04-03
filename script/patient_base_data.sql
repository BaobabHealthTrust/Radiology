UPDATE healthdata.MasterPatientRecord
SET Birth_Date = CONCAT_WS('-', SUBSTRING(Birth_Date,8,4),CASE SUBSTRING(Birth_Date,4,3) WHEN 'JAN' THEN '01' WHEN 'FEB' THEN '02' WHEN 'MAR' THEN '03' WHEN 'APR' THEN '04' WHEN 'MAY' THEN '05' WHEN 'JUN' THEN '06' WHEN 'JUL' THEN '07' WHEN 'AUG' THEN '08' WHEN 'SEP' THEN '09' WHEN 'OCT' THEN '10' WHEN 'NOV' THEN '11' WHEN 'DEC' THEN '12' END, SUBSTRING(Birth_Date,1,2)),
    Date_Reg = CONCAT_WS('-', SUBSTRING(Date_Reg,8,4),CASE SUBSTRING(Date_Reg,4,3) WHEN 'JAN' THEN '01' WHEN 'FEB' THEN '02' WHEN 'MAR' THEN '03' WHEN 'APR' THEN '04' WHEN 'MAY' THEN '05' WHEN 'JUN' THEN '06' WHEN 'JUL' THEN '07' WHEN 'AUG' THEN '08' WHEN 'SEP' THEN '09' WHEN 'OCT' THEN '10' WHEN 'NOV' THEN '11' WHEN 'DEC' THEN '12' END, SUBSTRING(Date_Reg,1,2));

/*End of update*/

INSERT INTO openmrs_bart2.person (birthdate, birthdate_estimated, gender, death_date, creator, voided, voided_by, void_reason, date_voided, date_created, uuid)
SELECT DATE(Birth_Date), 0, Sex, NULL, 1, Site_ID, NULL, Pat_ID, NULL, DATE(Date_Reg), (SELECT UUID()) AS uuid FROM healthdata.MasterPatientRecord WHERE Pat_ID > 1;

/*UPDATE openmrs_b2.person SET gender = LEFT(RTRIM(LTRIM(gender)), 1);*/

INSERT INTO openmrs_bart2.patient (patient_id, creator, voided, voided_by, void_reason, date_voided, date_created)
SELECT person_id, creator, 0, voided_by, '', date_voided, date_created FROM openmrs_bart2.person where openmrs_bart2.person.person_id > 1;

/* Update patient person addresses */
INSERT INTO openmrs_bart2.person_address (person_id, city_village, creator, voided, voided_by, void_reason, date_voided, date_created, uuid)
SELECT p.person_id,LTRIM(RTRIM(RIGHT(mpr.address, LENGTH(mpr.address) - INSTR(mpr.address,'/')))) AS city_village,p.creator,0, p.voided_by,'' AS void_reason, p.date_voided, p.date_created, (SELECT UUID()) AS uuid
FROM openmrs_bart2.person p 
 	INNER JOIN healthdata.MasterPatientRecord mpr
	ON mpr.Pat_ID = p.void_reason 
	AND mpr.Site_ID = p.voided;

/* Update patient identifiers and attributes 'skipping them for now'*/

INSERT INTO openmrs_bart2.patient_identifier (patient_id, identifier_type, preferred, location_id, identifier, creator, voided, voided_by, void_reason, date_voided, date_created, uuid)
SELECT 	DISTINCT
	p.person_id,
	3 AS identifier_type,
	0 AS preffered,
	CASE mpr.Site_ID
		WHEN 101 THEN 295
		WHEN 102 THEN 614
		WHEN 103 THEN 703
		ELSE 1
	END AS location_id,
	rs.Patient_Identifier AS identifier,
	1 AS creator, 0 AS voided, 0 AS voided_by, '' as void_reason, NULL AS date_voided, p.date_created, (SELECT UUID()) AS uuid 
FROM healthdata.RadiologyStudy rs
	INNER JOIN healthdata.MasterPatientRecord mpr
		ON CASE LEFT(rs.Patient_Identifier, 1)
			WHEN "p" THEN SUBSTRING(rs.Patient_Identifier,3,(LENGTH(rs.Patient_Identifier) - 5))
			ELSE REPLACE(SUBSTRING(Patient_Identifier,5,7), "-","")
		   END = mpr.Pat_ID
	INNER JOIN openmrs_bart2.person p
		ON mpr.Site_ID = p.voided
		AND mpr.Pat_ID = p.void_reason;

/*Radiology Study Number*/

INSERT INTO openmrs_bart2.patient_identifier (patient_id, identifier_type, preferred, location_id, identifier, creator, voided, voided_by, void_reason, date_voided, date_created, uuid)
SELECT 	DISTINCT
	p.person_id,
	30 AS identifier_type,
	0 AS preffered,
	CASE mpr.Site_ID
		WHEN 101 THEN 295
		WHEN 102 THEN 614
		WHEN 103 THEN 703
		ELSE 1
	END AS location_id,
	rs.Study_Number AS identifier,
	1 AS creator, 0 AS voided, 0 AS voided_by, '' as void_reason, NULL AS date_voided, p.date_created, (SELECT UUID()) AS uuid 
FROM healthdata.RadiologyStudy rs
	INNER JOIN healthdata.MasterPatientRecord mpr
		ON CASE LEFT(rs.Patient_Identifier, 1)
			WHEN "p" THEN SUBSTRING(rs.Patient_Identifier,3,(LENGTH(rs.Patient_Identifier) - 5))
			ELSE REPLACE(SUBSTRING(Patient_Identifier,5,7), "-","")
		  END = mpr.Pat_ID
	INNER JOIN openmrs_bart2.person p
		ON mpr.Site_ID = p.voided
		AND mpr.Pat_ID = p.void_reason;

/*update the person table in to replace the values of */
UPDATE openmrs_bart2.person
SET voided = 0, void_reason = '';


/* ---------Update the healthdata.MasterPatientRecord ----Reverting to the old format */

UPDATE healthdata.MasterPatientRecord
SET Birth_Date = CONCAT_WS('-', SUBSTRING(Birth_Date,9,2),CASE SUBSTRING(Birth_Date,6,2) WHEN '01' THEN 'JAN' WHEN '02' THEN 'FEB' WHEN '03' THEN 'MAR' WHEN '04' THEN 'APR' WHEN '05' THEN 'MAY' WHEN '06' THEN 'JUN' WHEN '07' THEN 'JUL' WHEN '08' THEN 'AUG' WHEN '09' THEN 'SEP' WHEN '10' THEN 'OCT' WHEN '11' THEN 'NOV' WHEN '12' THEN 'DEC' END, SUBSTRING(Birth_Date,1,4)),
    Date_Reg = CONCAT_WS('-', SUBSTRING(Date_Reg,9,2),CASE SUBSTRING(Date_Reg,6,2) WHEN '01' THEN 'JAN' WHEN '02' THEN 'FEB' WHEN '03' THEN 'MAR' WHEN '04' THEN 'APR' WHEN '05' THEN 'MAY' WHEN '06' THEN 'JUN' WHEN '07' THEN 'JUL' WHEN '08' THEN 'AUG' WHEN '09' THEN 'SEP' WHEN '10' THEN 'OCT' WHEN '11' THEN 'NOV' WHEN '12' THEN 'DEC' END, SUBSTRING(Date_Reg,1,4));
   
/*End of update*/
