TRUNCATE TABLE stg_clients;
INSERT INTO stg_clients 
SELECT client_id, last_name, first_name, patronymic, date_of_birth, passport_num, passport_valid_to, phone 
FROM clients;

TRUNCATE TABLE stg_accounts;
INSERT INTO stg_accounts (account_num, valid_to, client) 
SELECT account, valid_to, client 
FROM accounts;

TRUNCATE TABLE stg_cards;
INSERT INTO stg_cards (card_num, account_num)
SELECT card_num, account 
FROM cards;
