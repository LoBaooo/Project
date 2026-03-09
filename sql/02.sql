--  Загрузка транзакций
INSERT INTO dwh_fact_transactions (
    trans_id, trans_date, card_num, oper_type, amt, oper_result, terminal
)
SELECT 
    transaction_id,     
    transaction_date::timestamp(0),  
    card_num, 
    oper_type, 
    amount::decimal,              
    oper_result, 
    terminal
FROM stg_transactions
ON CONFLICT (trans_id) DO NOTHING;

-- Загрузка черного списка паспортов
INSERT INTO dwh_fact_passport_blacklist (passport_num, entry_dt)
SELECT 
    passport,  
    date::date       
FROM stg_passport_blacklist
ON CONFLICT (passport_num) DO NOTHING;


--  Загрузка карт (SCD1)
INSERT INTO dwh_dim_cards (card_num, account_num, create_dt, update_dt)
SELECT 
    card_num, 
    account_num, 
    CURRENT_TIMESTAMP::timestamp(0),
    CURRENT_TIMESTAMP::timestamp(0)
FROM stg_cards
ON CONFLICT (card_num) DO UPDATE SET
    account_num = EXCLUDED.account_num,
    update_dt = CURRENT_TIMESTAMP::timestamp(0)
WHERE dwh_dim_cards.account_num <> EXCLUDED.account_num;


-- Загрузка счетов (SCD1)
INSERT INTO dwh_dim_accounts (account_num, valid_to, client, create_dt, update_dt)
SELECT 
    account_num, 
    valid_to::date, 
    client, 
    CURRENT_TIMESTAMP::timestamp(0),
    CURRENT_TIMESTAMP::timestamp(0)
FROM stg_accounts
ON CONFLICT (account_num) DO UPDATE SET
    valid_to = EXCLUDED.valid_to,
    client = EXCLUDED.client,
    update_dt = CURRENT_TIMESTAMP::timestamp(0)
WHERE dwh_dim_accounts.valid_to <> EXCLUDED.valid_to 
   OR dwh_dim_accounts.client <> EXCLUDED.client;


--  Загрузка клиентов (SCD1)
INSERT INTO dwh_dim_clients (client_id, last_name, 
first_name, patronymic, date_of_birth, passport_num, passport_valid_to, phone, create_dt, update_dt)
SELECT 
    client_id, 
    last_name, 
    first_name, 
    patronymic, 
    date_of_birth::date, 
    passport_num, 
    passport_valid_to::date, 
    phone,
    CURRENT_TIMESTAMP::timestamp(0),
    CURRENT_TIMESTAMP::timestamp(0)
FROM stg_clients
ON CONFLICT (client_id) DO UPDATE SET
    last_name = EXCLUDED.last_name,
    first_name = EXCLUDED.first_name,
    patronymic = EXCLUDED.patronymic,
    date_of_birth = EXCLUDED.date_of_birth,
    passport_num = EXCLUDED.passport_num,
    passport_valid_to = EXCLUDED.passport_valid_to,
    phone = EXCLUDED.phone,
    update_dt = CURRENT_TIMESTAMP::timestamp(0)
WHERE dwh_dim_clients.last_name <> EXCLUDED.last_name 
   OR dwh_dim_clients.first_name <> EXCLUDED.first_name
   OR dwh_dim_clients.patronymic <> EXCLUDED.patronymic
   OR dwh_dim_clients.date_of_birth <> EXCLUDED.date_of_birth
   OR dwh_dim_clients.passport_num <> EXCLUDED.passport_num
   OR dwh_dim_clients.passport_valid_to <> EXCLUDED.passport_valid_to
   OR dwh_dim_clients.phone <> EXCLUDED.phone;

