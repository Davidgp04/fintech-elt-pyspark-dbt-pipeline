select * from {{ ref('accounts') }}
where (account_type = 'credit_card'
and credit_limit is null) or (account_type != 'credit_card' and credit_limit is not null)