#!/bin/sh

CONFIG_FILE=/opt/glider.conf
SUB_FOLDER=/tmp/sub
SUB_FILE=/tmp/sub/mod
EDITED_SUB=/tmp/sub/link

function decode_ss {
	if [ -e "${SUB_FILE}" ];then
		rm ${SUB_FILE}
	fi
	while IFS= read -r line; do

		encoded_string=$(echo -n "$line" | awk -F'ss://' '{print $2}' | awk -F'@' '{print $1}')
		decoded_string=$(echo -n "$encoded_string" | base64 -d)

		server_string=$(echo -n "$line" | awk -F'@' '{print $2}' | awk -F'?' '{print $1}')

		query_string=$(echo "$line" | awk -F'#' '{print $2}' | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g' | xargs -0 printf "%b")

		new_line="ss://$decoded_string@$server_string#$query_string"

		echo "$new_line" >> ${SUB_FILE}
	done < $1
}

function decode_obfs {
	if [ -e "${SUB_FILE}" ];then
		rm ${SUB_FILE}
	fi
	while IFS= read -r line; do
		encoded_string=$(echo -n "$line" | awk -F'ss://' '{print $2}' | awk -F'@' '{print $1}')

		decoded_string=$(echo -n "$encoded_string" | base64 -d)

		query_string=$(echo -n "$line" | awk -F'?' '{print $2}' | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g' | xargs -0 printf "%b")
		decoded_server=$(echo "$query_string" | awk -F'#' '{print $1}' | awk -F'obfs-host=' '{print $2}')
		decoded_protocol=$(echo "$query_string"| awk -F'#' '{print $1}' | awk -F'obfs=' '{print $2}' | awk -F';' '{print $1}')
		decode_name=$(echo "$query_string" | awk -F'#' '{print $2}')
		server_string=$(echo -n "$line" | awk -F'ss://' '{print $2}'  | awk -F'@' '{print $2}' | awk -F'?' '{print $1}')

		# port=80
		# if [ "${decoded_protocol}" == "https" ]; then
		# 	port=443
		# 	decoded_protocol=tls
		# fi

		new_line="simple-obfs://$server_string?type=$decoded_protocol&host=$decoded_server,ss://$decoded_string@$server_string#$decode_name"

		echo "$new_line" >> ${SUB_FILE}
	done < $1
}

function get_sub {
	if [ "$SUBLINK" = "" ];then
		exit 0
	fi
	curl -sL "$SUBLINK" | base64 -d - > ${EDITED_SUB}
	case "$TYPE" in
		"ss")
			decode_ss ${EDITED_SUB}
			;;
		"obfs")
			decode_obfs ${EDITED_SUB}
			;;
	esac
	LINK=$(cat ${SUB_FILE})
	echo "$LINK"
}

function output_config {
	if [ -e "${CONFIG_FILE}" ];then
		echo Existed Config:
		cat "${CONFIG_FILE}"
	else
		mkdir -p "${SUB_FOLDER}"
		echo "verbose=${VERBOSE}" > $CONFIG_FILE
		echo "strategy=${STRATEGY}" >> $CONFIG_FILE
		echo "listen=${LISTEN}" >> $CONFIG_FILE
		echo "check=${CHECK}" >> $CONFIG_FILE
		echo "checkinterval=60" >> $CONFIG_FILE

		if [ "$MANUAL" == 0 ]; then
			if [ ! -e "${SUB_FILE}" ] || [ "${RENEW}" -eq 1 ];then
				SUB=$(get_sub)
			else
				SUB=$(cat ${SUB_FILE})
			fi
			# if [ "$APPEND_LINK" == "" ]; then
			# 	echo "$COUNTRY" | awk -F '|' '{for (i=1; i<=NF; i++) print $i}' | while read pattern; do
			# 		echo "$SUB" |grep "${pattern}" | awk '{print "forward="$0}' >> $CONFIG_FILE
			# 	done

			# else
			# 	echo "$COUNTRY" | awk -F '|' '{for (i=1; i<=NF; i++) print $i}' | while read pattern; do
			# 		echo "$SUB" |grep "${pattern}" | awk -F'#' '{print "forward="$1 s a c $2}' c="#" s="," a="$APPEND_LINK" >> $CONFIG_FILE
			# 	done
			# fi
			echo "$COUNTRY" | awk -F '|' '{for (i=1; i<=NF; i++) print $i}' | while read pattern; do
				if [ "$APPEND_LINK" == "" ]; then
					echo "$SUB" |grep "${pattern}" | awk '{print "forward="$0}' >> $CONFIG_FILE
				else
					echo "$SUB" |grep "${pattern}" | awk -F'#' '{print "forward="$1 s a c $2}' c="#" s="," a="$APPEND_LINK" >> $CONFIG_FILE
				fi
			done

		elif [ "$MANUAL" == 1 ]; then
			echo "forward=$MANUAL_LINK" >> $CONFIG_FILE
			if [ ! "$MANUAL_LINK_BAK" == "" ];then
				echo "forward=$MANUAL_LINK_BAK" >> $CONFIG_FILE
			fi
		fi

		echo -e '\n'
		echo Current Config:
		cat "${CONFIG_FILE}"
	fi
}

function start_glider {
	glider -config=$CONFIG_FILE &
}

output_config
start_glider

function finish {
	kPID=$(ps -ef|grep -v grep|grep -v start|awk '{print $1}')
	echo "killing PID: $kPID"
	kill -9 $kPID
}
trap finish SIGTERM SIGINT SIGQUIT
while sleep 3600 && wait $!;do :;done # uncomment this at end