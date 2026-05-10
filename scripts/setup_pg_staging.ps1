# Setup script - creates all 18 PostgreSQL staging models in one shot

$ProjectRoot = "C:\KOMHAR\Workspace\dbt_Workspace\healthcare_dbt"
$StagingPath = "$ProjectRoot\models\staging\postgres"

# Create directory if missing
New-Item -ItemType Directory -Force -Path $StagingPath | Out-Null
Write-Host "Created folder: $StagingPath" -ForegroundColor Green

# Helper to create a file with content
function New-DbtModel {
    param([string]$FileName, [string]$Content)
    $FullPath = Join-Path $StagingPath $FileName
    $Content | Out-File -FilePath $FullPath -Encoding UTF8
    Write-Host "  Created: $FileName" -ForegroundColor Cyan
}

# Macro file
$MacroPath = "$ProjectRoot\macros"
New-Item -ItemType Directory -Force -Path $MacroPath | Out-Null

@'
{% macro get_metadata_columns() %}
    current_timestamp() as _dbt_loaded_at,
    '{{ invocation_id }}' as _dbt_run_id,
    '{{ this.name }}' as _dbt_source_model
{% endmacro %}
'@ | Out-File -FilePath "$MacroPath\get_metadata_columns.sql" -Encoding UTF8
Write-Host "Created macro file" -ForegroundColor Green

# ============= 18 STAGING MODELS =============

New-DbtModel "stg_pg_patients.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_patients') }}
),

renamed as (
    select
        patient_id,
        mrn                                              as medical_record_number,
        first_name,
        last_name,
        first_name || ' ' || last_name                   as full_name,
        date_of_birth,
        datediff('year', date_of_birth, current_date()) as age,
        gender,
        race,
        ethnicity,
        street_address,
        city,
        state_code,
        zip_code,
        phone,
        email,
        primary_provider_id,
        is_active,
        registered_date,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_providers.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_providers') }}
),

renamed as (
    select
        provider_id,
        npi_number,
        first_name,
        last_name,
        first_name || ' ' || last_name                  as full_name,
        specialty_id,
        facility_id,
        license_number,
        hire_date,
        datediff('year', hire_date, current_date())    as tenure_years,
        is_active,
        email,
        phone,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_facilities.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_facilities') }}
),

renamed as (
    select
        facility_id,
        facility_name,
        type_id                                         as facility_type_id,
        street_address,
        city,
        state_code,
        zip_code,
        phone,
        capacity_beds,
        is_active,
        opened_date,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_encounters.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_encounters') }}
),

renamed as (
    select
        encounter_id,
        encounter_number,
        patient_id,
        provider_id,
        facility_id,
        encounter_type,
        encounter_date,
        encounter_time,
        duration_minutes,
        chief_complaint,
        status                                          as encounter_status,
        case
            when encounter_type = 'Emergency'   then true
            when encounter_type = 'Urgent Care' then true
            else false
        end                                             as is_acute_visit,
        created_at,
        updated_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_encounter_diagnoses.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_encounter_diagnoses') }}
),

renamed as (
    select
        diagnosis_id,
        encounter_id,
        icd10_code,
        diagnosis_type,
        diagnosed_date,
        notes                                           as diagnosis_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_encounter_procedures.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_encounter_procedures') }}
),

renamed as (
    select
        procedure_id,
        encounter_id,
        cpt_code,
        performed_by                                    as performed_by_provider_id,
        performed_date,
        units,
        charge_amount,
        notes                                           as procedure_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_icd10_codes.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_icd10_codes') }}
),

renamed as (
    select
        code                                            as icd10_code,
        description                                     as diagnosis_description,
        category                                        as disease_category,
        is_chronic,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_cpt_codes.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_cpt_codes') }}
),

renamed as (
    select
        code                                            as cpt_code,
        description                                     as procedure_description,
        category                                        as procedure_category,
        base_cost,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_specialty_types.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_specialty_types') }}
),

renamed as (
    select
        specialty_id,
        specialty_name,
        description                                     as specialty_description,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_states.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_states') }}
),

renamed as (
    select
        state_code,
        state_name,
        region,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_facility_types.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_facility_types') }}
),

renamed as (
    select
        type_id                                         as facility_type_id,
        type_name                                       as facility_type_name,
        description                                     as facility_type_description,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_insurance_carriers.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_insurance_carriers') }}
),

renamed as (
    select
        carrier_id,
        carrier_name,
        carrier_type,
        payer_id                                        as external_payer_id,
        phone,
        is_active,
        contract_start                                  as contract_start_date,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_employees.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_employees') }}
),

renamed as (
    select
        employee_id,
        first_name,
        last_name,
        first_name || ' ' || last_name                  as full_name,
        job_title,
        department,
        facility_id,
        hire_date,
        is_active,
        email,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_prescriptions.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_prescriptions') }}
),

renamed as (
    select
        prescription_id,
        encounter_id,
        patient_id,
        provider_id,
        medication_name,
        dosage,
        frequency,
        duration_days,
        refills,
        prescribed_date,
        is_controlled,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_lab_orders.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_lab_orders') }}
),

renamed as (
    select
        lab_order_id,
        encounter_id,
        patient_id,
        provider_id,
        test_name,
        test_code,
        ordered_date,
        status                                          as order_status,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_lab_results.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_lab_results') }}
),

renamed as (
    select
        result_id,
        lab_order_id,
        result_value,
        result_unit,
        reference_range,
        is_abnormal,
        result_date,
        notes                                           as result_notes,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_vitals.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_vitals') }}
),

renamed as (
    select
        vital_id,
        encounter_id,
        patient_id,
        measured_date,
        systolic_bp,
        diastolic_bp,
        heart_rate,
        respiratory_rate,
        temperature_f,
        weight_kg,
        height_cm,
        oxygen_saturation,
        case
            when systolic_bp >= 140 or diastolic_bp >= 90 then 'Hypertensive'
            when systolic_bp >= 120 or diastolic_bp >= 80 then 'Elevated'
            else 'Normal'
        end                                             as bp_classification,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

New-DbtModel "stg_pg_allergies.sql" @'
{{ config(materialized='view') }}

with source as (
    select * from {{ source('pg_clinical', 'pg_allergies') }}
),

renamed as (
    select
        allergy_id,
        patient_id,
        allergen,
        reaction,
        severity,
        identified_date,
        is_active,
        created_at,
        {{ get_metadata_columns() }}
    from source
)

select * from renamed
'@

# Sources YAML
@'
version: 2

sources:
  - name: pg_clinical
    description: "Clinical data from Supabase PostgreSQL"
    database: HEALTHCARE_DW
    schema: RAW

    tables:
      - name: pg_icd10_codes
      - name: pg_cpt_codes
      - name: pg_specialty_types
      - name: pg_states
      - name: pg_facility_types
      - name: pg_facilities
      - name: pg_providers
      - name: pg_patients
      - name: pg_insurance_carriers
      - name: pg_employees
      - name: pg_encounters
      - name: pg_encounter_diagnoses
      - name: pg_encounter_procedures
      - name: pg_prescriptions
      - name: pg_lab_orders
      - name: pg_lab_results
      - name: pg_vitals
      - name: pg_allergies
'@ | Out-File -FilePath "$StagingPath\_pg_sources.yml" -Encoding UTF8
Write-Host "Created _pg_sources.yml" -ForegroundColor Green

Write-Host "`n=========================================" -ForegroundColor Yellow
Write-Host " 18 PostgreSQL staging models created" -ForegroundColor Yellow
Write-Host " 1 sources.yml created" -ForegroundColor Yellow
Write-Host " 1 macro file created" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow