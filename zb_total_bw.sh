#################################
## R.Hakimi
## Zabbix Total Bandwidth
## 21-01-2020 17:48
################################

S_DATE='12/03/2019 06:00:00' # Start DATE MM/DD/YYYY / Local Time Zone
E_DATE='12/03/2020 06:10:00' # End DATE MM/DD/YYYY / Local Time Zone

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ST_DATE=`date --date="$S_DATE" +"%s"`
ET_DATE=`date --date="$E_DATE" +"%s"`
# TMP Files
TMP_HISTORY_IN='.host_history_in'
TMP_HISTORY_OUT='.host_history_out'
TMP_HISTORY_SUM='.host_history_sum'
# Result File
BW_RESULT='Bandwidth_Result.csv'
# Description
HO='Hosts'
NC='NIC'
AVS='Avg Speed(Mb)'
TBH='Total Bandwidth Hours(MB)'
TBD='Total Bandwidth Day(GB)'
TBM='Total Bandwidth Month(TB)'
SD='Start Date'
ED='End Date'
# Zabbix Config
ZBX_API_URL='https://ZB_API_URL/api_jsonrpc.php'
ZBX_USER='ZB_API_USER'
ZBX_PASS='ZB_API_PASSWORD'
# Hosts
HOST_NIC='      XXX.XXX.XXX.XXX|NIC_NAME
                XXX.XXX.XXX.XXX|NIC_NAME
'


## Clean Files
        > $TMP_HISTORY_IN && \
        > $TMP_HISTORY_OUT && \
        > $TMP_HISTORY_SUM && \
        > $BW_RESULT && \
        echo -e "$HO,$NC,$AVS,$TBH,$TBD,$TBM,$SD,$ED" >> $BW_RESULT

        echo -ne '########                (20%)\r'
## TOKEN
        TOKEN=$(curl -s -i -X POST \
        -H 'Content-Type: application/json-rpc' \
        -d '{ "params": { "user": "'$ZBX_USER'", "password": "'$ZBX_PASS'" }, "jsonrpc": "2.0", "method": "user.login", "id": 0 }' \
        $ZBX_API_URL \
        | grep 'jsonrpc' \
        | jq '.result' \
        | sed 's/[^0-9\|a-Z]*//g')

        echo -ne '############            (40%)\r'
## HOST ID / ITEM ID
for HOSTS_D in $HOST_NIC
do
        HOST_IP=$(echo $HOSTS_D | cut -d"|" -f1)
        HOST_NIC=$(echo $HOSTS_D | cut -d"|" -f2)

        HOST_ID=$(curl -s -i -X POST \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","method":"host.get","params":{"output":"extend","filter":{"host":"'$HOST_IP'"}},"auth":"'$TOKEN'","id":1}' \
        $ZBX_API_URL \
        | grep 'jsonrpc' \
        | jq '.result[].hostid' \
        | sed 's/[^0-9\|a-Z]*//g')


        ITEM_ID_IN=$(curl -s -i -X POST \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","method":"item.get","params":{"output":"extend","filter":{"key_":"net.if.in['$HOST_NIC']","hostid":"'$HOST_ID'"}},"auth":"'$TOKEN'","id":1}' \
        $ZBX_API_URL \
        | grep 'jsonrpc' \
        | jq '.result[].itemid' \
        | sed 's/[^0-9\|a-Z]*//g')

        ITEM_ID_OUT=$(curl -s -i -X POST \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","method":"item.get","params":{"output":"extend","filter":{"key_":"net.if.out['$HOST_NIC']","hostid":"'$HOST_ID'"}},"auth":"'$TOKEN'","id":1}' \
        $ZBX_API_URL \
        | grep 'jsonrpc' \
        | jq '.result[].itemid' \
        | sed 's/[^0-9\|a-Z]*//g')

        echo -ne '################        (60%)\r'
# IN
        HISTORY_IN=$(curl -s -i -X POST \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","method":"history.get","params":{"itemids":['$ITEM_ID_IN'],"history":3,"output":"extend","time_from":"'$ST_DATE'","time_till":"'$ET_DATE'"},"auth":"'$TOKEN'","id":2}' \
        $ZBX_API_URL \
        | grep 'jsonrpc' \
        | jq '.result[].value' \
        | sed 's/[^0-9\|a-Z]*//g')

        HISTORY_C_IN=$(echo "$HISTORY_IN" | wc -l)
        echo "$HISTORY_IN" > $TMP_HISTORY_IN
        SUM_HISTORY_IN=$(paste -sd+ $TMP_HISTORY_IN | bc)
        AVG_HISTORY_IN=$(echo "$SUM_HISTORY_IN / $HISTORY_C_IN" | bc)

        echo -ne '####################    (80%)\r'
# OUT
        HISTORY_OUT=$(curl -s -i -X POST \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","method":"history.get","params":{"itemids":['$ITEM_ID_OUT'],"history":3,"output":"extend","time_from":"'$ST_DATE'","time_till":"'$ET_DATE'"},"auth":"'$TOKEN'","id":2}' \
        $ZBX_API_URL \
        | grep 'jsonrpc' \
        | jq '.result[].value' \
        | sed 's/[^0-9\|a-Z]*//g')

        HISTORY_C_OUT=$(echo "$HISTORY_OUT" | wc -l)
        echo "$HISTORY_OUT" > $TMP_HISTORY_OUT
        SUM_HISTORY_OUT=$(paste -sd+ $TMP_HISTORY_OUT | bc)
        AVG_HISTORY_OUT=$(echo "$SUM_HISTORY_OUT / $HISTORY_C_OUT" | bc)

        echo -ne '######################(100%)\r'
# SUM
        echo "$AVG_HISTORY_IN" > $TMP_HISTORY_SUM
        echo "$AVG_HISTORY_OUT" >> $TMP_HISTORY_SUM
        SUM_AVG_HISTORY_OUT_IN=$(paste -sd+ $TMP_HISTORY_SUM | bc)

        SPEED_MB=$(echo "$SUM_AVG_HISTORY_OUT_IN / 8000 / 1000" | bc -l) # Convert to Kilobyte
        TOTAL_HR=$(echo "$SPEED_MB * 60 * 60" | bc -l) # Convert to Hours
        TOTAL_DAY=$(echo "$SPEED_MB * 60 * 60 * 24 / 1000" | bc -l) # Convert to DAY
        TOTAL_MONTH=$(echo "$SPEED_MB * 60 * 60 * 24 / 1000 * 30  / 1000" | bc -l) # Convert to Month

        echo "Host: $HOST_IP  /  NIC: $HOST_NIC"
        echo "Start Date: $S_DATE  /  End Date: $E_DATE"
        P_AVS=$(printf "%.2f\n" "$SPEED_MB") && echo "$AVS: $P_AVS"
        P_TBH=$(printf "%.2f\n" "$TOTAL_HR") && echo "$TBH: $P_TBH"
        P_TBD=$(printf "%.2f\n" "$TOTAL_DAY") && echo "$TBD: $P_TBD"
        P_TBM=$(printf "%.2f\n" "$TOTAL_MONTH") && echo "$TBM: $P_TBM"
        echo "=================="

        echo "$HOST_IP,$HOST_NIC,$P_AVS,$P_TBH,$P_TBD,$P_TBM,$S_DATE,$E_DATE"  >> $BW_RESULT


done
