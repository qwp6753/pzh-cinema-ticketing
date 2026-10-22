-- 只读检查，不修改业务数据。
USE pzh_cinema;
SELECT TABLE_NAME, TABLE_COMMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;
SELECT 'base_tables' AS metric, COUNT(*) AS actual, 55 AS expected FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE';
SELECT 'broken_order_amount' AS issue, COUNT(*) AS rows_found FROM ticket_order WHERE original_amount <> discount_amount + payable_amount OR refunded_amount > paid_amount;
SELECT 'sold_seat_owner_mismatch' AS issue, COUNT(*) AS rows_found FROM screening_seat s LEFT JOIN ticket_order_item i ON i.id=s.sold_order_item_id WHERE s.status='SOLD' AND (i.id IS NULL OR i.screening_seat_id<>s.id OR i.status NOT IN ('VALID','VERIFIED'));
SELECT 'expired_seat_locks_to_reclaim' AS issue, COUNT(*) AS rows_found FROM screening_seat WHERE status='LOCKED' AND locked_until <= NOW(3);
SELECT 'duplicate_valid_tickets_for_inventory' AS issue, COUNT(*) AS rows_found FROM (SELECT screening_seat_id FROM ticket_order_item WHERE status IN ('VALID','VERIFIED') GROUP BY screening_seat_id HAVING COUNT(*) > 1) t;
SELECT 'order_items_amount_mismatch' AS issue, COUNT(*) AS rows_found FROM ticket_order o LEFT JOIN (SELECT order_id,COUNT(*) AS cnt,SUM(original_amount) AS original_amount,SUM(discount_amount) AS discount_amount,SUM(payable_amount) AS payable_amount FROM ticket_order_item GROUP BY order_id) x ON x.order_id=o.id WHERE COALESCE(x.cnt,0)<>o.ticket_count OR COALESCE(x.original_amount,0)<>o.original_amount OR COALESCE(x.discount_amount,0)<>o.discount_amount OR COALESCE(x.payable_amount,0)<>o.payable_amount;
