#!/bin/bash

THREE_MONTH_BACK_DATE=`date -d "now -3months" +%Y-%m-%d`
CURRENT_DATE=`date -d "now" +%Y-%m-%d`

EPOCH_3MONTHS_BACK=`date -d "$THREE_MONTH_BACK_DATE" +%s`
EPOCH_NOW=`date -d "$CURRENT_DATE" +%s`

ZABBIX_DATABASE="zabbix"
ZABBIX_USER="zabbix"
ZABBIX_PASSWD="zabbix"

ZABBIX_TABLE_NAME="history_uint"

BACKUP_DIR_PATH=/tmp/zabbix/zabbix_table_backup_${ZABBIX_TABLE_NAME}
BACKUP_FILE_PATH=${BACKUP_DIR_PATH}/${ZABBIX_TABLE_NAME}_${CURRENT_DATE}_${EPOCH_NOW}.sql

echo "------------------------------------------"
echo "Date to Keep Backup : $THREE_MONTH_BACK_DATE"
echo "Epoch to keep Backup : $EPOCH_3MONTHS_BACK"
echo "Today's Date : $CURRENT_DATE"
echo "Epoch For Today's Date : $EPOCH_NOW"
echo "------------------------------------------"

echo "##########################################"

echo "------------------------------------------"
echo "	Stopping Zabbix Server			"
echo "------------------------------------------"
sudo service zabbix-server stop; 
sleep 1

echo "------------------------------------------"
echo "	Display Tables				"
echo "------------------------------------------"
echo "show tables;" | mysql -u$ZABBIX_USER -p$ZABBIX_PASSWD $ZABBIX_DATABASE;
sleep 1

echo "------------------------------------------"
echo "	Backing up ${ZABBIX_TABLE_NAME} Table.	"
echo "	Location : ${BACKUP_FILE_PATH}		"
echo "------------------------------------------"
mkdir -p ${BACKUP_DIR_PATH}
mysqldump -u$ZABBIX_USER -p$ZABBIX_PASSWD $ZABBIX_DATABASE ${ZABBIX_TABLE_NAME} > ${BACKUP_FILE_PATH}
sleep 1

echo "------------------------------------------------------------------"
echo "1. Create Temp (${ZABBIX_TABLE_NAME}_${EPOCH_NOW}) Table"
echo "------------------------------------------------------------------"
echo "CREATE TABLE ${ZABBIX_TABLE_NAME}_${EPOCH_NOW} LIKE ${ZABBIX_TABLE_NAME}; " | mysql -u$ZABBIX_USER -p$ZABBIX_PASSWD $ZABBIX_DATABASE;
sleep 1

echo "------------------------------------------------------------------"
echo "2. Inserting from ${ZABBIX_TABLE_NAME} Table to Temp (${ZABBIX_TABLE_NAME}_${EPOCH_NOW}) Table"
echo "------------------------------------------------------------------"
echo "INSERT INTO ${ZABBIX_TABLE_NAME}_${EPOCH_NOW} SELECT * FROM ${ZABBIX_TABLE_NAME} WHERE clock > '${EPOCH_3MONTHS_BACK}'; " | mysql -u$ZABBIX_USER -p$ZABBIX_PASSWD $ZABBIX_DATABASE;
sleep 1

echo "------------------------------------------------------------------"
echo "3. Rename Table ${ZABBIX_TABLE_NAME} to ${ZABBIX_TABLE_NAME}_${EPOCH_NOW}_old"
echo "------------------------------------------------------------------"
echo "ALTER TABLE ${ZABBIX_TABLE_NAME} RENAME ${ZABBIX_TABLE_NAME}_${EPOCH_NOW}_old;" | mysql -u$ZABBIX_USER -p$ZABBIX_PASSWD $ZABBIX_DATABASE;
sleep 1

echo "------------------------------------------"
echo "4. Rename Temp Table (${ZABBIX_TABLE_NAME}_${EPOCH_NOW}) to Original Table (${ZABBIX_TABLE_NAME})"
echo "------------------------------------------"
echo "ALTER TABLE ${ZABBIX_TABLE_NAME}_${EPOCH_NOW} RENAME ${ZABBIX_TABLE_NAME}; " | mysql -u$ZABBIX_USER -p$ZABBIX_PASSWD $ZABBIX_DATABASE;
sleep 1

echo "------------------------------------------"
echo "5. Dropping Old Table (${ZABBIX_TABLE_NAME}_${EPOCH_NOW}_old), As we have already Backed it up. "
echo "------------------------------------------"
echo "DROP TABLE ${ZABBIX_TABLE_NAME}_${EPOCH_NOW}_old; " | mysql -u$ZABBIX_USER -p$ZABBIX_PASSWD $ZABBIX_DATABASE;
sleep 1

echo "------------------------------------------"
echo "	Starting Zabbix Server		"
echo "------------------------------------------"
sudo service zabbix-server start;

echo "##########################################"