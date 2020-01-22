# Zabbix Total Bandwidth

This script help you to get server bandwidth Average from zabbix database with API.  script result will be Total Month Bandwidth.

just you must enter Start Date, End Date, IP Address and NIC name. 



## Prerequisites

- Zabbix Server with API enabled >= 3.x 
- jq Linux Package (`sudo apt-get install jq`)
- bc Linux Package (`sudo apt-get install bc`)
- curl Linux Package (`sudo apt-get install curl`)



## Tested:
- Zabbix Server 4.4.2
- Ubuntu 18.04.3 LTS



## Usage

**Note:** Start and end dates must be 30 days. The calculations of this script are based on 30 days

**S_DATE**: Enter Start Date

**E_DATE:** Enter End Date

**ZBX_API_URL**: Zabbix API URL

**ZBX_USER:** Zabbix API Username

**ZBX_PASS**: Zabbix API Password

**HOST & NIC**: Enter Server IP and NIC name (Example `192.168.1.30|eth0` )



## Installation

First, clone the repository using git (recommended):

```
git clone https://github.com/Ramhm/zabbix-total-bw.git
```

or download the script manually using this command:

```
curl "https://github.com/Ramhm/zabbix-total-bw/master/zb_total_bw.sh" -o zb_total_bw.sh
```

Then give the execution permission to the script and run it:

```
 $chmod +x zb_total_bw.sh
 $./zb_total_bw.sh
```





> in this script we run any curl command to get user authentication information, “user.login” method is  used in the JSON RPC query. The following shell script is used to get  user authentication information. To export avg of the TBW , the “history.get” method is used in the JSPN RPC queries.
