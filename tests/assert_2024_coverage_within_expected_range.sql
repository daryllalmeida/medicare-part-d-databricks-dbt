select *
from {{ ref('mart_reconciliation_coverage') }}
where detail_claim is not null
and (claims_coverage_pct not between 80 and 95 or claims_coverage_pct not between 70 and 90)