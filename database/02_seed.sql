-- 基础字典；在01_schema.sql之后执行一次。不创建默认管理员或弱口令账号。
USE pzh_cinema;
SET NAMES utf8mb4;
SET time_zone = '+08:00';
START TRANSACTION;
INSERT INTO sys_region (id,parent_id,region_code,region_name,level_no,sort_no) VALUES
(1,NULL,'PZH','攀枝花市',1,1),(2,1,'PZH_EAST','东区',2,1),(3,1,'PZH_WEST','西区',2,2),
(4,1,'PZH_RENHE','仁和区',2,3),(5,1,'PZH_MIYI','米易县',2,4),(6,1,'PZH_YANBIAN','盐边县',2,5);
INSERT INTO sys_role (id,role_code,role_name,scope_type) VALUES
(1,'PLATFORM_ADMIN','系统管理员','GLOBAL'),(2,'CINEMA_ADMIN','影院管理员','CINEMA'),(3,'CUSTOMER','普通用户','GLOBAL'),(4,'TICKET_CHECKER','影院验票员','CINEMA');
INSERT INTO sys_permission (id,permission_code,permission_name,permission_type,route_path,sort_no) VALUES
(1,'platform:dashboard','平台数据看板','MENU','/platform/dashboard',1),
(2,'platform:film:manage','全局影片管理','API',NULL,2),
(3,'platform:category:manage','影片分类管理','API',NULL,3),
(4,'platform:cinema:audit','影院资质审核','API',NULL,4),
(5,'platform:admin:audit','影院管理员审核','API',NULL,5),
(6,'platform:user:manage','平台用户管理','API',NULL,6),
(7,'platform:role:manage','动态权限配置','API',NULL,7),
(8,'platform:review:audit','评价安全审核','API',NULL,8),
(9,'platform:sensitive:manage','敏感词配置','API',NULL,9),
(10,'platform:log:read','系统审计日志','API',NULL,10),
(11,'platform:announcement:manage','平台公告管理','API',NULL,11),
(12,'platform:activity:manage','平台活动管理','API',NULL,12),
(13,'platform:member:manage','平台会员管理','API',NULL,13),
(14,'platform:coupon:manage','平台优惠券管理','API',NULL,14),
(15,'platform:stats:read','平台统计查询','API',NULL,15),
(16,'platform:feedback:manage','平台反馈处理','API',NULL,16),
(20,'cinema:dashboard','影院经营看板','MENU','/cinema/dashboard',20),
(21,'cinema:profile:manage','本院信息管理','API',NULL,21),
(22,'cinema:film:manage','本院片库管理','API',NULL,22),
(23,'cinema:hall:manage','影厅座位管理','API',NULL,23),
(24,'cinema:screening:manage','排片管理','API',NULL,24),
(25,'cinema:pricing:manage','票价策略管理','API',NULL,25),
(26,'cinema:member:read','本院会员查询','API',NULL,26),
(27,'cinema:order:read','本院订单查询','API',NULL,27),
(28,'cinema:ticket:verify','现场验票核销','API',NULL,28),
(29,'cinema:after-sale:audit','退票改签审核','API',NULL,29),
(30,'cinema:announcement:manage','本院公告管理','API',NULL,30),
(31,'cinema:review:manage','本院评价管理与回复','API',NULL,31),
(32,'cinema:feedback:manage','本院反馈处理','API',NULL,32),
(33,'cinema:stats:read','本院实时统计','API',NULL,33),
(34,'cinema:activity:manage','本院活动管理','API',NULL,34),
(35,'cinema:coupon:manage','本院优惠券管理','API',NULL,35),
(40,'user:profile:manage','个人信息维护','API',NULL,40),
(41,'user:favorite:manage','我的收藏','API',NULL,41),
(42,'user:order:create','锁座与购票','API',NULL,42),
(43,'user:order:read','我的订单票夹','API',NULL,43),
(44,'user:after-sale:create','申请退票改签','API',NULL,44),
(45,'user:review:create','发布购票评价','API',NULL,45),
(46,'user:feedback:create','提交留言反馈','API',NULL,46),
(47,'user:activity:join','参加活动与领券','API',NULL,47),
(48,'user:member:read','我的会员积分','API',NULL,48);
INSERT INTO sys_role_permission (role_id,permission_id) SELECT 1,id FROM sys_permission WHERE id BETWEEN 1 AND 16;
INSERT INTO sys_role_permission (role_id,permission_id) SELECT 2,id FROM sys_permission WHERE id BETWEEN 20 AND 35;
INSERT INTO sys_role_permission (role_id,permission_id) SELECT 3,id FROM sys_permission WHERE id BETWEEN 40 AND 48;
INSERT INTO sys_role_permission (role_id,permission_id) VALUES (4,28);
INSERT INTO film_category (id,category_name,sort_no) VALUES (1,'剧情',1),(2,'喜剧',2),(3,'动作',3),(4,'科幻',4),(5,'动画',5),(6,'爱情',6),(7,'悬疑',7),(8,'纪录片',8);
INSERT INTO member_level (id,level_code,level_name,required_growth,ticket_discount_rate,points_per_yuan,sort_no) VALUES
(1,'NORMAL','普通会员',0,1.0000,1,1),(2,'SILVER','银卡会员',1000,0.9500,1,2),(3,'GOLD','金卡会员',5000,0.9000,2,3);
COMMIT;
