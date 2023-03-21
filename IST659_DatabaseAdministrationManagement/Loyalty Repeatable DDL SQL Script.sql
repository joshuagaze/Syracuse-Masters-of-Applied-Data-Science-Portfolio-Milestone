-- Joshua Gaze IST659 M402 Fall 2021 Loyalty Project
/*
*********************************************************************************
drop all procedures
*********************************************************************************
*/
drop procedure if exists dbo.add_child_group;
drop procedure if exists dbo.assign_parent;
/*
*********************************************************************************
drop all tables in reverse order of their dependencies
*********************************************************************************
*/
DROP TABLE IF EXISTS DBO.REWARDS_ACTIVITY; 
GO
DROP TABLE IF EXISTS DBO.REWARDS_TRANSACTION_ITEM; 
GO
DROP TABLE IF EXISTS DBO.ITEM; 
GO
DROP TABLE IF EXISTS DBO.REWARDS_TRANSACTION; 
GO
DROP TABLE IF EXISTS DBO.TRANSACTIONN; 
GO
DROP TABLE IF EXISTS DBO.ACCOUNT_USERS; 
GO
DROP TABLE IF EXISTS DBO.ACCOUNT_XREFERENCE; 
GO
DROP TABLE IF EXISTS DBO.ACCOUNT; 
GO
DROP TABLE IF EXISTS DBO.PROGRAM; 
GO 
DROP TABLE IF EXISTS DBO.GROUPS; 
GO
/*
*********************************************************************************
create all tables in the order of their dependencies
*********************************************************************************
*/
/*
*********************************************************************************
BEGIN Creation of the Loyalty tables 
*********************************************************************************
*/
-- creating the GROUPS table
/* 
	GROUPS contains the partitions that our clients (the banks) wish to distribute their 
	associated cardholders in. This table represents a hierarchy system where we have 
	the bank (having parent_groups_id = 1) being at the top and their associated partitions 
	having their parent_groups_id equal to the groups_id of their parent. 
*/
CREATE TABLE GROUPS (
	-- attributes/fields for the GROUPS table
	groups_id int identity,
	name varchar(40) not null,
	client_code varchar(4) not null,
	parent_groups_id int,
	group_type varchar(10),
	-- Constraints on the GROUPS table
	CONSTRAINT PK_groups PRIMARY KEY (groups_id),
	CONSTRAINT U1_groups UNIQUE(name),
	CONSTRAINT FK1_groups FOREIGN KEY (parent_groups_id) REFERENCES groups(groups_id))
GO
-- end of GROUPS table creation
-- creating the PROGRAM table
/*
	PROGRAM contains the methods as to how we decide how a cardholder turns their spending activity 
	into points from an earnings perspective. Or also how a cardholder utlizes their points for 
	some loyalty rewards item(s).
*/
CREATE TABLE PROGRAM (
	-- columns for the PROGRAM table
	program_id int identity,
	name varchar(40) not null,
	pgm_type varchar(10) not null,
	pgm_start_date datetime not null default GetDate(),
	pgm_end_date datetime,
	points2dollar_rate float
	-- Constraints on the PROGRAM table
	CONSTRAINT PK_PROGRAM PRIMARY KEY (program_id),
	CONSTRAINT U1_PROGRAM UNIQUE (name))
GO
-- end of PROGRAM table creation
-- creating the ACCOUNT table
/*
	ACCOUNT belongs to the individual that has ownership of the loyalty rewards. Depending on their 
	current status with their corresponding issuing bank, they have the discretion as to how their 
	loyalty points are utilized. An account may have child account's, but those kinds of accounts exist 
	in the ACCOUNT_USERS table. 
*/
CREATE TABLE ACCOUNT (
	-- columns for the ACCOUNT table
	account_id int identity,
	groups_id int not null,
	enrolled_date datetime not null default GetDate(),
	cancelled_date datetime,
	earn_flg binary not null,
	burn_flg binary not null,
	status_type varchar(2) not null,
	forfeit_points_flg binary not null,
	-- Constraints on the ACCOUNT table
	CONSTRAINT PK_ACCOUNT PRIMARY KEY (account_id),
	CONSTRAINT FK1_ACCOUNT FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id),)
