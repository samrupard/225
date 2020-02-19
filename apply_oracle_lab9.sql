-- ------------------------------------------------------------------
--  Program Name:   apply_oracle_lab9.sql
--  Lab Assignment: Lab #9
--  Program Author: Michael McLaughlin
--  Creation Date:  02-Mar-2010
-- ------------------------------------------------------------------
-- Instructions:
-- ------------------------------------------------------------------
-- The two scripts contain spooling commands, which is why there
-- isn't a spooling command in this script. When you run this file
-- you first connect to the Oracle database with this syntax:
--
--   sqlplus student/student@xe
--
-- Then, you call this script with the following syntax:
--
--   sql> @apply_oracle_lab9.sql
--
-- ------------------------------------------------------------------

-- Run the prior lab script.
@/home/student/Data/cit225/oracle/lab8/apply_oracle_lab8.sql

-- Open log file.
SPOOL apply_oracle_lab9.txt

-- Set the page size.
SET ECHO ON
SET PAGESIZE 999

-- ----------------------------------------------------------------------
--  Step #1 : Create the TRANSACTION table.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Step #1a : Create the TRANSACTION table and TRANSACTION_S1 sequence.
-- ----------------------------------------------------------------------

-- Conditionally drop the TRANSACTION table.
BEGIN
  FOR i IN (SELECT table_name
            FROM   user_tables
            WHERE  table_name = 'TRANSACTION') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||i.table_name||' CASCADE CONSTRAINTS';
  END LOOP;
  FOR i IN (SELECT sequence_name
            FROM   user_sequences
            WHERE  sequence_name = 'TRANSACTION_S1') LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE '||i.sequence_name;
  END LOOP;
END;
/

-- ----------------------------------------------------------------------
--  Step #1a : Create the TRANSACTION table.
-- ----------------------------------------------------------------------

create table transaction
(transaction_id             number          
, transaction_account       varchar2(25)    constraint nn_transaction_1 not null
, transaction_type          number          constraint nn_transaction_2 not null
, transaction_date          date            constraint nn_transaction_3 not null
, transaction_amount        float           constraint nn_transaction_4 not null
, rental_id                 number          constraint nn_transaction_5 not null
, payment_method_type       number          constraint nn_transaction_6 not null
, payment_account_number    varchar2(19)    constraint nn_transaction_7 not null
, created_by                number          constraint nn_transaction_8 not null
, creation_date             date            constraint nn_transaction_9 not null
, last_updated_by           number          constraint nn_transaction_10 not null
, last_update_date          date            constraint nn_transaction_11 not null
, constraint pk_transaction_1 primary key(transaction_id)
, constraint fk_transaction_1 foreign key(transaction_type) references common_lookup(common_lookup_id)
, constraint fk_transaction_2 foreign key(rental_id) references rental(rental_id)
, constraint fk_transaction_3 foreign key(payment_method_type) references common_lookup(common_lookup_id)
, constraint fk_transaction_4 foreign key(created_by) references system_user(system_user_id)
, constraint fk_transaction_5 foreign key(last_updated_by) references system_user(system_user_id));


-- ----------------------------------------------------------------------
--  Step #1a : Create the TRANSACTION sequence.
-- ----------------------------------------------------------------------

create sequence transaction_s1 start with 1;


-- ----------------------------------------------------------------------
--  Verify #1a : Check the TRANSACTION table and TRANSACTION_S1 sequence.
-- ----------------------------------------------------------------------
-- Query table structure.
COLUMN table_name   FORMAT A14
COLUMN column_id    FORMAT 9999
COLUMN column_name  FORMAT A22
COLUMN data_type    FORMAT A12
SELECT   table_name
,        column_id
,        column_name
,        CASE
           WHEN nullable = 'N' THEN 'NOT NULL'
           ELSE ''
         END AS nullable
,        CASE
           WHEN data_type IN ('CHAR','VARCHAR2','NUMBER') THEN
             data_type||'('||data_length||')'
           ELSE
             data_type
         END AS data_type
FROM     user_tab_columns
WHERE    table_name = 'TRANSACTION'
ORDER BY 2;

-- ----------------------------------------------------------------------
--  Step #1b : Create the NATURAL_KEY index on the TRANSACTION table.
-- ----------------------------------------------------------------------

create unique index natural_key on transaction(
  rental_id
, transaction_type
, transaction_date
, payment_method_type
, payment_account_number
, transaction_account);



