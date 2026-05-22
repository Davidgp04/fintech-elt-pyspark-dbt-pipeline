select lon
from {{ ref('geography') }}
where abs(lon) > 180