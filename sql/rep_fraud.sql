CREATE INDEX IF NOT EXISTS idx_trans_card ON dwh_fact_transactions(card_num);
CREATE INDEX IF NOT EXISTS idx_trans_date ON dwh_fact_transactions(trans_date);
CREATE INDEX IF NOT EXISTS idx_trans_oper ON dwh_fact_transactions(oper_result);

-- 1. Совершение операции при просроченном или заблокированном паспорте.
INSERT INTO rep_fraud (event_dt, passport, fio, phone, event_type, report_dt)
SELECT 
    t.trans_date AS event_dt,
    c.passport_num AS passport,
    c.last_name || ' ' || c.first_name || ' ' || c.patronymic AS fio,
    c.phone,
    'Совершение операции при просроченном или заблокированном паспорте' AS event_type,
    CURRENT_DATE AS report_dt
FROM dwh_fact_transactions t
JOIN dwh_dim_cards ca ON t.card_num = ca.card_num
JOIN dwh_dim_accounts a ON ca.account_num = a.account_num
JOIN dwh_dim_clients c ON a.client = c.client_id
LEFT JOIN dwh_fact_passport_blacklist b ON c.passport_num = b.passport_num
WHERE t.oper_result = 'SUCCESS'
  AND (c.passport_valid_to < t.trans_date::date OR b.entry_dt <= t.trans_date::date)
  AND NOT EXISTS (
      SELECT 1 FROM rep_fraud rf 
      WHERE rf.event_dt = t.trans_date AND rf.passport = c.passport_num
  );



-- 2. Совершение операции при недействующем договоре (счете).
INSERT INTO rep_fraud (event_dt, passport, fio, phone, event_type, report_dt)
SELECT 
    t.trans_date AS event_dt,
    c.passport_num AS passport,
    c.last_name || ' ' || c.first_name || ' ' || c.patronymic AS fio,
    c.phone,
    'Совершение операции при недействующем договоре (счете)' AS event_type,
    CURRENT_DATE AS report_dt
FROM dwh_fact_transactions t
JOIN dwh_dim_cards ca ON t.card_num = ca.card_num
JOIN dwh_dim_accounts a ON ca.account_num = a.account_num
JOIN dwh_dim_clients c ON a.client = c.client_id
WHERE t.oper_result = 'SUCCESS'
  AND a.valid_to < t.trans_date::date
  AND NOT EXISTS (
      SELECT 1 FROM rep_fraud rf 
      WHERE rf.event_dt = t.trans_date AND rf.passport = c.passport_num
  );

-- 3. Совершение операций в разных городах в течение одного часа.
INSERT INTO rep_fraud (event_dt, passport, fio, phone, event_type, report_dt)
SELECT DISTINCT 
    t2.trans_date AS event_dt,
    c.passport_num AS passport,
    c.last_name || ' ' || c.first_name || ' ' || c.patronymic AS fio,
    c.phone,
    'Совершение операций в разных городах в течение 1 часа' AS event_type,
    CURRENT_DATE AS report_dt
FROM dwh_fact_transactions t1
JOIN dwh_fact_transactions t2 
    ON t1.card_num = t2.card_num
   AND t1.trans_date < t2.trans_date 
   AND t2.trans_date <= t1.trans_date + INTERVAL '1 hour'
JOIN dwh_dim_terminals_hist term1 ON t1.terminal = term1.terminal_id
JOIN dwh_dim_terminals_hist term2 ON t2.terminal = term2.terminal_id
JOIN dwh_dim_cards ca ON t2.card_num = ca.card_num
JOIN dwh_dim_accounts a ON ca.account_num = a.account_num
JOIN dwh_dim_clients c ON a.client = c.client_id
WHERE t1.oper_result = 'SUCCESS' 
  AND t2.oper_result = 'SUCCESS'
  AND term1.terminal_city <> term2.terminal_city
  AND NOT EXISTS (
      SELECT 1 FROM rep_fraud rf 
      WHERE rf.event_dt = t2.trans_date AND rf.passport = c.passport_num
  );

--4. Попытка подбора суммы (20 минут)
INSERT INTO rep_fraud (event_dt, passport, fio, phone, event_type, report_dt)
SELECT DISTINCT 
    t4.trans_date AS event_dt,
    c.passport_num AS passport,
    c.last_name || ' ' || c.first_name || ' ' || c.patronymic AS fio,
    c.phone,
    'Попытка подбора суммы' AS event_type,
    CURRENT_DATE AS report_dt
FROM dwh_fact_transactions t1
JOIN dwh_fact_transactions t2 
    ON t1.card_num = t2.card_num AND t1.trans_date < t2.trans_date AND t2.amt < t1.amt
JOIN dwh_fact_transactions t3 
    ON t2.card_num = t3.card_num AND t2.trans_date < t3.trans_date AND t3.amt < t2.amt
JOIN dwh_fact_transactions t4 
    ON t3.card_num = t4.card_num AND t3.trans_date < t4.trans_date AND t4.amt < t3.amt
JOIN dwh_dim_cards ca ON t4.card_num = ca.card_num
JOIN dwh_dim_accounts a ON ca.account_num = a.account_num
JOIN dwh_dim_clients c ON a.client = c.client_id
WHERE t1.oper_result = 'REJECT'
  AND t2.oper_result = 'REJECT'
  AND t3.oper_result = 'REJECT'
  AND t4.oper_result = 'SUCCESS'
  AND t4.trans_date <= t1.trans_date + INTERVAL '20 minutes'
  AND NOT EXISTS (
      SELECT 1 FROM rep_fraud rf 
      WHERE rf.event_dt = t4.trans_date AND rf.passport = c.passport_num
  );

