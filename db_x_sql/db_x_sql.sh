#!/bin/sh

export x_base=/opt/db_x_sql
fail_sql=0
ok_sql=0
login_stat=0
is_break=0

if [ $# -eq 1 ]&&[ -f $x_base/$1/ora.env ];then
  . $x_base/$1/ora.env
  export SQLPATH=$x_base/$1
else
  echo "input wrong or not exist  $conf_home/$1/ora.env file."
  exit 1
fi

export sql_base_dir exclude_sql sql_err_str user_nf box_off order_by

f_x_sql()
{
if [ -f $do_sql ];then
  sqlplus  $db_user/$db_pass@$TNS_NAME | tee $do_sql.log
  err_count=`egrep -ci "$sql_err_str" $do_sql.log`
  if [ $err_count  -ne 0 ];then
     mv $do_sql $do_sql.failed
     let fail_sql=fail_sql+1
     echo "--------------$do_sql failed -----------------"
     echo "--------------input \"Y\" or \"y\" to continue, any others to break.----------"
     printf "input:"
     read _input
     if [ ${_input}a == ya ] || [ ${_input}a == Ya ];then
        echo "continue............"
     else
        echo "abort!!!!!!!"
        export is_break=1
        break
     fi
  else
     printf "\n"
     mv $do_sql $do_sql.ok
     let ok_sql=ok_sql+1
     echo "--------------$do_sql ok -----------------"
  fi
fi
}

f_summary_sql()
{
printf "\n"
echo "+++++++++++++++++++++++++summary+++++++++++++++++++++++++"
echo "$ok_sql successes"
echo "$fail_sql errors"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
printf "\n"
echo "*--*--*--*--*--*--SQLs executed with errors--*--*--*--*--*--*"
find ./ -name "*.failed"
printf "\n"
echo "*--*--*--*--*--*--*--SQLs not being done (please ignore driver sql) --*--*--*--*--*--*--*"
find ./ -name "*.[s|S][q|Q][l|L]"|egrep -v "${exclude_sql}"
printf "\n"
}


if [ -d $sql_base_dir ];then
  cd $sql_base_dir
  case $is_driver in
  0)
    for i in `echo $driver_sql`
    do
      >$i.driver
      if [ -f $i ];then
        export db_user=`ls $i|awk -F "/" '{print $NF}'|sed "s/.[sS][qQ][lL]//g"|awk -v nf_user="$user_nf"  -F "$box_off" '{print $nf_user}'|tr '[A-Z]' '[a-z]'`
        export db_pass=`eval echo "\$"${db_user}|openssl des3 -d -k pab -base64`
        for j in `cat $i|grep .sql|grep @|sed 's/@//g'|sed 's/;$//g'|sed 's/[ \t]*$//g'|sed 's/^[ \t]*//g'|tr -d '\015'`
        do
          if [ -f $j ];then
            cat $j|grep .sql|grep @|sed 's/@//g'|sed 's/;$//g'|sed 's/[ \t]*$//g'|sed 's/^[ \t]*//g'|tr -d '\015' >>$i.driver
          else
            echo "---------not exist $j-----------"
          fi
        done
        for do_sql in `cat $i.driver`
        do
          export do_sql
          f_x_sql
        done
        if [ $is_break -eq 1 ];then
          break
        fi
      else
        echo "---------not exist $i-----------"
      fi
    done
    f_summary_sql
    ;;
  1)
    for do_sql in `find ./ -name "*.[s|S][q|Q][l|L]" -type f|egrep -v "${exclude_sql}"|awk -F / '{print $0=$NF" "$0}'|sort -t $box_off -k${order_by}n|awk '{print $2}'`
    do
      export do_sql
      export db_user=`ls $do_sql|awk -F "/" '{print $NF}'|sed "s/.[sS][qQ][lL]//g"|awk  -v  nf_user="$user_nf" -F "$box_off" '{print $nf_user}'|tr '[A-Z]' '[a-z]'`
      export db_pass=`eval echo "\$"${db_user}|openssl des3 -d -k pab -base64`
      f_x_sql
    done
    f_summary_sql
    ;;
  esac
else
  echo "not exit $sql_base_dir,pls check!"
  exit 1
fi