-- ----------------------------------------------------------------------
--  Verify #1b : Query the TRANSACTION table's natural key index.
-- ----------------------------------------------------------------------
COLUMN table_name       FORMAT A12
COLUMN index_name       FORMAT A16
COLUMN uniqueness       FORMAT A8
COLUMN column_position  FORMAT 9999
COLUMN column_name      FORMAT A24
SELECT   i.table_name
,        i.index_name
,        i.uniqueness
,        ic.column_position
,        ic.column_name
FROM     user_indexes i INNER JOIN user_ind_columns ic
ON       i.index_name = ic.index_name
WHERE    i.table_name = 'TRANSACTION'
AND      i.uniqueness = 'UNIQUE'
AND      i.index_name = 'NATURAL_KEY';

-- ----------------------------------------------------------------------
--  Step #2 : Insert new rows in COMMON_LOOKUP table.
-- ----------------------------------------------------------------------
insert into common_lookup values(
  common_lookup_s1.nextval
, 'CREDIT'
, 'Credit'
, 1
, sysdate
, 1
, sysdate
, 'TRANSACTION'
, 'TRANSACTION_TYPE'
, 'CR');

insert into common_lookup values(
  common_lookup_s1.nextval
, 'DEBIT'
, 'Debit'
, 1
, sysdate
, 1
, sysdate
, 'TRANSACTION'
, 'TRANSACTION_TYPE'
, 'DR');

insert into common_lookup values(
  common_lookup_s1.nextval
, 'DISCOVER_CARD'
, 'Discover Card'
, 1
, sysdate
, 1
, sysdate
, 'TRANSACTION'
, 'PAYMENT_METHOD_TYPE'
, NULL);

insert into common_lookup values(
  common_lookup_s1.nextval
, 'VISA_CARD'
, 'Visa Card'
, 1
, sysdate
, 1
, sysdate
, 'TRANSACTION'
, 'PAYMENT_METHOD_TYPE'
, NULL);

insert into common_lookup values(
  common_lookup_s1.nextval
, 'MASTER_CARD'
, 'Master Card'
, 1
, sysdate
, 1
, sysdate
, 'TRANSACTION'
, 'PAYMENT_METHOD_TYPE'
, NULL);

insert into common_lookup values(
  common_lookup_s1.nextval
, 'CASH'
, 'Cash'
, 1
, sysdate
, 1
, sysdate
, 'TRANSACTION'
, 'PAYMENT_METHOD_TYPE'
, NULL);



-- ----------------------------------------------------------------------
--  Step #2 : Verify insertion of new rows into the COMMON_LOOKUP table.
-- ----------------------------------------------------------------------
COLUMN common_lookup_id     FORMAT 9999 HEADING "Lookup|ID #"
COLUMN common_lookup_table  FORMAT A18  HEADING "Lookup|Table"
COLUMN common_lookup_column FORMAT A20  HEADING "Lookup|Column"
COLUMN common_lookup_type   FORMAT A14  HEADING "Lookup|Type"
COLUMN common_lookup_code   FORMAT A8   HEADING "Lookup|Code"
SELECT common_lookup_id
,      common_lookup_table
,      common_lookup_column
,      common_lookup_type
,      common_lookup_code
FROM   common_lookup
WHERE  common_lookup_table IN ('TRANSACTION','RENTAL_ITEM');

-- ----------------------------------------------------------------------
--  Step #3a : Create and seed AIRPORT and ACCOUNT_LIST tables.
-- ----------------------------------------------------------------------
BEGIN
  FOR i IN (SELECT table_name
            FROM   user_tables
            WHERE  table_name = 'AIRPORT') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||i.table_name||' CASCADE CONSTRAINTS';
  END LOOP;
  FOR i IN (SELECT sequence_name
            FROM   user_sequences
            WHERE  sequence_name = 'AIRPORT_S1') LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE '||i.sequence_name;
  END LOOP;
END;
/

-- ----------------------------------------------------------------------
--  Step #3a : Create the AIRPORT table.
-- ----------------------------------------------------------------------
create table airport 
( airport_id        number         
, airport_code      varchar2(3)     constraint nn_airport_1 not null
, airport_city      varchar2(30)    constraint nn_airport_2 not null
, city              varchar2(30)    constraint nn_airport_3 not null
, state_province    varchar2(30)    constraint nn_airport_4 not null
, created_by        number          constraint nn_airport_5 not null
, creation_date     date            constraint nn_airport_6 not null
, last_updated_by   number          constraint nn_airport_7 not null
, last_update_date  date            constraint nn_airport_8 not null
, constraint pk_airport_1 primary key(airport_id)
, constraint fk_airport_1 foreign key(created_by) references system_user(system_user_id)
, constraint fk_airport_2 foreign key(last_updated_by) references system_user(system_user_id));




