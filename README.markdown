Name
====
fork from https://github.com/openresty/lua-resty-upstream-healthcheck

just for enhance.

lua-resty-upstream-healthcheck - Health-checker for Nginx upstream servers

说明
====
1. 增加: 健康检查的是否支持内容校验, 当然一般用简单的内容标识运行正常.
2. 增加: 利用health check的定时和共享内存暂停和恢复peer, 一般用于静态upstream的临时发布摘除.
3. 示例: 多个upstream的监控检查

你可能需要知道的 (但是这里不提供的)
====
1. 如果需要动态增删upstream里面的server, 你可以使用
    * openresty/lua-resty-balancer 
    * upyun/lua-resty-checkups
    * weibocom / nginx-upsync-module
    * yzprofile / ngx_http_dyups_module (或者 Tengine )

2. 如果你有多台机器, 可以使用redis来存放共享内存的内容
3. 如果不需要健康检查, 自己实现一个定时机制, 供worker自己更新自己的状态 (copy  healthcheck 然后去除多余的项目)     
    