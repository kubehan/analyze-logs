#!/bin/bash
# @Author: Kubehan
# @Date:   2024-07-20 11:06:31
# @Last Modified by:    Kubehan
# @Last Modified time: 2024-07-21 11:06:31
# @E-mail: kubehan@163.com
# 显示脚本的用法
usage() {
    echo "Usage: $0 [OPTIONS] --jsonlog LOGFILE"
    echo "Options:"
    echo "example: bash $0    --jsonlog  json.log  --start_time "2024-07-23T15:50:00+08:00" --end_time "2024-07-23T15:51:59+08:00" --report"
    echo "         bash $0    --jsonlog  json.log   --uri /api/v1/query"
    echo "  --jsonlog LOGFILE              Specify the JSON log file"
    echo "  --start_time                   Filter by time_local"
    echo "  --end_time                     Filter by time_local"
    echo "  --http_status STATUS_RANGE     Filter by http_status, supports range (MIN-MAX)"
    echo "  --request_time TIME_RANGE      Filter by request_time, supports range (MIN-MAX)"
    echo "  --upstream_response_time TIME_RANGE Filter by upstream_response_time, supports range (MIN-MAX)"
    echo "  --host HOST                    Filter by host"
    echo "  --request_uri REQUEST_URI       Filter by request_uri"
    echo "  --request_method METHOD        Filter by request_method"
    echo "  --upstream_status STATUS       Filter by upstream_status"
    echo "  --server_addr ADDRESS          Filter by server_addr"
    echo "  --upstream_addr ADDRESS        Filter by upstream_addr"
    echo "  --request_id REQUEST_ID        Filter by request_id"
    echo "  --uri URI                      Filter by uri"
    echo "  --report                       Output report"
    echo "  --help                         Display this help message"
    exit 1
}

# 解析参数
while [[ "$1" != "" ]]; do
    case $1 in
        --help ) usage ;;
        --jsonlog ) shift; JSONLOG=$1 ;;
        --time_local ) shift; TIME_LOCAL_RANGE=$1 ;;
        --start_time ) shift; START_TIME=$1 ;;
        --end_time ) shift; END_TIME=$1 ;;
        --http_status ) shift; HTTP_STATUS=$1 ;;
        --request_time ) shift; REQUEST_TIME_RANGE=$1 ;;
        --upstream_response_time ) shift; UPSTREAM_RESPONSE_TIME_RANGE=$1 ;;
        --host ) shift; HOST=$1 ;;
        --request_uri ) shift; REQUEST_URI=$1 ;;
        --request_method ) shift; REQUEST_METHOD=$1 ;;
        --upstream_status ) shift; UPSTREAM_STATUS=$1 ;;
        --server_addr ) shift; SERVER_ADDR=$1 ;;
        --upstream_addr ) shift; UPSTREAM_ADDR=$1 ;;
        --request_id ) shift; REQUEST_ID=$1 ;;
        --uri ) shift; URI=$1 ;;
        --report ) REPORT=1 ;;
        * ) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

# 检查 JSON 文件是否存在
if [[ ! -f $JSONLOG ]]; then
    echo "Error: Log file $JSONLOG does not exist."
    exit 1
fi

jq_query=". | select("
# 判断所有参数是否为空
    if [[ -z $START_TIME  && $END_TIME  && -z $HTTP_STATUS && -z $REQUEST_TIME_RANGE && -z $UPSTREAM_RESPONSE_TIME_RANGE && -z $HOST && -z $REQUEST_URI && -z $REQUEST_METHOD && -z $UPSTREAM_STATUS && -z $SERVER_ADDR && -z $UPSTREAM_ADDR && -z $URI && -z $REQUEST_ID ]]; then
    jq_query=". | select(."
    fi
    if [[ ! -z $START_TIME && $END_TIME ]]; then
            jq_query+=".time_local >= \"$START_TIME\" and .time_local <= \"$END_TIME\" and "
    fi


    if [[ ! -z $HTTP_STATUS && $HTTP_STATUS == *-* ]]; then
        IFS='-' read -r MIN_STATUS MAX_STATUS <<< "$HTTP_STATUS"
        jq_query+="(.http_status | tonumber) >= $MIN_STATUS and (.http_status | tonumber) <= $MAX_STATUS and "
    elif [[ ! -z $HTTP_STATUS ]]; then
        jq_query+=".http_status == $HTTP_STATUS and "
    fi

    if [[ ! -z $REQUEST_TIME_RANGE && $REQUEST_TIME_RANGE == *-* ]]; then
        IFS='-' read -r MIN_TIME MAX_TIME <<< "$REQUEST_TIME_RANGE"
        jq_query+="(.request_time | tonumber) >= $MIN_TIME and (.request_time | tonumber) <= $MAX_TIME and "
    fi

    if [[ ! -z $UPSTREAM_RESPONSE_TIME_RANGE && $UPSTREAM_RESPONSE_TIME_RANGE == *-* ]]; then
        IFS='-' read -r MIN_TIME MAX_TIME <<< "$UPSTREAM_RESPONSE_TIME_RANGE"
        jq_query+="(.upstream_response_time | tonumber) >= $MIN_TIME and (.upstream_response_time | tonumber) <= $MAX_TIME and "
    fi

    if [[ ! -z $HOST ]]; then
        jq_query+=".host == \"$HOST\" and "
    fi
    if [[ ! -z $REQUEST_URI ]]; then
        jq_query+=".request_uri == \"$REQUEST_URI\" and "
    fi
    if [[ ! -z $REQUEST_METHOD ]]; then
        jq_query+=".method == \"$REQUEST_METHOD\" and "
    fi
    if [[ ! -z $UPSTREAM_STATUS ]]; then
        jq_query+=".upstream_status == \"$UPSTREAM_STATUS\" and "
    fi
    if [[ ! -z $SERVER_ADDR ]]; then
        jq_query+=".server_addr == \"$SERVER_ADDR\" and "
    fi
    if [[ ! -z $UPSTREAM_ADDR ]]; then
        jq_query+=".upstream_addr == \"$UPSTREAM_ADDR\" and "
    fi
    if [[ ! -z $URI ]]; then
        jq_query+=".uri == \"$URI\" and "
    fi
    if [[ ! -z $REQUEST_ID ]]; then
        jq_query+=".request_id == \"$REQUEST_ID\" and "
    fi

