#!/bin/bash

source config.sh
#
RemoteBackupDataTmp="/var/tmp/backup_tmp1" # バックアップデータ作成先
RemoteBackupDataTmp2="/var/tmp/backup_tmp2" # バックアップデータ作成先

# 開始前通知
${DsmSlackPostPath} "${SlackPostName}" "バックアップ処理を開始します"

# リモート先でバックアップデータの作成
ssh -i ${DsmPrivateKey} ${RemoteUser}@${RemoteHost} "rm -rf ${RemoteBackupDataTmp} ${RemoteBackupDataTmp2}"
ssh -i ${DsmPrivateKey} ${RemoteUser}@${RemoteHost} "mkdir ${RemoteBackupDataTmp} ${RemoteBackupDataTmp2}"
ssh -i ${DsmPrivateKey} ${RemoteUser}@${RemoteHost} "mysqldump -u ${RemoteMysqlUser} -p${RemoteMysqlPass} ${RemoteMysqlDbName} > ${RemoteBackupDataTmp2}/wp_database.sql"
ssh -i ${DsmPrivateKey} ${RemoteUser}@${RemoteHost} "cp -r ${RemoteWebRootDirectory} ${RemoteBackupDataTmp2}/"
data_var=`date "+%Y%m%d_%H%M%S"`
ssh -i ${DsmPrivateKey} ${RemoteUser}@${RemoteHost} "tar -C ${RemoteBackupDataTmp2} -czf ${RemoteBackupDataTmp}/${data_var}.tgz ${RemoteBackupDataTmp2}"

# VM-NAS転送
log_file=$HOME`date "+%Y%m%d_%H%M%S"`".log"
rsync -av --log-file=${log_file} -e "ssh -i ${DsmPrivateKey}" ${RemoteUser}@${RemoteHost}:${RemoteBackupDataTmp}/ ${DsmFilePath}

# 新規転送ファイルの通知
while read line
do
    out=`echo ${line} | grep '>f+++++++++'`
    if [ $? = 0 ]; then
        receive_file_name=`echo ${line} | cut -d ' ' -f 5`
        ${DsmSlackPostPath} "${SlackPostName}" "${receive_file_name} を作成・転送しました。"
    fi
done < ${log_file}

# 削除するファイルの取得
rm_num=`expr $DsmFileGenerations + 1`
array=(`ls -1t $DsmFilePath | tail -n+$rm_num`)

# 古いファイルの削除
for eachValue in ${array[@]}; do
    # 削除
    ${DsmSlackPostPath} "${SlackPostName}" "過去のデータ ${eachValue} を削除します。"
    rm ${DsmFilePath}${eachValue}
done


# ファイル数・空き容量の通知
file_num=`ls -1 ${DsmFilePath} | wc -l`

capacity=`df -h $DsmFilePath | awk '{print $3" / "$2" "$5 }' | sed 1d`
${DsmSlackPostPath} "${SlackPostName}" "ストレージ容量 : ${capacity}"
${DsmSlackPostPath} "${SlackPostName}" "バックアップ数 : ${file_num} / ${DsmFileGenerations}"

# 最終通知
${DsmSlackPostPath} "${SlackPostName}" "バックアップ処理を終了します"