-- ----------------------------------------------------------------------
--  Step #3a : Create the AIRPORT sequence.
-- ----------------------------------------------------------------------

create sequence airport_s1 start with 1;



-- ----------------------------------------------------------------------
--  #3a : Verify creation of AIRPORT table.
-- ----------------------------------------------------------------------
COLUMN table_name   FORMAT A14
COLUMN column_id    FORMAT 9999
COLUMN column_name  FORMAT A22
COLUMN data_type    FORMAT A12
SELECT   table_name
,        column_id
,        column_name
,        CASE
           WHEN nullable = 'N' THEN 'NOT NULL'
           ELSE ''
         END AS nullable
,        CASE
           WHEN data_type IN ('CHAR','VARCHAR2','NUMBER') THEN
             data_type||'('||data_length||')'
           ELSE
             data_type
         END AS data_type
FROM     user_tab_columns
WHERE    table_name = 'AIRPORT'
ORDER BY 2;

-- ----------------------------------------------------------------------
--  Step #3b : Create natural key index on the AIRPORT table.
-- ----------------------------------------------------------------------

create unique index NK_AIRPORT on airport(
  airport_code
, airport_city
, city
, state_province);



-- ----------------------------------------------------------------------
--  Step #3b : Verify the quality of the natural key index.
-- ----------------------------------------------------------------------
COLUMN table_name       FORMAT A12
COLUMN index_name       FORMAT A16
COLUMN uniqueness       FORMAT A8
COLUMN column_position  FORMAT 9999
COLUMN column_name      FORMAT A24
SELECT   i.table_name
,        i.index_name
,        i.uniqueness
,        ic.column_position
,        ic.column_name
FROM     user_indexes i INNER JOIN user_ind_columns ic
ON       i.index_name = ic.index_name
WHERE    i.table_name = 'AIRPORT'
AND      i.uniqueness = 'UNIQUE'
AND      i.index_name = 'NK_AIRPORT';

-- ----------------------------------------------------------------------
--  Step #3c : Insert rows into the AIRPORT table.
-- ----------------------------------------------------------------------
insert into airport values
( airport_s1.nextval
, 'LAX'
, 'Los Angeles'
, 'Los Angeles'
, 'California'
, 1
, sysdate
, 1
, sysdate);

insert into airport values
( airport_s1.nextval
, 'SLC'
, 'Salt Lake City'
, 'Provo'
, 'Utah'
, 1
, sysdate
, 1
, sysdate);

insert into airport values
( airport_s1.nextval
, 'SLC'
, 'Salt Lake City'
, 'Spanish Fork'
, 'Utah'
, 1
, sysdate
, 1
, sysdate);

insert into airport values
( airport_s1.nextval
, 'SFO'
, 'San Francisco'
, 'San Francisco'
, 'California'
, 1
, sysdate
, 1
, sysdate);

insert into airport values
( airport_s1.nextval
, 'SJC'
, 'San Jose'
, 'San Jose'
, 'California'
, 1
, sysdate
, 1
, sysdate);

insert into airport values
( airport_s1.nextval
, 'SJC'
, 'San Jose'
, 'San Carlos'
, 'California'
, 1
, sysdate
, 1
, sysdate);




-- ----------------------------------------------------------------------
--  Step #3c : Verify insertion of rows into the AIRPORT table.
-- ----------------------------------------------------------------------
COLUMN code           FORMAT A6  HEADING "Code"
COLUMN airport_city   FORMAT A16 HEADING "Airport City"
COLUMN city           FORMAT A16 HEADING "City"
COLUMN state_province FORMAT A12 HEADING "State or|Province"
SELECT   airport_code AS code
,        airport_city
,        city
,        state_province
FROM     airport;

-- Conditionally drop table.
BEGIN
  FOR i IN (SELECT table_name
            FROM   user_tables
            WHERE  table_name = 'ACCOUNT_LIST') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||i.table_name||' CASCADE CONSTRAINTS';
  END LOOP;
  FOR i IN (SELECT sequence_name
            FROM   user_sequences
            WHERE  sequence_name = 'ACCOUNT_LIST_S1') LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE '||i.sequence_name;
  END LOOP;
END;
/

