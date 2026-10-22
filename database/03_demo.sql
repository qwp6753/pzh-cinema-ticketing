-- 可选演示数据：影院、影片、地址、用户均为虚构，不代表真实影院经营信息。
-- 演示账号全部LOCKED且无密码，不能直接登录；实际系统需通过注册/管理员初始化流程创建账号。
-- 在01、02执行后，空业务库中执行一次。
USE pzh_cinema;
SET NAMES utf8mb4;
SET time_zone = '+08:00';
START TRANSACTION;
INSERT INTO sys_user (id,username,nickname,status) VALUES
(1,'demo_platform','演示平台管理员','LOCKED'),(2,'demo_cinema_east','演示影院管理员甲','LOCKED'),(3,'demo_customer','演示购票用户','LOCKED'),(4,'demo_cinema_renhe','演示影院管理员乙','LOCKED');
INSERT INTO cinema (id,cinema_code,cinema_name,region_id,address,status) VALUES
(1,'DEMO_EAST','东区演示影院（毕设虚构）',2,'东区演示地址，非真实门店','ACTIVE'),
(2,'DEMO_RENHE','仁和演示影院（毕设虚构）',4,'仁和区演示地址，非真实门店','ACTIVE');
INSERT INTO sys_user_role (user_id,role_id,scope_type,cinema_id) VALUES
(1,1,'GLOBAL',NULL),(2,2,'CINEMA',1),(3,3,'GLOBAL',NULL),(4,2,'CINEMA',2);
INSERT INTO cinema_hall (id,cinema_id,hall_name,row_count,column_count) VALUES (1,1,'一号厅',2,5),(2,2,'一号厅',2,3);
INSERT INTO cinema_seat (id,cinema_id,hall_id,row_no,column_no,seat_label) VALUES
(1,1,1,1,1,'1排1座'),(2,1,1,1,2,'1排2座'),(3,1,1,1,3,'1排3座'),(4,1,1,1,4,'1排4座'),(5,1,1,1,5,'1排5座'),
(6,1,1,2,1,'2排1座'),(7,1,1,2,2,'2排2座'),(8,1,1,2,3,'2排3座'),(9,1,1,2,4,'2排4座'),(10,1,1,2,5,'2排5座'),
(201,2,2,1,1,'1排1座'),(202,2,2,1,2,'1排2座'),(203,2,2,1,3,'1排3座'),(204,2,2,2,1,'2排1座'),(205,2,2,2,2,'2排2座'),(206,2,2,2,3,'2排3座');
INSERT INTO film (id,film_name,director,duration_minutes,synopsis,release_status,publish_status,heat_score) VALUES
(1,'攀枝花之光（虚构演示影片）','演示导演',120,'用于毕业设计演示的虚构影片。','SHOWING','PUBLISHED',100),
(2,'山城奇遇（虚构演示影片）','演示导演',100,'用于验证影片检索与分类展示的虚构影片。','COMING','PUBLISHED',60);
INSERT INTO film_category_rel (film_id,category_id) VALUES (1,1),(1,8),(2,2);
INSERT INTO cinema_film (cinema_id,film_id) VALUES (1,1),(1,2),(2,1);
SET @d = CURRENT_DATE + INTERVAL 1 DAY;
INSERT INTO cinema_screening (id,cinema_id,hall_id,film_id,starts_at,ends_at,hall_release_at,sale_starts_at,sale_ends_at,base_price,audio_language,projection_format,status) VALUES
(1,1,1,1,TIMESTAMP(@d,'19:00:00'),TIMESTAMP(@d,'21:00:00'),TIMESTAMP(@d,'21:20:00'),NOW(3)-INTERVAL 1 DAY,TIMESTAMP(@d,'18:55:00'),40,'普通话','2D','ON_SALE'),
(2,1,1,1,TIMESTAMP(@d,'21:30:00'),TIMESTAMP(@d,'23:30:00'),TIMESTAMP(@d,'23:50:00'),NOW(3)-INTERVAL 1 DAY,TIMESTAMP(@d,'21:25:00'),45,'普通话','2D','ON_SALE'),
(3,2,2,1,TIMESTAMP(@d,'19:00:00'),TIMESTAMP(@d,'21:00:00'),TIMESTAMP(@d,'21:20:00'),NOW(3)-INTERVAL 1 DAY,TIMESTAMP(@d,'18:55:00'),35,'普通话','2D','ON_SALE');
INSERT INTO screening_seat (id,screening_id,cinema_id,hall_id,seat_id,seat_label_snapshot,row_no_snapshot,column_no_snapshot,sale_price)
SELECT id,1,1,1,id,seat_label,row_no,column_no,40 FROM cinema_seat WHERE hall_id=1;
INSERT INTO screening_seat (id,screening_id,cinema_id,hall_id,seat_id,seat_label_snapshot,row_no_snapshot,column_no_snapshot,sale_price)
SELECT id+100,2,1,1,id,seat_label,row_no,column_no,45 FROM cinema_seat WHERE hall_id=1;
INSERT INTO screening_seat (id,screening_id,cinema_id,hall_id,seat_id,seat_label_snapshot,row_no_snapshot,column_no_snapshot,sale_price)
SELECT id,3,2,2,id,seat_label,row_no,column_no,35 FROM cinema_seat WHERE hall_id=2;
INSERT INTO seat_hold (id,hold_no,user_id,cinema_id,screening_id,token_hash,expires_at,status) VALUES
(1,'DEMO-HOLD-1',3,1,1,SHA2('not-a-live-hold-token',256),NOW(3)+INTERVAL 10 MINUTE,'CONSUMED');
INSERT INTO seat_hold_item (hold_id,screening_id,cinema_id,screening_seat_id,seat_id,price_snapshot) VALUES (1,1,1,1,1,40);
INSERT INTO ticket_order (id,order_no,user_id,cinema_id,screening_id,film_id,hold_id,ticket_count,original_amount,discount_amount,payable_amount,paid_amount,status,expires_at,paid_at,film_name_snapshot,cinema_name_snapshot,hall_name_snapshot,starts_at_snapshot) VALUES
(1,'DEMO-ORDER-1',3,1,1,1,1,1,40,0,40,0,'UNPAID',NOW(3)+INTERVAL 10 MINUTE,NULL,'攀枝花之光（虚构演示影片）','东区演示影院（毕设虚构）','一号厅',TIMESTAMP(@d,'19:00:00'));
INSERT INTO ticket_order_item (id,order_id,user_id,cinema_id,screening_id,film_id,screening_seat_id,seat_id,seat_label_snapshot,original_amount,payable_amount,status) VALUES
(1,1,3,1,1,1,1,1,'1排1座',40,40,'VALID');
INSERT INTO payment_transaction (id,payment_no,order_id,provider,provider_trade_no,idempotency_key,amount,status,succeeded_at) VALUES
(1,'DEMO-PAY-1',1,'MOCK','DEMO-TRADE-1','DEMO-PAY-IDEMPOTENCY-1',40,'SUCCESS',NOW(3));
UPDATE ticket_order SET settled_payment_id=1,paid_amount=40,status='PAID',paid_at=NOW(3) WHERE id=1;
UPDATE screening_seat SET status='SOLD',sold_order_item_id=1,version=version+1 WHERE id=1;
INSERT INTO ticket (id,ticket_no,order_item_id,user_id,cinema_id,screening_id) VALUES (1,'DEMO-TICKET-1',1,3,1,1);
INSERT INTO order_status_history (order_id,from_status,to_status,operator_id,reason) VALUES (1,NULL,'UNPAID',3,'演示创建订单'),(1,'UNPAID','PAID',NULL,'演示沙箱支付成功');
INSERT INTO member_account (id,user_id,member_no,level_id,points_balance,growth_value) VALUES (1,3,'DEMO-MEMBER-1',1,40,40);
INSERT INTO member_points_ledger (member_account_id,points_delta,balance_after,source_type,source_no,idempotency_key) VALUES (1,40,40,'ORDER','DEMO-ORDER-1','DEMO-POINTS-1');
INSERT INTO cinema_member (cinema_id,user_id,member_no,total_net_spend) VALUES (1,3,'DEMO-EAST-MEMBER-1',40);
INSERT INTO user_favorite_film (user_id,film_id) VALUES (3,1);
INSERT INTO coupon_template (id,coupon_name,scope_type,cinema_id,discount_type,minimum_spend,fixed_discount,claim_starts_at,claim_ends_at,valid_from,valid_to,total_quantity,issued_quantity,status) VALUES
(1,'演示满50减10','CINEMA',1,'FIXED',50,10,NOW(3)-INTERVAL 1 DAY,NOW(3)+INTERVAL 7 DAY,NOW(3)-INTERVAL 1 DAY,NOW(3)+INTERVAL 30 DAY,100,1,'ACTIVE');
INSERT INTO user_coupon (id,coupon_no,template_id,user_id,valid_from,valid_to) VALUES (1,'DEMO-COUPON-1',1,3,NOW(3)-INTERVAL 1 DAY,NOW(3)+INTERVAL 30 DAY);
INSERT INTO announcement (scope_type,cinema_id,announcement_type,title,content,publisher_id,status,publish_at) VALUES
('PLATFORM',NULL,'SYSTEM','毕业设计演示公告','本库全部商业数据均为虚构，仅供系统开发与答辩演示。',1,'PUBLISHED',NOW(3)),
('CINEMA',1,'LOST_FOUND','演示失物招领','模拟失物招领公告，请勿据此联系真实门店。',2,'PUBLISHED',NOW(3));
INSERT INTO marketing_activity (id,scope_type,cinema_id,title,description,publisher_id,reward_coupon_template_id,signup_starts_at,signup_ends_at,starts_at,ends_at,capacity,status) VALUES
(1,'CINEMA',1,'演示观影交流活动','虚构活动，仅用于开发报名与奖励券功能。',2,1,NOW(3)-INTERVAL 1 DAY,TIMESTAMP(@d,'16:00:00'),TIMESTAMP(@d,'17:00:00'),TIMESTAMP(@d,'18:00:00'),20,'PUBLISHED');
INSERT INTO user_activity_event (event_no,user_id,cinema_id,event_type,occurred_at) VALUES ('DEMO-EVENT-1',3,1,'PAY',NOW(3));
COMMIT;
