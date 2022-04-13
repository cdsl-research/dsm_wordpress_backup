#!/bin/bash

# パラメータ
SlackPostPath=""
SlackPostName=""
DataPath=""

# 開始前通知
${SlackPostPath} "${SlackPostName}" "バックアップデータ作成処理を開始します。"

# 作業フォルダの初期化
rm -r /var/tmp/backup_data
mkdir /var/tmp/backup_data
mkdir /var/tmp/temporary

# データベースBackup
mysqldump wordpress > /var/tmp/temporary/wp_database.sql
cp -r /var/www/html/ /var/tmp/temporary/

# 圧縮
data_var=`date "+%Y%m%d_%H%M%S"`
tar -C /var/tmp/temporary -czf ${DataPath}${data_var}.tgz /var/tmp/temporary
${SlackPostPath} "${SlackPostName}" "バックアップデータ `echo $data_var`.tgz を作成しました。"

# 作業フォルダの削除
rm -r /var/tmp/temporary

# 終了時通知
${SlackPostPath} "${SlackPostName}" "バックアップデータ作成処理を終了します。"