-- ----------------------------------------------------------------------
--  Step #3d : Create the ACCOUNT_LIST table.
-- ----------------------------------------------------------------------
create table account_list
( account_list_id       number
, account_number        varchar2(10) constraint nn_account_list_1 not null
, consumed_date         date
, consumed_by           number
, created_by            number       constraint nn_account_list_2 not null
, creation_date         date         constraint nn_account_list_3 not null
, last_updated_by       number       constraint nn_account_list_4 not null
, last_update_date      date         constraint nn_account_list_5 not null
, constraint pk_account_list_1 primary key(account_list_id)
, constraint fk_account_list_1 foreign key(consumed_by) references system_user(system_user_id)
, constraint fk_account_list_2 foreign key(created_by) references system_user(system_user_id)
, constraint fk_account_list_3 foreign key(last_updated_by) references system_user(system_user_id));




-- ----------------------------------------------------------------------
--  Step #3d : Create the ACCOUNT_LIST sequence.
-- ----------------------------------------------------------------------

create sequence account_list_s1 start with 1;



-- ----------------------------------------------------------------------
-- Step #3d : Verify the creation of the ACCOUNT_LIST table.
-- ----------------------------------------------------------------------
COLUMN table_name   FORMAT A14
COLUMN column_id    FORMAT 9999
COLUMN column_name  FORMAT A22
COLUMN data_type    FORMAT A12
SELECT   table_name
,        column_id
,        column_name
,        CASE
           WHEN nullable = 'N' THEN 'NOT NULL'
           ELSE ''
         END AS nullable
,        CASE
           WHEN data_type IN ('CHAR','VARCHAR2','NUMBER') THEN
             data_type||'('||data_length||')'
           ELSE
             data_type
         END AS data_type
FROM     user_tab_columns
WHERE    table_name = 'ACCOUNT_LIST'
ORDER BY 2;

-- ----------------------------------------------------------------------
--  Step #3e : Seed the ACCOUNT_LIST table.
-- ----------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE seed_account_list IS

  /* Declare variable to capture table, and column. */
  lv_table_name   VARCHAR2(90);
  lv_column_name  VARCHAR2(30);

  /* Declare an exception variable and PRAGMA map. */
  not_null_column  EXCEPTION;
  PRAGMA EXCEPTION_INIT(not_null_column,-1400);

BEGIN
  /* Set savepoint. */
  SAVEPOINT all_or_none;

  /* Read a distinct list of airport codes. */
  FOR i IN (SELECT DISTINCT airport_code FROM airport) LOOP
    FOR j IN 1..50 LOOP
      INSERT INTO account_list
      VALUES
      ( account_list_s1.NEXTVAL
      , i.airport_code||'-'||LPAD(j,6,'0')
      , null
      , null
      , 1002
      , SYSDATE
      , 1002
      , SYSDATE);
    END LOOP;
  END LOOP;

  /* Commit the writes as a group. */
  COMMIT;

EXCEPTION
  WHEN not_null_column THEN
    /* Capture the table and column name that triggered the error. */
    lv_table_name := (TRIM(BOTH '"' FROM RTRIM(REGEXP_SUBSTR(SQLERRM,'".*\."',REGEXP_INSTR(SQLERRM,'\.',1,1)),'."')));
    lv_column_name := (TRIM(BOTH '"' FROM REGEXP_SUBSTR(SQLERRM,'".*"',REGEXP_INSTR(SQLERRM,'\.',1,2))));

    /* This undoes all DML statements to this point in the procedure. */
    ROLLBACK TO SAVEPOINT all_or_none;
    RAISE_APPLICATION_ERROR(
       -20001
      ,'Remove the NOT NULL contraint from the '||lv_column_name||' column in'||CHR(10)||' the '||lv_table_name||' table.');
  WHEN OTHERS THEN
    /* This undoes all DML statements to this point in the procedure. */
    ROLLBACK TO SAVEPOINT all_or_none;
END;
/

-- Show errors if any.
SHOW ERRORS

SET SERVEROUTPUT ON SIZE 99999

-- Call the nested loop seeding procedure.
EXECUTE seed_account_list;

-- ----------------------------------------------------------------------
--  Step #3e : Verify the values in the ACCOUNT_LIST table.
-- ----------------------------------------------------------------------
COLUMN airport FORMAT A7
SELECT   SUBSTR(account_number,1,3) AS "Airport"
,        COUNT(*) AS "# Accounts"
FROM     account_list
WHERE    consumed_date IS NULL
GROUP BY SUBSTR(account_number,1,3)
ORDER BY 1;

