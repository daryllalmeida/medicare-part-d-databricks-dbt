{{
  config(
    materialized = 'table',
    )
}}

with detail_summary as (
    select data_year as calendar_year,
    sum(total_claims) as detail_claim,
    sum(total_drug_cost) as detail_cost

    from {{ ref('fct_prescriber_drug_year') }}
    group by data_year
),

official as (
    select calendar_year,
    total_claims as official_claims,
    total_drug_cost  as official_cost
    from {{ ref("stg_part_d__national_totals_by_year") }}
),

joined as (
    select o.calendar_year,
    d.detail_claim,
    o.official_claims, 
    round(d.detail_claim/ o.official_claims * 100,1) as claims_coverage_pct,
    d.detail_cost,o.official_cost,
    round(d.detail_cost / o.official_cost * 100,1) as cost_coverage_pct
    from official o 
    left join detail_summary d on o.calendar_year = d.calendar_year
)



select *
from joined