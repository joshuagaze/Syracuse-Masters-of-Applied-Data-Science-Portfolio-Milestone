/*
	Author: Joshua A. Gaze
	Course: IST659 M402
	Loyalty Project
	Term: Fall 2021
*/

-- creating the GROUPS table
CREATE TABLE GROUPS (
	-- attributes/fields for the User table
	groups_id int identity,
	group_name varchar(20) not null,
	client_code varchar(4) not null,
	parent_groups_id int not null,
	group_type varchar(10),
	-- Constraints on the User table
	CONSTRAINT PK_groups PRIMARY KEY (groups_id),
	CONSTRAINT U1_groups UNIQUE(group_name),
	CONSTRAINT FK1_groups FOREIGN KEY (parent_groups_id) REFERENCES groups(groups_id)
)
-- end of GROUPS table creation

-- creating the PROGRAM table
CREATE TABLE PROGRAM (
	-- columns for the user_login table
	program_id int identity,
	groups_id int not null,
	pgm_name varchar(40) not null,
	pgm_type varchar(10) not null,
	pgm_start_date datetime not null default GetDate(),
	pgm_end_date datetime,
	-- Constraints on the user_login table
	CONSTRAINT PK_PROGRAM PRIMARY KEY (program_id),
	CONSTRAINT FK1_PROGRAM FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id)
)
-- end of PROGRAM table creation


-- creating the ACCOUNT table
CREATE TABLE ACCOUNT (
	-- columns for the follower_list table
	account_id int identity,
	groups_id int not null,
	earn_flg varchar(1) not null,
	burn_flg varchar(1) not null,
	status_type varchar(2) not null,
	forfeit_points_flg varchar(1) not null,
	enrolled_date datetime not null default GetDate(),
	cancelled_date datetime,
	-- Constraints on the Follower_List table
	CONSTRAINT PK_ACCOUNT PRIMARY KEY (account_id),
	CONSTRAINT FK1_ACCOUNT FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id),
)
-- end of ACCOUNT table creation

-- creating the ACCOUNT_XREFERENCE table
CREATE TABLE ACCOUNT_XREFERENCE (
	-- columns for the ACCOUNT_XREFERENCE table
	account_xreference_id int identity,
	account_id int not null,
	account_number varchar(12) not null,
	card_number varchar(16) not null,
	active_flg varchar(1) not null,
	groups_id int not null,
	-- Constraints of the ACCOUNT_XREFERENCE table
	CONSTRAINT PK_ACCOUNT_XREFERENCE PRIMARY KEY (account_xreference_id),
	CONSTRAINT FK1_ACCOUNT_XREFERENCE FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id),
	CONSTRAINT FK2_ACCOUNT_XREFERENCE FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id)
)
-- end of ACCOUNT_XREFERENCE table creation

-- creating of ACCOUNT_USERS table
CREATE TABLE ACCOUNT_USERS (
	-- columns for the ACCOUNT_USERS table
	account_users_id int identity,
	account_id int not null,
	account_xreference_id int not null,
	active_flg varchar(1) not null,
	groups_id int not null,
	user_level_type varchar(1) not null,
	enrolled_date datetime not null,
	-- Constraints on the ACCOUNT_USERS table
	CONSTRAINT PK_ACCOUNT_USERS PRIMARY KEY (account_users_id),
	CONSTRAINT FK1_ACCOUNT_USERS FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id),
	CONSTRAINT FK2_ACCOUNT_USERS FOREIGN KEY (account_xreference_id) REFERENCES ACCOUNT_XREFERENCE(account_xreference_id),
	CONSTRAINT FK3_ACCOUNT_USERS FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id)
)
-- end of ACCOUNT_USERS table creation


-- creating the TRANSACTION table
CREATE TABLE TRANSACTIONN (
	-- columns for the TRANSACTIONN table
	transactionn_id int identity,
	groups_id int not null,
	account_id int not null,
	card_number varchar(16) not null,
	account_users_id int not null,
	sales_date datetime not null,
	posting_date datetime not null default GetDate(),
	sales_amount decimal(6,2) not null,
	-- Constraints of the TRANSACTION table
	CONSTRAINT PK_TRANSACTIONN PRIMARY KEY (transactionn_id),
	CONSTRAINT FK1_TRANSACTIONN FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id),
	CONSTRAINT FK2_TRANSACTIONN FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id),
	CONSTRAINT FK3_TRANSACTIONN FOREIGN KEY (account_users_id) REFERENCES ACCOUNT_USERS(account_users_id)
)
-- end of TRANSACTIONN table creation