-- ----------------------------------------------------------------------
--  Step #3f : Update the ADDRESS table.
-- ----------------------------------------------------------------------

update address
set state_province = 'California'
where state_province= 'CA';




-- ----------------------------------------------------------------------
--  Step #3g : Update the MEMBER table and consume values from the
--             ACCOUNT_LIST table.
-- ----------------------------------------------------------------------
-- Enable session debugging.
ALTER SESSION SET PLSQL_CCFLAGS = 'debug:1';

CREATE OR REPLACE PROCEDURE update_member_account IS

  /* Declare a local variable. */
  lv_account_number VARCHAR2(10);

  /* Declare a SQL cursor fabricated from local variables. */
  CURSOR member_cursor IS
    SELECT   DISTINCT
             m.member_id
    ,        a.city
    ,        a.state_province
    FROM     member m INNER JOIN contact c
    ON       m.member_id = c.member_id INNER JOIN address a
    ON       c.contact_id = a.contact_id
    ORDER BY m.member_id;

BEGIN

  /* Set savepoint. */
  SAVEPOINT all_or_none;

  /* Conditional debugging.
  ||  Enable it with the following command:
  || --------------------------------------------------
  ||  ALTER SESSION SEt PLSQL_CCFLAGS = 'debug:1';
  || --------------------------------------------------
  */
  $IF $$DEBUG = 1 $THEN
    dbms_output.put_line(CHR(10));
    dbms_output.put_line('Debugging Consumed by ID numbers.');
    dbms_output.put_line('------------------------------------------');
  $END

  /* Open a local cursor. */
  FOR i IN member_cursor LOOP

      /* Secure a unique account number as they are consumed. */
      SELECT al.account_number
      INTO   lv_account_number
      FROM   account_list al INNER JOIN airport ap
      ON     SUBSTR(al.account_number,1,3) = ap.airport_code
      WHERE  ap.city = i.city
      AND    ap.state_province = i.state_province
      AND    consumed_by IS NULL
      AND    consumed_date IS NULL
      AND    ROWNUM < 2
      ORDER BY al.account_number;

      /* Conditional debugging.
      ||  Enable it with the following command:
      || --------------------------------------------------
      ||  ALTER SESSION SEt PLSQL_CCFLAGS = 'debug:1';
      || --------------------------------------------------
      */
      $IF $$DEBUG = 1 $THEN
        dbms_output.put_line(
            '[id]['||i.member_id||']: '
	  ||'lv_account_number ['||lv_account_number||']');
      $END

      /* Update a member with a unique account number linked an airport. */
      UPDATE member
      SET    account_number = lv_account_number
      WHERE  member_id = i.member_id;

      /* Mark consumed the last used account number. */
      UPDATE account_list
      SET    consumed_by = 1002
      ,      consumed_date = SYSDATE
      WHERE  account_number = lv_account_number;

  END LOOP;

  $IF $$DEBUG = 1 $THEN
    dbms_output.put_line('------------------------------------------');
  $END

  /* Commit the writes as a group. */
  COMMIT;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    /* This prints a message. */
    dbms_output.put_line('You have an error in your AIRPORT table inserts.');

    /* This undoes all DML statements to this point in the procedure. */
    ROLLBACK TO SAVEPOINT all_or_none;
  WHEN OTHERS THEN
    /* This undoes all DML statements to this point in the procedure. */
    ROLLBACK TO SAVEPOINT all_or_none;
END;
/

LIST
SHOW ERRORS

-- Enable session debugging.
ALTER SESSION SET PLSQL_CCFLAGS = '';

-- ----------------------------------------------------------------------
--  Verify #3g : Verify the update of the MEMBER table and consume
--               values from the ACCOUNT_LIST table.
-- ----------------------------------------------------------------------
COLUMN object_name FORMAT A22
COLUMN object_type FORMAT A12
SELECT   object_name
,        object_type
FROM     user_objects
WHERE    object_name = 'UPDATE_MEMBER_ACCOUNT';

-- Call the UPDATE_MEMBER_ACCOUNT procedure.
EXECUTE update_member_account();


-- ----------------------------------------------------------------------
--  Step #3g : Verify procedure ran correctly
-- ----------------------------------------------------------------------
-- Format the SQL statement display.
COLUMN member_id      FORMAT 999999 HEADING "Member|ID #"
COLUMN last_name      FORMAT A7     HEADING "Last|Name"
COLUMN account_number FORMAT A10    HEADING "Account|Number"
COLUMN acity          FORMAT A12    HEADING "Address City"
COLUMN apcode         FORMAT A8     HEADING "Airport|State or|Province"
COLUMN alcode         FORMAT A8     HEADING "Airport|Code"

