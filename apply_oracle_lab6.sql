-- ------------------------------------------------------------------
--  Program Name:   apply_oracle_lab6.sql
--  Lab Assignment: Lab #6
--  Program Author: Michael McLaughlin
--  Creation Date:  02-Mar-2018
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
--   sql> @apply_oracle_lab6.sql
--
-- ------------------------------------------------------------------

-- Call library files.
@/home/student/Data/cit225/oracle/lab5/apply_oracle_lab5.sql

-- Open log file.
SPOOL apply_oracle_lab6.txt

-- Set the page size.
SET ECHO ON
SET PAGESIZE 999

-- ----------------------------------------------------------------------
--  Step #1 : Add two columns to the RENTAL_ITEM table.
-- ----------------------------------------------------------------------
SELECT  'Step #1' AS "Step Number" FROM dual;

-- ----------------------------------------------------------------------
--  Objective #1: Add the RENTAL_ITEM_PRICE and RENTAL_ITEM_TYPE columns
--                to the RENTAL_ITEM table. Both columns should use a
--                NUMBER data type in Oracle, and an int unsigned data
--                type.
-- ----------------------------------------------------------------------

-- --------------------------------------------------
--  Step 1: Write the ALTER statement.
-- --------------------------------------------------
ALTER TABLE rental_item
ADD rental_item_price NUMBER
ADD rental_item_type NUMBER;



-- ----------------------------------------------------------------------
--  Verification #1: Verify the table structure.
-- ----------------------------------------------------------------------
SET NULL ''
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
WHERE    table_name = 'RENTAL_ITEM'
ORDER BY 2;

-- ----------------------------------------------------------------------
--  Step #2 : Create the PRICE table.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Objective #1: Conditionally drop a PRICE table before creating a
--                PRICE table and PRICE_S1 sequence.
-- ----------------------------------------------------------------------

-- Conditionally drop PRICE table and sequence.
BEGIN
  FOR i IN (SELECT null
            FROM   user_tables
            WHERE  table_name = 'PRICE') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE PRICE CASCADE CONSTRAINTS';
  END LOOP;
  FOR i IN (SELECT null
            FROM   user_sequences
            WHERE  sequence_name = 'PRICE_S1') LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE PRICE_S1';
  END LOOP;
END;
/

-- --------------------------------------------------
--  Step 1: Write the CREATE TABLE statement.
-- ------------------------------------------------
CREATE TABLE price 
(
price_id             NUMBER 
, item_id            NUMBER constraint nn_price_1 not null
, price_type         NUMBER
, active_flag        varchar2(1) constraint nn_price_2 not null
, start_date         DATE   constraint nn_price_3 not null
, end_date           DATE
, amount             NUMBER constraint nn_price_4 not null
, created_by         NUMBER constraint nn_price_5 not null
, creation_date      DATE   constraint nn_price_6 not null
, last_updated_by    NUMBER constraint nn_price_7 not null
, last_update_date   DATE   constraint nn_price_8 not null
, constraint pk_price_1
    primary key (price_id)
, constraint fk_price_1
    foreign key (item_id) references item(item_id)   
, constraint fk_price_2
    foreign key (price_type) references common_lookup(common_lookup_id)
, constraint fk_price_3
    foreign key (created_by) references system_user(system_user_id)
, constraint fk_price_4
    foreign key (last_updated_by) references system_user(system_user_id)
, constraint yn_price check (active_flag in ('Y', 'N')));
    


-- --------------------------------------------------
--  Step 2: Write the CREATE SEQUENCE statement.
-- --------------------------------------------------

create sequence price_s1 start with 1001 nocache;



-- ----------------------------------------------------------------------
--  Objective #2: Verify the table structure.
-- ----------------------------------------------------------------------
SET NULL ''
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
WHERE    table_name = 'PRICE'
ORDER BY 2;
-- ----------------------------------------------------------------------
--  Objective #3: Verify the table constraints.
-- ----------------------------------------------------------------------
COLUMN constraint_name   FORMAT A16
COLUMN search_condition  FORMAT A30
SELECT   uc.constraint_name
,        uc.search_condition
FROM     user_constraints uc INNER JOIN user_cons_columns ucc
ON       uc.table_name = ucc.table_name
AND      uc.constraint_name = ucc.constraint_name
WHERE    uc.table_name = UPPER('price')
AND      ucc.column_name = UPPER('active_flag')
AND      uc.constraint_name = UPPER('yn_price')
AND      uc.constraint_type = 'C';

