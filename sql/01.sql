-- STG
CREATE TABLE IF NOT EXISTS stg_transactions (
    trans_id VARCHAR(128),
    trans_date TIMESTAMP, 
    card_num VARCHAR(128),
    oper_type VARCHAR(128),
    amt DECIMAL(15,2),
    oper_result VARCHAR(128),
    terminal VARCHAR(128),
    load_dt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    file_name VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS stg_terminals (
    terminal_id VARCHAR(128),
    terminal_type VARCHAR(128),
    terminal_city VARCHAR(128),
    terminal_address VARCHAR(128),
    load_dt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    file_name VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS stg_passport_blacklist (
    entry_dt DATE,
    passport_num VARCHAR(128),
    load_dt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    file_name VARCHAR(100)
);
CREATE TABLE IF NOT EXISTS stg_clients (
    client_id         VARCHAR(128),
    last_name         VARCHAR(128),
    first_name        VARCHAR(128),
    patronymic        VARCHAR(128),
    date_of_birth     DATE,
    passport_num      VARCHAR(128),
    passport_valid_to DATE,
    phone             VARCHAR(128)
);

CREATE TABLE IF NOT EXISTS stg_accounts (
    account_num VARCHAR(128), 
    valid_to DATE,
    client VARCHAR(128)
);

CREATE TABLE IF NOT EXISTS stg_cards (
    card_num VARCHAR(128),
    account_num VARCHAR(128)
);

-- DWH (SDC2)

CREATE TABLE IF NOT EXISTS dwh_dim_terminals_hist (
    terminal_id VARCHAR(128),
    terminal_type VARCHAR(128),
    terminal_city VARCHAR(128),
    terminal_address VARCHAR(128),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    deleted_flg VARCHAR(1) DEFAULT '0',
    PRIMARY KEY (terminal_id, effective_from) 
);

-- DWH (SCD1) 
CREATE TABLE IF NOT EXISTS dwh_dim_cards (
    card_num VARCHAR(128) PRIMARY KEY,
    account_num VARCHAR(128),
    create_dt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_dt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dwh_dim_accounts (
    account_num VARCHAR(128) PRIMARY KEY,
    valid_to DATE,
    client VARCHAR(128),
    create_dt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_dt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dwh_dim_clients (
    client_id VARCHAR(128) PRIMARY KEY,
    last_name VARCHAR(128),
    first_name VARCHAR(128),
    patronymic VARCHAR(128),
    date_of_birth DATE,
    passport_num VARCHAR(128),
    passport_valid_to DATE,
    phone VARCHAR(128),
    create_dt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_dt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- DWH (FACT)
CREATE TABLE IF NOT EXISTS dwh_fact_transactions (
    trans_id VARCHAR(128) PRIMARY KEY,
    trans_date TIMESTAMP,
    card_num VARCHAR(128),
    oper_type VARCHAR(128),
    amt DECIMAL(15,2),
    oper_result VARCHAR(128),
    terminal VARCHAR(128),
    create_dt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dwh_fact_passport_blacklist (
    passport_num VARCHAR(128) PRIMARY KEY,
    entry_dt     DATE,
    create_dt    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- REP_FRAUD 
CREATE TABLE IF NOT EXISTS rep_fraud (
    event_dt TIMESTAMP,
    passport VARCHAR(128),
    fio VARCHAR(512), 
    phone VARCHAR(128),
    event_type VARCHAR(128),
    report_dt DATE
);
