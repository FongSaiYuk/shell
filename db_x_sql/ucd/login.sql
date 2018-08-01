define _editor=vi                                           

set serveroutput on size 1000000                                      

set trimspool on
set long 5000
set linesize 100
set pagesize 9999
column plan_plus_exp format a80
column global_name new_value gname
set termout off
define gname=idle
column global_name new_value gname
select lower(user) || '@' || substr( global_name, 1, decode( dot, 0,
length(global_name), dot-1) ) global_name
  from (select global_name, instr(global_name,'.') dot from global_name );
set sqlprompt '&gname> '
set termout on
select to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') cur_date_time from dual;
select count(*) as x_objects_before from user_objects where status='INVALID';
@$do_sql
host sh $x_base/sql_err_do.sh
@$do_sql.do
select count(*) as x_objects_after from user_objects where status='INVALID';
select to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') cur_date_time from dual;
exit;