-- creating the REWARDS_TRANSACTION table
CREATE TABLE REWARDS_TRANSACTION (
	-- columns for the REWARDS_TRANSACTION table
	rewards_transaction_id int identity,
	account_id int not null,
	account_users_id int not null,
	groups_id int not null,
	rewards_value decimal(12,0) not null,
	program_id int not null,
	order_confirmation_number varchar(20) not null,
	create_time datetime not null default GetDate(),
	-- Constraints of the REWARDS_TRANSACTION table
	CONSTRAINT PK_REWARDS_TRANSACTION PRIMARY KEY (rewards_transaction_id),
	CONSTRAINT FK1_REWARDS_TRANSACTION FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id),
	CONSTRAINT FK2_REWARDS_TRANSACTION FOREIGN KEY (account_users_id) REFERENCES ACCOUNT_USERS(account_users_id),
	CONSTRAINT FK3_REWARDS_TRANSACTION FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id),
	CONSTRAINT FK4_REWARDS_TRANSACTION FOREIGN KEY (program_id) REFERENCES PROGRAM(program_id)
)

-- end of REWARDS_TRANSACTION table creation

-- creating of ITEM table
CREATE TABLE ITEM (
	-- columns for the ITEM table
	item_id int identity, 
	item_name varchar(20) not null,
	item_description varchar(300),
	item_cost decimal(5,2) not null,
	model_number varchar(30),
	SKU varchar(50) not null,
	-- Constraints of the ITEM table
	CONSTRAINT PK_ITEM PRIMARY KEY (item_id),
	CONSTRAINT U1_ITEM UNIQUE (item_name)
)
-- end of ITEM table creation

-- creating of REWARDS_TRANSACTION_ITEM table
CREATE TABLE REWARDS_TRANSACTION_ITEM (
	-- columns for the REWARDS_TRANSACTION_ITEM table
	rewards_transaction_item_id int identity not null,
	rewards_transaction_id int not null,
	rewards_value decimal not null,
	item_cost decimal(6,2),
	item_id int not null,
	rewards_items_type varchar(30) not null,
	quantity decimal not null,
	groups_id int not null
	-- Constraints of the REWARDS_TRANSACTION_ITEM table
	CONSTRAINT PK_REWARDS_TRANSACTION_ITEM PRIMARY KEY (rewards_transaction_item_id)
	CONSTRAINT FK1_REWARDS_TRANSACTION_ITEM FOREIGN KEY (rewards_transaction_id) REFERENCES REWARDS_TRANSACTION(rewards_transaction_id),
	CONSTRAINT FK2_REWARDS_TRANSACTION_ITEM FOREIGN KEY (item_id) REFERENCES ITEM(item_id),
	CONSTRAINT FK3_REWARDS_TRANSACTION_ITEM FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id)
)
-- end of REWARDS_TRANSACTION_ITEM table creation

-- creating of REWARDS_ACTIVITY table
CREATE TABLE REWARDS_ACTIVITY (
	-- columns for the REWARDS_ACTIVITY table
	rewards_activity_id int identity not null,
	account_id int not null,
	account_users_id int not null,
	rewards_value decimal not null,
	rewards_type varchar(5) not null,
	rewards_activity_type varchar(20) not null,
	program_id int not null,
	groups_id int not null,
	sales_date datetime, 
	posting_date datetime not null,
	tender_amount decimal(6,2),
	transactionn_id int,
	rewards_transaction_id int,
	rewards_transaction_item_id int,
	-- Constraints of the REWARDS_ACTIVITY table
	CONSTRAINT PK_REWARDS_ACTIVITY PRIMARY KEY (rewards_activity_id),
	CONSTRAINT FK1_REWARDS_ACTIVITY FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id),
	CONSTRAINT FK2_REWARDS_ACTIVITY FOREIGN KEY (account_users_id) REFERENCES ACCOUNT_USERS(account_users_id),
	CONSTRAINT FK3_REWARDS_ACTIVITY FOREIGN KEY (program_id) REFERENCES PROGRAM(program_id),
	CONSTRAINT FK4_REWARDS_ACTIVITY FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id),
	CONSTRAINT FK5_REWARDS_ACTIVITY FOREIGN KEY (transactionn_id) REFERENCES TRANSACTIONN(transactionn_id),
	CONSTRAINT FK6_REWARDS_ACTIVITY FOREIGN KEY (rewards_transaction_id) REFERENCES REWARDS_TRANSACTION(rewards_transaction_id),
	CONSTRAINT FK7_REWARDS_ACTIVITY FOREIGN KEY (rewards_transaction_item_id) REFERENCES REWARDS_TRANSACTION_ITEM(rewards_transaction_item_id)
)
-- end of REWARDS_ACTIVITY table creation

-- creating of ACCOUNT_BALANCE table
CREATE TABLE ACCOUNT_BALANCE (
	-- columns for the ACCOUNT_BALANCE table
	account_balance_id int identity not null,
	groups_id int not null,
	account_id int not null,
	available_balance decimal not null,
	unvested_points decimal,
	update_time datetime,
	expiration_date datetime,
	-- Constraints of the ACCOUNT_BALANCE table
	CONSTRAINT PK_ACCOUNT_BALANCE PRIMARY KEY (account_balance_id),
	CONSTRAINT FK1_ACCOUNT_BALANCE FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id),
	CONSTRAINT FK2_ACCOUNT_BALANCE FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id)
)
-- end of ACCOUNT_BALANCE table creation


