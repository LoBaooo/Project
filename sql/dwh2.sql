-- Новые терминал 
INSERT INTO dwh_dim_terminals_hist (
    terminal_id, terminal_type, terminal_city, terminal_address, 
    effective_from, effective_to, deleted_flg
)
SELECT 
    stg.terminal_id, 
    stg.terminal_type, 
    stg.terminal_city, 
    stg.terminal_address,
    CURRENT_TIMESTAMP::timestamp(0) AS effective_from,
    '5999-12-31 23:59:59'::timestamp(0) AS effective_to,
    '0' AS deleted_flg
FROM stg_terminals stg
LEFT JOIN dwh_dim_terminals_hist tgt 
    ON stg.terminal_id = tgt.terminal_id
WHERE tgt.terminal_id IS NULL;


-- Врменная таблица с терминалом, если данные изменились
CREATE TEMP TABLE tmp_updated_terminals AS
SELECT stg.terminal_id
FROM stg_terminals stg
INNER JOIN dwh_dim_terminals_hist tgt 
    ON stg.terminal_id = tgt.terminal_id
WHERE tgt.effective_to = '5999-12-31 23:59:59'::timestamp(0)
  AND (
       tgt.terminal_type <> stg.terminal_type OR
       tgt.terminal_city <> stg.terminal_city OR
       tgt.terminal_address <> stg.terminal_address
  );


-- Старые записи (временная таблица)
UPDATE dwh_dim_terminals_hist
SET effective_to = CURRENT_TIMESTAMP::timestamp(0) - INTERVAL '1 second'
WHERE terminal_id IN (SELECT terminal_id FROM tmp_updated_terminals)
  AND effective_to = '5999-12-31 23:59:59'::timestamp(0);


-- Новые данные терминала
INSERT INTO dwh_dim_terminals_hist (
    terminal_id, terminal_type, terminal_city, terminal_address, 
    effective_from, effective_to, deleted_flg
)
SELECT 
    stg.terminal_id, 
    stg.terminal_type, 
    stg.terminal_city, 
    stg.terminal_address,
    CURRENT_TIMESTAMP::timestamp(0) AS effective_from,
    '5999-12-31 23:59:59'::timestamp(0) AS effective_to,
    '0' AS deleted_flg
FROM stg_terminals stg
WHERE stg.terminal_id IN (SELECT terminal_id FROM tmp_updated_terminals);


-- Удалить таблицу
DROP TABLE tmp_updated_terminals;
