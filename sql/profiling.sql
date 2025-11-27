select * from st_orders where currency like 'US$';
select * from st_orders where currency like 'US$';
select * from st_orders;
select * from st_orders where currency like 'HUF';
select * from st_orders where currency like 'EURO';
select * from st_orders where currency like 'EUR';
select * from st_orders where currency like 'USD';
select * from st_orders where currency in ('null', 'NULL', '(null)', '0', 'N/A');
select * from st_orders where currency is null;
select * from st_orders where amount like '% USD';
select * from st_orders where regexp_like(amount,'^-[0-9]+(\.[0-9]+)?$');
select * from st_orders where regexp_like(amount,'^[-[0-9]+(\.[0-9]+)?$');
select * from st_orders where regexp_like(amount,'^[-]?[0-9]+(\.[0-9]+)?$');
select * from st_orders where regexp_like(amount,'^[+-]?[0-9]+(\.[0-9]+)?$');
select * from st_orders where regexp_like(amount,'^[0-9]+(\.[0-9]+)?$');
select * from st_orders where amount is null;
select * from st_orders where amount in ('null', 'NULL', '(null)', '0', 'N/A');
select * from st_orders where regexp_like(order_date, '^[A-Za-z]{3} +[0-9]{2}+, [0-9]{4}$');
select * from st_orders where regexp_like(order_date, '^[0-9]{2} +[A-Za-z]+ [0-9]{4}$');
select * from st_orders where regexp_like(order_date, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$');
select * from st_orders where regexp_like(order_date, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$');
select * from st_orders where regexp_like(order_date, '^20[0-9]{2}-[0-9]{2}-[0-9]{2}$');
select * from st_orders where order_date like 'yesterday';
select * from st_orders where order_date like 'today';
select * from st_orders where order_date like 'unknown';
select * from st_orders where order_date is null;
select * from st_orders where order_date in ('null', 'NULL', '(null)', '0', 'N/A');
select * from st_orders where regexp_like(customer_id, '^[0-9]{4}$');
select * from st_orders where customer_id like 'CUST%';
select * from st_orders where customer_id is null;
select * from st_orders where customer_id like '(null)';
select * from st_orders where customer_id like '%(null)%';
select * from st_orders where customer_id in ('null', 'NULL', '(null)', '0', 'N/A');
select * from st_orders where regexp_like(order_id, '^[0-9]{4}$');
select * from st_orders where order_id like '%-%';
select * from st_orders where order_id like 'ORD%';
select * from st_orders where order_id in ('null', '0', 'N/A');
select * from st_customers where phone like '%ext.%';
select * from st_customers where regexp_like(phone, '^[0-9]{9}');
select * from st_customers;
select * from st_customers where phone like 'phone:%';
select * from st_customers where regexp_like(phone, '^\+[0-9]{2} +[0-9]{9}$');
select * from st_customers where regexp_like(phone, '^[0-9]{9}$');
select * from st_customers where regexp_like(phone, '^[0-9]{2}\-+[0-9]{8}$');
select * from st_customers where regexp_like(phone, '^\([0-9]{3}\) [0-9]{6}$');
select * from st_customers where regexp_like(phone, '^([0-9]{3})+[0-9]{6}$');
select * from st_customers where regexp_like(phone, '^([0-9]{3})  +[0-9]{6}$');
select * from st_customers where regexp_like(phone, '^(+[0-9]{3}+) +[0-9]{6}$');
select * from st_customers where regexp_like(phone, '^([0-9]{3}) +[0-9]{6}$');
select * from st_customers where phone in ('null', '0', 'N/A');
select * from st_customers where reg_date like 'yesterday';
select * from st_customers where regexp_like(reg_date, '^[A-Za-z]{3} +[0-9]{2}+, [0-9]{4}$');
select * from st_customers where regexp_like(reg_date, '^[A-Za-z]{} +[0-9]{2}+, [0-9]{4}$');
select * from st_customers where regexp_like(reg_date, '^[0-9]{2} +[A-Za-z]+ [0-9]{4}$');
select * from st_customers where regexp_like(reg_date, '^[0-9]{2} % [0-9]{4}$');
select * from st_customers where regexp_like(reg_date, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$');
select * from st_customers where regexp_like(reg_date, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$');
select * from st_customers where regexp_like(reg_date, '^[0-9]{2}-[0-9]{2}-[0-9]{4}$');
select * from st_customers where regexp_like(reg_date, '^20[0-9]{2}-[0-9]{2}-[0-9]{2}$');
select * from st_customers where reg_date like 'today';
select * from st_customers where reg_date like 'unknown';
select * from st_customers where reg_date like 'unkonwn';
select * from st_customers where reg_date in ('null', '0', 'N/A');
select * from st_customers where email like '%,%';
select * from st_customers where email like '%@example.com';
select * from st_customers where email like '%@company.org';
select * from st_customers where email like '%@gmail.com';
select * from st_customers where email like '%/%@gmail.com';
select * from st_customers where email like 'not-an-email';
select * from st_customers where email like '@example.com';
select count (*) from st_customers where email in ('null', '0', 'N/A');
select * from st_customers where not regexp_like(customer_id, '^[0-9]{4}$') and customer_id not like 'CUST%';
select * from st_customers where regexp_like(customer_id, '^[0-9]{4}$');
select * from st_customers where regexp_like(customer_id, '^[0-9]{7}$');
select * from st_customers where regexp_like(customer_id, '^[0-9]{6}$');
select * from st_customers where regexp_like(customer_id, '^[0-9]{1}$');
select * from st_customers where regexp_like(customer_id, '^[0-9]{}$');
select * from st_customers where regexp_like(customer_id, '^[0-9]{2}$');
select * from st_customers where regexp_like(customer_id, '^[0-9]{3}$');
select * from st_customers where regexp_like(customer_id, '^[0-9]{5}$');
select count(*) from st_customers where regexp_like(customer_id, '^[0-9]{4}$');
select count(*) from st_customers where full_name not like '%/%';
select * from st_customers where full_name not like '%/%';
select * from st_customers where full_name like '%/%';
select count (*) from st_customers where full_name in ('null', '0', 'N/A');
select count (full_name) from st_customers;
select * from st_customers where customer_id like 'CUST%';
select * from st_customers where customer_id like '[0-9][0-9][0-9][0-9]';
select * from st_customers where customer_id like '[0-9999]';
select * from st_customers where customer_id like '[0-9]';
select count (*) from st_customers;
select * from st_customers where customer_id like 'CUST%';
select * from st_customers where email not like '%@%.';
select  * from st_customers where reg_date in ('null', '0', 'N/A');
select count (*) from st_customers where reg_date in ('null', '0', 'N/A');
select count (*) from st_customers where phone in ('null', '0', 'N/A');
select count (*) from st_customers where customer_id in ('null', '0', 'N/A');


select * from st_payments;
select count(*) from st_payments;
select * from st_payments where payment_id in ('null', 'NULL', '(null)', '0', 'N/A');
select * from st_payments where payment_id like 'PAY%';
select * from st_payments where regexp_like(payment_id, '^[0-9]{4}$');
select * from st_payments where payment_id like '%-';

select * from st_payments where order_id in ('null', 'NULL', '(null)', '0', 'N/A');
select * from st_payments where order_id is null;
select * from st_payments where order_id like 'ORD%';
select * from st_payments where regexp_like(order_id, '^[0-9]{4}$');

select * from st_payments where payment_date in ('null', 'NULL', '0', 'N/A');
select * from st_payments where payment_date is null;
select * from st_payments where payment_date like 'today';
select * from st_payments where payment_date like 'unknown';
select * from st_payments where payment_date like 'yesterday';
select * from st_payments where regexp_like(payment_date, '^[A-Za-z]{3} +[0-9]{2}+, [0-9]{4}$');
select * from st_payments where regexp_like(payment_date, '^[A-Za-z]{} +[0-9]{2}+, [0-9]{4}$');
select * from st_payments where regexp_like(payment_date, '^[0-9]{2} +[A-Za-z]+ [0-9]{4}$');
select * from st_payments where regexp_like(payment_date, '^[0-9]{2} % [0-9]{4}$');
select * from st_payments where regexp_like(payment_date, '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$');
select * from st_payments where regexp_like(payment_date, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$');
select * from st_payments where regexp_like(payment_date, '^[0-9]{2}-[0-9]{2}-[0-9]{4}$');
select * from st_payments where regexp_like(payment_date, '^20[0-9]{2}-[0-9]{2}-[0-9]{2}$');

select * from st_payments;
select * from st_payments where amount in ('0', 'NULL', 'null', 'N/A');
select * from st_payments where amount is null;
select * from st_payments where amount like '% USD';
select * from st_payments where regexp_like(amount,'^-[0-9]+(\.[0-9]+)?$');
select * from st_payments where regexp_like(amount,'^[-[0-9]+(\.[0-9]+)?$');
select * from st_payments where regexp_like(amount,'^[-]?[0-9]+(\.[0-9]+)?$');
select * from st_payments where regexp_like(amount,'^[+-]?[0-9]+(\.[0-9]+)?$');
select * from st_payments where regexp_like(amount,'^[0-9]+(\.[0-9]+)?$');

select * from st_payments where method in ('0', 'null', 'NULL', 'N/A');
select * from st_payments where method like 'bank_transfer';
select * from st_payments where method like 'bank-tf';
select * from st_payments where upper(method) like 'CARD';
select * from st_payments where method like 'PayPal';
select * from st_payments where method like 'Card';
select * from st_payments where method like 'pay_pal';
select * from st_payments where method like 'cash';


select * from st_payments;



drop table lxn_data_profile_log;

CREATE TABLE LXN_DATA_PROFILE_LOG (
    key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name VARCHAR2(50),
    column_name VARCHAR2(50),
    no_records NUMBER,
    input_form VARCHAR2(100),
    regex VARCHAR2(100),
    no_records_form NUMBER,
    percentage NUMBER,
    min_value NUMBER,
    max_value NUMBER,
    duplicates NUMBER,
    normalized_form VARCHAR2(100)
);
commit;

select * from lxn_data_profile_log;

INSERT INTO LXN_DATA_PROFILE_LOG 
(table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'customer_id', 360, 'CUST*four digit number*', '^CUST[0-9]{4}$', 112, 31.11, 0, 0, 97, 'four digit numbers');

INSERT INTO LXN_DATA_PROFILE_LOG 
(table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'customer_id', 360, 'four digit number', '^[0-9]{4}$', 130, 36.11, 0, 0, 8, 'four digit numbers');

INSERT INTO LXN_DATA_PROFILE_LOG 
(table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'customer_id', 360, 'random sequence', '^[A-Za-z0-9]+$', 118, 32.77, 0, 0, NULL, 'four digit numbers');


INSERT INTO LXN_DATA_PROFILE_LOG 
(table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'full_name', 360, 'Name/Name', '^[A-Za-z]+/[A-Za-z]+$', 14, 3.88, 0, 0, NULL, 'Name Name');

INSERT INTO LXN_DATA_PROFILE_LOG 
(table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'full_name', 360, 'Name Name', '^[A-Za-z]+ [A-Za-z]+$', 346, 96.11, 0, 0, NULL, 'Name Name');


INSERT INTO LXN_DATA_PROFILE_LOG 
(table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'email', 360, 'not-an-email', '^not-an-email$', 60, 16.66, 0, 0, NULL, 'null');



INSERT INTO LXN_DATA_PROFILE_LOG 
(table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'email', 360, 'not-an-email', '^not-an-email$', 60, 16.66, NULL, 0, 0, NULL, 'null');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'email', 360, '*email*@gmail.com', '^[A-Za-z0-9._%+-]+@gmail\.com$', 102, 28.33, 0, 0, NULL, 'email%gmail.com/email@company.org/email@example.com');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'email', 360, '*email*@company.org', '^[A-Za-z0-9._%+-]+@company\.org$', 96, 26.66, 0, 0, NULL, 'email%gmail.com/email@company.org/email@example.com');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'email', 360, '*email*@example.com', '^[A-Za-z0-9._%+-]+@example\.com$', 102, 28.33, 0, 0, NULL, 'email%gmail.com/email@company.org/email@example.com');


INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'reg_date', 360, 'unknown', '^unknown$', 5, 1.38, 0, 0, NULL, 'null');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'reg_date', 360, 'N/A', '^N/A$', 1, 0.27, 0, 0, NULL, 'null');


INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'reg_date', 360, 'today', '^today$', 1, 0.27, 0, 0, NULL, 'sysdate');


INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'reg_date', 360, 'yyyy-mm-dd', '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', 70, 19.44, 0, 0, NULL, NULL);


INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'reg_date', 360, 'dd/mm/yyyy', '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 107, 29.72, 0, 0, NULL, NULL);


INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'reg_date', 360, 'dd-Mon-yyyy', '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$', 58, 16.11, 0, 0, NULL, NULL);


INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'reg_date', 360, 'dd Month yyyy', '^[0-9]{2} [A-Za-z]+ [0-9]{4}$', 57, 15.83, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'reg_date', 360, 'Mon dd, yyyy', '^[A-Za-z]{3} [0-9]{2}, [0-9]{4}$', 59, 16.38, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'reg_date', 360, 'yesterday', '^yesterday$', 2, 0.55, 0, 0, NULL, 'sysdate-1');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'phone', 360, '(xxx) xxxxxx', '^\([0-9]{3}\) [0-9]{6}$', 76, 21.11, 0, 0, NULL, 'keep');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'phone', 360, 'xx-xxxxxxxx', '^[0-9]{2}-[0-9]{8}$', 72, 20, 0, 0, NULL, 'keep');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'phone', 360, 'xxxxxxxxx', '^[0-9]{9}$', 73, 20.27, 0, 0, NULL, 'keep');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'phone', 360, '+xx xxxxxxxx', '^\+[0-9]{2} [0-9]{8}$', 66, 18.33, 0, 0, NULL, 'keep');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_customers', 'phone', 360, 'phone: xxxxxxx', '^phone: [0-9]{7}$', 58, 16.11, 0, 0, NULL, 'xxxxxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_id', 720, 'ORDxxxx', '^ORD[0-9]{4}$', 242, 33.61, 0, 0, NULL, 'xxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_id', 720, 'xxxx', '^[0-9]{4}$', 251, 34.86, 0, 0, NULL, 'xxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_id', 720, 'string-x', '^[A-Za-z0-9]+-[A-Za-z0-9]$', 227, 31.52, 0, 0, NULL, 'xxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'customer_id', 720, 'NULL', '^NULL$', 184, 25.55, 0, 0, NULL, 'null');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'customer_id', 720, '(null)', 'is null', 191, 26.52, 0, 0, NULL, 'null');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'customer_id', 720, 'CUST:xxxx', '^CUST[0-9]{4}$', 188, 26.11, 0, 0, NULL, 'xxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'customer_id', 720, 'xxxx', '^[0-9]{4}$', 157, 21.8, 0, 0, NULL, 'xxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_date', 720, 'N/A', '^N/A$', 4, 0.55, 0, 0, NULL, 'null');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_date', 720, 'unknown', '^unknown$', 8, 1.11, 0, 0, NULL, 'null');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_date', 720, 'today', '^today$', 2, 0.27, 0, 0, NULL, 'sysdate');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_date', 720, 'yesterday', '^yesterday$', 3, 0.41, 0, 0, NULL, 'sysdate-1');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_date', 720, 'yyyy-mm-dd', '^20[0-9]{2}-[0-9]{2}-[0-9]{2}$', 111, 15.41, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_date', 720, 'dd-mon-yyyy', '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$', 118, 16.38, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_date', 720, 'dd Month yyyy', '^[0-9]{2} [A-Za-z]+ [0-9]{4}$', 124, 17.22, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'order_date', 720, 'Mon dd, yyyy', '^[A-Za-z]{3} [0-9]{2}, [0-9]{4}$', 114, 15.83, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'amount', 720, 'null', 'is null', 206, 28.61, 0, 0, NULL, 'null');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'amount', 720, 'USD', '^USD$', 91, 12.63, 0, 0, NULL, 'keep');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'amount', 720, 'EUR', '^EUR$', 101, 14.02, 0, 0, NULL, 'keep');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'amount', 720, 'EURO', '^EURO$', 95, 13.19, 0, 0, NULL, 'EUR');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'amount', 720, 'HUF', '^HUF$', 110, 15.27, 0, 0, NULL, 'keep');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_orders', 'amount', 720, 'US $', '^US \$$', 117, 16.25, 0, 0, NULL, 'USD');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'payment_id', 720, 'PAYxxxx', '^PAY[0-9]{4}$', 243, 33.75, 0, 0, NULL, 'xxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'payment_id', 720, 'xxxx', '^[0-9]{4}$', 239, 33.19, 0, 0, NULL, 'keep');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'payment_id', 720, 'xxxxxxxx-', '^[A-Za-z0-9]{8}-$', 238, 33.05, 0, 0, NULL, 'xxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_id', 720, 'NULL', '^NULL$', 190, 26.38, 0, 0, NULL, 'xxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_id', 720, 'null', 'is null', 157, 21.8,, 0, 0, NULL, 'xxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_id', 720, 'ORDxxxx', '^ORD[0-9]{4}$', 193, 26.8, 0, 0, NULL, 'xxxx');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_id', 720, 'xxxx', '^[0-9]{4}$', 180, 25, 0, 0, NULL, 'keep');


INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_date', 720, 'N/A', '^N/A$', 9, 1.25, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_date', 720, 'today', '^today$', 6, 0.83, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_date', 720, 'unknown', '^unknown$', 8, 1.11, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_date', 720, 'yesterday', '^yesterday$', 10, 1.38, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_date', 720, 'Mon dd, yyyy', '^[A-Za-z]{3} [0-9]{2}, [0-9]{4}$', 108, 15, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_date', 720, 'dd month yyyy', '^[0-9]{2} [A-Za-z]+ [0-9]{4}$', 116, 16.11, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_date', 720, 'dd-mon-yyyy', '^[0-9]{2}-[A-Za-z]{3}-[0-9]{4}$', 121, 16.8, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_date', 720, 'dd/mm/yyyy', '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 221, 30.69, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'order_date', 720, 'yyyy-mm-dd', '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', 121, 16.8, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'amount', 720, 'N/A', '^N/A$', 45, 6.25, 0, 0, NULL, 'numeric');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'amount', 720, 'numeric', '^[0-9]+$', 621, 86.25, 0, 0, NULL, 'keep');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'amount', 720, 'numeric', '^[0-9]+USD$', 38, 52.77, 0, 0, NULL, 'numeric');

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'method', 720, 'bank_transfer', '^bank_transfer$', 113, 15.69, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'method', 720, 'bank-tf', '^bank-tf$', 80, 11.11, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'method', 720, 'PayPal', '^PayPal$', 96, 13.33, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'method', 720, 'cash', '^cash$', 87, 12.08, 0, 0, NULL, NULL);

