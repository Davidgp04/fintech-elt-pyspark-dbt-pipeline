select email
from {{ ref('customers') }}
where length(email) != length(replace(trim(email), ' ', ''))