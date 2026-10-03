{{ config(materialized='table') }}

with drug_names as (

    select distinct
        brand_name,
        generic_name
    from {{ ref('stg_part_d__prescriber_drug') }}

),

flags as (

    select * from {{ ref('stg_part_d__drug_class_flags') }}

),

joined as (

    select
        md5(concat_ws('|', d.brand_name, d.generic_name)) as drug_key,
        d.brand_name,
        d.generic_name,
        coalesce(f.is_opioid, false)         as is_opioid,
        coalesce(f.is_la_opioid, false)      as is_la_opioid,
        coalesce(f.is_antibiotic, false)     as is_antibiotic,
        coalesce(f.is_antipsychotic, false)  as is_antipsychotic

    from drug_names d
    left join flags f
        on d.brand_name = f.drug_name
        and d.generic_name = f.generic_name

)

select * from joined