{{
  config(
    materialized = 'table',
    )
}}

with prescribers as(
    select distinct
    prescriber_npi,
    prescriber_last_or_org_name,
    prescriber_first_name,
    prescriber_city,
    prescriber_state,
    prescriber_state_fips,
    prescriber_type,
    prescriber_type_source

    from {{ref('stg_part_d__prescriber_drug') }}
)

select *
from prescribers