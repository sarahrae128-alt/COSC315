-- ============================================
-- Database: Mythical Veterinary Clinic
-- Author: Sarah Rae Pritchard
-- Date: 2026-03-02
-- Description: Complete schema for managing patients,
-- owners, clinical visits, procedures, medications,
-- boarding, and billing in a fantasy veterinary clinic.
-- ============================================

BEGIN;

-- ============================================
-- DROP TABLES (reverse dependency order)
-- ============================================
-- WARNING: DROP statements included for development/testing only
DROP TABLE IF EXISTS "BoardingStay" CASCADE;
DROP TABLE IF EXISTS "FinancialAdjustment" CASCADE;
DROP TABLE IF EXISTS "Payment" CASCADE;
DROP TABLE IF EXISTS "Invoice" CASCADE;
DROP TABLE IF EXISTS "MedicationContraindication" CASCADE;
DROP TABLE IF EXISTS "MedicationSideEffect" CASCADE;
DROP TABLE IF EXISTS "MedicationOrder" CASCADE;
DROP TABLE IF EXISTS "VisitDiagnosis" CASCADE;
DROP TABLE IF EXISTS "ProcedureStaff" CASCADE;
DROP TABLE IF EXISTS "VisitProcedure" CASCADE;
DROP TABLE IF EXISTS "VaccineRecord" CASCADE;
DROP TABLE IF EXISTS "Visit" CASCADE;
DROP TABLE IF EXISTS "Appointment" CASCADE;
DROP TABLE IF EXISTS "PatientAbility" CASCADE;
DROP TABLE IF EXISTS "PatientAllergy" CASCADE;
DROP TABLE IF EXISTS "PatientOwnership" CASCADE;
DROP TABLE IF EXISTS "Patient" CASCADE;
DROP TABLE IF EXISTS "Staff" CASCADE;
DROP TABLE IF EXISTS "Breed" CASCADE;
DROP TABLE IF EXISTS "Owner" CASCADE;
DROP TABLE IF EXISTS "Stall" CASCADE;
DROP TABLE IF EXISTS "Medication" CASCADE;
DROP TABLE IF EXISTS "Diagnosis" CASCADE;
DROP TABLE IF EXISTS "Procedure" CASCADE;
DROP TABLE IF EXISTS "Vaccine" CASCADE;
DROP TABLE IF EXISTS "Allergy" CASCADE;
DROP TABLE IF EXISTS "Contraindication" CASCADE;
DROP TABLE IF EXISTS "SideEffect" CASCADE;
DROP TABLE IF EXISTS "SpecialAbility" CASCADE;
DROP TABLE IF EXISTS "Species" CASCADE;
DROP TABLE IF EXISTS "UniverseOfOrigin" CASCADE;
DROP TABLE IF EXISTS "Realm" CASCADE;

-- ============================================
-- INDEPENDENT TABLES
-- ============================================

CREATE TABLE "Realm" (
  "RealmID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "RealmName" VARCHAR(100) NOT NULL,
  "Description" TEXT,
  CONSTRAINT uq_realm_name UNIQUE ("RealmName")
);

CREATE TABLE "UniverseOfOrigin" (
  "UniverseID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "UniverseName" VARCHAR(100) NOT NULL,
  "UniverseDescription" TEXT,
  CONSTRAINT uq_universe_name UNIQUE ("UniverseName")
);

CREATE TABLE "Species" (
  "SpeciesID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "SpeciesName" VARCHAR(100) NOT NULL,
  CONSTRAINT uq_species_name UNIQUE ("SpeciesName")
);

CREATE TABLE "SpecialAbility" (
  "AbilityID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "AbilityName" VARCHAR(100) NOT NULL,
  "Description" TEXT,
  CONSTRAINT uq_special_ability_name UNIQUE ("AbilityName")
);

CREATE TABLE "SideEffect" (
  "SideEffectID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "SideEffectName" VARCHAR(150) NOT NULL,
  "Description" TEXT,
  CONSTRAINT uq_side_effect_name UNIQUE ("SideEffectName")
);

