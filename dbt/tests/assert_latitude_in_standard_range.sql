-- tests/assert_latitude_in_standard_range.sql
select lat
from {{ ref('geography') }}
where abs(lat) > 90