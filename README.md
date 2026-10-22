# 攀枝花市影院售票系统

本项目对应毕业设计的用户移动端、影院管理员Web端、系统管理员Web端。当前交付为**数据库设计与项目目录**：55张表、4个统计视图、基础字典、可选虚构演示数据、导入脚本和设计文档。三端业务程序尚未实现，各代码目录目前只有范围说明，不能当作可运行系统。

## 文件位置

- .gitignore、.env.example、docs/密钥与环境配置.md：私密文件忽略规则、空配置参考和地图API凭证使用约定。
- database/01_schema.sql：完整MySQL建表脚本，包含主外键、唯一索引、CHECK约束和循环关联的后置外键。
- database/02_seed.sql：攀枝花项目内区域字典、角色权限、影片分类和会员等级；无默认弱口令账号。
- database/03_demo.sql：可选虚构影院、影片、场次和一笔沙箱已支付订单；演示账号不可登录。
- database/04_views.sql：场次库存、影片评分、影院实时经营、全平台DAU四个视图。
- database/05_readonly_checks.sql：业务金额、库存归属及数量一致性的只读查询。
- database/import.ps1：Windows导入入口。
- docs/数据库设计说明.md、数据字典.md、表清单.md、需求表映射.md：设计与字段说明。
- docs/业务事务与Redis方案.md：锁座、支付、退改签、核销、营销等事务边界。
- docs/验证报告.md：本次实际执行结果及验证范围。
- backend/：后续Spring Boot + MyBatis-Plus后端代码。
- admin-web/：后续Vue 3 + Element Plus管理端，按角色提供两类管理入口。
- user-uniapp/：后续Uni-app微信小程序/H5用户端。
- deploy/：后续部署配置。

## 导入

要求MySQL 8.0.16及以上，推荐使用已安装的MySQL 8.0近期补丁版本。数据库名pzh_cinema，字符集utf8mb4，存储引擎InnoDB，时间统一北京时间。CHECK从MySQL 8.0.16起才会被执行，参见[MySQL官方说明](https://dev.mysql.com/doc/refman/8.0/en/create-table-check-constraints.html)。

在PowerShell进入此项目目录，按顺序导入。密码由mysql客户端交互询问，脚本不硬编码：

~~~powershell
.\database\import.ps1 -MySqlCommand 'D:\MySQL\MySQL Server 8.0\bin\mysql.exe' -User root -IncludeDemo
~~~

不需要演示数据时去掉-IncludeDemo。若使用自己的MySQL路径，修改-MySqlCommand；端口或主机不同可指定-Port、-HostName。脚本不会修改既有MySQL服务配置，也不会DROP数据库；如果已有同名表，会报错，DDL已创建的对象不会自动撤销。新项目只执行一次；后续改表应使用版本化迁移。

如果PowerShell执行策略阻止运行，可在mysql交互客户端依次执行source database/01_schema.sql、source database/02_seed.sql、source database/03_demo.sql（可选）、source database/04_views.sql。先在项目根目录启动mysql客户端，确保相对路径正确。

数据库会创建在你选择的MySQL实例中。此文件夹统一存放代码、SQL和文档，不复制MySQL服务自身的数据目录。