-- ----------------------------------------------------------------------
--  Step #3 : Insert new data into the model.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Objective #3: Rename ITEM_RELEASE_DATE column to RELEASE_DATE column,
--                insert three new DVD releases into the ITEM table,
--                insert three new rows in the MEMBER, CONTACT, ADDRESS,
--                STREET_ADDRESS, and TELEPHONE tables, and insert
--                three new RENTAL and RENTAL_ITEM table rows.
-- ----------------------------------------------------------------------

-- ----------------------------------------------------------------------
--  Step #3a: Rename ITEM_RELEASE_DATE Column.
-- ----------------------------------------------------------------------
alter table item
rename column item_release_date to release_date;





-- ----------------------------------------------------------------------
--  Verification #3a: Verify the column name change.
-- ----------------------------------------------------------------------
SET NULL ''
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
,        data_type
||      '('||data_length||')' AS data_type
FROM     user_tab_columns
WHERE    TABLE_NAME = 'ITEM'
ORDER BY 2;

-- ----------------------------------------------------------------------
--  Step #3b: Insert three rows in the ITEM table.
-- ----------------------------------------------------------------------
insert into item
(
  item_id
, item_barcode          
, item_type
, item_title
, release_date
, created_by
, creation_date
, last_updated_by
, last_update_date
, rating_id)
values(
    item_s1.nextval
,   '12-34567-89854'
,   (select common_lookup_id
     from common_lookup
     where common_lookup_context = 'ITEM'
     and common_lookup_type = 'DVD_FULL_SCREEN')
,   'TRON'
, (TRUNC(SYSDATE - 1))
, 1001
, SYSDATE
, 1001
, SYSDATE
, (select rating_id
 from rating
 where rating = 'PG'));
 
 insert into item
(
  item_id
, item_barcode          
, item_type
, item_title
, release_date
, created_by
, creation_date
, last_updated_by
, last_update_date
, rating_id)
values(
    item_s1.nextval
,   '12-34568-89854'
,   (select common_lookup_id
     from common_lookup
     where common_lookup_context = 'ITEM'
     and common_lookup_type = 'DVD_FULL_SCREEN')
,   'Enders Game'
, (TRUNC(SYSDATE - 1))
, 1001
, SYSDATE
, 1001
, SYSDATE
, (select rating_id
 from rating
 where rating = 'PG-13'));
 
 insert into item
(
  item_id
, item_barcode          
, item_type
, item_title
, release_date
, created_by
, creation_date
, last_updated_by
, last_update_date
, rating_id)
values(
    item_s1.nextval
,   '12-34569-89854'
,   (select common_lookup_id
     from common_lookup
     where common_lookup_context = 'ITEM'
     and common_lookup_type = 'DVD_FULL_SCREEN')
,   'Elysium'
, (TRUNC(SYSDATE - 1))
, 1001
, SYSDATE
, 1001
, SYSDATE
, (select rating_id
 from rating
 where rating = 'R'));
 
 
 
 


-- ----------------------------------------------------------------------
--  Verification #3b: Verify the column name change.
-- ----------------------------------------------------------------------
COLUMN item_title FORMAT A14
COLUMN today FORMAT A10
COLUMN release_date FORMAT A10 HEADING "RELEASE|DATE"
SELECT   i.item_title
,        SYSDATE AS today
,        i.release_date
FROM     item i
WHERE   (SYSDATE - i.release_date) < 31;

-- ----------------------------------------------------------------------
--  Step #3c: Insert three new rows in the MEMBER, CONTACT, ADDRESS,
--            STREET_ADDRESS, and TELEPHONE tables.
-- ----------------------------------------------------------------------
insert into member values
    (member_s1.nextval
    , (select common_lookup_id
       from common_lookup
       where common_lookup_context = 'MEMBER'
       and common_lookup_type = 'GROUP')
       , 'US00011'
       , '6011-0000-0000-0078'
       , (select common_lookup_id
       from common_lookup
       where common_lookup_context = 'MEMBER'
       and common_lookup_type ='DISCOVER_CARD')
       , 1
       , SYSDATE
       , 1
       , SYSDATE);
       