INSERT INTO LXN_DATA_PROFILE_LOG (table_name, column_name, no_records, input_form, regex, no_records_form, percentage, min_value, max_value, duplicates, normalized_form)
VALUES ('st_payments', 'method', 720, 'card', '^card$', 259, 35.97, 0, 0, NULL, NULL);

select * from lxn_data_profile_log;
/

CREATE OR REPLACE PROCEDURE populate_profile_stats AS
    -- Cursor to loop over profile rows
    CURSOR c_prof IS
        SELECT rowid AS rid,
               table_name,
               column_name,
               no_records,
               regex
        FROM lxn_data_profile_log;
    --variables
    v_sql          VARCHAR2(4000);
    v_count_form   NUMBER; 
    v_duplicates   NUMBER; 
    v_percentage   NUMBER;  
    v_min          NUMBER;
    v_max          NUMBER;

BEGIN
    FOR r IN c_prof LOOP
        begin
        --count no_records_form (all of the records that fit the regex)
        v_sql :=
            'SELECT COUNT(*) FROM ' || r.table_name ||
            ' WHERE REGEXP_LIKE(' || r.column_name || ', :regex)';

        EXECUTE IMMEDIATE v_sql INTO v_count_form USING r.regex;
	--count duplicates (duplicates)
        v_sql :=
            'SELECT COUNT(*) FROM (
                SELECT ' || r.column_name || '
                FROM   ' || r.table_name ||
                ' WHERE REGEXP_LIKE(' || r.column_name || ', :regex)
                GROUP BY ' || r.column_name || '
                HAVING COUNT(*) > 1
            )';
        EXECUTE IMMEDIATE v_sql INTO v_duplicates USING r.regex;
	--count percentages
        IF r.no_records > 0 THEN
            v_percentage := v_count_form / r.no_records;
        ELSE
            v_percentage := NULL;
        END IF;
       --min/max
        BEGIN
            v_sql :=
                'SELECT MIN(' || r.column_name || '), MAX(' || r.column_name || ')
                 FROM ' || r.table_name ||
                ' WHERE REGEXP_LIKE(' || r.column_name || ', :regex)';
            EXECUTE IMMEDIATE v_sql INTO v_min, v_max USING r.regex;
        EXCEPTION
            WHEN OTHERS THEN
                -- if not numeric
                v_min := NULL;
                v_max := NULL;
        END;
        --update table
        UPDATE lxn_data_profile_log
           SET no_records_form = v_count_form,
               duplicates      = v_duplicates,
               percentage      = v_percentage,
               min_value       = v_min,
               max_value       = v_max
         WHERE rowid = r.rid;
         exception
            when others then  
                null;
        end;
    END LOOP;
    COMMIT;
END;
/

begin
populate_profile_stats;
end;
/
rollback;