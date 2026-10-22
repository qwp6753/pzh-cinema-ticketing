-- 统计视图：实时查询示例；历史汇总由定时任务写入stat_*_daily，可重算。
USE pzh_cinema;
SET time_zone = '+08:00';
CREATE VIEW v_screening_inventory AS
SELECT s.id AS screening_id,s.cinema_id,s.film_id,s.hall_id,s.starts_at,s.status,
 COUNT(i.id) AS physical_seat_count,
 SUM(CASE WHEN i.status <> 'DISABLED' THEN 1 ELSE 0 END) AS saleable_seat_count,
 SUM(CASE WHEN i.status='AVAILABLE' THEN 1 ELSE 0 END) AS available_count,
 SUM(CASE WHEN i.status='LOCKED' AND i.locked_until>NOW(3) THEN 1 ELSE 0 END) AS locked_count,
 SUM(CASE WHEN i.status='LOCKED' AND i.locked_until<=NOW(3) THEN 1 ELSE 0 END) AS expired_lock_count,
 SUM(CASE WHEN i.status='SOLD' THEN 1 ELSE 0 END) AS sold_count,
 COALESCE(ROUND(100.0*SUM(CASE WHEN i.status='SOLD' THEN 1 ELSE 0 END)/NULLIF(SUM(CASE WHEN i.status <> 'DISABLED' THEN 1 ELSE 0 END),0),2),0) AS occupancy_percent
FROM cinema_screening s LEFT JOIN screening_seat i ON i.screening_id=s.id GROUP BY s.id,s.cinema_id,s.film_id,s.hall_id,s.starts_at,s.status;

CREATE VIEW v_film_rating AS
SELECT f.id AS film_id,COUNT(r.id) AS review_count,ROUND(AVG(r.rating),2) AS average_rating
FROM film f LEFT JOIN film_review r ON r.film_id=f.id AND r.status='APPROVED' GROUP BY f.id;

CREATE VIEW v_cinema_realtime AS
SELECT c.id AS cinema_id,c.cinema_name,
 COALESCE((SELECT SUM(o.paid_amount-o.refunded_amount) FROM ticket_order o WHERE o.cinema_id=c.id),0) AS all_time_net_sales,
 COALESCE((SELECT SUM(o.paid_amount) FROM ticket_order o WHERE o.cinema_id=c.id AND o.paid_at>=CURRENT_DATE AND o.paid_at<CURRENT_DATE+INTERVAL 1 DAY),0) AS today_gross_sales,
 COALESCE((SELECT SUM(r.amount) FROM payment_refund r JOIN ticket_order o ON o.id=r.order_id AND o.settled_payment_id=r.payment_id WHERE o.cinema_id=c.id AND r.status='SUCCESS' AND r.succeeded_at>=CURRENT_DATE AND r.succeeded_at<CURRENT_DATE+INTERVAL 1 DAY),0) AS today_refunds,
 (SELECT COUNT(DISTINCT e.user_id) FROM user_activity_event e WHERE e.cinema_id=c.id AND e.occurred_at>=CURRENT_DATE AND e.occurred_at<CURRENT_DATE+INTERVAL 1 DAY) AS today_active_users
FROM cinema c;

CREATE VIEW v_platform_daily_activity AS
SELECT DATE(occurred_at) AS stat_date,COUNT(DISTINCT user_id) AS active_user_count FROM user_activity_event GROUP BY DATE(occurred_at);
