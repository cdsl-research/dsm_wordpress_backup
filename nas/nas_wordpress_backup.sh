#!/bin/bash

# パラメータ
Generations=""
FilePath=""
SlackPostPath=""
SlackPostName=""

PrivateKey=""
Host=""
User=""
DataPath=""

# 開始前通知
${SlackPostPath} "${SlackPostName}" "バックアップデータ取得処理を開始します。"

# VM-NAS転送
log_file=$HOME`date "+%Y%m%d_%H%M%S"`".log"
rsync -av --log-file=${log_file} -e "ssh -i ${PrivateKey}" ${User}@${Host}:${DataPath} ${FilePath}

# 新規転送ファイルの通知
while read line
do
    out=`echo ${line} | grep '>f+++++++++'`
    if [ $? = 0 ]; then
        receive_file_name=`echo ${line} | cut -d ' ' -f 5`
        ${SlackPostPath} "${SlackPostName}" "バックアップデータ ${receive_file_name} を転送しました。"
    fi
done < ${log_file}

# 削除するファイルの取得
rm_num=`expr $Generations + 1`
array=(`ls -1t $FilePath | tail -n+$rm_num`)

# 出力と通知
# ${SlackPostPath} "${SlackPostName}" "バックアップファイル総数は${file_num}です。"
# ${SlackPostPath} "${SlackPostName}" "世代数は${Generations}でセットアップされています。"

# 古いファイルの削除
for eachValue in ${array[@]}; do
    # 削除
    ${SlackPostPath} "${SlackPostName}" "過去のデータ ${eachValue} を削除します。"
    rm ${FilePath}${eachValue}
done

# ファイル数・空き容量の通知
file_num=`ls -1 ${FilePath} | wc -l`

capacity=`df -h $FilePath | awk '{print "Backup Storage: "$3" / "$2" "$5 }' | sed 1d`
${SlackPostPath} "${SlackPostName}" "${capacity}"
${SlackPostPath} "${SlackPostName}" "バックアップ数 : ${file_num}世代 / ${Generations}世代"

# 最終通知
${SlackPostPath} "${SlackPostName}" "バックアップデータ取得処理を終了します。"