-- Query distinct members and addresses.
SELECT   DISTINCT
         m.member_id
,        c.last_name
,        m.account_number
,        a.city AS acity
,        ap.state_province AS apstate
,        SUBSTR(al.account_number,1,3) AS alcode
FROM     member m INNER JOIN contact c
ON       m.member_id = c.member_id INNER JOIN address a
ON       c.contact_id = a.contact_id INNER JOIN airport ap
ON       a.city = ap.city
AND      a.state_province = ap.state_province INNER JOIN account_list al
ON       ap.airport_code = SUBSTR(al.account_number,1,3)
ORDER BY 1;

-- ----------------------------------------------------------------------
--  Step #3g : Troubleshooting script
-- ----------------------------------------------------------------------

-- Expand line size.
SET LINESIZE 99

-- Verify the account changes in the MEMBER table.
COLUMN member_id      FORMAT 999999 HEADING "Member|ID #"
COLUMN last_name      FORMAT A7     HEADING "Last|Name"
COLUMN account_number FORMAT A10    HEADING "Account|Number"
COLUMN acity          FORMAT A14    HEADING "Address City"
COLUMN apcity         FORMAT A14    HEADING "Airport City"
COLUMN astate         FORMAT A10    HEADING "Address|State or|Province"
COLUMN apstate        FORMAT A10    HEADING "Airport|State or|Province"
COLUMN apcode         FORMAT A8     HEADING "Airport|State or|Province"
COLUMN alcode         FORMAT A8     HEADING "Account|State or|Province"
SELECT   DISTINCT
         m.member_id
,        c.last_name
,        m.account_number
,        a.city AS acity
,        ap.city AS apcity
,        a.state_province AS astate
,        ap.state_province AS apstate
,        ap.airport_code AS apcode
,        SUBSTR(al.account_number,1,3) AS alcode
FROM     member m INNER JOIN contact c
ON       m.member_id = c.member_id INNER JOIN address a
ON       c.contact_id = a.contact_id RIGHT JOIN airport ap
ON       a.city = ap.city
AND      a.state_province = ap.state_province RIGHT JOIN account_list al
ON       ap.airport_code = SUBSTR(al.account_number,1,3)
ORDER BY 1;


-- ----------------------------------------------
--  Step #4 : Create Oracle external table and verify data set.
-- ----------------------------------------------
-- Conditionally drop table.
BEGIN
  FOR i IN (SELECT table_name
            FROM   user_tables
            WHERE  table_name = 'TRANSACTION_UPLOAD') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||i.table_name||' CASCADE CONSTRAINTS';
  END LOOP;
END;
/
-- ----------------------------------------------
--  Step #4 : Create Oracle external table.
-- ----------------------------------------------

create table transaction_upload
( account_number            varchar2(10)
, first_name                varchar2(20)
, middle_name               varchar2(20)
, last_name                 varchar2(20)
, check_out_date            date
, return_date               date
, rental_item_type          varchar2(12)
, transaction_type          varchar2(14)
, transaction_amount        number
, transaction_date          date
, item_id                   number
, payment_method_type       varchar2(14)
, payment_account_number    varchar2(19)
)
    organization external
    (type oracle_loader
     default directory "UPLOAD"
     access parameters
     ( RECORDS DELIMITED BY NEWLINE CHARACTERSET US7ASCII
     BADFILE        'UPLOAD':'transaction_upload.bad'
     DISCARDFILE    'UPLOAD':'transaction_upload.dis'
     LOGFILE        'UPLOAD':'transaction_upload.log'
     FIELDS TERMINATED BY ','
     OPTIONALLY ENCLOSED BY "'"
     MISSING FIELD VALUES ARE NULL)
     LOCATION
     ('transaction_upload.csv')
     )
     REJECT LIMIT UNLIMITED;





-- ----------------------------------------------
--  Step #4 : Verify Oracle external table.
-- ----------------------------------------------
SET LONG 4000000
SELECT dbms_metadata.get_ddl('TABLE'
                            ,'TRANSACTION_UPLOAD') AS "Table Description"
FROM   dual;

-- ----------------------------------------------
--  Step #4 : Verify rows in external table.
-- ----------------------------------------------
SELECT COUNT(*) AS "External Rows"
FROM   transaction_upload;

SPOOL OFF
