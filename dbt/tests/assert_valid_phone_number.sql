select *
from {{ ref('customers') }}
where phone_number !~ '^\+[1-9][0-9]{6,14}$'