{{
  config(
    materialized = 'table',
    )
}}

select prescriber_drug_key,
prescriber_npi, md5(concat_ws('|', brand_name, generic_name))  as drug_key,
    data_year,
    total_claims,
    total_30day_fills,
    total_day_supply,
    total_drug_cost,
    total_beneficiaries,
    ge65_total_claims,
    ge65_total_30day_fills,
    ge65_total_day_supply,
    ge65_total_drug_cost,
    ge65_total_beneficiaries,
    is_ge65_suppressed,
    is_ge65_bene_suppressed

from {{ ref("stg_part_d__prescriber_drug") }}