CREATE TABLE "Contraindication" (
  "ContraindicationID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ContraindicationName" VARCHAR(150) NOT NULL,
  "Description" TEXT,
  CONSTRAINT uq_contraindication_name UNIQUE ("ContraindicationName")
);

CREATE TABLE "Allergy" (
  "AllergyID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "AllergyName" VARCHAR(150) NOT NULL,
  "SeverityLevel" VARCHAR(50) NOT NULL,
  CONSTRAINT uq_allergy_name_severity UNIQUE ("AllergyName","SeverityLevel"),
  CONSTRAINT ck_allergy_severity CHECK ("SeverityLevel" IN ('Mild','Moderate','Severe','Anaphylaxis'))
);

CREATE TABLE "Vaccine" (
  "VaccineID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "VaccineName" VARCHAR(150) NOT NULL,
  "FrequencyMonths" INTEGER,
  CONSTRAINT uq_vaccine_name UNIQUE ("VaccineName"),
  CONSTRAINT ck_vaccine_freq CHECK ("FrequencyMonths" IS NULL OR "FrequencyMonths" > 0)
);

CREATE TABLE "Procedure" (
  "ProcedureID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ProcedureName" VARCHAR(150) NOT NULL,
  "StandardCost" NUMERIC(12,2) NOT NULL DEFAULT 0,
  CONSTRAINT uq_procedure_name UNIQUE ("ProcedureName"),
  CONSTRAINT ck_procedure_cost CHECK ("StandardCost" >= 0)
);

CREATE TABLE "Diagnosis" (
  "DiagnosisID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "DiagnosisName" VARCHAR(200) NOT NULL,
  "IsChronic" BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT uq_diagnosis_name UNIQUE ("DiagnosisName")
);

CREATE TABLE "Medication" (
  "MedicationID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "MedicationName" VARCHAR(200) NOT NULL,
  CONSTRAINT uq_medication_name UNIQUE ("MedicationName")
);

CREATE TABLE "Stall" (
  "StallID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "StallNum" VARCHAR(50) NOT NULL,
  "SizeCategory" VARCHAR(50) NOT NULL,
  "Status" VARCHAR(50) NOT NULL,
  CONSTRAINT uq_stall_num UNIQUE ("StallNum"),
  CONSTRAINT ck_stall_status CHECK ("Status" IN ('Available','Occupied','Maintenance','OutOfService'))
);

-- ============================================
-- MASTER TABLES
-- ============================================

CREATE TABLE "Owner" (
  "OwnerID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "FirstName" VARCHAR(100) NOT NULL,
  "LastName" VARCHAR(100) NOT NULL,
  "Phone" VARCHAR(30),
  "Email" VARCHAR(254),
  "Address" TEXT,
  "RealmID" BIGINT,
  CONSTRAINT uq_owner_email UNIQUE ("Email"),
  CONSTRAINT fk_owner_realm FOREIGN KEY ("RealmID")
    REFERENCES "Realm" ("RealmID") ON DELETE SET NULL
);

CREATE TABLE "Breed" (
  "BreedID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "BreedName" VARCHAR(150) NOT NULL,
  "SpeciesID" BIGINT NOT NULL,
  CONSTRAINT uq_breed_species UNIQUE ("BreedName","SpeciesID"),
  CONSTRAINT fk_breed_species FOREIGN KEY ("SpeciesID")
    REFERENCES "Species" ("SpeciesID") ON DELETE RESTRICT
);

CREATE TABLE "Staff" (
  "StaffID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "FirstName" VARCHAR(100) NOT NULL,
  "LastName" VARCHAR(100) NOT NULL,
  "RoleType" VARCHAR(50) NOT NULL,
  "HireDate" DATE NOT NULL,
  "EndDate" DATE,
  "LicenseNumber" VARCHAR(100),
  "Phone" VARCHAR(30),
  "Email" VARCHAR(254),
  CONSTRAINT uq_staff_email UNIQUE ("Email"),
  CONSTRAINT uq_staff_license UNIQUE ("LicenseNumber"),
  CONSTRAINT ck_staff_role CHECK ("RoleType" IN ('Veterinarian','VetTech','Assistant','Reception','Admin','Other')),
  CONSTRAINT ck_staff_dates CHECK ("EndDate" IS NULL OR "EndDate" >= "HireDate")
);

