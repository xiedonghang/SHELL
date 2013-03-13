#!/bin/ksh

##############################
#      By xie
#       V1.3 
##############################

BASE_PATH="/home/wasadmin/replace"

if [ $PWD != "${BASE_PATH}" ]
then
echo $PWD
echo "Usage: 请在/home/wasadmin/replace目录运行该脚本"
exit 1
fi

if [ ! -s "$BASE_PATH/code.txt" ]
then
echo "Usage: code.txt 不存在或者为空！"
exit 2
fi

WAS_PATH="/usr/WebSphere/WAS7/AppServer/profiles/CS_CRM_02/installedApps/CS_CELL_DM_WAS"
WASADMIN="/usr/WebSphere/WAS7/AppServer/profiles/CS_CRM_02/bin/wsadmin.sh -lang jython -user wasadmin -password wasadmin"
line_num=1
JARS=`find ${WAS_PATH} -name "ngcrm*.jar"`
TXT="${BASE_PATH}/code.txt"
DATE_C=`date +%y%m%d%H%M%S`

cat $TXT|while read line
do
  code[$line_num]=$line
	echo ${code[$line_num]}
	let line_num=$line_num+1
done



RE_CLASS ()
{
  echo "%%%%%替换CLASS%%%%%"
  echo "mkdir -p" "${CLASS%/*}"
  mkdir -p "${CLASS%/*}"
  echo "cp" "${CLASS##*/}" "${CLASS%/*}"
  cp "${CLASS##*/}" "${CLASS%/*}"
  echo "jar" "uvf" "${JAR_PATH}"  "${CLASS}"
  jar uvf "${JAR_PATH}"  "${CLASS}"
  echo "rm -r" "${CLASS%%/*}"
  rm -r "${CLASS%%/*}"
  mv "${CLASS##*/}" bak/${DATE_C}
  ls -lrt ${JAR_PATH}
}

RE_JSP_JS_OTHER ()
{
  echo "%%%%%替换JSP,JS,OTHER%%%%%"
  echo "cp" "$FILE" "${F%/*}"
  cp "$FILE" "${F%/*}"
  mv "$FILE" bak/${DATE_C}
  ls -lrt ${F}
}


FIND ()
{
num=1
for n in ${code[@]}
do
 echo "\n"
 echo ------------------------------查找第"$num"个文件------------------------------------
  SUFFIX=${n##*.}
  echo "$x""#" "$n"
  if [ "$SUFFIX"x = "java"x ] || [ "$SUFFIX"x = "xml"x ]
   #-------class,XML查找-------    
   then
   if [ "$SUFFIX" == "java" ]
    then 
	  FILE=$(echo ${n##*/}|sed s/java/class/)
	  F_PATH=$(echo ${n#*/}|sed s/java/class/)
   else
	  FILE=${n##*/}
	  F_PATH=${n#*/}
   fi
   FOUND=""
   for EACHJAR in ${JARS}
      do
       FOUND=$(jar tf ${EACHJAR}|grep ${FILE}|grep ${F_PATH})
        if [ "x${FOUND}" != "x" ]
         then
         CLASS=${FOUND}
         JAR_PATH=${EACHJAR}
         echo "JAR包的路径：${JAR_PATH}"
         echo "文件在JAR包中的路径：${CLASS}"
        fi
      done
    if [ "x${FOUND}" = "x" ]
     then
      F=`find ${WAS_PATH} -name $FILE |grep ${n#*/}`
   	  echo "文件的路径：\n $F"
   	fi
   else
   #-------其他文件查找------- 
   	FILE=${n##*/}
   	F=`find ${WAS_PATH} -name $FILE |grep ${n#*/}`
   	echo "文件的路径：\n $F"
 fi
 let num=$num+1
done
}

REPLACE ()
{
JARS=`find ${WAS_PATH} -name "ngcrm*.jar"|grep $1`
num=1
for n in ${code[@]}
do
 echo "\n"
 echo ------------------------------替换第"$num"个文件------------------------------------
  SUFFIX=${n##*.}
  echo "$num""#" "${n}"
  if [ "$SUFFIX"x = "java"x ] || [ "$SUFFIX"x = "xml"x ]
  #-------class,XML替换-------    
   then
   if [ "$SUFFIX" == "java" ]
    then 
	  FILE=$(echo ${n##*/}|sed s/java/class/)
	  F_PATH=$(echo ${n#*/}|sed s/java/class/)
   else
	  FILE=${n##*/}
	  F_PATH=${n#*/}
   fi
   for EACHJAR in ${JARS}
    do
       FOUND=$(jar tf ${EACHJAR}|grep ${FILE}|grep ${F_PATH})
       if [ "x${FOUND}" != "x" ]
        then
        CLASS=${FOUND}
        JAR_PATH=${EACHJAR}
        echo ${JAR_PATH}
        echo ${CLASS}
       fi
     done
    RE_CLASS
    if [ "x${FOUND}" = "x" ]
     then
      F=`find ${WAS_PATH} -name $FILE |grep ${n#*/}`
   		echo "文件的路径：\n $F"
   		RE_JSP_JS_OTHER
   	fi     
  else
   #-------JSP,JS和其他文件替换-------    
   FILE=${n##*/}
   F=`find ${WAS_PATH} -name $FILE |grep ${n#*/}|grep $1`
   echo $F
   RE_JSP_JS_OTHER
 fi
 let num=$num+1
done
}

SERVER ()
{
$WASADMIN -c "AdminControl.invoke('WebSphere:name=ApplicationManager,process=CS_CRM_02,platform=proxy,node=CS_NODE_CRM_02,version=7.0.0.17,type=ApplicationManager,mbeanIdentifier=ApplicationManager,cell=CS_CELL_DM_WAS,spec=1.0', '$1', '[$2]', '[java.lang.String]')"
}

FIND
echo "\n"
echo "-----输入要替换包的编号（如：ngcrm.war-20130308-1056-502.war，为了准确匹配，请输入“20130308-1056-502”）------------------"
read INPUT_NUM
WAS_PATH="/usr/WebSphere/WAS7/AppServer/profiles/CS_CRM_02/installedApps/CS_CELL_DM_WAS/ngcrm_war*${INPUT_NUM}*ear/ngcrm.war*war"
APP_NAME=$(echo ${WAS_PATH}|cut -d \/ -f10|cut -d . -f1)
echo "\n"
echo "你输入的编号：${INPUT_NUM}"
echo "要替换的包的路径：${WAS_PATH}"
echo ”${APP_NAME}“
if [ ! -d ${WAS_PATH} ]
 then
 echo "-----没有对应的应用包，请再核对--------"
 exit 4
fi

#判断要替换的文件是否存在，不存在则退出
for n in ${code[@]}
do
 if [ "${n##*.}"x = "java"x ]
 then
  CODE_NAME=$(echo ${n##*/}|sed s/java/class/)
 else
  CODE_NAME=${n##*/}
 fi
 if [ ! -s ${CODE_NAME} ]
 then
  echo "${CODE_NAME} 不存在"
  exit 5
 fi
done

mkdir -p bak/${DATE_C}
cp ${TXT} bak/${DATE_C}


echo "\n"
echo ------------------------------停止应用------------------------------------
SERVER stopApplication ${APP_NAME}
REPLACE ${APP_NAME}
echo "\n"
echo ------------------------------启动应用------------------------------------
SERVER startApplication ${APP_NAME}
