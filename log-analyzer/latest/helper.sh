#!/usr/bin/env bash

if [[ $1 == "oss" ]]; then
  ossutil --config-file /etc/ossutil/.config ${@:2}

  exit 0
fi

if [[ $1 == "list" ]]; then
  LIST=$(helper.sh oss ls ${OSS_LOGS_URL})
  echo "${LIST//"${OSS_LOGS_URL}/"/""}"

  exit 0
fi

if [[ $1 == "download-combine" ]]; then
  if [ -z ${2} ]; then
    echo "Second argument (pattern to be used with grep) is not provided."
    echo "  |_ e.g. helper.sh download-combine haproxy/2017-12-15"

    exit 1
  fi

  TMP=/tmp/$(echo -n ${2} | md5sum | cut -d ' ' -f 1)
  mkdir -p ${TMP}
  OUTPUT_PATH=${TMP}/combined.log

  if [[ ! -e ${OUTPUT_PATH} ]] || [[ ${3} == "force" ]]; then
    echo "Fetching list of all logs then pattern matching..."
    LOGS=$(helper.sh oss ls -s ${OSS_LOGS_URL} | grep ${2})
    if [ -z "${LOGS}" ]; then
      echo "Could not find any logs for pattern ${2}"
      exit 4
    fi

    while read -r LogObject; do
      echo "Downloading ${LogObject//"${OSS_LOGS_URL}/"/""}..."
      OUTPUT=$(helper.sh oss cp --checkpoint-dir /etc/ossutil/.checkpoint -f ${LogObject} ${TMP}/ 2>&1 |tee /dev/tty)
      # ossutil returns 0 exit code despite having errors!
      if [[ ${OUTPUT} == *"WithError"* ]]; then
        echo ${OUTPUT}
        exit 5
      fi
    done <<< "${LOGS}"

    if [ $(echo "${LOGS}" | wc -l) == "1" ]; then
      OUTPUT_PATH=$(ls -1 ${TMP}/*/*/*.log | tail -n1)
    else
      ALL_DOWNLOADED_LOGS=$(ls -1 ${TMP}/*/*/*.log)
      echo "Combining all "$(echo "${ALL_DOWNLOADED_LOGS}" | wc -l)" log files..."
      cat ${ALL_DOWNLOADED_LOGS} > ${OUTPUT_PATH}
    fi
  else
    echo "Log file is already cached."
  fi

  echo "Output logfile ("$(du -h ${OUTPUT_PATH} | awk '{print $1}')") is located at:"
  echo ""
  echo ${OUTPUT_PATH}

  exit 0
fi

if [[ $1 == "analyze" ]]; then
  if [ -z ${2} ]; then
    echo "Second argument (pattern to be used with grep) is not provided."
    echo "  |_ e.g. helper.sh analyze haproxy/2017-12-15"

    exit 1
  fi

  echo "Downloading and combining logs with pattern ${2}..."
  DOWNLOAD_OUTPUT=$(helper.sh download-combine ${2} |tee /dev/tty; exit ${PIPESTATUS[0]})
  exit_code=$?
  if [[ $exit_code != 0 ]]; then
    exit 1
  fi
  COMBINED_LOGS_PATH=$(echo "${DOWNLOAD_OUTPUT}" | tail -n1)
  echo "Total Combined Size: " $(du -h ${COMBINED_LOGS_PATH} | awk '{print $1}')

  set -e

  echo "Running HAProxy log analysis..."
  haproxy_log_analysis -l ${COMBINED_LOGS_PATH} ${@:3}

  exit 0
fi