CREATE TABLE "Patient" (
  "PatientID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PatientName" VARCHAR(150) NOT NULL,
  "BreedID" BIGINT NOT NULL,
  "UniverseID" BIGINT,
  "BirthDate" DATE,
  "Color" VARCHAR(100),
  "Temperament" VARCHAR(100),
  CONSTRAINT fk_patient_breed FOREIGN KEY ("BreedID")
    REFERENCES "Breed" ("BreedID") ON DELETE RESTRICT,
  CONSTRAINT fk_patient_universe FOREIGN KEY ("UniverseID")
    REFERENCES "UniverseOfOrigin" ("UniverseID") ON DELETE SET NULL
);

-- ============================================
-- JUNCTION TABLES & CLINICAL
-- ============================================

CREATE TABLE "PatientOwnership" (
  "PatientID" BIGINT NOT NULL,
  "OwnerID" BIGINT NOT NULL,
  "OwnershipStartDate" DATE NOT NULL,
  "OwnershipEndDate" DATE,
  PRIMARY KEY ("PatientID","OwnerID","OwnershipStartDate"),
  CONSTRAINT fk_po_patient FOREIGN KEY ("PatientID")
    REFERENCES "Patient" ("PatientID") ON DELETE CASCADE,
  CONSTRAINT fk_po_owner FOREIGN KEY ("OwnerID")
    REFERENCES "Owner" ("OwnerID") ON DELETE CASCADE
);

CREATE TABLE "PatientAllergy" (
  "PatientID" BIGINT NOT NULL,
  "AllergyID" BIGINT NOT NULL,
  "Notes" TEXT,
  PRIMARY KEY ("PatientID","AllergyID"),
  CONSTRAINT fk_pa_patient FOREIGN KEY ("PatientID")
    REFERENCES "Patient" ("PatientID") ON DELETE CASCADE,
  CONSTRAINT fk_pa_allergy FOREIGN KEY ("AllergyID")
    REFERENCES "Allergy" ("AllergyID") ON DELETE RESTRICT
);

CREATE TABLE "PatientAbility" (
  "PatientID" BIGINT NOT NULL,
  "AbilityID" BIGINT NOT NULL,
  "AbilityStartDate" DATE NOT NULL,
  "AbilityEndDate" DATE,
  PRIMARY KEY ("PatientID","AbilityID","AbilityStartDate"),
  CONSTRAINT fk_pab_patient FOREIGN KEY ("PatientID")
    REFERENCES "Patient" ("PatientID") ON DELETE CASCADE,
  CONSTRAINT fk_pab_ability FOREIGN KEY ("AbilityID")
    REFERENCES "SpecialAbility" ("AbilityID") ON DELETE RESTRICT
);

CREATE TABLE "Appointment" (
  "AppointmentID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PatientID" BIGINT NOT NULL,
  "StaffID" BIGINT NOT NULL,
  "AppointmentDate" TIMESTAMP NOT NULL,
  "Status" VARCHAR(30) NOT NULL,
  "Reason" VARCHAR(200) NOT NULL,
  CONSTRAINT fk_appointment_patient FOREIGN KEY ("PatientID")
    REFERENCES "Patient" ("PatientID"),
  CONSTRAINT fk_appointment_staff FOREIGN KEY ("StaffID")
    REFERENCES "Staff" ("StaffID"),
  CONSTRAINT ck_appt_status CHECK ("Status" IN ('Scheduled','Completed','Cancelled','NoShow','Rescheduled'))
);

