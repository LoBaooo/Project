-- Новые транзакции
INSERT INTO dwh_fact_transactions (
    trans_id, trans_date, card_num, oper_type, amt, oper_result, terminal
)
SELECT 
    transaction_id,     
    transaction_date::timestamp,  
    card_num, 
    oper_type, 
    amount::decimal,        
    oper_result, 
    terminal
FROM stg_transactions
ON CONFLICT (trans_id) DO NOTHING;

-- Черного список паспортов (новые)
INSERT INTO dwh_fact_passport_blacklist (passport_num, entry_dt)
SELECT 
    passport, 
    date::date
FROM stg_passport_blacklist
ON CONFLICT (passport_num) DO NOTHING;