insert into contact values
    (contact_s1.nextval
,    member_s1.currval  
,    (select common_lookup_id
       from common_lookup
       where common_lookup_context = 'CONTACT'
       and common_lookup_type = 'CUSTOMER')
,      'Harry'
,      ''
,      'Potter'
,      1
,      SYSDATE
,      1
,      SYSDATE);

insert into address values
    (address_s1.nextval
,    contact_s1.currval
,    (select common_lookup_id
     from common_lookup
     where common_lookup_context = 'MULTIPLE'
     and common_lookup_type = 'HOME')
,    'Provo'
,    'Utah'
,    84097
,    1
,    SYSDATE
,    1
,    SYSDATE);

insert into street_address values
    (street_address_s1.nextval
,    address_s1.currval
,   '980 E 300 N'
,   1
,    SYSDATE
,    1
,    SYSDATE);

insert into telephone values
    (telephone_s1.nextval
,   contact_s1.currval
,   address_s1.currval
,   (select common_lookup_id
     from common_lookup
     where common_lookup_context = 'MULTIPLE'
     and common_lookup_type = 'HOME')
,   '1'
,   '801'
,   '333-3333'
,   1
,    SYSDATE
,    1
,    SYSDATE);    


insert into contact values
    (contact_s1.nextval
,    member_s1.currval  
,    (select common_lookup_id
       from common_lookup
       where common_lookup_context = 'CONTACT'
       and common_lookup_type = 'CUSTOMER')
,      'Ginny'
,      ''
,      'Potter'
,      1
,      SYSDATE
,      1
,      SYSDATE);

insert into address values
    (address_s1.nextval
,    contact_s1.currval
,    (select common_lookup_id
     from common_lookup
     where common_lookup_context = 'MULTIPLE'
     and common_lookup_type = 'HOME')
,    'Provo'
,    'Utah'
,    84097
,    1
,    SYSDATE
,    1
,    SYSDATE);

insert into street_address values
    (street_address_s1.nextval
,    address_s1.currval
,   '980 E 300 N'
,   1
,    SYSDATE
,    1
,    SYSDATE);

insert into telephone values
    (telephone_s1.nextval
,   contact_s1.currval
,   address_s1.currval
,   (select common_lookup_id
     from common_lookup
     where common_lookup_context = 'MULTIPLE'
     and common_lookup_type = 'HOME')
,   '1'
,   '801'
,   '333-3333'
,   1
,    SYSDATE
,    1
,    SYSDATE); 



insert into contact values
    (contact_s1.nextval
,    member_s1.currval  
,    (select common_lookup_id
       from common_lookup
       where common_lookup_context = 'CONTACT'
       and common_lookup_type = 'CUSTOMER')
,      'Lily'
,      'Luna'
,      'Potter'
,      1
,      SYSDATE
,      1
,      SYSDATE);

insert into address values
    (address_s1.nextval
,    contact_s1.currval
,    (select common_lookup_id
     from common_lookup
     where common_lookup_context = 'MULTIPLE'
     and common_lookup_type = 'HOME')
,    'Provo'
,    'Utah'
,    84097
,    1
,    SYSDATE
,    1
,    SYSDATE);

insert into street_address values
    (street_address_s1.nextval
,    address_s1.currval
,   '980 E 300 N'
,   1
,    SYSDATE
,    1
,    SYSDATE);

insert into telephone values
    (telephone_s1.nextval
,   contact_s1.currval
,   address_s1.currval
,   (select common_lookup_id
     from common_lookup
     where common_lookup_context = 'MULTIPLE'
     and common_lookup_type = 'HOME')
,   '1'
,   '801'
,   '333-3333'
,   1
,    SYSDATE
,    1
,    SYSDATE); 

