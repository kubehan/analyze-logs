# Nginx 日志分析脚本，太好用了吧！！！！！

> 最近在分析 Nginx 日志时候被搞麻了，一大坨日志，不太好进行分析啊，自己手撸一个来用吧！！！欢迎一起改造。

> 平时你都是怎么分析 Nginx 日志的呢？

前置条件：Nginx 日志格式如下：

```shell
{"time_local":"$time_iso8601", "msec": $msec, "remote_addr":
            "$remote_addr", "remote_user": "$remote_user", "body_bytes_sent": $body_bytes_sent,
            "content_length": "$content_length", "upstream_response_length": "$upstream_response_length",
            "upstream_addr": "$upstream_addr", "upstream_connect_time": "$upstream_connect_time",
            "bytes_sent": $bytes_sent, "request_length": $request_length, "connection_requests":
            $connection_requests, "http_status": $status, "schema": "$scheme", "uri":
            "$uri", "http_cookie": "$http_cookie", "request_uri": "$request_uri",
            "query_string": "$query_string", "method": "$request_method", "request_time":
            $request_time, "upstream_response_time": "$upstream_response_time", "upstream_status":
            "$upstream_status", "http_host": "$http_host", "http_referrer": "$http_referer",
            "http_x_forwarded_for": "$http_x_forwarded_for", "sla_appname": "$cookie_sla_appname",
            "http_user_agent": "$http_user_agent", "host": "$host", "request": "$request",
            "server_addr": "$server_addr", "request_id": "$http_x_request_id"}
```

顺序不要紧，只需要保证对应的字段存在就行啦。

## 脚本功能描述：

1. 分析 json 日志请求分布情况，如 API 访问情况
2. 分析 Nginx 慢日志请求情况，如 request_time 请求情况
3. 根据各种查询条件分析 Nginx 日志
4. 生成分析报表，如最大最小请求时间

## 使用帮助：

```shell
bash  analyze_logsv2.sh  --help
Options:
  --jsonlog LOGFILE              Specify the JSON log file
  --time_local TIME_RANGE        Filter by time_local
  --http_status STATUS_RANGE     Filter by http_status, supports range (MIN-MAX)
  --request_time TIME_RANGE      Filter by request_time, supports range (MIN-MAX)
  --upstream_response_time TIME_RANGE Filter by upstream_response_time, supports range (MIN-MAX)
  --host HOST                    Filter by host
  --request_uri REQUEST_URI      Filter by request_uri
  --request_method METHOD        Filter by request_method
  --upstream_status STATUS       Filter by upstream_status
  --server_addr ADDRESS          Filter by server_addr
  --upstream_addr ADDRESS        Filter by upstream_addr
  --uri URI                      Filter by uri
  --report                       Output report
  --help                         Display this help message
```

## 输出说明

```shell
--jsonlog LOGFILE # 必须指定json日志文件
未输入其他参数时默认分析全部日志内容，输入其他参数时候将以且的逻辑传入参数查询并输出结果
--report #仅输入此参数时候才会输出报表
```

## 输出效果

### 无报表输出

```shell
bash  analyze_logsv2.sh  --jsonlog json.log --host www.kubehan.cn --http_status 404-500  --uri "/springadmin/instances"
# 此时的输出没有做优化，仅将符合条件的数据原样输出，可自行结合jq awk 等命令输出
```

截取了一段作为输出展示

```json
{"time_local":"2024-07-21T21:46:28+08:00","msec":1721569588.97,"remote_addr":"10.154.168.204","remote_user":"-","body_bytes_sent":65,"content_length":"249","upstream_response_length":"65","upstream_addr":"10.154.168.184:8000","upstream_connect_time":"0.000","bytes_sent":529,"request_length":497,"connection_requests":5,"http_status":404,"schema":"http","uri":"/springadmin/instances","http_cookie":"-","request_uri":"/springadmin/instances","query_string":"-","method":"POST","request_time":0.002,"upstream_response_time":"0.001","upstream_status":"404","http_host":"www.kubehan.cn:8888","http_referrer":"-","http_x_forwarded_for":"-","sla_appname":"-","http_user_agent":"Apache-HttpClient/4.5.13 (Java/11.0.2)","host":"www.kubehan.cn","request":"POST /springadmin/instances HTTP/1.1","server_addr":"10.154.168.11","request_id":"22-10.154.168.11:35458-1721569588968-1.8851489992375e+17"}
```

