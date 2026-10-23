# Spring Boot 后端基础框架实施计划

Goal: 在现有桌面项目 backend 中建立可运行、可验证的后端及真实影片分页查询。

Architecture: 模块化单体；common/config 提供通用能力，film 按 Controller、Service、Mapper、Entity、DTO、VO 分层。MySQL 是事实来源，Redis 仅检查连接，JWT 留扩展依赖，本阶段没有登录业务。

Tech Stack: Java 21、Maven、Spring Boot 3.5.16、MyBatis-Plus 3.5.17、Springdoc 2.8.17，其他版本由 Boot BOM 管理。

Spec: 用户当前消息《开发任务一：Spring Boot 后端基础框架搭建》。

Global Constraints: 不改已有表/数据；不输出或提交密码；不自动初始化 SQL；不开发登录、订单、前端。用户要求直接执行，按现有目录实施，不进行额外的计划审批或工作树流程。

Review Focus: SQL 字段与物理库一致；未发布影片不可公开；无默认账号或全量 permitAll；生产禁用文档；分页异常不能返回 500；日志与 JAR 不包含私密配置。

## Task 1：核验并固定环境

- [x] 检查实际 55 表、4 视图及 film 的 17 个字段；SQL/模型无差异。
- [x] 找到本机 Java 21（默认 Java 为 25），Maven 3.9.4。
- [x] 校正仅本地 Redis 端口/认证配置，认证 PING 成功。
- [x] 留存物理结构只读快照，后续比较不改表。

## Task 2：基础框架

Interfaces: ApiResponse(code,message,data,requestId)，PageQuery(page,pageSize)，PageResponse(records,total,page,pageSize,pages)。Long 主键在 VO 中输出字符串；业务路径 /api/v1。

- [x] 创建 Maven、环境配置、异常、分页及日志基础代码；先测试分页边界，观察失败再实现约束。
- [x] Security 仅允许 GET films、health，dev 允许文档，其余需要认证；CORS 使用明确来源列表。
- [x] 使用 MockMvc 检查参数校验、错误脱敏、401/403、CORS、请求编号。
- [x] `mvn test`：测试全部通过。

## Task 3：真实影片查询

Interfaces: GET /api/v1/films?page=1&pageSize=10；page 1..1000000，pageSize 1..100；仅 film.publish_status=PUBLISHED，按 id DESC，越界页为空。

- [x] FilmEntity 只映射真实字段；Mapper 使用 BaseMapper；Service 事务只读并通过分页拦截器查询，VO 只给用户需要的公开字段。
- [x] live Maven profile 的测试使用实际 MySQL/Redis，读数据库结果与 JDBC 对照，不写入或播种。
- [x] `mvn -Plive verify`：打包与真实连接测试通过。

## Task 4：启动与交付

- [x] 运行 JAR，HTTP 验证影片两页、非法参数、受保护路径、健康、OpenAPI、Swagger 静态资源。
- [x] 验证 prod 文档关闭；比较数据库结构快照。
- [x] 审查代码与私密文件忽略情况，记录执行结果和剩余限制。
- [x] 完善 backend README、运行脚本与交付说明，代码同步桌面和公开交付目录。