-- ----------------------------------------------------------------------
--  Verification #3c: Verify the three new CONTACTS and their related
--                    information set.
-- ----------------------------------------------------------------------
SET NULL ''
COLUMN full_name FORMAT A20
COLUMN city      FORMAT A10
COLUMN state     FORMAT A10
SELECT   c.last_name || ', ' || c.first_name AS full_name
,        a.city
,        a.state_province AS state
FROM     member m INNER JOIN contact c
ON       m.member_id = c.member_id INNER JOIN address a
ON       c.contact_id = a.contact_id INNER JOIN street_address sa
ON       a.address_id = sa.address_id INNER JOIN telephone t
ON       c.contact_id = t.contact_id
WHERE    c.last_name = 'Potter';

-- ----------------------------------------------------------------------
--  Step #3d: Insert three new RENTAL and RENTAL_ITEM table rows..
-- ----------------------------------------------------------------------
insert into rental values
    (rental_s1.nextval
,   (select contact_id
    from contact
    where first_name = 'Harry'
    and last_name = 'Potter')
,   SYSDATE
,   SYSDATE + 1
,   1
,    SYSDATE
,    1
,    SYSDATE);

insert into rental_item values
    (rental_item_s1.nextval
,   rental_s1.currval
,   (select item_id
    from item
    where item_title = 'Star Wars I')
,    1
,    SYSDATE
,    1
,    SYSDATE
,    1
,    1);

insert into rental_item values
    (rental_item_s1.nextval
,   rental_s1.currval
,   (select item_id
    from item
    where item_title = 'Cars')
,    1
,    SYSDATE
,    1
,    SYSDATE
,    1
,    1);


insert into rental values
    (rental_s1.nextval
,   (select contact_id
    from contact
    where first_name = 'Ginny'
    and last_name = 'Potter')
,   SYSDATE
,   SYSDATE + 3
,   1
,    SYSDATE
,    1
,    SYSDATE);

insert into rental_item values
    (rental_item_s1.nextval
,   rental_s1.currval
,   (select item_id
    from item
    where item_title = 'Star Wars III')
,    1
,    SYSDATE
,    1
,    SYSDATE
,    3
,    3);


insert into rental values
    (rental_s1.nextval
,   (select contact_id
    from contact
    where first_name = 'Lily'
    and last_name = 'Potter')
,   SYSDATE
,   SYSDATE + 5
,   1
,    SYSDATE
,    1
,    SYSDATE);

insert into rental_item values
    (rental_item_s1.nextval
,   rental_s1.currval
,   (select item_id
    from item
    where item_title = 'RoboCop')
,    1
,    SYSDATE
,    1
,    SYSDATE
,    5
,    5);





-- ----------------------------------------------------------------------
--  Verification #3d: Verify the three new CONTACTS and their related
--                    information set.
-- ----------------------------------------------------------------------
COLUMN full_name   FORMAT A18
COLUMN rental_id   FORMAT 9999
COLUMN rental_days FORMAT A14
COLUMN rentals     FORMAT 9999
COLUMN items       FORMAT 9999
SELECT   c.last_name||', '||c.first_name||' '||c.middle_name AS full_name
,        r.rental_id
,       (r.return_date - r.check_out_date) || '-DAY RENTAL' AS rental_days
,        COUNT(DISTINCT r.rental_id) AS rentals
,        COUNT(ri.rental_item_id) AS items
FROM     rental r INNER JOIN rental_item ri
ON       r.rental_id = ri.rental_id INNER JOIN contact c
ON       r.customer_id = c.contact_id
WHERE   (SYSDATE - r.check_out_date) < 15
AND      c.last_name = 'Potter'
GROUP BY c.last_name||', '||c.first_name||' '||c.middle_name
,        r.rental_id
,       (r.return_date - r.check_out_date) || '-DAY RENTAL'
ORDER BY 2;

-- ----------------------------------------------------------------------
--  Objective #4: Modify the design of the COMMON_LOOKUP table, insert
--                new data into the model, and update old non-compliant
--                design data in the model.
-- ----------------------------------------------------------------------

-- ----------------------------------------------------------------------
--  Step #4a: Drop Indexes.
-- ----------------------------------------------------------------------
drop index common_lookup_n1;
drop index common_lookup_u2;



