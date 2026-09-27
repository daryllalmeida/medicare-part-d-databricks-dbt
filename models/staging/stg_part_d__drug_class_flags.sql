{{ config(materialized = 'table') }}

with source as (
    select * 
    from {{ source('bronze','drug_class_flags') }}
),

renamed as (
    select 
    upper(trim(drug_name)) as drug_name,
    upper(trim(generic_name)) as generic_name,
    (upper(trim(opioid_flag)) = 'Y' ) as is_opioid,
    (upper(trim(la_opioid_flag)) = 'Y' ) as is_la_opioid,    
    (upper(trim(antibiotic_flag)) = 'Y' ) as is_antibiotic,
    (upper(trim(antipsychotic_flag)) = 'Y' ) as is_antipsychotic,   
    (upper(trim(ndc_conflict_flag)) = 'Y' ) as has_ndc_conflict
    from source        
)


select * from renamed