CREATE TABLE "Visit" (
  "VisitID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PatientID" BIGINT NOT NULL,
  "StaffID" BIGINT NOT NULL,
  "AppointmentID" BIGINT,
  "VisitStart" TIMESTAMP NOT NULL,
  "VisitEnd" TIMESTAMP,
  "Notes" TEXT,
  CONSTRAINT fk_visit_patient FOREIGN KEY ("PatientID")
    REFERENCES "Patient" ("PatientID"),
  CONSTRAINT fk_visit_staff FOREIGN KEY ("StaffID")
    REFERENCES "Staff" ("StaffID"),
  CONSTRAINT fk_visit_appt FOREIGN KEY ("AppointmentID")
    REFERENCES "Appointment" ("AppointmentID") ON DELETE SET NULL
);

CREATE TABLE "VisitProcedure" (
  "VisitProcedureID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "VisitID" BIGINT NOT NULL,
  "ProcedureID" BIGINT NOT NULL,
  "StartTime" TIMESTAMP NOT NULL,
  "EndTime" TIMESTAMP,
  "Outcome" VARCHAR(200),
  CONSTRAINT fk_vp_visit FOREIGN KEY ("VisitID")
    REFERENCES "Visit" ("VisitID") ON DELETE CASCADE,
  CONSTRAINT fk_vp_procedure FOREIGN KEY ("ProcedureID")
    REFERENCES "Procedure" ("ProcedureID")
);

CREATE TABLE "ProcedureStaff" (
  "VisitProcedureID" BIGINT NOT NULL,
  "StaffID" BIGINT NOT NULL,
  "Role" VARCHAR(100) NOT NULL,
  PRIMARY KEY ("VisitProcedureID","StaffID"),
  CONSTRAINT fk_ps_vp FOREIGN KEY ("VisitProcedureID")
    REFERENCES "VisitProcedure" ("VisitProcedureID") ON DELETE CASCADE,
  CONSTRAINT fk_ps_staff FOREIGN KEY ("StaffID")
    REFERENCES "Staff" ("StaffID")
);

CREATE TABLE "VisitDiagnosis" (
  "VisitID" BIGINT NOT NULL,
  "DiagnosisID" BIGINT NOT NULL,
  "Notes" TEXT,
  PRIMARY KEY ("VisitID","DiagnosisID"),
  CONSTRAINT fk_vd_visit FOREIGN KEY ("VisitID")
    REFERENCES "Visit" ("VisitID") ON DELETE CASCADE,
  CONSTRAINT fk_vd_diag FOREIGN KEY ("DiagnosisID")
    REFERENCES "Diagnosis" ("DiagnosisID")
);


CREATE TABLE "MedicationOrder" (
  "MedicationOrderID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "VisitID" BIGINT NOT NULL,
  "MedicationID" BIGINT NOT NULL,
  "DosageAmount" VARCHAR(100) NOT NULL,
  "QuantityDispensed" NUMERIC(10,2) NOT NULL,
  "Frequency" VARCHAR(100),
  "Route" VARCHAR(100),
  "StartDate" DATE NOT NULL,
  "EndDate" DATE,
  CONSTRAINT fk_mo_visit FOREIGN KEY ("VisitID")
    REFERENCES "Visit" ("VisitID") ON DELETE CASCADE,
  CONSTRAINT fk_mo_med FOREIGN KEY ("MedicationID")
    REFERENCES "Medication" ("MedicationID"),
  CONSTRAINT ck_mo_quantity CHECK ("QuantityDispensed" > 0),
  CONSTRAINT ck_mo_dates CHECK ("EndDate" IS NULL OR "EndDate" >= "StartDate")
);


CREATE TABLE "MedicationSideEffect" (
  "MedicationID" BIGINT NOT NULL,
  "SideEffectID" BIGINT NOT NULL,
  "SeverityLevel" VARCHAR(50) NOT NULL,
  PRIMARY KEY ("MedicationID","SideEffectID"),
  CONSTRAINT fk_mse_med FOREIGN KEY ("MedicationID")
    REFERENCES "Medication" ("MedicationID") ON DELETE CASCADE,
  CONSTRAINT fk_mse_se FOREIGN KEY ("SideEffectID")
    REFERENCES "SideEffect" ("SideEffectID"),
  CONSTRAINT ck_mse_severity CHECK ("SeverityLevel" IN ('Mild','Moderate','Severe'))
);