-- ----------------------------------------------------------------------
--  Verification #4a: Verify the unique indexes are dropped.
-- ----------------------------------------------------------------------
COLUMN table_name FORMAT A14
COLUMN index_name FORMAT A20
SELECT   table_name
,        index_name
FROM     user_indexes
WHERE    table_name = 'COMMON_LOOKUP';

-- ----------------------------------------------------------------------
--  Step #4b: Add three new columns.
-- ----------------------------------------------------------------------
alter table common_lookup
add  common_lookup_table varchar2(30)
add  common_lookup_column varchar2(30)
add  common_lookup_code varchar2(30);




-- ----------------------------------------------------------------------
--  Verification #4b: Verify the unique indexes are dropped.
-- ----------------------------------------------------------------------
SET NULL ''
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
WHERE    table_name = 'COMMON_LOOKUP'
ORDER BY 2;

-- ----------------------------------------------------------------------
--  Step #4c: Migrate data subject to re-engineered COMMON_LOOKUP table.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Step #4c(1): Query the pre-change state of the table.
-- ----------------------------------------------------------------------
COLUMN common_lookup_context  FORMAT A14  HEADING "Common|Lookup Context"
COLUMN common_lookup_table    FORMAT A12  HEADING "Common|Lookup Table"
COLUMN common_lookup_column   FORMAT A18  HEADING "Common|Lookup Column"
COLUMN common_lookup_type     FORMAT A18  HEADING "Common|Lookup Type"
SELECT   common_lookup_context
,        common_lookup_table
,        common_lookup_column
,        common_lookup_type
FROM     common_lookup
ORDER BY 1, 2, 3;

-- ----------------------------------------------------------------------
--  Step #4c(2): Query the post COMMON_LOOKUP_TABLE changes where the
--               COMMON_LOOKUP_CONTEXT is equal to the table names.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Step #4c(2): Update the records.
-- ----------------------------------------------------------------------

update common_lookup
set common_lookup_table =
case when common_lookup_context <> 'MULTIPLE'
then common_lookup_context
end;



-- ----------------------------------------------------------------------
--  Step #4c(2): Verify update of the records.
-- ----------------------------------------------------------------------
COLUMN common_lookup_context  FORMAT A14  HEADING "Common|Lookup Context"
COLUMN common_lookup_table    FORMAT A12  HEADING "Common|Lookup Table"
COLUMN common_lookup_column   FORMAT A18  HEADING "Common|Lookup Column"
COLUMN common_lookup_type     FORMAT A18  HEADING "Common|Lookup Type"
SELECT   common_lookup_context
,        common_lookup_table
,        common_lookup_column
,        common_lookup_type
FROM     common_lookup
ORDER BY 1, 2, 3;

-- ----------------------------------------------------------------------
--  Step #4c(3): Query the post COMMON_LOOKUP_TABLE changes where the
--               COMMON_LOOKUP_CONTEXT is not equal to the table names.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Step #4c(3): Update the records.
-- ----------------------------------------------------------------------

update common_lookup
set common_lookup_table =
case when common_lookup_context = 'MULTIPLE'
then 'ADDRESS'
else common_lookup_context
end; 



-- ----------------------------------------------------------------------
--  Step #4c(3): Verify update of the records.
-- ----------------------------------------------------------------------
COLUMN common_lookup_context  FORMAT A14  HEADING "Common|Lookup Context"
COLUMN common_lookup_table    FORMAT A12  HEADING "Common|Lookup Table"
COLUMN common_lookup_column   FORMAT A18  HEADING "Common|Lookup Column"
COLUMN common_lookup_type     FORMAT A18  HEADING "Common|Lookup Type"
SELECT   common_lookup_context
,        common_lookup_table
,        common_lookup_column
,        common_lookup_type
FROM     common_lookup
ORDER BY 1, 2, 3;

-- ----------------------------------------------------------------------
--  Step #4c(4): Query the post COMMON_LOOKUP_COLUMN change.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Step #4c(4): Update the type records.
-- ----------------------------------------------------------------------
update common_lookup
set common_lookup_column =  
case when common_lookup_context <> 'MULTIPLE' 
then common_lookup_context || '_TYPE'
else 
    'ADDRESS_TYPE'
end;



