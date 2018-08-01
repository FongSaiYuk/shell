sql_stat=`egrep -ci "$sql_err_str" $do_sql.log`
if [ $sql_stat -gt 0 ];then
  echo "-----------$do_sql failed,u need to do with errors,pls choose-----------"
  echo "0 commit"
  echo "1 rollback"
  printf "Your Choose: "
  read err_do
  case $err_do in 
  0)
    echo "commit;" >$do_sql.do
    ;;
  1)
    echo "rollback;" >$do_sql.do
    ;;
  esac
else
  echo "commit;" >$do_sql.do
fi
