{{config(materialized = 'table')}}

with source as (
    select *
    from {{ source('bronze','national_totals_by_year') }}
)
,

renamed as (
    select
        `Calendar Year`                                                  as calendar_year,

        -- all beneficiaries
        `Total Claims`                                                   as total_claims,
        `Total Standardized 30-Day Fills`                                as total_30day_fills,
        `Total Drug Cost`                                                as total_drug_cost,
        `Total Beneficiaries`                                            as total_beneficiaries,
        `Total Prescribers`                                              as total_prescribers,

        -- age 65+
        `Total Claims for Beneficiaries  (Age 65+)`                      as ge65_total_claims,
        `Total Standardized 30-Day Fills for Beneficiaries (Age 65+)`    as ge65_total_30day_fills,
        `Total Drug Cost for Beneficiaries  (Age 65+)`                   as ge65_total_drug_cost,
        `Total Beneficiaries (Age 65+)`                                  as ge65_total_beneficiaries,

        -- brand / generic / other
        `Total Claims for Brand Drugs`                                   as brand_total_claims,
        `Total Drug Cost  for Brand Drugs`                               as brand_total_drug_cost,
        `Total Claims for Generic Drugs`                                 as generic_total_claims,
        `Total Drug Cost for Generic Drugs`                              as generic_total_drug_cost,
        `Total Claims for Other Drugs`                                   as other_total_claims,
        `Total Drug Cost for Other Drugs`                                as other_total_drug_cost,

        -- LIS / non-LIS
        `Total Claims for LIS Beneficiaries`                             as lis_total_claims,
        `Total Drug Cost for LIS Beneficiaries`                          as lis_total_drug_cost,
        `Total Claims for NonLIS Beneficiaries`                          as nonlis_total_claims,
        `Total Drug Cost for NonLIS Beneficiaries`                       as nonlis_total_drug_cost,

        -- antibiotic
        `Total Claims for Antibiotic Drugs`                              as antibiotic_total_claims,
        `Total Drug Cost  for Antibiotic Drugs`                          as antibiotic_total_drug_cost,
        `Total Beneficiaries for Antibiotic Drugs`                       as antibiotic_total_beneficiaries,

        -- antipsychotic (age 65+)
        `Total Claims for Antipsychotic Drugs (Age 65+)`                 as antipsychotic_ge65_total_claims,
        `Total Drug Cost for Antipsychotic Drugs  (Age 65+)`             as antipsychotic_ge65_total_drug_cost,
        `Total Beneficiaries for Antipsychotic Drugs  (Age 65+)`         as antipsychotic_ge65_total_beneficiaries,

        -- opioid
        `Total Claims for Opioid Drugs`                                  as opioid_total_claims,
        `Total Drug Cost  for Opioid Drugs`                              as opioid_total_drug_cost,
        `Total Beneficiaries for Opioid Drugs`                           as opioid_total_beneficiaries,

        -- long-acting opioid
        `Total Claims for LA Opioid Drugs`                               as la_opioid_total_claims,
        `Total Drug Cost  for LA Opioid Drugs`                           as la_opioid_total_drug_cost,
        `Total Beneficiaries for LA Opioid Drugs`                        as la_opioid_total_beneficiaries

    from source

)

select * from renamed