-- ----------------------------------------------------------------------
--  Step #4c(4): Verify update of the type records.
-- ----------------------------------------------------------------------
COLUMN common_lookup_context  FORMAT A14  HEADING "Common|Lookup Context"
COLUMN common_lookup_table    FORMAT A12  HEADING "Common|Lookup Table"
COLUMN common_lookup_column   FORMAT A18  HEADING "Common|Lookup Column"
COLUMN common_lookup_type     FORMAT A18  HEADING "Common|Lookup Type"
SELECT   common_lookup_context
,        common_lookup_table
,        common_lookup_column
,        common_lookup_type
FROM     common_lookup
WHERE    common_lookup_table IN
          (SELECT table_name
           FROM   user_tables)
ORDER BY 1, 2, 3;

-- ----------------------------------------------------------------------
--  Step #4c(4): Query the post COMMON_LOOKUP_COLUMN change.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Step #4c(4): Update the ADDRESS table type records.
-- ----------------------------------------------------------------------




-- ----------------------------------------------------------------------
--  Step #4c(4): Verify update of the ADDRESS table type records.
-- ----------------------------------------------------------------------
COLUMN common_lookup_context  FORMAT A14  HEADING "Common|Lookup Context"
COLUMN common_lookup_table    FORMAT A12  HEADING "Common|Lookup Table"
COLUMN common_lookup_column   FORMAT A18  HEADING "Common|Lookup Column"
COLUMN common_lookup_type     FORMAT A18  HEADING "Common|Lookup Type"
SELECT   common_lookup_context
,        common_lookup_table
,        common_lookup_column
,        common_lookup_type
FROM     common_lookup
WHERE    common_lookup_table IN
          (SELECT table_name
           FROM   user_tables)
ORDER BY 1, 2, 3;

-- ----------------------------------------------------------------------
--  Step #4c(5): Query the post COMMON_LOOKUP_COLUMN change.
-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------
--  Step #4c(4): Alter the table and remove the unused column.
-- ----------------------------------------------------------------------
alter table common_lookup
drop column common_lookup_context;



-- ----------------------------------------------------------------------
--  Step #4c(4): Verify modification of table structure.
-- ----------------------------------------------------------------------
SET NULL ''
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
WHERE    table_name = 'COMMON_LOOKUP'
ORDER BY 2;

-- ----------------------------------------------------------------------
--  Step #4c(6): Insert new rows for the TELEPHONE table.
-- ----------------------------------------------------------------------
insert into common_lookup values
    (common_lookup_s1.nextval
,   'HOME'
,   'Home'
,   1
,   SYSDATE
,   1
,   SYSDATE
,   'TELEPHONE'
,   'TELEPHONE_TYPE'
,   'New');

insert into common_lookup values
    (common_lookup_s1.nextval
,   'WORK'
,   'Work'
,   1
,   SYSDATE
,   1
,   SYSDATE
,   'TELEPHONE'
,   'TELEPHONE_TYPE'
,   'New');





-- ----------------------------------------------------------------------
--  Step #4c(6): Verify insert of new rows to the TELEPHONE table.
-- ----------------------------------------------------------------------
COLUMN common_lookup_table    FORMAT A12  HEADING "Common|Lookup Table"
COLUMN common_lookup_column   FORMAT A18  HEADING "Common|Lookup Column"
COLUMN common_lookup_type     FORMAT A18  HEADING "Common|Lookup Type"
SELECT   common_lookup_table
,        common_lookup_column
,        common_lookup_type
FROM     common_lookup
WHERE    common_lookup_table IN
          (SELECT table_name
           FROM   user_tables)
ORDER BY 1, 2, 3;

-- ----------------------------------------------------------------------
--  Step #4d: Alter the table structure.
-- ----------------------------------------------------------------------
alter table common_lookup
modify common_lookup_table constraint nn_common_lookup_8 NOT NULL
modify common_lookup_column constraint nn_common_lookup_9 NOT NULL;




-- ----------------------------------------------------------------------
--  Step #4d: Verify changes to the table structure.
-- ----------------------------------------------------------------------
SET NULL ''
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
WHERE    table_name = 'COMMON_LOOKUP'
ORDER BY 2;