GO
-- end of ACCOUNT table creation
-- creating the ACCOUNT_XREFERENCE table
/*
	ACCOUNT_XREFERENCE is used as a cross reference table between ACCOUNT and ACCOUNT_USERS 
	so that we are able to distinguish the credit card that belongs to the specific ACCOUNT_USER
*/
CREATE TABLE ACCOUNT_XREFERENCE (
	-- columns for the ACCOUNT_XREFERENCE table
	account_xreference_id int identity,
	account_id int not null,
	account_number varchar(12) not null,
	card_number varchar(16) not null,
	active_flg binary not null,
	groups_id int not null,
	-- Constraints of the ACCOUNT_XREFERENCE table
	CONSTRAINT PK_ACCOUNT_XREFERENCE PRIMARY KEY (account_xreference_id),
	CONSTRAINT FK1_ACCOUNT_XREFERENCE FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id),
	CONSTRAINT FK2_ACCOUNT_XREFERENCE FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id))
GO
-- end of ACCOUNT_XREFERENCE table creation
-- creating of ACCOUNT_USERS table
/*
	The purpose of the ACCOUNT_USERS table is to prevent redundant data
	in the instance of a specific account wanting to have multiple cards
	associated with it. An example of this would be the primary account holder
	being the parent and the secondary users being his/her children. 
*/
CREATE TABLE ACCOUNT_USERS (
	-- columns for the ACCOUNT_USERS table
	account_users_id int identity,
	account_id int not null,
	account_xreference_id int not null,
	active_flg binary not null,
	user_level_type varchar(10),
	groups_id int not null,
	primary_account binary not null,
	enrolled_date datetime not null,
	-- Constraints on the ACCOUNT_USERS table
	CONSTRAINT PK_ACCOUNT_USERS PRIMARY KEY (account_users_id),
	CONSTRAINT FK1_ACCOUNT_USERS FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id),
	CONSTRAINT FK2_ACCOUNT_USERS FOREIGN KEY (account_xreference_id) REFERENCES ACCOUNT_XREFERENCE(account_xreference_id),
	CONSTRAINT FK3_ACCOUNT_USERS FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id))
GO
-- end of ACCOUNT_USERS table creation
-- creating the TRANSACTION table
/*
	TRANSACTIONN is the table that deals with all "card swipes", meaning that this deals
	with driving earnings of loyalty points that will be performed in the REWARDS_ACTIVITY table.
*/
CREATE TABLE TRANSACTIONN (
	-- columns for the TRANSACTIONN table
	transactionn_id int identity,
	groups_id int not null,
	account_id int not null,
	card_number varchar(16) not null,
	account_users_id int not null,
	sales_date date not null,
	posting_date date not null,
	sales_amount money not null,
	-- Constraints of the TRANSACTIONN table
	CONSTRAINT PK_TRANSACTIONN PRIMARY KEY (transactionn_id),
	CONSTRAINT FK1_TRANSACTIONN FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id),
	CONSTRAINT FK2_TRANSACTIONN FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id),
	CONSTRAINT FK3_TRANSACTIONN FOREIGN KEY (account_users_id) REFERENCES ACCOUNT_USERS(account_users_id))
GO
-- end of TRANSACTIONN table creation
-- creating the REWARDS_TRANSACTION table
/*
	REWARDS_TRANSACTION deals with the manipulation of an account's balance of points. 
	Things driving this table would include the redemption or forfeiture of points.
*/
CREATE TABLE REWARDS_TRANSACTION (
	-- columns for the REWARDS_TRANSACTION table
	rewards_transaction_id int identity,
	account_id int not null,
	account_users_id int not null,
	groups_id int not null,
	rewards_value float not null,
	program_id int not null,
	order_confirmation_number varchar(20) not null,
	create_time datetime not null default GetDate(),
	-- Constraints of the REWARDS_TRANSACTION table
	CONSTRAINT PK_REWARDS_TRANSACTION PRIMARY KEY (rewards_transaction_id),
	CONSTRAINT FK1_REWARDS_TRANSACTION FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id),
	CONSTRAINT FK2_REWARDS_TRANSACTION FOREIGN KEY (account_users_id) REFERENCES ACCOUNT_USERS(account_users_id),
	CONSTRAINT FK3_REWARDS_TRANSACTION FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id),
	CONSTRAINT FK4_REWARDS_TRANSACTION FOREIGN KEY (program_id) REFERENCES PROGRAM(program_id))