CREATE TABLE "MedicationContraindication" (
  "MedicationID" BIGINT NOT NULL,
  "ContraindicationID" BIGINT NOT NULL,
  PRIMARY KEY ("MedicationID","ContraindicationID"),
  CONSTRAINT fk_mc_med FOREIGN KEY ("MedicationID")
    REFERENCES "Medication" ("MedicationID") ON DELETE CASCADE,
  CONSTRAINT fk_mc_contra FOREIGN KEY ("ContraindicationID")
    REFERENCES "Contraindication" ("ContraindicationID")
);

CREATE TABLE "VaccineRecord" (
  "VaccinationRecordID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PatientID" BIGINT NOT NULL,
  "VaccineID" BIGINT NOT NULL,
  "DateAdministered" TIMESTAMP NOT NULL,
  "NextDueDate" TIMESTAMP,
  CONSTRAINT fk_vr_patient FOREIGN KEY ("PatientID")
    REFERENCES "Patient" ("PatientID") ON DELETE CASCADE,
  CONSTRAINT fk_vr_vaccine FOREIGN KEY ("VaccineID")
    REFERENCES "Vaccine" ("VaccineID")
);

-- ============================================
-- BILLING
-- ============================================

CREATE TABLE "Invoice" (
  "InvoiceID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "VisitID" BIGINT NOT NULL,
  "TotalAmount" NUMERIC(12,2) NOT NULL,
  "StatusPaid" BOOLEAN NOT NULL DEFAULT FALSE,
  "IssueDate" DATE NOT NULL,
  CONSTRAINT fk_invoice_visit FOREIGN KEY ("VisitID")
    REFERENCES "Visit" ("VisitID") ON DELETE CASCADE
);

CREATE TABLE "Payment" (
  "PaymentID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "InvoiceID" BIGINT NOT NULL,
  "PaymentDate" DATE NOT NULL,
  "Amount" NUMERIC(12,2) NOT NULL,
  "Method" VARCHAR(100) NOT NULL,
  "ProcessedByStaffID" BIGINT NOT NULL,
  CONSTRAINT fk_payment_invoice FOREIGN KEY ("InvoiceID")
    REFERENCES "Invoice" ("InvoiceID") ON DELETE CASCADE,
  CONSTRAINT fk_payment_staff FOREIGN KEY ("ProcessedByStaffID")
    REFERENCES "Staff" ("StaffID")
);

CREATE TABLE "FinancialAdjustment" (
  "AdjustmentID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "InvoiceID" BIGINT NOT NULL,
  "AdjustmentDate" DATE NOT NULL,
  "Amount" NUMERIC(12,2) NOT NULL,
  "AdjustmentType" VARCHAR(100) NOT NULL,
  "ApprovedByStaffID" BIGINT NOT NULL,
  CONSTRAINT fk_fa_invoice FOREIGN KEY ("InvoiceID")
    REFERENCES "Invoice" ("InvoiceID") ON DELETE CASCADE,
  CONSTRAINT fk_fa_staff FOREIGN KEY ("ApprovedByStaffID")
    REFERENCES "Staff" ("StaffID")
);

CREATE TABLE "BoardingStay" (
  "BoardingStayID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "PatientID" BIGINT NOT NULL,
  "StallID" BIGINT NOT NULL,
  "StartDate" DATE NOT NULL,
  "EndDate" DATE,
  "DailyRate" NUMERIC(10,2) NOT NULL,
  CONSTRAINT fk_bs_patient FOREIGN KEY ("PatientID")
    REFERENCES "Patient" ("PatientID") ON DELETE CASCADE,
  CONSTRAINT fk_bs_stall FOREIGN KEY ("StallID")
    REFERENCES "Stall" ("StallID")
);

COMMIT;