### 报表输出

```shell
bash  analyze_logsv2.sh  --jsonlog json.log --host www.kubehan.cn --http_status 404-500  --uri "/springadmin/instances"
------------------
日志总数: 3515
HTTP 状态码统计:
   3515 404

请求方法统计:
   3515 POST

请求时间统计:
Mean: 0.00138919 Count: 3515
Request Time - Max: 0.064, Min: 0

上游响应时间统计:
Mean: 0.000594026 Count: 3515
Upstream Response Time - Max: 0.025, Min: 0

主机统计:
   3515 www.kubehan.cn
Top 10 Request Times:
Host                                   URI                     HTTP Status  Upstream Address     Request Time
www.kubehan.cn  /springadmin/instances  404            10.154.168.184:8000  0.064
www.kubehan.cn  /springadmin/instances  404            10.154.137.222:8000  0.014
www.kubehan.cn  /springadmin/instances  404            -                    0.01
www.kubehan.cn  /springadmin/instances  404            10.154.137.222:8000  0.008
www.kubehan.cn  /springadmin/instances  404            10.154.137.222:8000  0.006
www.kubehan.cn  /springadmin/instances  404            10.154.168.184:8000  0.006
www.kubehan.cn  /springadmin/instances  404            10.154.137.222:8000  0.005
www.kubehan.cn  /springadmin/instances  404            10.154.137.222:8000  0.005
www.kubehan.cn  /springadmin/instances  404            10.154.137.222:8000  0.005
www.kubehan.cn  /springadmin/instances  404            10.154.137.222:8000  0.004
URI 访问统计:
   3515 /springadmin/instances
```

```shell
bash  analyze_logsv2.sh  --jsonlog json.log    --report
日志总数: 24336
HTTP 状态码统计:
  13361 404
  10639 200
    297 503
     19 201
     14 500
      5 401
      1 400

请求方法统计:
  13673 POST
  10663 GET

请求时间统计:
Mean: 0.0571686 Count: 24336
Request Time - Max: 166.867, Min: 0

上游响应时间统计:
Mean: 0.056565 Count: 24336
Upstream Response Time - Max: 166.855, Min: 0

主机统计:
   9566 routing-qiluhospital.marathon-prod
   9403 hello.kubehan.cn
   3551 site.kubehan.cn
    667 www.kubehan.cn
    483 test.kubehan.cn
    362 openapi.intra.kubehan.cn
    297 grafana.kubehan.cn
      7 kibana.k8s.kubehan.cn
Top 10 Request Times:
Host                            URI                                 HTTP Status  Upstream Address   Request Time
www.kubehan.cn  /sre/api/ldap/ldap3_mutiple_update  200            10.154.168.234:80  166.867
www.kubehan.cn  /sre/api/ldap/ldap3_mutiple_update  200            10.154.168.234:80  166.583
www.kubehan.cn  /sre/api/ldap/ldap3_mutiple_update  200            10.154.168.234:80  165.527
www.kubehan.cn  /sre/api/ldap/ldap3_mutiple_update  200            10.154.168.234:80  165.157
www.kubehan.cn  /sre/api/ldap/ldap3_mutiple_update  200            10.154.168.234:80  163.708
www.kubehan.cn  /sre/api/ldap/ldap3_mutiple_update  200            10.154.138.165:80  97.391
www.kubehan.cn  /sre/api/ldap/ldap3_mutiple_update  200            10.154.138.165:80  97.357
www.kubehan.cn  /sre/api/ldap/ldap3_mutiple_update  200            10.154.138.165:80  96.568
www.kubehan.cn  /sre/api/ldap/ldap3_mutiple_update  200            10.154.138.165:80  95.629
www.kubehan.cn  /sre/api/ldap/                      200            10.154.138.165:80  5.383
URI 访问统计:
  12875 /springadmin/instances
   5944 /api/pullserver/pullserver/get_todo_task
   3419 /openapi/dev/servicelist
    362 /openapi/idtoken/refresh
    297 /api/v1/query
    136 /openapi/pandora/findDataZip
    126 /sso/passport/user/who
    117 /sso/oauth/iam/who
    111 /openapi/pandora/excute
```

> **脚本还在不断完善中......,如有这方面的需求的同学可以联系我一起优化一下脚本！完成最终版本后分享给大家使用！！！**

**如果觉得不错，点个关注！！！**