-- Display non-unique constraints.
COLUMN constraint_name   FORMAT A22  HEADING "Constraint Name"
COLUMN search_condition  FORMAT A36  HEADING "Search Condition"
COLUMN constraint_type   FORMAT A10  HEADING "Constraint|Type"
SELECT   uc.constraint_name
,        uc.search_condition
,        uc.constraint_type
FROM     user_constraints uc INNER JOIN user_cons_columns ucc
ON       uc.table_name = ucc.table_name
AND      uc.constraint_name = ucc.constraint_name
WHERE    uc.table_name = UPPER('common_lookup')
AND      uc.constraint_type IN (UPPER('c'),UPPER('p'))
ORDER BY uc.constraint_type DESC
,        uc.constraint_name;

-- ----------------------------------------------------------------------
--  Step #4d: Add unique index.
-- ----------------------------------------------------------------------
create unique index clookup_u2
on common_lookup(common_lookup_table, common_lookup_column, common_lookup_type);



-- ----------------------------------------------------------------------
--  Step #4d: Verify new unique index.
-- ----------------------------------------------------------------------
COLUMN sequence_name   FORMAT A22 HEADING "Sequence Name"
COLUMN column_position FORMAT 999 HEADING "Column|Position"
COLUMN column_name     FORMAT A22 HEADING "Column|Name"
SELECT   ui.index_name
,        uic.column_position
,        uic.column_name
FROM     user_indexes ui INNER JOIN user_ind_columns uic
ON       ui.index_name = uic.index_name
AND      ui.table_name = uic.table_name
WHERE    ui.table_name = UPPER('common_lookup')
ORDER BY ui.index_name
,        uic.column_position;

-- ----------------------------------------------------------------------
--  Step #4d: Update the foreign keys of the TELEPHONE table.
-- ----------------------------------------------------------------------
update telephone
set telephone_type = (select common_lookup_id from common_lookup
                        where common_lookup_table = 'TELEPHONE'
                        and common_lookup_type = 'HOME');

alter table telephone
drop constraint fk_telephone_2;

alter table telephone
add constraint fk_telephone_5
foreign key (telephone_type) references common_lookup(common_lookup_id);



-- ----------------------------------------------------------------------
--  Step #4d: Verify the foreign keys of the TELEPHONE table.
-- ----------------------------------------------------------------------
COLUMN common_lookup_table  FORMAT A14 HEADING "Common|Lookup Table"
COLUMN common_lookup_column FORMAT A14 HEADING "Common|Lookup Column"
COLUMN common_lookup_type   FORMAT A8  HEADING "Common|Lookup|Type"
COLUMN count_dependent      FORMAT 999 HEADING "Count of|Foreign|Keys"
COLUMN count_lookup         FORMAT 999 HEADING "Count of|Primary|Keys"
SELECT   cl.common_lookup_table
,        cl.common_lookup_column
,        cl.common_lookup_type
,        COUNT(a.address_id) AS count_dependent
,        COUNT(DISTINCT cl.common_lookup_table) AS count_lookup
FROM     address a RIGHT JOIN common_lookup cl
ON       a.address_type = cl.common_lookup_id
WHERE    cl.common_lookup_table = 'ADDRESS'
AND      cl.common_lookup_column = 'ADDRESS_TYPE'
AND      cl.common_lookup_type IN ('HOME','WORK')
GROUP BY cl.common_lookup_table
,        cl.common_lookup_column
,        cl.common_lookup_type
UNION
SELECT   cl.common_lookup_table
,        cl.common_lookup_column
,        cl.common_lookup_type
,        COUNT(t.telephone_id) AS count_dependent
,        COUNT(DISTINCT cl.common_lookup_table) AS count_lookup
FROM     telephone t RIGHT JOIN common_lookup cl
ON       t.telephone_type = cl.common_lookup_id
WHERE    cl.common_lookup_table = 'TELEPHONE'
AND      cl.common_lookup_column = 'TELEPHONE_TYPE'
AND      cl.common_lookup_type IN ('HOME','WORK')
GROUP BY cl.common_lookup_table
,        cl.common_lookup_column
,        cl.common_lookup_type;

SPOOL OFF
