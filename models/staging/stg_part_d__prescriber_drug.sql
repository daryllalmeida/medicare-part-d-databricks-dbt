{{ config(materialized='table') }}

with source as (

    select * from {{ source('bronze', 'prescriber_drug') }}

),

renamed as (

    select
        -- prescriber
        try_cast(nullif(trim(Prscrbr_NPI), '') as bigint)         as prescriber_npi,
        nullif(trim(Prscrbr_Last_Org_Name), '')                   as prescriber_last_or_org_name,
        nullif(trim(Prscrbr_First_Name), '')                      as prescriber_first_name,
        nullif(trim(Prscrbr_City), '')                            as prescriber_city,
        nullif(trim(Prscrbr_State_Abrvtn), '')                    as prescriber_state,
        try_cast(nullif(trim(Prscrbr_State_FIPS), '') as int)     as prescriber_state_fips,
        nullif(trim(Prscrbr_Type), '')                            as prescriber_type,
        nullif(trim(Prscrbr_Type_Src), '')                        as prescriber_type_source,

        -- drug
        upper(trim(Brnd_Name))                                    as brand_name,
        upper(trim(Gnrc_Name))                                    as generic_name,

        -- measures, all beneficiaries
        try_cast(nullif(trim(Tot_Clms), '') as bigint)            as total_claims,
        try_cast(nullif(trim(Tot_30day_Fills), '') as decimal(18,1)) as total_30day_fills,
        try_cast(nullif(trim(Tot_Day_Suply), '') as bigint)       as total_day_supply,
        try_cast(nullif(trim(Tot_Drug_Cst), '') as decimal(18,2)) as total_drug_cost,
        try_cast(nullif(trim(Tot_Benes), '') as bigint)           as total_beneficiaries,

        -- measures, age 65+ (blank when CMS suppressed them)
        nullif(trim(GE65_Sprsn_Flag), '')                         as ge65_suppression_flag,
        try_cast(nullif(trim(GE65_Tot_Clms), '') as bigint)       as ge65_total_claims,
        try_cast(nullif(trim(GE65_Tot_30day_Fills), '') as decimal(18,1)) as ge65_total_30day_fills,
        try_cast(nullif(trim(GE65_Tot_Drug_Cst), '') as decimal(18,2)) as ge65_total_drug_cost,
        try_cast(nullif(trim(GE65_Tot_Day_Suply), '') as bigint)  as ge65_total_day_supply,
        nullif(trim(GE65_Bene_Sprsn_Flag), '')                    as ge65_bene_suppression_flag,
        try_cast(nullif(trim(GE65_Tot_Benes), '') as bigint)      as ge65_total_beneficiaries,

        data_year

    from source

),

final as (

    select
        md5(concat_ws('|',
            cast(prescriber_npi as string),
            brand_name,
            generic_name,
            cast(data_year as string)
        ))                                              as prescriber_drug_key,

        *,

        ge65_suppression_flag is not null               as is_ge65_suppressed,
        ge65_bene_suppression_flag is not null          as is_ge65_bene_suppressed

    from renamed

)

select * from final