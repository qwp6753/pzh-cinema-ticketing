-- 攀枝花市影院售票系统：数据库设计 V1
-- 目标 MySQL >= 8.0.16；InnoDB / utf8mb4；金额人民币元，时间北京时间。
-- 本脚本不包含DROP/TRUNCATE；请在空数据库执行，已有同名表会报错并停止。
CREATE DATABASE IF NOT EXISTS pzh_cinema CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE pzh_cinema;
SET NAMES utf8mb4;
SET time_zone = '+08:00';

-- 账号权限 / 区域字典
CREATE TABLE `sys_region` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `parent_id` BIGINT NULL COMMENT '父区域',
  `region_code` VARCHAR(32) NOT NULL COMMENT '项目内区域编号，不作为行政区划编码',
  `region_name` VARCHAR(64) NOT NULL COMMENT '区域名称',
  `level_no` TINYINT NOT NULL DEFAULT 1 COMMENT '层级：1城市、2区县',
  `sort_no` INT NOT NULL DEFAULT 0 COMMENT '显示顺序',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ENABLED' COMMENT '状态；ENABLED/DISABLED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_region_uk_1` (`region_code`),
  CONSTRAINT `sys_region_fk_2` FOREIGN KEY (`parent_id`) REFERENCES `sys_region` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `sys_region_ck_3` CHECK (level_no IN (1,2)),
  CONSTRAINT `sys_region_ck_4` CHECK (`status` IN ('ENABLED', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='区域字典';

-- 账号权限 / 统一用户账号
CREATE TABLE `sys_user` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `username` VARCHAR(64) NULL COMMENT '用户名',
  `phone` VARCHAR(32) NULL COMMENT '手机号；未绑定时为NULL',
  `password_hash` VARCHAR(100) COLLATE utf8mb4_bin NULL COMMENT 'BCrypt密码摘要；禁止明文，演示账号不设置密码',
  `wechat_app_id` VARCHAR(64) COLLATE utf8mb4_bin NULL COMMENT '微信应用标识',
  `wechat_openid` VARCHAR(128) COLLATE utf8mb4_bin NULL COMMENT '微信OpenID；按应用隔离',
  `wechat_unionid` VARCHAR(128) COLLATE utf8mb4_bin NULL COMMENT '微信UnionID',
  `nickname` VARCHAR(64) NOT NULL COMMENT '昵称',
  `avatar_url` VARCHAR(512) NULL COMMENT '头像地址',
  `gender` VARCHAR(24) NOT NULL DEFAULT 'UNKNOWN' COMMENT '性别；UNKNOWN/MALE/FEMALE',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ACTIVE' COMMENT '账号状态；ACTIVE/LOCKED/CLOSED',
  `last_login_at` DATETIME(3) NULL COMMENT '最近登录时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_user_uk_1` (`username`),
  UNIQUE KEY `sys_user_uk_2` (`phone`),
  UNIQUE KEY `sys_user_uk_3` (`wechat_app_id`, `wechat_openid`),
  UNIQUE KEY `sys_user_uk_4` (`wechat_unionid`),
  CONSTRAINT `sys_user_ck_5` CHECK (username IS NOT NULL OR phone IS NOT NULL OR wechat_openid IS NOT NULL),
  CONSTRAINT `sys_user_ck_6` CHECK ((wechat_app_id IS NULL AND wechat_openid IS NULL) OR (wechat_app_id IS NOT NULL AND wechat_openid IS NOT NULL)),
  CONSTRAINT `sys_user_ck_7` CHECK (`gender` IN ('UNKNOWN', 'MALE', 'FEMALE')),
  CONSTRAINT `sys_user_ck_8` CHECK (`status` IN ('ACTIVE', 'LOCKED', 'CLOSED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='统一用户账号';

-- 账号权限 / 角色
CREATE TABLE `sys_role` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `role_code` VARCHAR(64) NOT NULL COMMENT '角色编码',
  `role_name` VARCHAR(64) NOT NULL COMMENT '角色名称',
  `scope_type` VARCHAR(24) NOT NULL DEFAULT 'GLOBAL' COMMENT '授权范围；GLOBAL/CINEMA',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ENABLED' COMMENT '状态；ENABLED/DISABLED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_role_uk_1` (`role_code`),
  UNIQUE KEY `sys_role_uk_2` (`id`, `scope_type`),
  CONSTRAINT `sys_role_ck_3` CHECK (`scope_type` IN ('GLOBAL', 'CINEMA')),
  CONSTRAINT `sys_role_ck_4` CHECK (`status` IN ('ENABLED', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='角色';

-- 账号权限 / 权限与菜单
CREATE TABLE `sys_permission` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `parent_id` BIGINT NULL COMMENT '父权限',
  `permission_code` VARCHAR(96) NOT NULL COMMENT '后端权限编码',
  `permission_name` VARCHAR(64) NOT NULL COMMENT '名称',
  `permission_type` VARCHAR(24) NOT NULL DEFAULT 'MENU' COMMENT '类型；MENU/BUTTON/API',
  `route_path` VARCHAR(200) NULL COMMENT '前端路由',
  `sort_no` INT NOT NULL DEFAULT 0 COMMENT '显示顺序',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ENABLED' COMMENT '状态；ENABLED/DISABLED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_permission_uk_1` (`permission_code`),
  CONSTRAINT `sys_permission_fk_2` FOREIGN KEY (`parent_id`) REFERENCES `sys_permission` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `sys_permission_ck_3` CHECK (`permission_type` IN ('MENU', 'BUTTON', 'API')),
  CONSTRAINT `sys_permission_ck_4` CHECK (`status` IN ('ENABLED', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='权限与菜单';

-- 账号权限 / 角色权限关联
CREATE TABLE `sys_role_permission` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `role_id` BIGINT NOT NULL COMMENT '角色',
  `permission_id` BIGINT NOT NULL COMMENT '权限',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_role_permission_uk_1` (`role_id`, `permission_id`),
  CONSTRAINT `sys_role_permission_fk_2` FOREIGN KEY (`role_id`) REFERENCES `sys_role` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `sys_role_permission_fk_3` FOREIGN KEY (`permission_id`) REFERENCES `sys_permission` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='角色权限关联';

-- 影院排片 / 影院基本资料
CREATE TABLE `cinema` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `cinema_code` VARCHAR(32) NOT NULL COMMENT '影院编号',
  `cinema_name` VARCHAR(120) NOT NULL COMMENT '影院名称',
  `region_id` BIGINT NOT NULL COMMENT '所属区县',
  `address` VARCHAR(255) NOT NULL COMMENT '详细地址',
  `contact_phone` VARCHAR(32) NULL COMMENT '业务联系电话',
  `longitude` DECIMAL(10,7) NULL COMMENT '经度',
  `latitude` DECIMAL(10,7) NULL COMMENT '纬度',
  `business_hours` VARCHAR(120) NULL COMMENT '营业时间说明',
  `cover_url` VARCHAR(512) NULL COMMENT '封面图',
  `introduction` TEXT NULL COMMENT '影院介绍',
  `status` VARCHAR(24) NOT NULL DEFAULT 'PENDING' COMMENT '入驻及营业状态；PENDING/ACTIVE/SUSPENDED/REJECTED/CLOSED',
  `refund_cutoff_minutes` INT NOT NULL DEFAULT 60 COMMENT '开场前允许退票的最短分钟数',
  `change_cutoff_minutes` INT NOT NULL DEFAULT 60 COMMENT '开场前允许改签的最短分钟数',
  `refund_fee_rate` DECIMAL(5,4) NOT NULL DEFAULT 0 COMMENT '退票手续费率，0到1；以购票时快照为准',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cinema_uk_1` (`cinema_code`),
  CONSTRAINT `cinema_fk_2` FOREIGN KEY (`region_id`) REFERENCES `sys_region` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `cinema_ix_3` (`region_id`, `status`),
  CONSTRAINT `cinema_ck_4` CHECK (refund_cutoff_minutes >= 0 AND change_cutoff_minutes >= 0),
  CONSTRAINT `cinema_ck_5` CHECK (refund_fee_rate BETWEEN 0 AND 1),
  CONSTRAINT `cinema_ck_6` CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
  CONSTRAINT `cinema_ck_7` CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
  CONSTRAINT `cinema_ck_8` CHECK (`status` IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'REJECTED', 'CLOSED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影院基本资料';

-- 账号权限 / 用户角色授权
CREATE TABLE `sys_user_role` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `user_id` BIGINT NOT NULL COMMENT '被授权用户',
  `role_id` BIGINT NOT NULL COMMENT '角色',
  `scope_type` VARCHAR(24) NOT NULL DEFAULT 'GLOBAL' COMMENT '授权范围；GLOBAL/CINEMA',
  `cinema_id` BIGINT NULL COMMENT '影院范围；全局角色为NULL',
  `scope_key` BIGINT GENERATED ALWAYS AS (IFNULL(cinema_id, 0)) STORED COMMENT '唯一性辅助列；全局范围映射为0',
  `granted_by` BIGINT NULL COMMENT '授权人',
  `expires_at` DATETIME(3) NULL COMMENT '授权到期时间；NULL为长期',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `sys_user_role_uk_1` (`user_id`, `role_id`, `scope_key`),
  CONSTRAINT `sys_user_role_fk_2` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `sys_user_role_fk_3` FOREIGN KEY (`role_id`, `scope_type`) REFERENCES `sys_role` (`id`, `scope_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `sys_user_role_fk_4` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `sys_user_role_fk_5` FOREIGN KEY (`granted_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `sys_user_role_ix_6` (`cinema_id`, `user_id`),
  CONSTRAINT `sys_user_role_ck_7` CHECK ((scope_type = 'GLOBAL' AND cinema_id IS NULL) OR (scope_type = 'CINEMA' AND cinema_id IS NOT NULL)),
  CONSTRAINT `sys_user_role_ck_8` CHECK (`scope_type` IN ('GLOBAL', 'CINEMA'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户角色授权';

-- 影院排片 / 影院入驻资质审核记录
CREATE TABLE `cinema_application` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `cinema_id` BIGINT NOT NULL COMMENT '申请对应的待审核影院',
  `applicant_id` BIGINT NOT NULL COMMENT '申请人',
  `company_name` VARCHAR(160) NOT NULL COMMENT '经营主体名称',
  `license_number` VARCHAR(64) NOT NULL COMMENT '资质证照编号',
  `qualification_files` JSON NOT NULL COMMENT '资质文件存储键数组；不保存公开敏感文件链接',
  `status` VARCHAR(24) NOT NULL DEFAULT 'PENDING' COMMENT '审批状态；PENDING/APPROVED/REJECTED/WITHDRAWN',
  `reviewer_id` BIGINT NULL COMMENT '平台审核人',
  `reviewed_at` DATETIME(3) NULL COMMENT '审核时间',
  `review_remark` VARCHAR(500) NULL COMMENT '审核说明',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `cinema_application_fk_1` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_application_fk_2` FOREIGN KEY (`applicant_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_application_fk_3` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `cinema_application_ix_4` (`status`, `created_at`),
  CONSTRAINT `cinema_application_ck_5` CHECK (`status` IN ('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影院入驻资质审核记录';

-- 账号权限 / 影院管理员账号申请
CREATE TABLE `cinema_admin_application` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `user_id` BIGINT NOT NULL COMMENT '申请账号',
  `cinema_id` BIGINT NOT NULL COMMENT '申请管理的影院',
  `role_id` BIGINT NOT NULL COMMENT '申请的影院角色',
  `role_scope` VARCHAR(24) NOT NULL DEFAULT 'CINEMA' COMMENT '限定为影院范围；CINEMA',
  `real_name` VARCHAR(64) NOT NULL COMMENT '申请人姓名',
  `contact_phone` VARCHAR(32) NOT NULL COMMENT '申请联系号码',
  `application_note` VARCHAR(500) NULL COMMENT '申请说明',
  `status` VARCHAR(24) NOT NULL DEFAULT 'PENDING' COMMENT '审核状态；PENDING/APPROVED/REJECTED/WITHDRAWN',
  `pending_user_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status = 'PENDING' THEN user_id ELSE NULL END) STORED COMMENT '同一用户同一影院同一角色仅一条待审申请',
  `reviewer_id` BIGINT NULL COMMENT '平台审核人',
  `reviewed_at` DATETIME(3) NULL COMMENT '审核时间',
  `review_remark` VARCHAR(500) NULL COMMENT '审核说明',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cinema_admin_application_uk_1` (`pending_user_id`, `cinema_id`, `role_id`),
  CONSTRAINT `cinema_admin_application_fk_2` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_admin_application_fk_3` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_admin_application_fk_4` FOREIGN KEY (`role_id`, `role_scope`) REFERENCES `sys_role` (`id`, `scope_type`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_admin_application_fk_5` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `cinema_admin_application_ix_6` (`status`, `created_at`),
  CONSTRAINT `cinema_admin_application_ck_7` CHECK (`role_scope` IN ('CINEMA')),
  CONSTRAINT `cinema_admin_application_ck_8` CHECK (`status` IN ('PENDING', 'APPROVED', 'REJECTED', 'WITHDRAWN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影院管理员账号申请';

-- 影院排片 / 影厅
CREATE TABLE `cinema_hall` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `cinema_id` BIGINT NOT NULL COMMENT '所属影院',
  `hall_name` VARCHAR(64) NOT NULL COMMENT '影厅名称',
  `hall_type` VARCHAR(24) NOT NULL DEFAULT 'STANDARD' COMMENT '厅类型；STANDARD/IMAX/DOLBY/VIP',
  `row_count` INT NOT NULL DEFAULT 1 COMMENT '布局行数',
  `column_count` INT NOT NULL DEFAULT 1 COMMENT '布局列数',
  `layout_version` INT NOT NULL DEFAULT 1 COMMENT '座位布局版本',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态；ACTIVE/MAINTENANCE/DISABLED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cinema_hall_uk_1` (`cinema_id`, `hall_name`),
  UNIQUE KEY `cinema_hall_uk_2` (`id`, `cinema_id`),
  CONSTRAINT `cinema_hall_fk_3` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_hall_ck_4` CHECK (row_count > 0 AND column_count > 0 AND layout_version > 0),
  CONSTRAINT `cinema_hall_ck_5` CHECK (`hall_type` IN ('STANDARD', 'IMAX', 'DOLBY', 'VIP')),
  CONSTRAINT `cinema_hall_ck_6` CHECK (`status` IN ('ACTIVE', 'MAINTENANCE', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影厅';

-- 影院排片 / 影厅物理座位
CREATE TABLE `cinema_seat` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `hall_id` BIGINT NOT NULL COMMENT '影厅',
  `row_no` INT NOT NULL DEFAULT 1 COMMENT '网格行号，从1开始',
  `column_no` INT NOT NULL DEFAULT 1 COMMENT '网格列号，从1开始',
  `seat_label` VARCHAR(32) NOT NULL COMMENT '可读座位号，例如3排5座',
  `seat_type` VARCHAR(24) NOT NULL DEFAULT 'NORMAL' COMMENT '座位类型；NORMAL/VIP/ACCESSIBLE/COUPLE',
  `couple_group` VARCHAR(32) NULL COMMENT '情侣座组合编号',
  `surcharge` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '座位加价',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态；过道不建座位记录；ACTIVE/DISABLED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cinema_seat_uk_1` (`hall_id`, `row_no`, `column_no`),
  UNIQUE KEY `cinema_seat_uk_2` (`hall_id`, `seat_label`),
  UNIQUE KEY `cinema_seat_uk_3` (`id`, `cinema_id`, `hall_id`),
  CONSTRAINT `cinema_seat_fk_4` FOREIGN KEY (`hall_id`, `cinema_id`) REFERENCES `cinema_hall` (`id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_seat_ck_5` CHECK (row_no > 0 AND column_no > 0 AND surcharge >= 0),
  CONSTRAINT `cinema_seat_ck_6` CHECK (`seat_type` IN ('NORMAL', 'VIP', 'ACCESSIBLE', 'COUPLE')),
  CONSTRAINT `cinema_seat_ck_7` CHECK (`status` IN ('ACTIVE', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影厅物理座位';

-- 影院排片 / 影片分类
CREATE TABLE `film_category` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `category_name` VARCHAR(64) NOT NULL COMMENT '分类名',
  `sort_no` INT NOT NULL DEFAULT 0 COMMENT '显示顺序',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ENABLED' COMMENT '状态；ENABLED/DISABLED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `film_category_uk_1` (`category_name`),
  CONSTRAINT `film_category_ck_2` CHECK (`status` IN ('ENABLED', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影片分类';

-- 影院排片 / 全局影片库
CREATE TABLE `film` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `film_name` VARCHAR(160) NOT NULL COMMENT '影片名称',
  `original_name` VARCHAR(160) NULL COMMENT '原名',
  `poster_url` VARCHAR(512) NULL COMMENT '海报地址',
  `trailer_url` VARCHAR(512) NULL COMMENT '预告片地址',
  `director` VARCHAR(255) NOT NULL COMMENT '导演',
  `cast_list` JSON NULL COMMENT '演员名数组',
  `country` VARCHAR(80) NULL COMMENT '制片地区',
  `language` VARCHAR(64) NULL COMMENT '语言',
  `duration_minutes` INT NOT NULL DEFAULT 120 COMMENT '片长分钟数',
  `release_date` DATE NULL COMMENT '上映日期',
  `synopsis` TEXT NOT NULL COMMENT '剧情简介',
  `release_status` VARCHAR(24) NOT NULL DEFAULT 'COMING' COMMENT '上映状态；COMING/SHOWING/FINISHED',
  `publish_status` VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '平台上下架状态；DRAFT/PUBLISHED/OFFLINE',
  `heat_score` BIGINT NOT NULL DEFAULT 0 COMMENT '热度派生值；可重建',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  KEY `film_ix_1` (`publish_status`, `release_status`, `release_date`),
  KEY `film_ix_2` (`heat_score`),
  CONSTRAINT `film_ck_3` CHECK (duration_minutes > 0 AND heat_score >= 0),
  CONSTRAINT `film_ck_4` CHECK (`release_status` IN ('COMING', 'SHOWING', 'FINISHED')),
  CONSTRAINT `film_ck_5` CHECK (`publish_status` IN ('DRAFT', 'PUBLISHED', 'OFFLINE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='全局影片库';

-- 影院排片 / 影片分类关联
CREATE TABLE `film_category_rel` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `film_id` BIGINT NOT NULL COMMENT '影片',
  `category_id` BIGINT NOT NULL COMMENT '分类',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `film_category_rel_uk_1` (`film_id`, `category_id`),
  CONSTRAINT `film_category_rel_fk_2` FOREIGN KEY (`film_id`) REFERENCES `film` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `film_category_rel_fk_3` FOREIGN KEY (`category_id`) REFERENCES `film_category` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `film_category_rel_ix_4` (`category_id`, `film_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影片分类关联';

-- 影院排片 / 影院片库
CREATE TABLE `cinema_film` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `film_id` BIGINT NOT NULL COMMENT '全局影片',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ENABLED' COMMENT '本院上架状态；ENABLED/DISABLED',
  `local_note` TEXT NULL COMMENT '本院展示补充说明',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cinema_film_uk_1` (`cinema_id`, `film_id`),
  CONSTRAINT `cinema_film_fk_2` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_film_fk_3` FOREIGN KEY (`film_id`) REFERENCES `film` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_film_ck_4` CHECK (`status` IN ('ENABLED', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影院片库';

-- 会员营销 / 平台会员等级
CREATE TABLE `member_level` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `level_code` VARCHAR(32) NOT NULL COMMENT '等级编码',
  `level_name` VARCHAR(64) NOT NULL COMMENT '名称',
  `required_growth` BIGINT NOT NULL DEFAULT 0 COMMENT '所需成长值',
  `ticket_discount_rate` DECIMAL(5,4) NOT NULL DEFAULT 1 COMMENT '会员票价乘数；0.9表示九折',
  `points_per_yuan` INT NOT NULL DEFAULT 1 COMMENT '每消费1元获得积分',
  `sort_no` INT NOT NULL DEFAULT 0 COMMENT '排序',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `member_level_uk_1` (`level_code`),
  UNIQUE KEY `member_level_uk_2` (`required_growth`),
  CONSTRAINT `member_level_ck_3` CHECK (required_growth >= 0 AND ticket_discount_rate > 0 AND ticket_discount_rate <= 1 AND points_per_yuan >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='平台会员等级';

-- 影院排片 / 影院票价策略
CREATE TABLE `cinema_pricing_rule` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `rule_name` VARCHAR(100) NOT NULL COMMENT '策略名称',
  `hall_id` BIGINT NULL COMMENT '指定影厅；NULL适用全部',
  `film_id` BIGINT NULL COMMENT '指定电影；NULL适用全部',
  `valid_from` DATE NOT NULL COMMENT '生效日期',
  `valid_to` DATE NOT NULL COMMENT '截止日期',
  `weekday_mask` SMALLINT NOT NULL DEFAULT 127 COMMENT '周一到周日七位掩码，127表示每天',
  `time_from` TIME NOT NULL DEFAULT '00:00:00' COMMENT '适用的场次开始时间下限',
  `time_to` TIME NOT NULL DEFAULT '23:59:59' COMMENT '适用的场次开始时间上限',
  `price_mode` VARCHAR(24) NOT NULL DEFAULT 'FIXED' COMMENT '固定票价或乘数；FIXED/MULTIPLIER',
  `fixed_price` DECIMAL(10,2) NULL COMMENT '固定基础价',
  `multiplier` DECIMAL(5,4) NULL COMMENT '基础票价乘数',
  `priority` INT NOT NULL DEFAULT 0 COMMENT '优先级，数值越大越优先',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ENABLED' COMMENT '状态；ENABLED/DISABLED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cinema_pricing_rule_uk_1` (`id`, `cinema_id`),
  CONSTRAINT `cinema_pricing_rule_fk_2` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_pricing_rule_fk_3` FOREIGN KEY (`hall_id`, `cinema_id`) REFERENCES `cinema_hall` (`id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_pricing_rule_fk_4` FOREIGN KEY (`film_id`) REFERENCES `film` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `cinema_pricing_rule_ix_5` (`cinema_id`, `status`, `valid_from`, `valid_to`),
  CONSTRAINT `cinema_pricing_rule_ck_6` CHECK (valid_to >= valid_from AND time_to > time_from AND weekday_mask BETWEEN 1 AND 127),
  CONSTRAINT `cinema_pricing_rule_ck_7` CHECK ((price_mode = 'FIXED' AND fixed_price IS NOT NULL AND fixed_price > 0 AND multiplier IS NULL) OR (price_mode = 'MULTIPLIER' AND multiplier IS NOT NULL AND multiplier > 0 AND fixed_price IS NULL)),
  CONSTRAINT `cinema_pricing_rule_ck_8` CHECK (`price_mode` IN ('FIXED', 'MULTIPLIER')),
  CONSTRAINT `cinema_pricing_rule_ck_9` CHECK (`status` IN ('ENABLED', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影院票价策略';

-- 影院排片 / 放映场次
CREATE TABLE `cinema_screening` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `hall_id` BIGINT NOT NULL COMMENT '影厅',
  `film_id` BIGINT NOT NULL COMMENT '影片',
  `pricing_rule_id` BIGINT NULL COMMENT '应用的票价策略快照来源',
  `starts_at` DATETIME(3) NOT NULL COMMENT '开场时间',
  `ends_at` DATETIME(3) NOT NULL COMMENT '影片结束时间',
  `hall_release_at` DATETIME(3) NOT NULL COMMENT '清场结束；排片冲突区间上界',
  `sale_starts_at` DATETIME(3) NOT NULL COMMENT '开始售票时间',
  `sale_ends_at` DATETIME(3) NOT NULL COMMENT '停止售票时间',
  `base_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '场次基础票价',
  `audio_language` VARCHAR(64) NOT NULL COMMENT '放映语言',
  `projection_format` VARCHAR(32) NOT NULL COMMENT '2D/3D/IMAX等',
  `layout_version` INT NOT NULL DEFAULT 1 COMMENT '生成库存时的影厅布局版本',
  `status` VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '场次状态；DRAFT/ON_SALE/STOPPED/FINISHED/CANCELLED',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cinema_screening_uk_1` (`id`, `cinema_id`),
  UNIQUE KEY `cinema_screening_uk_2` (`id`, `cinema_id`, `hall_id`),
  UNIQUE KEY `cinema_screening_uk_3` (`id`, `cinema_id`, `film_id`),
  CONSTRAINT `cinema_screening_fk_4` FOREIGN KEY (`hall_id`, `cinema_id`) REFERENCES `cinema_hall` (`id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_screening_fk_5` FOREIGN KEY (`cinema_id`, `film_id`) REFERENCES `cinema_film` (`cinema_id`, `film_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_screening_fk_6` FOREIGN KEY (`pricing_rule_id`, `cinema_id`) REFERENCES `cinema_pricing_rule` (`id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `cinema_screening_ix_7` (`film_id`, `status`, `starts_at`),
  KEY `cinema_screening_ix_8` (`cinema_id`, `status`, `starts_at`),
  KEY `cinema_screening_ix_9` (`hall_id`, `starts_at`, `hall_release_at`),
  CONSTRAINT `cinema_screening_ck_10` CHECK (ends_at > starts_at AND hall_release_at >= ends_at),
  CONSTRAINT `cinema_screening_ck_11` CHECK (sale_starts_at < sale_ends_at AND sale_ends_at <= starts_at),
  CONSTRAINT `cinema_screening_ck_12` CHECK (base_price > 0 AND layout_version > 0 AND version >= 0),
  CONSTRAINT `cinema_screening_ck_13` CHECK (`status` IN ('DRAFT', 'ON_SALE', 'STOPPED', 'FINISHED', 'CANCELLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='放映场次';

-- 交易票务 / 临时锁座批次
CREATE TABLE `seat_hold` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `hold_no` VARCHAR(40) NOT NULL COMMENT '对外锁座批次号',
  `user_id` BIGINT NOT NULL COMMENT '锁座用户',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `screening_id` BIGINT NOT NULL COMMENT '场次',
  `token_hash` VARCHAR(64) COLLATE utf8mb4_bin NOT NULL COMMENT '锁座凭证SHA-256摘要；原文只交给持有人',
  `expires_at` DATETIME(3) NOT NULL COMMENT '锁座绝对过期时间',
  `status` VARCHAR(24) NOT NULL DEFAULT 'HELD' COMMENT '锁座状态；HELD/ORDERED/CONSUMED/RELEASED/EXPIRED',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `seat_hold_uk_1` (`hold_no`),
  UNIQUE KEY `seat_hold_uk_2` (`token_hash`),
  UNIQUE KEY `seat_hold_uk_3` (`id`, `screening_id`, `cinema_id`),
  UNIQUE KEY `seat_hold_uk_4` (`id`, `user_id`, `screening_id`, `cinema_id`),
  CONSTRAINT `seat_hold_fk_5` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `seat_hold_fk_6` FOREIGN KEY (`screening_id`, `cinema_id`) REFERENCES `cinema_screening` (`id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `seat_hold_ix_7` (`status`, `expires_at`),
  CONSTRAINT `seat_hold_ck_8` CHECK (version >= 0),
  CONSTRAINT `seat_hold_ck_9` CHECK (`status` IN ('HELD', 'ORDERED', 'CONSUMED', 'RELEASED', 'EXPIRED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='临时锁座批次';

-- 交易票务 / 场次座位库存
CREATE TABLE `screening_seat` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `screening_id` BIGINT NOT NULL COMMENT '场次',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `hall_id` BIGINT NOT NULL COMMENT '影厅',
  `seat_id` BIGINT NOT NULL COMMENT '物理座位',
  `seat_label_snapshot` VARCHAR(32) NOT NULL COMMENT '场次创建时的座位名称',
  `row_no_snapshot` INT NOT NULL DEFAULT 1 COMMENT '行号快照',
  `column_no_snapshot` INT NOT NULL DEFAULT 1 COMMENT '列号快照',
  `sale_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '本场次该座位含加价的销售基础价',
  `status` VARCHAR(24) NOT NULL DEFAULT 'AVAILABLE' COMMENT '库存状态；AVAILABLE/LOCKED/SOLD/DISABLED',
  `active_hold_id` BIGINT NULL COMMENT '当前锁座批次；仅LOCKED非空',
  `locked_until` DATETIME(3) NULL COMMENT '锁定截止时间；仅LOCKED非空',
  `sold_order_item_id` BIGINT NULL COMMENT '当前有效售出的订单明细；仅SOLD非空',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `screening_seat_uk_1` (`screening_id`, `seat_id`),
  UNIQUE KEY `screening_seat_uk_2` (`id`, `screening_id`, `cinema_id`, `seat_id`),
  CONSTRAINT `screening_seat_fk_3` FOREIGN KEY (`screening_id`, `cinema_id`, `hall_id`) REFERENCES `cinema_screening` (`id`, `cinema_id`, `hall_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `screening_seat_fk_4` FOREIGN KEY (`seat_id`, `cinema_id`, `hall_id`) REFERENCES `cinema_seat` (`id`, `cinema_id`, `hall_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `screening_seat_fk_5` FOREIGN KEY (`active_hold_id`, `screening_id`, `cinema_id`) REFERENCES `seat_hold` (`id`, `screening_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `screening_seat_ix_6` (`screening_id`, `status`),
  KEY `screening_seat_ix_7` (`status`, `locked_until`),
  CONSTRAINT `screening_seat_ck_8` CHECK (sale_price >= 0 AND version >= 0 AND row_no_snapshot > 0 AND column_no_snapshot > 0),
  CONSTRAINT `screening_seat_ck_9` CHECK ((status = 'LOCKED' AND active_hold_id IS NOT NULL AND locked_until IS NOT NULL AND sold_order_item_id IS NULL) OR (status = 'SOLD' AND sold_order_item_id IS NOT NULL AND active_hold_id IS NULL AND locked_until IS NULL) OR (status IN ('AVAILABLE','DISABLED') AND active_hold_id IS NULL AND locked_until IS NULL AND sold_order_item_id IS NULL)),
  CONSTRAINT `screening_seat_ck_10` CHECK (`status` IN ('AVAILABLE', 'LOCKED', 'SOLD', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='场次座位库存';

-- 交易票务 / 锁座批次明细
CREATE TABLE `seat_hold_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `hold_id` BIGINT NOT NULL COMMENT '锁座批次',
  `screening_id` BIGINT NOT NULL COMMENT '场次',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `screening_seat_id` BIGINT NOT NULL COMMENT '场次库存',
  `seat_id` BIGINT NOT NULL COMMENT '物理座位',
  `price_snapshot` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '锁座时票价快照',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `seat_hold_item_uk_1` (`hold_id`, `screening_seat_id`),
  CONSTRAINT `seat_hold_item_fk_2` FOREIGN KEY (`hold_id`, `screening_id`, `cinema_id`) REFERENCES `seat_hold` (`id`, `screening_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `seat_hold_item_fk_3` FOREIGN KEY (`screening_seat_id`, `screening_id`, `cinema_id`, `seat_id`) REFERENCES `screening_seat` (`id`, `screening_id`, `cinema_id`, `seat_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `seat_hold_item_ck_4` CHECK (price_snapshot >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='锁座批次明细';

-- 交易票务 / 购票订单
CREATE TABLE `ticket_order` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `order_no` VARCHAR(40) NOT NULL COMMENT '对外订单号',
  `user_id` BIGINT NOT NULL COMMENT '购票用户',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `screening_id` BIGINT NOT NULL COMMENT '场次',
  `film_id` BIGINT NOT NULL COMMENT '影片',
  `hold_id` BIGINT NOT NULL COMMENT '对应锁座批次；一批次只生成一单',
  `ticket_count` INT NOT NULL DEFAULT 1 COMMENT '购买张数',
  `original_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '原价合计',
  `discount_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '优惠合计',
  `payable_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '应付合计',
  `paid_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '实际认领的已支付金额',
  `refunded_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '已成功退款金额',
  `settled_payment_id` BIGINT NULL COMMENT '被本订单认领的支付记录',
  `status` VARCHAR(24) NOT NULL DEFAULT 'UNPAID' COMMENT '订单主状态；UNPAID/PAID/CANCELLED/EXPIRED/COMPLETED',
  `expires_at` DATETIME(3) NOT NULL COMMENT '支付截止；不得晚于锁座到期',
  `paid_at` DATETIME(3) NULL COMMENT '认领支付时间',
  `closed_at` DATETIME(3) NULL COMMENT '关闭时间',
  `film_name_snapshot` VARCHAR(160) NOT NULL COMMENT '影片名称快照',
  `cinema_name_snapshot` VARCHAR(120) NOT NULL COMMENT '影院名称快照',
  `hall_name_snapshot` VARCHAR(64) NOT NULL COMMENT '影厅名称快照',
  `starts_at_snapshot` DATETIME(3) NOT NULL COMMENT '开场时间快照',
  `refund_cutoff_snapshot` INT NOT NULL DEFAULT 60 COMMENT '退票截止提前分钟快照',
  `change_cutoff_snapshot` INT NOT NULL DEFAULT 60 COMMENT '改签截止提前分钟快照',
  `refund_fee_rate_snapshot` DECIMAL(5,4) NOT NULL DEFAULT 0 COMMENT '退款手续费率快照',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ticket_order_uk_1` (`order_no`),
  UNIQUE KEY `ticket_order_uk_2` (`hold_id`),
  UNIQUE KEY `ticket_order_uk_3` (`settled_payment_id`),
  UNIQUE KEY `ticket_order_uk_4` (`id`, `user_id`, `cinema_id`, `screening_id`, `film_id`),
  UNIQUE KEY `ticket_order_uk_5` (`id`, `user_id`, `cinema_id`),
  UNIQUE KEY `ticket_order_uk_6` (`id`, `cinema_id`),
  CONSTRAINT `ticket_order_fk_7` FOREIGN KEY (`hold_id`, `user_id`, `screening_id`, `cinema_id`) REFERENCES `seat_hold` (`id`, `user_id`, `screening_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ticket_order_fk_8` FOREIGN KEY (`screening_id`, `cinema_id`, `film_id`) REFERENCES `cinema_screening` (`id`, `cinema_id`, `film_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `ticket_order_ix_9` (`user_id`, `created_at`),
  KEY `ticket_order_ix_10` (`cinema_id`, `status`, `created_at`),
  KEY `ticket_order_ix_11` (`status`, `expires_at`),
  KEY `ticket_order_ix_12` (`cinema_id`, `paid_at`),
  CONSTRAINT `ticket_order_ck_13` CHECK (ticket_count > 0 AND original_amount >= 0 AND discount_amount >= 0 AND payable_amount >= 0 AND original_amount = discount_amount + payable_amount),
  CONSTRAINT `ticket_order_ck_14` CHECK (paid_amount >= 0 AND paid_amount <= payable_amount AND refunded_amount >= 0 AND refunded_amount <= paid_amount),
  CONSTRAINT `ticket_order_ck_15` CHECK ((paid_amount = 0 AND settled_payment_id IS NULL) OR (paid_amount > 0 AND settled_payment_id IS NOT NULL)),
  CONSTRAINT `ticket_order_ck_16` CHECK (refund_cutoff_snapshot >= 0 AND change_cutoff_snapshot >= 0 AND refund_fee_rate_snapshot BETWEEN 0 AND 1 AND version >= 0),
  CONSTRAINT `ticket_order_ck_17` CHECK (`status` IN ('UNPAID', 'PAID', 'CANCELLED', 'EXPIRED', 'COMPLETED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='购票订单';

-- 交易票务 / 订单座位明细
CREATE TABLE `ticket_order_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `order_id` BIGINT NOT NULL COMMENT '订单',
  `user_id` BIGINT NOT NULL COMMENT '用户',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `screening_id` BIGINT NOT NULL COMMENT '场次',
  `film_id` BIGINT NOT NULL COMMENT '影片',
  `screening_seat_id` BIGINT NOT NULL COMMENT '场次库存',
  `seat_id` BIGINT NOT NULL COMMENT '物理座位',
  `seat_label_snapshot` VARCHAR(32) NOT NULL COMMENT '座位名称快照',
  `original_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '本票原价',
  `discount_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '分摊优惠额',
  `payable_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '本票应付',
  `refunded_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '本票成功退款累计',
  `status` VARCHAR(24) NOT NULL DEFAULT 'UNPAID' COMMENT '票明细状态；UNPAID/VALID/VERIFIED/REFUNDED/EXCHANGED/CANCELLED',
  `active_screening_seat_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status IN ('UNPAID','VALID','VERIFIED') THEN screening_seat_id ELSE NULL END) STORED COMMENT '同一场次库存至多一条待支付或有效售票明细；历史退改记录允许保留',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ticket_order_item_uk_1` (`order_id`, `screening_seat_id`),
  UNIQUE KEY `ticket_order_item_uk_2` (`active_screening_seat_id`),
  UNIQUE KEY `ticket_order_item_uk_3` (`id`, `screening_seat_id`),
  UNIQUE KEY `ticket_order_item_uk_4` (`id`, `order_id`, `cinema_id`),
  UNIQUE KEY `ticket_order_item_uk_5` (`id`, `user_id`, `film_id`, `cinema_id`),
  UNIQUE KEY `ticket_order_item_uk_6` (`id`, `user_id`, `cinema_id`, `screening_id`),
  CONSTRAINT `ticket_order_item_fk_7` FOREIGN KEY (`order_id`, `user_id`, `cinema_id`, `screening_id`, `film_id`) REFERENCES `ticket_order` (`id`, `user_id`, `cinema_id`, `screening_id`, `film_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ticket_order_item_fk_8` FOREIGN KEY (`screening_seat_id`, `screening_id`, `cinema_id`, `seat_id`) REFERENCES `screening_seat` (`id`, `screening_id`, `cinema_id`, `seat_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `ticket_order_item_ix_9` (`cinema_id`, `screening_id`, `status`),
  CONSTRAINT `ticket_order_item_ck_10` CHECK (original_amount >= 0 AND discount_amount >= 0 AND payable_amount >= 0 AND original_amount = discount_amount + payable_amount AND refunded_amount >= 0 AND refunded_amount <= payable_amount),
  CONSTRAINT `ticket_order_item_ck_11` CHECK (`status` IN ('UNPAID', 'VALID', 'VERIFIED', 'REFUNDED', 'EXCHANGED', 'CANCELLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='订单座位明细';

-- 交易票务 / 支付尝试与渠道流水
CREATE TABLE `payment_transaction` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `payment_no` VARCHAR(40) NOT NULL COMMENT '平台支付流水号',
  `order_id` BIGINT NOT NULL COMMENT '订单',
  `provider` VARCHAR(24) NOT NULL DEFAULT 'MOCK' COMMENT '支付渠道；MOCK只用于毕设沙箱；MOCK/WECHAT/ALIPAY',
  `provider_trade_no` VARCHAR(128) COLLATE utf8mb4_bin NULL COMMENT '渠道交易号；未返回为NULL',
  `idempotency_key` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL COMMENT '创建支付请求幂等键',
  `amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '支付金额',
  `status` VARCHAR(24) NOT NULL DEFAULT 'CREATED' COMMENT '支付状态；CREATED/PENDING/SUCCESS/FAILED/CLOSED',
  `succeeded_at` DATETIME(3) NULL COMMENT '渠道成功时间',
  `failure_reason` VARCHAR(500) NULL COMMENT '失败原因',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `payment_transaction_uk_1` (`payment_no`),
  UNIQUE KEY `payment_transaction_uk_2` (`provider`, `provider_trade_no`),
  UNIQUE KEY `payment_transaction_uk_3` (`idempotency_key`),
  UNIQUE KEY `payment_transaction_uk_4` (`id`, `order_id`),
  UNIQUE KEY `payment_transaction_uk_5` (`id`, `order_id`, `provider`),
  CONSTRAINT `payment_transaction_fk_6` FOREIGN KEY (`order_id`) REFERENCES `ticket_order` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `payment_transaction_ix_7` (`order_id`, `status`),
  CONSTRAINT `payment_transaction_ck_8` CHECK (amount > 0),
  CONSTRAINT `payment_transaction_ck_9` CHECK (`provider` IN ('MOCK', 'WECHAT', 'ALIPAY')),
  CONSTRAINT `payment_transaction_ck_10` CHECK (`status` IN ('CREATED', 'PENDING', 'SUCCESS', 'FAILED', 'CLOSED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='支付尝试与渠道流水';

-- 交易票务 / 支付退款回调收件箱
CREATE TABLE `payment_callback_event` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `provider` VARCHAR(24) NOT NULL DEFAULT 'MOCK' COMMENT '渠道；MOCK/WECHAT/ALIPAY',
  `provider_event_id` VARCHAR(128) COLLATE utf8mb4_bin NOT NULL COMMENT '渠道事件唯一编号',
  `event_type` VARCHAR(24) NOT NULL DEFAULT 'PAYMENT' COMMENT '事件类型；PAYMENT/REFUND',
  `business_no` VARCHAR(64) NOT NULL COMMENT '支付或退款商户单号',
  `payload_hash` VARCHAR(64) COLLATE utf8mb4_bin NOT NULL COMMENT '回调体摘要',
  `sanitized_payload` JSON NULL COMMENT '验签后脱敏回调；不保留密钥、完整证件号等',
  `status` VARCHAR(24) NOT NULL DEFAULT 'RECEIVED' COMMENT '处理状态；RECEIVED/PROCESSED/RETRY/REJECTED',
  `retry_count` INT NOT NULL DEFAULT 0 COMMENT '重试次数',
  `processed_at` DATETIME(3) NULL COMMENT '处理完成时间',
  `last_error` VARCHAR(500) NULL COMMENT '最近错误',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `payment_callback_event_uk_1` (`provider`, `provider_event_id`),
  KEY `payment_callback_event_ix_2` (`status`, `created_at`),
  CONSTRAINT `payment_callback_event_ck_3` CHECK (retry_count >= 0),
  CONSTRAINT `payment_callback_event_ck_4` CHECK (`provider` IN ('MOCK', 'WECHAT', 'ALIPAY')),
  CONSTRAINT `payment_callback_event_ck_5` CHECK (`event_type` IN ('PAYMENT', 'REFUND')),
  CONSTRAINT `payment_callback_event_ck_6` CHECK (`status` IN ('RECEIVED', 'PROCESSED', 'RETRY', 'REJECTED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='支付退款回调收件箱';

-- 交易票务 / 电子票
CREATE TABLE `ticket` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `ticket_no` VARCHAR(40) NOT NULL COMMENT '电子票编号',
  `order_item_id` BIGINT NOT NULL COMMENT '订单明细；一条明细一张电子票',
  `user_id` BIGINT NOT NULL COMMENT '持票用户',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `screening_id` BIGINT NOT NULL COMMENT '场次',
  `status` VARCHAR(24) NOT NULL DEFAULT 'VALID' COMMENT '电子票状态；VALID/VERIFIED/FROZEN/REFUNDED/EXCHANGED/VOID',
  `qr_version` INT NOT NULL DEFAULT 1 COMMENT '二维码凭证版本；冻结、退改时递增以撤销旧码',
  `verified_at` DATETIME(3) NULL COMMENT '成功核销时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ticket_uk_1` (`ticket_no`),
  UNIQUE KEY `ticket_uk_2` (`order_item_id`),
  UNIQUE KEY `ticket_uk_3` (`id`, `cinema_id`),
  CONSTRAINT `ticket_fk_4` FOREIGN KEY (`order_item_id`, `user_id`, `cinema_id`, `screening_id`) REFERENCES `ticket_order_item` (`id`, `user_id`, `cinema_id`, `screening_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `ticket_ix_5` (`user_id`, `status`),
  CONSTRAINT `ticket_ck_6` CHECK (qr_version > 0),
  CONSTRAINT `ticket_ck_7` CHECK (`status` IN ('VALID', 'VERIFIED', 'FROZEN', 'REFUNDED', 'EXCHANGED', 'VOID'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='电子票';

-- 交易票务 / 动态验票凭证
CREATE TABLE `ticket_qr_token` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `ticket_id` BIGINT NOT NULL COMMENT '电子票',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `nonce_hash` VARCHAR(64) COLLATE utf8mb4_bin NOT NULL COMMENT '随机nonce的SHA-256摘要；禁止存明文动态码',
  `qr_version` INT NOT NULL DEFAULT 1 COMMENT '签发时电子票版本',
  `valid_from` DATETIME(3) NOT NULL COMMENT '生效时间',
  `expires_at` DATETIME(3) NOT NULL COMMENT '短时过期时间',
  `consumed_at` DATETIME(3) NULL COMMENT '消费时间；成功验票后赋值',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ticket_qr_token_uk_1` (`nonce_hash`),
  UNIQUE KEY `ticket_qr_token_uk_2` (`id`, `ticket_id`, `cinema_id`),
  CONSTRAINT `ticket_qr_token_fk_3` FOREIGN KEY (`ticket_id`, `cinema_id`) REFERENCES `ticket` (`id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `ticket_qr_token_ix_4` (`ticket_id`, `expires_at`),
  KEY `ticket_qr_token_ix_5` (`expires_at`),
  CONSTRAINT `ticket_qr_token_ck_6` CHECK (expires_at > valid_from AND qr_version > 0),
  CONSTRAINT `ticket_qr_token_ck_7` CHECK (consumed_at IS NULL OR (consumed_at >= valid_from AND consumed_at < expires_at))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='动态验票凭证';

-- 交易票务 / 验票核销日志
CREATE TABLE `ticket_verification_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `cinema_id` BIGINT NOT NULL COMMENT '扫码影院',
  `operator_id` BIGINT NOT NULL COMMENT '验票工作人员',
  `ticket_id` BIGINT NULL COMMENT '识别到的电子票；未知票可为NULL',
  `qr_token_id` BIGINT NULL COMMENT '识别到的二维码凭证',
  `presented_token_hash` VARCHAR(64) COLLATE utf8mb4_bin NULL COMMENT '呈现凭证摘要，仅用于审计',
  `result` VARCHAR(24) NOT NULL DEFAULT 'SUCCESS' COMMENT '验票结果；SUCCESS/INVALID/EXPIRED/USED/WRONG_CINEMA/FROZEN',
  `reason` VARCHAR(255) NULL COMMENT '结果说明',
  `success_ticket_id` BIGINT GENERATED ALWAYS AS (CASE WHEN result = 'SUCCESS' THEN ticket_id ELSE NULL END) STORED COMMENT '一张电子票仅一条成功核销记录',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ticket_verification_log_uk_1` (`success_ticket_id`),
  CONSTRAINT `ticket_verification_log_fk_2` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ticket_verification_log_fk_3` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ticket_verification_log_fk_4` FOREIGN KEY (`ticket_id`, `cinema_id`) REFERENCES `ticket` (`id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ticket_verification_log_fk_5` FOREIGN KEY (`qr_token_id`, `ticket_id`, `cinema_id`) REFERENCES `ticket_qr_token` (`id`, `ticket_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `ticket_verification_log_ix_6` (`cinema_id`, `created_at`),
  CONSTRAINT `ticket_verification_log_ck_7` CHECK (result <> 'SUCCESS' OR (ticket_id IS NOT NULL AND qr_token_id IS NOT NULL)),
  CONSTRAINT `ticket_verification_log_ck_8` CHECK (`result` IN ('SUCCESS', 'INVALID', 'EXPIRED', 'USED', 'WRONG_CINEMA', 'FROZEN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='验票核销日志';

-- 交易票务 / 退票改签申请
CREATE TABLE `after_sale_request` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `request_no` VARCHAR(40) NOT NULL COMMENT '申请单号',
  `request_type` VARCHAR(24) NOT NULL DEFAULT 'REFUND' COMMENT '类型；REFUND/CHANGE',
  `original_order_id` BIGINT NOT NULL COMMENT '原订单',
  `user_id` BIGINT NOT NULL COMMENT '申请人',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `target_screening_id` BIGINT NULL COMMENT '改签目标场次；退款为NULL',
  `new_order_id` BIGINT NULL COMMENT '改签生成的新订单；原单永不覆盖',
  `reason` VARCHAR(500) NOT NULL COMMENT '申请理由',
  `requested_refund` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '申请退款金额',
  `fee_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '退改手续费',
  `price_difference` DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '改签差价；正数补款，负数退差',
  `status` VARCHAR(24) NOT NULL DEFAULT 'PENDING' COMMENT '审批与执行状态；PENDING/APPROVED/REJECTED/PROCESSING/COMPLETED/CANCELLED/FAILED',
  `reviewer_id` BIGINT NULL COMMENT '审核管理员',
  `reviewed_at` DATETIME(3) NULL COMMENT '审核时间',
  `review_remark` VARCHAR(500) NULL COMMENT '审批说明',
  `completed_at` DATETIME(3) NULL COMMENT '完成时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `after_sale_request_uk_1` (`request_no`),
  UNIQUE KEY `after_sale_request_uk_2` (`new_order_id`),
  UNIQUE KEY `after_sale_request_uk_3` (`id`, `original_order_id`, `cinema_id`),
  UNIQUE KEY `after_sale_request_uk_4` (`id`, `new_order_id`, `cinema_id`),
  CONSTRAINT `after_sale_request_fk_5` FOREIGN KEY (`original_order_id`, `user_id`, `cinema_id`) REFERENCES `ticket_order` (`id`, `user_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `after_sale_request_fk_6` FOREIGN KEY (`new_order_id`, `user_id`, `cinema_id`) REFERENCES `ticket_order` (`id`, `user_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `after_sale_request_fk_7` FOREIGN KEY (`target_screening_id`, `cinema_id`) REFERENCES `cinema_screening` (`id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `after_sale_request_fk_8` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `after_sale_request_ix_9` (`cinema_id`, `status`, `created_at`),
  CONSTRAINT `after_sale_request_ck_10` CHECK (requested_refund >= 0 AND fee_amount >= 0),
  CONSTRAINT `after_sale_request_ck_11` CHECK ((request_type = 'REFUND' AND target_screening_id IS NULL AND new_order_id IS NULL AND price_difference = 0) OR (request_type = 'CHANGE' AND target_screening_id IS NOT NULL)),
  CONSTRAINT `after_sale_request_ck_12` CHECK (new_order_id IS NULL OR new_order_id <> original_order_id),
  CONSTRAINT `after_sale_request_ck_13` CHECK (`request_type` IN ('REFUND', 'CHANGE')),
  CONSTRAINT `after_sale_request_ck_14` CHECK (`status` IN ('PENDING', 'APPROVED', 'REJECTED', 'PROCESSING', 'COMPLETED', 'CANCELLED', 'FAILED')),
  UNIQUE KEY `after_sale_request_uk_15` (`id`, `original_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='退票改签申请';

-- 交易票务 / 退改座位明细
CREATE TABLE `after_sale_item` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `request_id` BIGINT NOT NULL COMMENT '申请单',
  `original_order_id` BIGINT NOT NULL COMMENT '原订单',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `original_order_item_id` BIGINT NOT NULL COMMENT '原票明细',
  `new_order_id` BIGINT NULL COMMENT '改签新订单；须与申请一致',
  `new_order_item_id` BIGINT NULL COMMENT '改签后新票明细',
  `refund_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '本票申请退还金额',
  `fee_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '本票手续费',
  `released_at` DATETIME(3) NULL COMMENT '处理终结并解除退改占用的时间',
  `active_order_item_id` BIGINT GENERATED ALWAYS AS (CASE WHEN released_at IS NULL THEN original_order_item_id ELSE NULL END) STORED COMMENT '每张原票最多一个在途退改申请',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `after_sale_item_uk_1` (`request_id`, `original_order_item_id`),
  UNIQUE KEY `after_sale_item_uk_2` (`active_order_item_id`),
  CONSTRAINT `after_sale_item_fk_3` FOREIGN KEY (`request_id`, `original_order_id`, `cinema_id`) REFERENCES `after_sale_request` (`id`, `original_order_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `after_sale_item_fk_4` FOREIGN KEY (`original_order_item_id`, `original_order_id`, `cinema_id`) REFERENCES `ticket_order_item` (`id`, `order_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `after_sale_item_fk_5` FOREIGN KEY (`request_id`, `new_order_id`, `cinema_id`) REFERENCES `after_sale_request` (`id`, `new_order_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `after_sale_item_fk_6` FOREIGN KEY (`new_order_item_id`, `new_order_id`, `cinema_id`) REFERENCES `ticket_order_item` (`id`, `order_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `after_sale_item_ck_7` CHECK (refund_amount >= 0 AND fee_amount >= 0),
  CONSTRAINT `after_sale_item_ck_8` CHECK ((new_order_id IS NULL AND new_order_item_id IS NULL) OR (new_order_id IS NOT NULL AND new_order_item_id IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='退改座位明细';

-- 交易票务 / 退款渠道流水
CREATE TABLE `payment_refund` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `refund_no` VARCHAR(40) NOT NULL COMMENT '平台退款单号',
  `order_id` BIGINT NOT NULL COMMENT '订单',
  `payment_id` BIGINT NOT NULL COMMENT '原支付记录',
  `provider` VARCHAR(24) NOT NULL DEFAULT 'MOCK' COMMENT '原支付渠道；MOCK/WECHAT/ALIPAY',
  `after_sale_request_id` BIGINT NULL COMMENT '关联退改申请；迟到或重复支付退款为NULL',
  `refund_reason` VARCHAR(24) NOT NULL DEFAULT 'AFTER_SALE' COMMENT '退款原因；AFTER_SALE/LATE_PAYMENT/DUPLICATE_PAYMENT/SYSTEM_CANCEL',
  `provider_refund_no` VARCHAR(128) COLLATE utf8mb4_bin NULL COMMENT '渠道退款号',
  `idempotency_key` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL COMMENT '退款幂等键',
  `amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '退款金额',
  `status` VARCHAR(24) NOT NULL DEFAULT 'CREATED' COMMENT '退款状态；CREATED/PENDING/SUCCESS/FAILED',
  `succeeded_at` DATETIME(3) NULL COMMENT '退款成功时间',
  `failure_reason` VARCHAR(500) NULL COMMENT '失败原因',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `payment_refund_uk_1` (`refund_no`),
  UNIQUE KEY `payment_refund_uk_2` (`provider`, `provider_refund_no`),
  UNIQUE KEY `payment_refund_uk_3` (`idempotency_key`),
  CONSTRAINT `payment_refund_fk_4` FOREIGN KEY (`payment_id`, `order_id`, `provider`) REFERENCES `payment_transaction` (`id`, `order_id`, `provider`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `payment_refund_fk_5` FOREIGN KEY (`after_sale_request_id`, `order_id`) REFERENCES `after_sale_request` (`id`, `original_order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `payment_refund_ix_6` (`order_id`, `status`),
  KEY `payment_refund_ix_7` (`status`, `created_at`),
  CONSTRAINT `payment_refund_ck_8` CHECK (amount > 0),
  CONSTRAINT `payment_refund_ck_9` CHECK ((refund_reason = 'AFTER_SALE' AND after_sale_request_id IS NOT NULL) OR (refund_reason <> 'AFTER_SALE' AND after_sale_request_id IS NULL)),
  CONSTRAINT `payment_refund_ck_10` CHECK (`provider` IN ('MOCK', 'WECHAT', 'ALIPAY')),
  CONSTRAINT `payment_refund_ck_11` CHECK (`refund_reason` IN ('AFTER_SALE', 'LATE_PAYMENT', 'DUPLICATE_PAYMENT', 'SYSTEM_CANCEL')),
  CONSTRAINT `payment_refund_ck_12` CHECK (`status` IN ('CREATED', 'PENDING', 'SUCCESS', 'FAILED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='退款渠道流水';

-- 交易票务 / 订单状态流转日志
CREATE TABLE `order_status_history` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `order_id` BIGINT NOT NULL COMMENT '订单',
  `from_status` VARCHAR(32) NULL COMMENT '原状态；创建为NULL',
  `to_status` VARCHAR(32) NOT NULL COMMENT '新状态',
  `operator_id` BIGINT NULL COMMENT '操作人；系统任务为NULL',
  `reason` VARCHAR(500) NOT NULL COMMENT '变更原因',
  `request_id` VARCHAR(64) NULL COMMENT '请求追踪号',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `order_status_history_fk_1` FOREIGN KEY (`order_id`) REFERENCES `ticket_order` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `order_status_history_fk_2` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `order_status_history_ix_3` (`order_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='订单状态流转日志';

-- 会员营销 / 影片收藏
CREATE TABLE `user_favorite_film` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `user_id` BIGINT NOT NULL COMMENT '用户',
  `film_id` BIGINT NOT NULL COMMENT '影片',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_favorite_film_uk_1` (`user_id`, `film_id`),
  CONSTRAINT `user_favorite_film_fk_2` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `user_favorite_film_fk_3` FOREIGN KEY (`film_id`) REFERENCES `film` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影片收藏';

-- 会员营销 / 平台会员账户
CREATE TABLE `member_account` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `user_id` BIGINT NOT NULL COMMENT '会员用户',
  `member_no` VARCHAR(40) NOT NULL COMMENT '会员号',
  `level_id` BIGINT NOT NULL COMMENT '当前会员等级',
  `points_balance` BIGINT NOT NULL DEFAULT 0 COMMENT '可用积分',
  `growth_value` BIGINT NOT NULL DEFAULT 0 COMMENT '成长值',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态；ACTIVE/FROZEN',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `member_account_uk_1` (`user_id`),
  UNIQUE KEY `member_account_uk_2` (`member_no`),
  CONSTRAINT `member_account_fk_3` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `member_account_fk_4` FOREIGN KEY (`level_id`) REFERENCES `member_level` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `member_account_ck_5` CHECK (points_balance >= 0 AND growth_value >= 0 AND version >= 0),
  CONSTRAINT `member_account_ck_6` CHECK (`status` IN ('ACTIVE', 'FROZEN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='平台会员账户';

-- 会员营销 / 积分收支流水
CREATE TABLE `member_points_ledger` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `member_account_id` BIGINT NOT NULL COMMENT '会员账户',
  `points_delta` BIGINT NOT NULL COMMENT '积分变化；增加为正、扣减为负',
  `balance_after` BIGINT NOT NULL DEFAULT 0 COMMENT '变化后余额',
  `source_type` VARCHAR(32) NOT NULL COMMENT '来源：ORDER/REFUND/ACTIVITY/ADJUST等',
  `source_no` VARCHAR(64) NOT NULL COMMENT '来源业务号',
  `idempotency_key` VARCHAR(96) COLLATE utf8mb4_bin NOT NULL COMMENT '积分事件幂等键',
  `remark` VARCHAR(255) NULL COMMENT '说明',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `member_points_ledger_uk_1` (`idempotency_key`),
  CONSTRAINT `member_points_ledger_fk_2` FOREIGN KEY (`member_account_id`) REFERENCES `member_account` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `member_points_ledger_ix_3` (`member_account_id`, `created_at`),
  CONSTRAINT `member_points_ledger_ck_4` CHECK (points_delta <> 0 AND balance_after >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='积分收支流水';

-- 会员营销 / 本院会员关系
CREATE TABLE `cinema_member` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `user_id` BIGINT NOT NULL COMMENT '用户',
  `member_no` VARCHAR(40) NOT NULL COMMENT '本院会员号',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态；ACTIVE/FROZEN',
  `total_net_spend` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '本院净消费派生值',
  `visit_count` INT NOT NULL DEFAULT 0 COMMENT '本院已核销观影次数',
  `last_visit_at` DATETIME(3) NULL COMMENT '最近观影时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cinema_member_uk_1` (`cinema_id`, `user_id`),
  UNIQUE KEY `cinema_member_uk_2` (`cinema_id`, `member_no`),
  CONSTRAINT `cinema_member_fk_3` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_member_fk_4` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `cinema_member_ck_5` CHECK (total_net_spend >= 0 AND visit_count >= 0),
  CONSTRAINT `cinema_member_ck_6` CHECK (`status` IN ('ACTIVE', 'FROZEN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='本院会员关系';

-- 会员营销 / 优惠券模板
CREATE TABLE `coupon_template` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `coupon_name` VARCHAR(100) NOT NULL COMMENT '名称',
  `scope_type` VARCHAR(24) NOT NULL DEFAULT 'PLATFORM' COMMENT '适用范围；PLATFORM/CINEMA',
  `cinema_id` BIGINT NULL COMMENT '限定影院；平台券为NULL',
  `discount_type` VARCHAR(24) NOT NULL DEFAULT 'FIXED' COMMENT '满减或折扣；FIXED/RATE',
  `minimum_spend` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '最低原价门槛',
  `fixed_discount` DECIMAL(10,2) NULL COMMENT '满减金额',
  `discount_rate` DECIMAL(5,4) NULL COMMENT '支付比例；0.8表示八折',
  `max_discount` DECIMAL(10,2) NULL COMMENT '折扣券优惠上限',
  `claim_starts_at` DATETIME(3) NOT NULL COMMENT '领券开始',
  `claim_ends_at` DATETIME(3) NOT NULL COMMENT '领券结束',
  `valid_from` DATETIME(3) NOT NULL COMMENT '使用开始',
  `valid_to` DATETIME(3) NOT NULL COMMENT '使用结束',
  `total_quantity` INT NOT NULL DEFAULT 100 COMMENT '总发行量',
  `issued_quantity` INT NOT NULL DEFAULT 0 COMMENT '已发行量',
  `per_user_limit` INT NOT NULL DEFAULT 1 COMMENT '单人领取上限',
  `status` VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '模板状态；DRAFT/ACTIVE/DISABLED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `coupon_template_fk_1` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `coupon_template_ix_2` (`scope_type`, `cinema_id`, `status`),
  CONSTRAINT `coupon_template_ck_3` CHECK ((scope_type = 'PLATFORM' AND cinema_id IS NULL) OR (scope_type = 'CINEMA' AND cinema_id IS NOT NULL)),
  CONSTRAINT `coupon_template_ck_4` CHECK ((discount_type = 'FIXED' AND fixed_discount IS NOT NULL AND fixed_discount > 0 AND discount_rate IS NULL AND max_discount IS NULL) OR (discount_type = 'RATE' AND discount_rate IS NOT NULL AND discount_rate > 0 AND discount_rate < 1 AND fixed_discount IS NULL AND (max_discount IS NULL OR max_discount > 0))),
  CONSTRAINT `coupon_template_ck_5` CHECK (minimum_spend >= 0 AND claim_ends_at > claim_starts_at AND valid_to > valid_from AND claim_starts_at <= valid_to),
  CONSTRAINT `coupon_template_ck_6` CHECK (total_quantity >= 0 AND issued_quantity BETWEEN 0 AND total_quantity AND per_user_limit > 0),
  CONSTRAINT `coupon_template_ck_7` CHECK (`scope_type` IN ('PLATFORM', 'CINEMA')),
  CONSTRAINT `coupon_template_ck_8` CHECK (`discount_type` IN ('FIXED', 'RATE')),
  CONSTRAINT `coupon_template_ck_9` CHECK (`status` IN ('DRAFT', 'ACTIVE', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='优惠券模板';

-- 会员营销 / 用户领券记录
CREATE TABLE `user_coupon` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `coupon_no` VARCHAR(40) NOT NULL COMMENT '券实例编号',
  `template_id` BIGINT NOT NULL COMMENT '券模板',
  `user_id` BIGINT NOT NULL COMMENT '持有人',
  `valid_from` DATETIME(3) NOT NULL COMMENT '实际生效时间',
  `valid_to` DATETIME(3) NOT NULL COMMENT '实际失效时间',
  `status` VARCHAR(24) NOT NULL DEFAULT 'AVAILABLE' COMMENT '使用状态；AVAILABLE/LOCKED/USED/EXPIRED/VOID',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_coupon_uk_1` (`coupon_no`),
  UNIQUE KEY `user_coupon_uk_2` (`id`, `user_id`),
  CONSTRAINT `user_coupon_fk_3` FOREIGN KEY (`template_id`) REFERENCES `coupon_template` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `user_coupon_fk_4` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `user_coupon_ix_5` (`user_id`, `status`, `valid_to`),
  KEY `user_coupon_ix_6` (`template_id`, `user_id`),
  CONSTRAINT `user_coupon_ck_7` CHECK (valid_to > valid_from),
  CONSTRAINT `user_coupon_ck_8` CHECK (`status` IN ('AVAILABLE', 'LOCKED', 'USED', 'EXPIRED', 'VOID'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户领券记录';

-- 会员营销 / 优惠券订单占用流水
CREATE TABLE `coupon_usage` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `user_coupon_id` BIGINT NOT NULL COMMENT '用户券实例',
  `user_id` BIGINT NOT NULL COMMENT '持有人',
  `order_id` BIGINT NOT NULL COMMENT '购票订单',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `discount_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '实际抵扣金额',
  `status` VARCHAR(24) NOT NULL DEFAULT 'RESERVED' COMMENT '占用状态；RESERVED/USED/RELEASED',
  `active_coupon_id` BIGINT GENERATED ALWAYS AS (CASE WHEN status IN ('RESERVED','USED') THEN user_coupon_id ELSE NULL END) STORED COMMENT '一张券至多绑定一个在途或成功订单',
  `released_at` DATETIME(3) NULL COMMENT '释放时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `coupon_usage_uk_1` (`order_id`),
  UNIQUE KEY `coupon_usage_uk_2` (`active_coupon_id`),
  CONSTRAINT `coupon_usage_fk_3` FOREIGN KEY (`user_coupon_id`, `user_id`) REFERENCES `user_coupon` (`id`, `user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `coupon_usage_fk_4` FOREIGN KEY (`order_id`, `user_id`, `cinema_id`) REFERENCES `ticket_order` (`id`, `user_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `coupon_usage_ck_5` CHECK (discount_amount >= 0),
  CONSTRAINT `coupon_usage_ck_6` CHECK (`status` IN ('RESERVED', 'USED', 'RELEASED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='优惠券订单占用流水';

-- 会员营销 / 平台及影院公告
CREATE TABLE `announcement` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `scope_type` VARCHAR(24) NOT NULL DEFAULT 'PLATFORM' COMMENT '发布范围；PLATFORM/CINEMA',
  `cinema_id` BIGINT NULL COMMENT '发布影院；平台公告为NULL',
  `announcement_type` VARCHAR(24) NOT NULL DEFAULT 'SYSTEM' COMMENT '公告类别；SYSTEM/PROMOTION/LOST_FOUND',
  `title` VARCHAR(200) NOT NULL COMMENT '标题',
  `content` TEXT NOT NULL COMMENT '正文；展示前需清理危险HTML',
  `publisher_id` BIGINT NOT NULL COMMENT '发布人',
  `status` VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '发布状态；DRAFT/PUBLISHED/OFFLINE',
  `publish_at` DATETIME(3) NULL COMMENT '发布时间',
  `expires_at` DATETIME(3) NULL COMMENT '展示结束时间',
  `is_pinned` TINYINT NOT NULL DEFAULT 0 COMMENT '置顶标志',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `announcement_fk_1` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `announcement_fk_2` FOREIGN KEY (`publisher_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `announcement_ix_3` (`scope_type`, `cinema_id`, `status`, `publish_at`),
  CONSTRAINT `announcement_ck_4` CHECK ((scope_type = 'PLATFORM' AND cinema_id IS NULL) OR (scope_type = 'CINEMA' AND cinema_id IS NOT NULL)),
  CONSTRAINT `announcement_ck_5` CHECK (is_pinned IN (0,1)),
  CONSTRAINT `announcement_ck_6` CHECK (expires_at IS NULL OR publish_at IS NULL OR expires_at > publish_at),
  CONSTRAINT `announcement_ck_7` CHECK (`scope_type` IN ('PLATFORM', 'CINEMA')),
  CONSTRAINT `announcement_ck_8` CHECK (`announcement_type` IN ('SYSTEM', 'PROMOTION', 'LOST_FOUND')),
  CONSTRAINT `announcement_ck_9` CHECK (`status` IN ('DRAFT', 'PUBLISHED', 'OFFLINE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='平台及影院公告';

-- 会员营销 / 平台及门店活动
CREATE TABLE `marketing_activity` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `scope_type` VARCHAR(24) NOT NULL DEFAULT 'PLATFORM' COMMENT '活动范围；PLATFORM/CINEMA',
  `cinema_id` BIGINT NULL COMMENT '所属影院',
  `title` VARCHAR(160) NOT NULL COMMENT '活动名称',
  `description` TEXT NOT NULL COMMENT '活动说明',
  `publisher_id` BIGINT NOT NULL COMMENT '发布人',
  `reward_coupon_template_id` BIGINT NULL COMMENT '奖励券模板',
  `signup_starts_at` DATETIME(3) NOT NULL COMMENT '报名开始',
  `signup_ends_at` DATETIME(3) NOT NULL COMMENT '报名截止',
  `starts_at` DATETIME(3) NOT NULL COMMENT '活动开始',
  `ends_at` DATETIME(3) NOT NULL COMMENT '活动结束',
  `capacity` INT NOT NULL DEFAULT 0 COMMENT '名额上限，0表示不限',
  `registered_count` INT NOT NULL DEFAULT 0 COMMENT '当前报名人数派生值',
  `status` VARCHAR(24) NOT NULL DEFAULT 'DRAFT' COMMENT '状态；DRAFT/PUBLISHED/CLOSED/CANCELLED',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `marketing_activity_fk_1` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `marketing_activity_fk_2` FOREIGN KEY (`publisher_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `marketing_activity_fk_3` FOREIGN KEY (`reward_coupon_template_id`) REFERENCES `coupon_template` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `marketing_activity_ix_4` (`scope_type`, `cinema_id`, `status`, `starts_at`),
  CONSTRAINT `marketing_activity_ck_5` CHECK ((scope_type = 'PLATFORM' AND cinema_id IS NULL) OR (scope_type = 'CINEMA' AND cinema_id IS NOT NULL)),
  CONSTRAINT `marketing_activity_ck_6` CHECK (signup_ends_at > signup_starts_at AND ends_at > starts_at AND signup_ends_at <= starts_at),
  CONSTRAINT `marketing_activity_ck_7` CHECK (capacity >= 0 AND registered_count >= 0 AND (capacity = 0 OR registered_count <= capacity)),
  CONSTRAINT `marketing_activity_ck_8` CHECK (`scope_type` IN ('PLATFORM', 'CINEMA')),
  CONSTRAINT `marketing_activity_ck_9` CHECK (`status` IN ('DRAFT', 'PUBLISHED', 'CLOSED', 'CANCELLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='平台及门店活动';

-- 会员营销 / 活动参与记录
CREATE TABLE `activity_participation` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `activity_id` BIGINT NOT NULL COMMENT '活动',
  `user_id` BIGINT NOT NULL COMMENT '参与用户',
  `status` VARCHAR(24) NOT NULL DEFAULT 'REGISTERED' COMMENT '状态；REGISTERED/ATTENDED/CANCELLED',
  `reward_user_coupon_id` BIGINT NULL COMMENT '已发放的奖励券',
  `attended_at` DATETIME(3) NULL COMMENT '签到时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `activity_participation_uk_1` (`activity_id`, `user_id`),
  CONSTRAINT `activity_participation_fk_2` FOREIGN KEY (`activity_id`) REFERENCES `marketing_activity` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `activity_participation_fk_3` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `activity_participation_fk_4` FOREIGN KEY (`reward_user_coupon_id`, `user_id`) REFERENCES `user_coupon` (`id`, `user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `activity_participation_ck_5` CHECK (`status` IN ('REGISTERED', 'ATTENDED', 'CANCELLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='活动参与记录';

-- 互动审核 / 购票影片评价
CREATE TABLE `film_review` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `user_id` BIGINT NOT NULL COMMENT '评价人',
  `film_id` BIGINT NOT NULL COMMENT '影片',
  `cinema_id` BIGINT NOT NULL COMMENT '购票影院',
  `order_item_id` BIGINT NOT NULL COMMENT '已购票明细；一张票仅一条评价',
  `rating` TINYINT NOT NULL DEFAULT 5 COMMENT '评分1到5',
  `content` TEXT NOT NULL COMMENT '评价正文',
  `status` VARCHAR(24) NOT NULL DEFAULT 'PENDING' COMMENT '审核状态；PENDING/APPROVED/REJECTED/HIDDEN',
  `reviewer_id` BIGINT NULL COMMENT '审核人员',
  `reviewed_at` DATETIME(3) NULL COMMENT '审核时间',
  `review_remark` VARCHAR(500) NULL COMMENT '审核说明',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `film_review_uk_1` (`order_item_id`),
  CONSTRAINT `film_review_fk_2` FOREIGN KEY (`order_item_id`, `user_id`, `film_id`, `cinema_id`) REFERENCES `ticket_order_item` (`id`, `user_id`, `film_id`, `cinema_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `film_review_fk_3` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `film_review_ix_4` (`film_id`, `status`, `created_at`),
  KEY `film_review_ix_5` (`cinema_id`, `status`, `created_at`),
  CONSTRAINT `film_review_ck_6` CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT `film_review_ck_7` CHECK (`status` IN ('PENDING', 'APPROVED', 'REJECTED', 'HIDDEN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='购票影片评价';

-- 互动审核 / 评价商家回复
CREATE TABLE `review_reply` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `review_id` BIGINT NOT NULL COMMENT '被回复评价',
  `operator_id` BIGINT NOT NULL COMMENT '回复管理员',
  `content` TEXT NOT NULL COMMENT '回复正文',
  `status` VARCHAR(24) NOT NULL DEFAULT 'VISIBLE' COMMENT '显示状态；VISIBLE/HIDDEN',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `review_reply_fk_1` FOREIGN KEY (`review_id`) REFERENCES `film_review` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `review_reply_fk_2` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `review_reply_ix_3` (`review_id`, `created_at`),
  CONSTRAINT `review_reply_ck_4` CHECK (`status` IN ('VISIBLE', 'HIDDEN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='评价商家回复';

-- 互动审核 / 用户留言反馈
CREATE TABLE `user_feedback` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `user_id` BIGINT NOT NULL COMMENT '提交人',
  `cinema_id` BIGINT NULL COMMENT '反馈影院；NULL为平台反馈',
  `feedback_type` VARCHAR(24) NOT NULL DEFAULT 'SUGGESTION' COMMENT '类型；SUGGESTION/COMPLAINT/QUESTION/OTHER',
  `subject` VARCHAR(160) NOT NULL COMMENT '主题',
  `content` TEXT NOT NULL COMMENT '反馈内容',
  `attachment_keys` JSON NULL COMMENT '附件存储键数组',
  `status` VARCHAR(24) NOT NULL DEFAULT 'OPEN' COMMENT '处理状态；OPEN/PROCESSING/RESOLVED/CLOSED',
  `assigned_to` BIGINT NULL COMMENT '处理管理员',
  `resolved_at` DATETIME(3) NULL COMMENT '解决时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `user_feedback_fk_1` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `user_feedback_fk_2` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `user_feedback_fk_3` FOREIGN KEY (`assigned_to`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `user_feedback_ix_4` (`cinema_id`, `status`, `created_at`),
  KEY `user_feedback_ix_5` (`user_id`, `created_at`),
  CONSTRAINT `user_feedback_ck_6` CHECK (`feedback_type` IN ('SUGGESTION', 'COMPLAINT', 'QUESTION', 'OTHER')),
  CONSTRAINT `user_feedback_ck_7` CHECK (`status` IN ('OPEN', 'PROCESSING', 'RESOLVED', 'CLOSED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户留言反馈';

-- 互动审核 / 反馈沟通记录
CREATE TABLE `feedback_reply` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `feedback_id` BIGINT NOT NULL COMMENT '反馈单',
  `author_id` BIGINT NOT NULL COMMENT '回复人',
  `author_type` VARCHAR(24) NOT NULL DEFAULT 'USER' COMMENT '回复身份快照；USER/STAFF',
  `content` TEXT NOT NULL COMMENT '回复内容',
  `is_internal` TINYINT NOT NULL DEFAULT 0 COMMENT '内部备注，普通用户不可见',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `feedback_reply_fk_1` FOREIGN KEY (`feedback_id`) REFERENCES `user_feedback` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `feedback_reply_fk_2` FOREIGN KEY (`author_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `feedback_reply_ix_3` (`feedback_id`, `created_at`),
  CONSTRAINT `feedback_reply_ck_4` CHECK (is_internal IN (0,1)),
  CONSTRAINT `feedback_reply_ck_5` CHECK (`author_type` IN ('USER', 'STAFF'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='反馈沟通记录';

-- 互动审核 / 敏感词规则
CREATE TABLE `sensitive_word_rule` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `rule_name` VARCHAR(100) NOT NULL COMMENT '规则名称',
  `pattern` VARCHAR(255) NOT NULL COMMENT '词条或受限正则；应用层限制执行耗时',
  `match_type` VARCHAR(24) NOT NULL DEFAULT 'LITERAL' COMMENT '匹配方式；LITERAL/REGEX',
  `action_type` VARCHAR(24) NOT NULL DEFAULT 'REVIEW' COMMENT '处理动作；REVIEW/REJECT/MASK',
  `status` VARCHAR(24) NOT NULL DEFAULT 'ENABLED' COMMENT '状态；ENABLED/DISABLED',
  `updated_by` BIGINT NOT NULL COMMENT '维护人',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `sensitive_word_rule_fk_1` FOREIGN KEY (`updated_by`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `sensitive_word_rule_ix_2` (`status`, `match_type`),
  CONSTRAINT `sensitive_word_rule_ck_3` CHECK (`match_type` IN ('LITERAL', 'REGEX')),
  CONSTRAINT `sensitive_word_rule_ck_4` CHECK (`action_type` IN ('REVIEW', 'REJECT', 'MASK')),
  CONSTRAINT `sensitive_word_rule_ck_5` CHECK (`status` IN ('ENABLED', 'DISABLED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='敏感词规则';

-- 互动审核 / 内容审核日志
CREATE TABLE `moderation_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `target_type` VARCHAR(24) NOT NULL DEFAULT 'REVIEW' COMMENT '对象类型；REVIEW/REVIEW_REPLY/FEEDBACK/ANNOUNCEMENT',
  `target_id` BIGINT NOT NULL COMMENT '对象业务ID；多态引用由应用保证',
  `rule_id` BIGINT NULL COMMENT '命中敏感词规则',
  `reviewer_id` BIGINT NULL COMMENT '人工审核人；自动审核为NULL',
  `decision` VARCHAR(24) NOT NULL DEFAULT 'APPROVE' COMMENT '决策；APPROVE/REJECT/MASK/HIDE/PENDING',
  `reason` VARCHAR(500) NOT NULL COMMENT '审核理由；避免复制完整敏感原文',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `moderation_log_fk_1` FOREIGN KEY (`rule_id`) REFERENCES `sensitive_word_rule` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `moderation_log_fk_2` FOREIGN KEY (`reviewer_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `moderation_log_ix_3` (`target_type`, `target_id`, `created_at`),
  CONSTRAINT `moderation_log_ck_4` CHECK (`target_type` IN ('REVIEW', 'REVIEW_REPLY', 'FEEDBACK', 'ANNOUNCEMENT')),
  CONSTRAINT `moderation_log_ck_5` CHECK (`decision` IN ('APPROVE', 'REJECT', 'MASK', 'HIDE', 'PENDING'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='内容审核日志';

-- 统计审计 / 管理操作审计
CREATE TABLE `sys_audit_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `operator_id` BIGINT NULL COMMENT '操作者；系统任务为NULL',
  `cinema_id` BIGINT NULL COMMENT '被操作数据的影院范围',
  `action_code` VARCHAR(96) NOT NULL COMMENT '操作编码',
  `resource_type` VARCHAR(64) NOT NULL COMMENT '资源类型',
  `resource_id` VARCHAR(64) NULL COMMENT '资源标识',
  `request_id` VARCHAR(64) NOT NULL COMMENT '请求追踪号',
  `client_ip` VARCHAR(64) NULL COMMENT '来源IP；按环境进行脱敏',
  `result` VARCHAR(24) NOT NULL DEFAULT 'SUCCESS' COMMENT '执行结果；SUCCESS/FAILURE',
  `sanitized_details` JSON NULL COMMENT '脱敏变更摘要；排除密码、密钥、完整令牌',
  `duration_ms` INT NOT NULL DEFAULT 0 COMMENT '耗时毫秒',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `sys_audit_log_fk_1` FOREIGN KEY (`operator_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `sys_audit_log_fk_2` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `sys_audit_log_ix_3` (`operator_id`, `created_at`),
  KEY `sys_audit_log_ix_4` (`cinema_id`, `created_at`),
  KEY `sys_audit_log_ix_5` (`request_id`),
  CONSTRAINT `sys_audit_log_ck_6` CHECK (duration_ms >= 0),
  CONSTRAINT `sys_audit_log_ck_7` CHECK (`result` IN ('SUCCESS', 'FAILURE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='管理操作审计';

-- 统计审计 / 登录安全日志
CREATE TABLE `user_login_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `user_id` BIGINT NULL COMMENT '登录用户；未知账号为NULL',
  `account_hint` VARCHAR(64) NULL COMMENT '脱敏账号摘要',
  `login_type` VARCHAR(24) NOT NULL DEFAULT 'PASSWORD' COMMENT '登录方式；PASSWORD/WECHAT/SMS',
  `client_ip` VARCHAR(64) NULL COMMENT '来源IP',
  `user_agent` VARCHAR(500) NULL COMMENT '客户端摘要',
  `result` VARCHAR(24) NOT NULL DEFAULT 'SUCCESS' COMMENT '结果；SUCCESS/FAILURE/BLOCKED',
  `reason` VARCHAR(255) NULL COMMENT '原因',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  CONSTRAINT `user_login_log_fk_1` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `user_login_log_ix_2` (`user_id`, `created_at`),
  KEY `user_login_log_ix_3` (`client_ip`, `created_at`),
  CONSTRAINT `user_login_log_ck_4` CHECK (`login_type` IN ('PASSWORD', 'WECHAT', 'SMS')),
  CONSTRAINT `user_login_log_ck_5` CHECK (`result` IN ('SUCCESS', 'FAILURE', 'BLOCKED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='登录安全日志';

-- 统计审计 / 活跃用户事件
CREATE TABLE `user_activity_event` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `event_no` VARCHAR(64) NOT NULL COMMENT '客户端或服务端事件幂等编号',
  `user_id` BIGINT NOT NULL COMMENT '已登录用户',
  `cinema_id` BIGINT NULL COMMENT '关联影院；平台页面为NULL',
  `event_type` VARCHAR(24) NOT NULL DEFAULT 'LOGIN' COMMENT '事件类型；LOGIN/BROWSE/ORDER/PAY/REVIEW/ACTIVITY',
  `occurred_at` DATETIME(3) NOT NULL COMMENT '事件发生时间，服务端校正',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_activity_event_uk_1` (`event_no`),
  CONSTRAINT `user_activity_event_fk_2` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `user_activity_event_fk_3` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `user_activity_event_ix_4` (`occurred_at`, `user_id`),
  KEY `user_activity_event_ix_5` (`cinema_id`, `occurred_at`, `user_id`),
  CONSTRAINT `user_activity_event_ck_6` CHECK (`event_type` IN ('LOGIN', 'BROWSE', 'ORDER', 'PAY', 'REVIEW', 'ACTIVITY'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='活跃用户事件';

-- 统计审计 / 影院每日汇总
CREATE TABLE `stat_cinema_daily` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `cinema_id` BIGINT NOT NULL COMMENT '影院',
  `stat_date` DATE NOT NULL COMMENT '北京时间自然日',
  `gross_sales` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '当日订单认领的成功支付额',
  `refund_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '当日对已认领款的成功退款额',
  `sold_ticket_count` INT NOT NULL DEFAULT 0 COMMENT '当日成功出票张数',
  `refunded_ticket_count` INT NOT NULL DEFAULT 0 COMMENT '当日退票张数',
  `scheduled_seat_count` INT NOT NULL DEFAULT 0 COMMENT '当日有效开场场次座位总量',
  `occupied_seat_count` INT NOT NULL DEFAULT 0 COMMENT '上述场次当前已售座位总量',
  `active_user_count` INT NOT NULL DEFAULT 0 COMMENT '本院当日去重活跃用户数',
  `calculated_at` DATETIME(3) NOT NULL COMMENT '汇总计算时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `stat_cinema_daily_uk_1` (`cinema_id`, `stat_date`),
  CONSTRAINT `stat_cinema_daily_fk_2` FOREIGN KEY (`cinema_id`) REFERENCES `cinema` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `stat_cinema_daily_ck_3` CHECK (gross_sales >= 0 AND refund_amount >= 0 AND sold_ticket_count >= 0 AND refunded_ticket_count >= 0 AND scheduled_seat_count >= 0 AND occupied_seat_count BETWEEN 0 AND scheduled_seat_count AND active_user_count >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='影院每日汇总';

-- 统计审计 / 平台每日汇总
CREATE TABLE `stat_platform_daily` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `stat_date` DATE NOT NULL COMMENT '北京时间自然日',
  `gross_sales` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '当日认领支付总额',
  `refund_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '当日成功退还的认领款',
  `paid_order_count` INT NOT NULL DEFAULT 0 COMMENT '成功支付订单数',
  `active_user_count` INT NOT NULL DEFAULT 0 COMMENT '全平台按用户去重；禁止直接相加影院DAU',
  `new_user_count` INT NOT NULL DEFAULT 0 COMMENT '新增普通用户数',
  `active_cinema_count` INT NOT NULL DEFAULT 0 COMMENT '营业影院数',
  `calculated_at` DATETIME(3) NOT NULL COMMENT '汇总计算时间',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `stat_platform_daily_uk_1` (`stat_date`),
  CONSTRAINT `stat_platform_daily_ck_2` CHECK (gross_sales >= 0 AND refund_amount >= 0 AND paid_order_count >= 0 AND active_user_count >= 0 AND new_user_count >= 0 AND active_cinema_count >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='平台每日汇总';

-- 统计审计 / 事务消息发件箱
CREATE TABLE `outbox_event` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `event_no` VARCHAR(64) NOT NULL COMMENT '全局事件编号',
  `aggregate_type` VARCHAR(64) NOT NULL COMMENT '聚合类型',
  `aggregate_id` VARCHAR(64) NOT NULL COMMENT '聚合标识；多态引用',
  `event_type` VARCHAR(96) NOT NULL COMMENT '事件类型',
  `payload` JSON NOT NULL COMMENT '不含凭证的事件数据',
  `status` VARCHAR(24) NOT NULL DEFAULT 'NEW' COMMENT '投递状态；NEW/PROCESSING/SENT/FAILED',
  `retry_count` INT NOT NULL DEFAULT 0 COMMENT '重试次数',
  `next_retry_at` DATETIME(3) NOT NULL COMMENT '下次重试时间',
  `locked_until` DATETIME(3) NULL COMMENT '消费者租约到期',
  `locked_by` VARCHAR(64) NULL COMMENT '消费者实例标识',
  `last_error` VARCHAR(500) NULL COMMENT '错误摘要',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `outbox_event_uk_1` (`event_no`),
  KEY `outbox_event_ix_2` (`status`, `next_retry_at`),
  KEY `outbox_event_ix_3` (`status`, `locked_until`),
  CONSTRAINT `outbox_event_ck_4` CHECK (retry_count >= 0),
  CONSTRAINT `outbox_event_ck_5` CHECK (`status` IN ('NEW', 'PROCESSING', 'SENT', 'FAILED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='事务消息发件箱';

-- 统计审计 / 业务请求幂等记录
CREATE TABLE `idempotency_record` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键；应用使用 Java Long，接口以字符串返回',
  `user_id` BIGINT NOT NULL COMMENT '请求发起人',
  `operation_code` VARCHAR(64) NOT NULL COMMENT '操作类型',
  `key_hash` VARCHAR(64) COLLATE utf8mb4_bin NOT NULL COMMENT '客户端幂等键摘要',
  `request_hash` VARCHAR(64) COLLATE utf8mb4_bin NOT NULL COMMENT '请求内容摘要；同键异参必须拒绝',
  `status` VARCHAR(24) NOT NULL DEFAULT 'PROCESSING' COMMENT '状态；PROCESSING/SUCCEEDED/FAILED',
  `resource_type` VARCHAR(64) NULL COMMENT '结果资源类型',
  `resource_id` VARCHAR(64) NULL COMMENT '结果业务编号',
  `expires_at` DATETIME(3) NOT NULL COMMENT '幂等窗口结束',
  `processing_until` DATETIME(3) NOT NULL COMMENT '执行租约到期时间',
  `owner_token` VARCHAR(64) COLLATE utf8mb4_bin NOT NULL COMMENT '执行者租约令牌',
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间；统一使用北京时间',
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最近更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idempotency_record_uk_1` (`user_id`, `operation_code`, `key_hash`),
  CONSTRAINT `idempotency_record_fk_2` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  KEY `idempotency_record_ix_3` (`expires_at`),
  KEY `idempotency_record_ix_4` (`status`, `processing_until`),
  CONSTRAINT `idempotency_record_ck_5` CHECK (`status` IN ('PROCESSING', 'SUCCEEDED', 'FAILED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='业务请求幂等记录';

ALTER TABLE `screening_seat` ADD CONSTRAINT `screening_seat_fk_90` FOREIGN KEY (`sold_order_item_id`, `id`) REFERENCES `ticket_order_item` (`id`, `screening_seat_id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE `ticket_order` ADD CONSTRAINT `ticket_order_fk_91` FOREIGN KEY (`settled_payment_id`, `id`) REFERENCES `payment_transaction` (`id`, `order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT;