# 去掉末尾的 " and "
jq_query="${jq_query% and }"
jq_query+=")"

# 使用构建好的 jq 查询
FILTERED_LOGS=$(jq -c "$jq_query" "$JSONLOG")

# 输出报表或详细日志
if [[ ! -z $REPORT ]]; then
    # 总日志数
    TOTAL_COUNT=$(echo "$FILTERED_LOGS" | wc -l)

    # HTTP 状态码统计
    HTTP_STATUS_STATS=$(echo "$FILTERED_LOGS" | jq -r '.http_status' | sort | uniq -c | sort -nr)

    # 请求方法统计
    REQUEST_METHOD_STATS=$(echo "$FILTERED_LOGS" | jq -r '.method' | sort | uniq -c | sort -nr)

    # 响应时间统计
    # 计算最大值和最小值
    MAX_REQUEST_TIME=$(echo "$FILTERED_LOGS" | jq -r '.request_time | tonumber' | sort -n | tail -1)
    MIN_REQUEST_TIME=$(echo "$FILTERED_LOGS" | jq -r '.request_time | tonumber' | sort -n | head -1)
    MAX_UPSTREAM_RESPONSE_TIME=$(echo "$FILTERED_LOGS" | jq -r '.upstream_response_time | tonumber' | sort -n | tail -1)
    MIN_UPSTREAM_RESPONSE_TIME=$(echo "$FILTERED_LOGS" | jq -r '.upstream_response_time | tonumber' | sort -n | head -1)
    REQUEST_TIMES=$(echo "$FILTERED_LOGS" | jq -r '.request_time' | awk '{s+=$1; count+=1} END {print "Mean:", s/count, "Count:", count}')
    UPSTREAM_RESPONSE_TIMES=$(echo "$FILTERED_LOGS" | jq -r '.upstream_response_time' | awk '{s+=$1; count+=1} END {print "Mean:", s/count, "Count:", count}')

    # 按主机统计
    HOST_STATS=$(echo "$FILTERED_LOGS" | jq -r '.host' | sort | uniq -c | sort -nr)
    # 获取 request_time 的 Top 10
    TOP_10_REQUEST_TIME=$(echo "$FILTERED_LOGS"| jq -s '[.[] | {host: .host, uri: .uri, http_status: .http_status, upstream_addr: .upstream_addr, request_time: .request_time}] | sort_by(.request_time | tonumber) | reverse | .[0:10] | (["Host", "URI", "HTTP Status", "Upstream Address", "Request Time"] | @csv), (.[] | [.host, .uri, .http_status, .upstream_addr, .request_time] | @csv)' | sed 's/"//g' | column -t -s ',' |sed 's#\\##g')
    # 按 URI 统计
    URI_STATS=$(echo "$FILTERED_LOGS" | jq -r '.uri' | sort | uniq -c | sort -nr)

    # 输出报表
    echo "日志总数: $TOTAL_COUNT"
    echo "HTTP 状态码统计:"
    echo "$HTTP_STATUS_STATS"
    echo
    echo "请求方法统计:"
    echo "$REQUEST_METHOD_STATS"
    echo
    echo "请求时间统计:"
    echo "$REQUEST_TIMES"
    echo "Request Time - Max: $MAX_REQUEST_TIME, Min: $MIN_REQUEST_TIME"
    echo
    echo "上游响应时间统计:"
    echo "$UPSTREAM_RESPONSE_TIMES"
    echo "Upstream Response Time - Max: $MAX_UPSTREAM_RESPONSE_TIME, Min: $MIN_UPSTREAM_RESPONSE_TIME"
    echo
    echo "主机统计:"
    echo "$HOST_STATS"
    echo "Top 10 Request Times:"
    echo "$TOP_10_REQUEST_TIME"
    echo "URI 访问统计:"
    echo "$URI_STATS"
else
    # 输出详细日志
    echo "$FILTERED_LOGS"
fi
