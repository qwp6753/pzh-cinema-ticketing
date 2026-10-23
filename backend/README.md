# Spring Boot 后端基础框架

本阶段实现通用能力和真实影片分页查询。没有登录、JWT 签发、RBAC 业务、订单或前端；除明确列出的公开 GET 外，其他路径均要求认证，本阶段尚无可用的业务认证入口。

## 版本与结构

- Java 21；Maven 3.6.3+（本机验证 3.9.4）。
- Spring Boot 3.5.16、MyBatis-Plus 3.5.17、分页解析器同版本、Springdoc 2.8.17。
- MySQL Connector/J、Spring Security、Spring Data Redis/Lettuce、Validation、Lombok、JUnit 5 使用 Boot BOM 管理版本。
- `src/main/java/com/pzh/cinema/common`：统一返回、异常、分页 DTO/结果、请求编号。
- `config`：分页拦截器、CORS、安全过滤链、OpenAPI。
- `film/{controller,service,mapper,entity,vo}`：仅影片查询模块；分页 DTO 为通用 `common/api/PageQuery`。
- `src/main/resources`：公共/dev/prod 配置、滚动日志配置。
- `src/test/java`：默认单元/MVC 测试和显式开启的真实基础设施测试。
- `scripts/dev.cjs`：可选 dotenv 启动工具，需要 Node.js 20.12+。不使用工具时，手动设置环境变量后直接使用 Maven/JAR。

## 配置

实际数据库为 **pzh_cinema**，已核对 `film` 的 17 个字段。配置不会执行 SQL 初始化、建表、清表或迁移。启动前无需重新运行 `database/import.ps1`。

项目根目录 `.env.example` 是空凭据模板，复制为 `.env.local` 后在本机填写。Spring Boot **不会自动读取 dotenv**；下述脚本将该文件解析为 Maven 子进程环境变量，不执行文件内容。也可以通过 IDE、操作系统或部署平台注入同名变量。

| 环境变量 | 用途 |
| --- | --- |
| SPRING_DATASOURCE_URL | 完整 JDBC URL，如 `jdbc:mysql://127.0.0.1:3306/pzh_cinema?serverTimezone=Asia/Shanghai` |
| SPRING_DATASOURCE_USERNAME / PASSWORD | 必填账号/密码，密码变量全名为 SPRING_DATASOURCE_PASSWORD；无内置账号 |
| SPRING_DATA_REDIS_HOST / PORT / PASSWORD / DATABASE | Redis 配置，均带 SPRING_DATA_REDIS_ 前缀；默认地址 127.0.0.1:6379、库 0，本机实际端口以 `.env.local` 为准 |
| SPRING_PROFILES_ACTIVE | 开发 `dev`（默认）；部署明确设置 `prod` |
| SERVER_PORT | 默认 8080 |
| APP_CORS_ALLOWED_ORIGINS | 逗号分隔的准确来源；dev 默认 localhost/127.0.0.1 的 5173、5174；prod 默认不允许跨域 |
| LOG_PATH | 默认工作目录的 logs；按天/10MB 滚动，保留 14 天、总计最多 200MB |
| JWT_SECRET | 后续阶段预留；本阶段不读取、不签发或校验 JWT |

真实 `.env.local`、私密配置、密钥、日志、target 被 Git 忽略，`.env.local` 位于 backend 资源目录之外，不进入 JAR。地图服务端密钥不能放进 `VITE_*` 或小程序代码。

## 运行与验证

在 `backend` 目录执行：

```powershell
node .\scripts\dev.cjs verify-live --java-home 'C:\Users\yxl\.jdks\ms-21.0.11' --maven-home 'D:\idea\apache-maven-3.9.4'
node .\scripts\dev.cjs run --java-home 'C:\Users\yxl\.jdks\ms-21.0.11' --maven-home 'D:\idea\apache-maven-3.9.4'
```

也可分别用 `JAVA_HOME`、`MAVEN_HOME` 设置工具目录。`--repo-local` 可指定缓存，`--config-file` 可指定其他 dotenv 路径；工具不修改全局 Java 设置。

已自行注入环境变量时，标准 Maven 用法：

```powershell
mvn test               # 默认测试不要求 MySQL/Redis
mvn verify             # 测试并生成可执行 JAR
mvn -Plive verify      # 加测真实 MySQL、Redis、HTTP、Swagger、prod 安全边界
mvn spring-boot:run
java -jar .\target\cinema-backend-0.1.0-SNAPSHOT.jar --spring.profiles.active=prod
```

生产环境明确选择 `prod`，不要同时启用 `dev`，配置通过部署环境注入。默认端口 8080，Ctrl+C 正常退出。

## 接口

| 方法与路径 | 行为 |
| --- | --- |
| GET /api/v1/films?page=1&pageSize=10 | 公开目录，真实 MyBatis-Plus 查询，仅 `publish_status=PUBLISHED`，`id DESC` |
| GET /actuator/health | MySQL/Redis 综合健康，公开状态，不公开依赖详情 |
| GET /v3/api-docs | dev OpenAPI JSON |
| GET /swagger-ui.html | dev Swagger UI，跳转到 `/swagger-ui/index.html` |

`page` 范围 1..1000000、`pageSize` 范围 1..100，默认 1/10；参数类型错误或越界返回 400。超过末页返回空 records，不跳回第一页。未发布/下架影片不公开。

```json
{
  "code": 0,
  "message": "成功",
  "data": {
    "records": [{"id": "2", "filmName": "数据库中的影片名称"}],
    "total": 2, "page": 1, "pageSize": 10, "pages": 1
  },
  "requestId": "请求编号"
}
```

上例仅展示结构，影片数据来自数据库。VO 还返回海报、导演、国家、语言、片长、上映日期、上映状态、热度；不返回内部维护信息。主键 id 为字符串，分页计数为数字。

API 错误采用相同结构及实际 HTTP 状态（400/401/403/404/405/409/500/503）；校验错误的 data 为字段错误数组，不回显输入。未知异常和数据库异常不回显内部详情。响应头 `X-Request-Id` 可用于日志追踪。

Actuator、OpenAPI、Swagger 静态资源保持各自标准协议；CORS 拒绝由 Spring Security CORS 处理器生成。其他业务接口默认要求认证，包括 POST /api/v1/films。prod 关闭文档注册及匿名访问。

## 数据及后续扩展

现有 2 条电影是数据库中保存的**虚构开发样例**，服务不内置模拟电影、不播种。FilmEntity 对应 17 列，JSON 演员信息按原始文本映射，本阶段列表不展示演员明细。DATETIME(3) 使用 LocalDateTime，约定北京时间。

JWT JOSE/Resource Server 依赖已预留，未启用认证过滤或令牌签发；Redis 已配置但未实现缓存业务和锁座。下一阶段建议开发真实账号认证、JWT 与 RBAC/影院数据隔离，再进入影院、影厅和排片管理。

兼容性依据：[Boot 3.5 系统要求](https://docs.spring.io/spring-boot/3.5/system-requirements.html)、[Springdoc 兼容矩阵](https://springdoc.org/v2/#what-is-the-compatibility-matrix-of-springdoc-openapi-with-spring-boot)、[MyBatis-Plus 分页依赖](https://baomidou.com/en/plugins/pagination/)。实际执行结果见项目 `docs/后端基础框架交付说明.md`。