if [[ $1 == "summary" ]]; then
  if [ -z ${2} ]; then
    echo "Second argument (grep-compatible <pattern>) is not provided."
    echo "  |_ e.g. helper.sh summary haproxy/2017-12-15"

    exit 1
  fi

  echo "---------------------------------------------------"
  echo "[SUMMARY] Getting no. of requests..."
  echo "---------------------------------------------------"
  NUMBER_OF_REQUESTS=$(helper.sh analyze ${2} ${@:3} -c counter |tee /dev/tty | tail -n1)

  echo "---------------------------------------------------"
  echo "[SUMMARY] Getting no. of 503 requests..."
  echo "---------------------------------------------------"
  NUMBER_OF_503s=$(helper.sh analyze ${2} ${@:3} -c counter -f "status_code[503]" |tee /dev/tty | tail -n1)
  PERCENT_OF_503s=$(awk 'BEGIN { pc=100*'${NUMBER_OF_503s}'/'${NUMBER_OF_REQUESTS}'; printf "%.4f\n", pc; }')

  echo "---------------------------------------------------"
  echo "[SUMMARY] Getting no. of 504 requests..."
  echo "---------------------------------------------------"
  NUMBER_OF_504s=$(helper.sh analyze ${2} ${@:3} -c counter -f "status_code[504]" |tee /dev/tty | tail -n1)
  PERCENT_OF_504s=$(awk 'BEGIN { pc=100*'${NUMBER_OF_504s}'/'${NUMBER_OF_REQUESTS}'; printf "%.4f\n", pc; }')

  echo "---------------------------------------------------"
  echo "[SUMMARY] Calculating avg. response time..."
  echo "---------------------------------------------------"
  AVERAGE_RESPONSE_TIME=$(helper.sh analyze ${2} ${@:3} -c average_response_time |tee /dev/tty | tail -n1)
  AVERAGE_RESPONSE_TIME=$(awk 'BEGIN{printf "%.1f", '${AVERAGE_RESPONSE_TIME}'}')

  echo "---------------------------------------------------"
  echo "[SUMMARY] Counting reqs. longer than 3 seconds..."
  echo "---------------------------------------------------"
  LONGER_THAN_3_SECONDS=$(helper.sh analyze ${2} ${@:3} -c counter -f "slow_requests[3000]" |tee /dev/tty | tail -n1)

  echo "---------------------------------------------------"
  echo "[SUMMARY] Counting reqs. longer than 5 seconds..."
  echo "---------------------------------------------------"
  LONGER_THAN_5_SECONDS=$(helper.sh analyze ${2} ${@:3} -c counter -f "slow_requests[5000]" |tee /dev/tty | tail -n1)

  echo "---------------------------------------------------"
  echo "[SUMMARY] Counting reqs. longer than 10 seconds..."
  echo "---------------------------------------------------"
  LONGER_THAN_10_SECONDS=$(helper.sh analyze ${2} ${@:3} -c counter -f "slow_requests[10000]" |tee /dev/tty | tail -n1)

cat << EOF

  Summary for pattern: ${2}
  ---------------------------------------

  - Number of requests: ${NUMBER_OF_REQUESTS}
  - Number of 503 errors: ${NUMBER_OF_503s} [${PERCENT_OF_503s}%]
  - Number of 504 errors: ${NUMBER_OF_504s} [${PERCENT_OF_504s}%]

  - Average response time: ${AVERAGE_RESPONSE_TIME} milliseconds

  - Number of requests taking longer than 3s: ${LONGER_THAN_3_SECONDS}
  - Number of requests taking longer than 5s: ${LONGER_THAN_5_SECONDS}
  - Number of requests taking longer than 10s: ${LONGER_THAN_10_SECONDS}

EOF

  exit 0
fi

echo "Unknown argument."
echo ""
echo "Usage:"
echo "    - helper.sh summary <pattern> [options...]"
echo "     |_ A summary report for a specific pattern. Options will be appended to haproxy_log_analysis"
echo ""
echo "        e.g. Report of a specific date:"
echo "              helper.sh summary haproxy/2017-12-15"
echo ""
echo "    - helper.sh analyze <pattern> [options...]"
echo "     |_ Download logs for <pattern> and run haproxy_log_analysis with [options...] on it"
echo ""
echo "        e.g. Number of requests:"
echo "              helper.sh analyze haproxy/2017-12-15 -c counter"
echo ""
echo "        e.g. Number of 504s:"
echo "              helper.sh analyze haproxy/2017-12-15 -c counter -f status_code[504]"
echo ""
echo "        e.g. Avg. response time:"
echo "              helper.sh analyze haproxy/2017-12-15 -c average_response_time"
echo ""
echo "    - helper.sh list"
echo "     |_ Lists all available log files"
echo ""
echo "    - helper.sh download-combine <pattern>"
echo "     |_ Downloads and combines all logs files with their name matching the <pattern>"
echo "        and returns path of combined log file."
echo ""
echo "    - helper.sh oss [OPTIONS...]"
echo "     |_ Runs ossutil with OPTIONS... Note --config-file is automatically set."
echo ""