GO
-- end of REWARDS_TRANSACTION table creation
-- creating of ITEM table
/*
	The ITEM table contains the various items that cardholder's can
	redeem their loyalty rewards points for (provided they have the balance to do so)
*/
CREATE TABLE ITEM (
	-- columns for the ITEM table
	item_id int identity, 
	name varchar(20) not null,
	item_description varchar(300),
	item_cost_points int not null,
	item_cost money not null,
	SKU varchar(50) not null,
	-- Constraints of the ITEM table
	CONSTRAINT PK_ITEM PRIMARY KEY (item_id),
	CONSTRAINT U1_ITEM UNIQUE (name, SKU))
GO
-- end of ITEM table creation
-- creating of REWARDS_TRANSACTION_ITEM table
/*
	To prevent redundancy and repetition of data from the REWARDS_TRANSACTION table,
	the REWARDS_TRANSACTION_ITEM table gives additional details as to what the redemption was for. 
*/
CREATE TABLE REWARDS_TRANSACTION_ITEM (
	-- columns for the REWARDS_TRANSACTION_ITEM table
	rewards_transaction_item_id int identity not null,
	rewards_transaction_id int not null,
	rewards_value float not null,
	item_cost money,
	item_id int not null,
	rewards_items_type varchar(30) not null,
--	order_confirmation_number varchar(20) not null, -- possibly add this in
	quantity integer not null,
	groups_id int not null
	-- Constraints of the REWARDS_TRANSACTION_ITEM table
	CONSTRAINT PK_REWARDS_TRANSACTION_ITEM PRIMARY KEY (rewards_transaction_item_id)
	CONSTRAINT FK1_REWARDS_TRANSACTION_ITEM FOREIGN KEY (rewards_transaction_id) REFERENCES REWARDS_TRANSACTION(rewards_transaction_id),
	CONSTRAINT FK2_REWARDS_TRANSACTION_ITEM FOREIGN KEY (item_id) REFERENCES ITEM(item_id),
	CONSTRAINT FK3_REWARDS_TRANSACTION_ITEM FOREIGN KEY (groups_id) REFERENCES GROUPS(groups_id))
GO
-- end of REWARDS_TRANSACTION_ITEM table creation

-- creating of REWARDS_ACTIVITY table
/*
	The Ledger of Points.
	By far the most important table in our database, as this table documents every time points are touched in any way,
	whether that be in a positive or negative aspect. 
*/
CREATE TABLE REWARDS_ACTIVITY (
	-- columns for the REWARDS_ACTIVITY table
	rewards_activity_id int identity not null,
	account_id int not null,
	account_users_id int not null,
	rewards_value float not null,
	rewards_type varchar(5) not null,
	rewards_activity_type varchar(20) not null,
	program_id int not null,
	groups_id int not null,
	sales_date datetime, 
	posting_date datetime not null default getDate(),
	tender_amount money,
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
	CONSTRAINT FK7_REWARDS_ACTIVITY FOREIGN KEY (rewards_transaction_item_id) REFERENCES REWARDS_TRANSACTION_ITEM(rewards_transaction_item_id))
GO
--END of creating the Loyalty tables 
/*
*********************************************************************************
BEGIN creation of Procedures 
*********************************************************************************
*/
-- adding new product to the GROUPS table
/*
	Create a stored procedure to add a new child group to a parent in the GROUPS table. 
	The child group must reference who it's parent through the following logic: 
			CHILD.parent_groups_id = PARENT.groups_id
	Input(s):
		@group_name: name of the child group
		@client_code: to mark which collection of products this child belongs to.
	Returns:
		@@identity, or the groups_id, to the newly created CHILD group.
*/
CREATE PROCEDURE add_child_group(
	@group_name varchar(40), 
	@client_code varchar(4),
	@group_type varchar(10)) 
AS
BEGIN
	-- Code the procedure!
	INSERT INTO dbo.GROUPS(name, client_code, group_type)
	VALUES (@group_name, @client_code, @group_type);
	RETURN @@identity
END
GO
-- assigning newly created child group to its corresponding parent group
CREATE PROCEDURE assign_parent(@groups_id int) AS 
BEGIN
	UPDATE DBO.GROUPS
	SET parent_groups_id = (select g1.groups_id from groups g1 left join groups g2 on g1.groups_id = g2.groups_id where g1.client_code = (select client_code from groups where groups_id = @groups_id) and g1.parent_groups_id = 1)
	WHERE groups_id = @groups_id
END
GO
;
EXEC assign_parent 5
--*/
/*
*********************************************************************************
*********************************************************************************
				BEGINNING OF INSERT STATEMENTS FOR LOYALTY TABLES
*********************************************************************************
*********************************************************************************
*/
-- Insert of the Issuing Banks (parent level), Since this is a hierarchy and we don't want any bank to be above the other, also created "Loyalty Root" as the Top entry to eliminate any complication/issue
INSERT INTO GROUPS (name, client_code, parent_groups_id, group_type)
VALUES 
('Loyalty Root', '0000', 1,'ROOT'),
('Bank of America', '1776', 1,'PARENT'),
('Regions', '9570', 1, 'PARENT'),
('Navy Federal Credit Union', '7339', 1, 'PARENT')
;
SELECT * FROM GROUPS;
-- Insert child groups of the issuing banks
INSERT INTO DBO.GROUPS (name, client_code, parent_groups_id, group_type)
VALUES
('BOA Cash Rewards', '1776', 2, 'CHILD'),
('BOA Travel Rewards', '1776', 2, 'CHILD'),
('BOA Premium Rewards','1776', 2, 'CHILD'),
('Regions Student Rewards', '9570', 3, 'CHILD'),
('Signature Cashback Rewards', '9570', 3, 'CHILD'),
('Mastercard Rewards', '7339', 4, 'CHILD'),
('Visa Signature Rewards', '7339', 4, 'CHILD'), 
('American Express More Rewards', '7339', 4, 'CHILD')
;
-- After creating the add_child_group stored-procedure, execute the following SQL against the GROUPS table:
DECLARE @new_groups_id int
EXEC @new_groups_id  = add_child_group 'BOA Example New Group','1776', 'CHILD'
SELECT * FROM GROUPS WHERE groups_id = @new_groups_id 
;
GO
UPDATE DBO.GROUPS
SET parent_groups_id = 2
WHERE groups_id = 13
;
GO
-- Inserting programs into the PROGRAM table.
INSERT INTO DBO.PROGRAM(name, pgm_type, pgm_start_date, pgm_end_date, points2dollar_rate)
VALUES
('Cash Rewards Base Earn ', 'EARN', '1/1/2000','1/1/2999', 1 ),
('Travel Rewards Base Earn', 'EARN', '1/1/2000','1/1/2999', 1),
('Premium Rewards Base Earn', 'EARN', '1/1/2000','1/1/2999', 1),
('Student Rewards Base Earn', 'EARN', '1/1/2000','1/1/2999', 1),
('Signature Cashback Rewards Base Earn', 'EARN', '1/1/2000','1/1/2999', 1),
('Mastercard Rewards Base Earn', 'EARN', '1/1/2000','1/1/2999', 1),
('Visa Signature Rewards Base Earn', 'EARN', '1/1/2000','1/1/2999', 1),
('More Rewards Base Earn', 'EARN', '1/1/2000','1/1/2999', 1 ),
('Loyalty Redemption Program', 'REDEEM', '1/1/2000', '1/1/2999', 1)
;
-- Inserting accounts with their corresponding attributes
INSERT INTO DBO.ACCOUNT(groups_id, enrolled_date, earn_flg, burn_flg, status_type, forfeit_points_flg)
VALUES
(5, '03-07-2020', 1, 1, 'OP', 0),
(6, '07-10-2021', 1, 1, 'OP', 0),
(7, '05-07-2020', 1, 1, 'OP', 0),
(8, '06-07-2020', 1, 1, 'OP', 0),
(9, '10-11-2021', 1, 1, 'OP', 0),
(10, '10-08-2019', 0, 1,'CT',1),
(11, '03-02-2019', 0, 0, 'CP', 1),
(12, '06-14-2021', 1, 1, 'OP', 0)
;
SELECT * FROM ACCOUNT;
-- Inserting additional information for the cross reference table ACCOUNT_XREFERENCE
INSERT INTO DBO.ACCOUNT_XREFERENCE(account_id, account_number, card_number, active_flg, groups_id)
VALUES
(1,'609414768152','2887986118958270', 1, 5),
(2, '710525879263','3998097229069380',1, 6),
(3, '821636989274', '4009108330170490', 1, 7),
(4, '932747090385', '5110219441281500', 1, 8),
(5, '043858101496', '6221320552392610', 1, 9),
(6, '154969212507', '7332431663403720', 0, 10),
(7, '265070323618', '8443542774514830', 0, 11),
(8, '376181434729', '9554653884645940', 1, 12)
;
SELECT * FROM ACCOUNT_XREFERENCE;
-- Inserting the child accounts that stem from the ACCOUNT table
INSERT INTO DBO.ACCOUNT_USERS(account_id, account_xreference_id, active_flg, user_level_type, groups_id, primary_account, enrolled_date)
VALUES
(1, 1, 1, 'PRIMARY', 5, 1, '03-07-2020 08:05'),
(1, 1, 0, 'SECONDARY', 5, 0, '09-14-2020 11:47'),
(1, 1, 1, 'SECONDARY', 5, 0, '10-27-2020 13:17'),
(2, 2, 1, 'PRIMARY', 6, 1, '05-06-2019 07:47'),
(3, 3, 1, 'PRIMARY', 7, 1, '01-29-2020 14:12'),
(3, 3, 1, 'SECONDARY', 7, 0, '02-26-2020 12:00'),
(3, 3, 1, 'SECONDARY', 7, 0, '03-01-2020 13:00'), 
(4, 4, 1, 'PRIMARY', 8, 1, '11-06-2018 14:02'),
(4, 4, 1, 'SECONDARY', 8, 0, '11-08-2018 15:00'),
(5, 5, 1, 'PRIMARY', 9, 1, '07-30-2018 18:15'),
(5, 5, 1, 'SECONDARY', 9, 0, '8-29-2018 17:00'),
(6, 6, 0, 'PRIMARY', 10, 1, '06-11-2018 10:45'),
(6, 6, 0, 'SECONDARY', 10, 0, '07-12-2018 10:05'),
(6, 6, 0, 'SECONDARY', 10, 0, '08-13-2018 11:01'),
(7, 7, 0, 'PRIMARY', 11, 1, '03-27-2019 09:46'),
(8, 8, 1, 'PRIMARY', 12, 1, '05-20-2020 08:58')
;
SELECT * FROM ACCOUNT_USERS
ORDER BY GROUPS_ID, ACCOUNT_ID, ACCOUNT_USERS_ID;
-- Inserting items that are available for redemptions 
INSERT INTO DBO.ITEM(NAME, ITEM_DESCRIPTION, ITEM_COST_POINTS, ITEM_COST, SKU)
VALUES
('$10 Cashback',	'Statement credit of 10 dollars USD',				-10000,			10,		'98403102639425922328045955308679845468176392588359'), 
('$25 Cashback',	'Statement credit of 25 dollars USD',				-25000,			25,		'43082700080318863420587001226028796154178366559535'),
('$50 Cashback',	'Statement credit of 50 dollars USD',				-50000,			50,		'36004068480284993944030917661316034187840378415048'), 
('$100 Amazon GC',	'Amazon giftcard with 100 dollars USD Balance',		-100000,	   100,		'75216895456389503456328907661316034187840378314568')
;
SELECT * FROM ITEM;
(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 1 AND ACCOUNT_ID = 1)
-- Inserting incoming transaction entries that came from Credit Card Swipes!
INSERT INTO dbo.TRANSACTIONN(groups_id, account_id, card_number, account_users_id, sales_date, posting_date, sales_amount)
VALUES 
(	5	,	1	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 5 AND ACCOUNT_ID = 1)	,	1	,	'	01-05-21	'	,	'	01-06-21	'	,	779	)	,
(	5	,	1	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 5 AND ACCOUNT_ID = 1)	,	1	,	'	01-12-21	'	,	'	01-13-21	'	,	375	)	,
(	5	,	1	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 5 AND ACCOUNT_ID = 1)	,	1	,	'	01-19-21	'	,	'	01-20-21	'	,	173	)	,
(	5	,	1	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 5 AND ACCOUNT_ID = 1)	,	1	,	'	02-26-21	'	,	'	02-27-21	'	,	479	)	,
(	5	,	1	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 5 AND ACCOUNT_ID = 1)	,	3	,	'	03-13-21	'	,	'	03-14-21	'	,	48	)	,
(	6	,	2	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 6 AND ACCOUNT_ID = 2)	,	4	,	'	08-19-21	'	,	'	08-20-21	'	,	79	)	,
(	7	,	3	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 7 AND ACCOUNT_ID = 3)	,	5	,	'	08-22-21	'	,	'	08-23-21	'	,	77	)	,
(	7	,	3	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 7 AND ACCOUNT_ID = 3)	,	5	,	'	08-29-21	'	,	'	08-30-21	'	,	84	)	,
(	7	,	3	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 7 AND ACCOUNT_ID = 3)	,	6	,	'	09-14-21	'	,	'	09-15-21	'	,	41	)	,
(	7	,	3	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 7 AND ACCOUNT_ID = 3)	,	7	,	'	11-14-21	'	,	'	11-15-21	'	,	280	)	,
(	7	,	3	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 7 AND ACCOUNT_ID = 3)	,	7	,	'	11-21-21	'	,	'	11-22-21	'	,	78	)	,
(	8	,	4	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 8 AND ACCOUNT_ID = 4)	,	8	,	'	05-04-21	'	,	'	05-05-21	'	,	54	)	,
(	8	,	4	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 8 AND ACCOUNT_ID = 4)	,	9	,	'	05-16-21	'	,	'	05-17-21	'	,	103	)	,
(	8	,	4	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 8 AND ACCOUNT_ID = 4)	,	9	,	'	05-23-21	'	,	'	05-24-21	'	,	81	)	,
(	9	,	5	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 9 AND ACCOUNT_ID = 5)	,	10	,	'	08-11-21	'	,	'	08-12-21	'	,	57	)	,
(	9	,	5	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 9 AND ACCOUNT_ID = 5)	,	11	,	'	10-21-21	'	,	'	10-22-21	'	,	378	)	,
(	11	,	7	,	(SELECT CARD_NUMBER FROM ACCOUNT_XREFERENCE WHERE GROUPS_ID = 11 AND ACCOUNT_ID = 7),	16	,	'	11-18-21	'	,	'	11-19-21	'	,	83	)	
SELECT * FROM TRANSACTIONN;
-- Insert REWARDS_TRANSACTION rows that make withdraws of points accrued for redemptions
INSERT INTO dbo.rewards_transaction(account_id, account_users_id, groups_id, rewards_value, program_id, order_confirmation_number, create_time)
VALUES 
(1,	1,  5,	-50000	, 9, '63228801057494242721', getdate()-15),
(1,	1,	5,	-100000	, 9, '86064402486499332735', getdate()-11),
(2,	4,	6,	-25000	, 9, '79654871009244873174', getdate()-7 ),
(3,	5,	7,	-50000	, 9, '83205871078925874169', getdate()-17),
(4, 8,	8,	-50000	, 9, '84879651187965131889', getdate()-17),
(5, 10, 9,	-25000	, 9, '56549878879779887559', getdate()-14),
(8, 16, 12, -25000	, 9, '15726752197217219716', getdate()-13)
SELECT * FROM REWARDS_TRANSACTION;
-- Insert REWARDS_TRANSACTION_ITEM entries that correspond to redemptions found in REWARDS_TRANSACTION and REWARDS_ACTIVITY
INSERT INTO dbo.rewards_transaction_item(rewards_transaction_id, rewards_value, item_cost, item_id, rewards_items_type, quantity, groups_id)
VALUES
(1, (SELECT item_cost_points FROM ITEM WHERE ITEM_ID = 1), (SELECT item_cost FROM ITEM WHERE ITEM_ID = 1),	1, 'STATEMENT_CREDIT'	, 1, 5),
(2, (SELECT item_cost_points FROM ITEM WHERE ITEM_ID = 4), (SELECT item_cost FROM ITEM WHERE ITEM_ID = 4),	4, 'GIFT_CARD'			, 1, 5),
(3, (SELECT item_cost_points FROM ITEM WHERE ITEM_ID = 2), (SELECT item_cost FROM ITEM WHERE ITEM_ID = 2),	2, 'STATEMENT_CREDIT'	, 1, 6),
(4, (SELECT item_cost_points FROM ITEM WHERE ITEM_ID = 2), (SELECT item_cost FROM ITEM WHERE ITEM_ID = 2),	2, 'STATEMENT_CREDIT'	, 1, 7),
(5, (SELECT item_cost_points FROM ITEM WHERE ITEM_ID = 2), (SELECT item_cost FROM ITEM WHERE ITEM_ID = 2),	2, 'STATEMENT_CREDIT'	, 1, 8),
(6, (SELECT item_cost_points FROM ITEM WHERE ITEM_ID = 3), (SELECT item_cost FROM ITEM WHERE ITEM_ID = 3),  3, 'STATEMENT_CREDIT'	, 1, 9),
(7, (SELECT item_cost_points FROM ITEM WHERE ITEM_ID = 1), (SELECT item_cost FROM ITEM WHERE ITEM_ID = 1),	1, 'STATEMENT_CREDIT'	, 1, 12)
SELECT * FROM REWARDS_TRANSACTION_ITEM;
-- Inserting the Redemption activity from REWARDS_TRANSACTION into the Points Ledger REWARDS_ACTIVITY
INSERT INTO dbo.rewards_activity( account_id, account_users_id, rewards_value, rewards_type, rewards_activity_type, program_id, groups_id, posting_date, rewards_transaction_id, rewards_transaction_item_id)
VALUES
((SELECT ACCOUNT_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 1), (SELECT ACCOUNT_USERS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 1), (SELECT REWARDS_VALUE FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 1), 'OTHER','REDEEM', 9, (SELECT GROUPS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 1), (SELECT CREATE_TIME FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 1), (SELECT REWARDS_TRANSACTION_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 1), (SELECT REWARDS_TRANSACTION_ITEM_ID FROM REWARDS_TRANSACTION_ITEM WHERE REWARDS_TRANSACTION_ID = 1)), 
((SELECT ACCOUNT_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 2), (SELECT ACCOUNT_USERS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 2), (SELECT REWARDS_VALUE FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 2), 'OTHER','REDEEM', 9, (SELECT GROUPS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 2), (SELECT CREATE_TIME FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 2), (SELECT REWARDS_TRANSACTION_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 2), (SELECT REWARDS_TRANSACTION_ITEM_ID FROM REWARDS_TRANSACTION_ITEM WHERE REWARDS_TRANSACTION_ID = 2)),
((SELECT ACCOUNT_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 3), (SELECT ACCOUNT_USERS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 3), (SELECT REWARDS_VALUE FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 3), 'OTHER','REDEEM', 9, (SELECT GROUPS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 3), (SELECT CREATE_TIME FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 3), (SELECT REWARDS_TRANSACTION_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 3), (SELECT REWARDS_TRANSACTION_ITEM_ID FROM REWARDS_TRANSACTION_ITEM WHERE REWARDS_TRANSACTION_ID = 3)),
((SELECT ACCOUNT_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 4), (SELECT ACCOUNT_USERS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 4), (SELECT REWARDS_VALUE FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 4), 'OTHER','REDEEM', 9, (SELECT GROUPS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 4), (SELECT CREATE_TIME FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 4), (SELECT REWARDS_TRANSACTION_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 4), (SELECT REWARDS_TRANSACTION_ITEM_ID FROM REWARDS_TRANSACTION_ITEM WHERE REWARDS_TRANSACTION_ID = 4)),
((SELECT ACCOUNT_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 5), (SELECT ACCOUNT_USERS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 5), (SELECT REWARDS_VALUE FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 5), 'OTHER','REDEEM', 9, (SELECT GROUPS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 5), (SELECT CREATE_TIME FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 5), (SELECT REWARDS_TRANSACTION_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 5), (SELECT REWARDS_TRANSACTION_ITEM_ID FROM REWARDS_TRANSACTION_ITEM WHERE REWARDS_TRANSACTION_ID = 5)),
((SELECT ACCOUNT_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 6), (SELECT ACCOUNT_USERS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 6), (SELECT REWARDS_VALUE FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 6), 'OTHER','REDEEM', 9, (SELECT GROUPS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 6), (SELECT CREATE_TIME FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 6), (SELECT REWARDS_TRANSACTION_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 6), (SELECT REWARDS_TRANSACTION_ITEM_ID FROM REWARDS_TRANSACTION_ITEM WHERE REWARDS_TRANSACTION_ID = 6)),
((SELECT ACCOUNT_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 7), (SELECT ACCOUNT_USERS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 7), (SELECT REWARDS_VALUE FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 7), 'OTHER','REDEEM', 9, (SELECT GROUPS_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 7), (SELECT CREATE_TIME FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 7), (SELECT REWARDS_TRANSACTION_ID FROM REWARDS_TRANSACTION WHERE REWARDS_TRANSACTION_ID = 7), (SELECT REWARDS_TRANSACTION_ITEM_ID FROM REWARDS_TRANSACTION_ITEM WHERE REWARDS_TRANSACTION_ID = 7))
-- Inserting the card swipes activity from TRANSACTIONN into the Points Ledger REWARDS_ACTIVITY
INSERT INTO DBO.REWARDS_ACTIVITY(account_id, account_users_id, rewards_value, rewards_type, rewards_activity_type, program_id, groups_id, sales_date, posting_date, tender_amount, transactionn_id)
VALUES
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 1),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 1),	  (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 1), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 1),	(select sales_date from transactionn where transactionn_id = 1),(select posting_date from transactionn where transactionn_id = 1),(select sales_amount from transactionn where transactionn_id = 1),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 1)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 2),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 2),   (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 2), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 2),	(select sales_date from transactionn where transactionn_id = 2),(select posting_date from transactionn where transactionn_id = 2),(select sales_amount from transactionn where transactionn_id = 2),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 2)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 3),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 3),   (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 3), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 3),	(select sales_date from transactionn where transactionn_id = 3),(select posting_date from transactionn where transactionn_id = 3),(select sales_amount from transactionn where transactionn_id = 3),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 3)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 4),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 4),   (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 4), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 4),	(select sales_date from transactionn where transactionn_id = 4),(select posting_date from transactionn where transactionn_id = 4),(select sales_amount from transactionn where transactionn_id = 4),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 4)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 5),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 5),   (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 5), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 5),	(select sales_date from transactionn where transactionn_id = 5),(select posting_date from transactionn where transactionn_id = 5),(select sales_amount from transactionn where transactionn_id = 5),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 5)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 6),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 6),   (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 6), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 6),	(select sales_date from transactionn where transactionn_id = 6),(select posting_date from transactionn where transactionn_id = 6),(select sales_amount from transactionn where transactionn_id = 6),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 6)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 7),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 7),   (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 7), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 7),	(select sales_date from transactionn where transactionn_id = 7),(select posting_date from transactionn where transactionn_id = 7),(select sales_amount from transactionn where transactionn_id = 7),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 7)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 8),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 8),   (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 8), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 8),	(select sales_date from transactionn where transactionn_id = 8),(select posting_date from transactionn where transactionn_id = 8),(select sales_amount from transactionn where transactionn_id = 8),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 8)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 9),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 9),   (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 9), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 9),	(select sales_date from transactionn where transactionn_id = 9),(select posting_date from transactionn where transactionn_id = 9),(select sales_amount from transactionn where transactionn_id = 9),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 9)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 10),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 10), (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 10), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 10), (select sales_date from transactionn where transactionn_id = 10),(select posting_date from transactionn where transactionn_id = 10),(select sales_amount from transactionn where transactionn_id = 10),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 10)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 11),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 11), (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 11), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 11), (select sales_date from transactionn where transactionn_id = 11),(select posting_date from transactionn where transactionn_id = 11),(select sales_amount from transactionn where transactionn_id = 11),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 11)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 12),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 12), (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 12), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 12), (select sales_date from transactionn where transactionn_id = 12),(select posting_date from transactionn where transactionn_id = 12),(select sales_amount from transactionn where transactionn_id = 12),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 12)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 13),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 13), (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 13), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 13), (select sales_date from transactionn where transactionn_id = 13),(select posting_date from transactionn where transactionn_id = 13),(select sales_amount from transactionn where transactionn_id = 13),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 13)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 14),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 14), (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 14), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 14), (select sales_date from transactionn where transactionn_id = 14),(select posting_date from transactionn where transactionn_id = 14),(select sales_amount from transactionn where transactionn_id = 14),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 14)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 15),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 15), (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 15), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 15), (select sales_date from transactionn where transactionn_id = 15),(select posting_date from transactionn where transactionn_id = 15),(select sales_amount from transactionn where transactionn_id = 15),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 15)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 16),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 16), (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 16), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 16), (select sales_date from transactionn where transactionn_id = 16),(select posting_date from transactionn where transactionn_id = 16),(select sales_amount from transactionn where transactionn_id = 16),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 16)),
((SELECT ACCOUNT_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 17),(SELECT ACCOUNT_USERS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 17), (SELECT SALES_AMOUNT*100 FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 17), 'BASE', 'EARN',1,(SELECT GROUPS_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 17), (select sales_date from transactionn where transactionn_id = 17),(select posting_date from transactionn where transactionn_id = 17),(select sales_amount from transactionn where transactionn_id = 1),(SELECT TRANSACTIONN_ID FROM TRANSACTIONN WHERE TRANSACTIONN_ID = 1))
;
SELECT * FROM REWARDS_ACTIVITY;
/*
******************************************************************************************************************************************************************
******************************************************************************************************************************************************************
														DONE WITH INSERT STATEMENTS FOR LOYALTY TABLES
******************************************************************************************************************************************************************
******************************************************************************************************************************************************************
*/