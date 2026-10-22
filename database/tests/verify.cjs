// Runs only a freshly initialized isolated MySQL instance; never connects to port 3306.
// Usage: node database/tests/verify.cjs --mysql-bin "D:/MySQL/MySQL Server 8.0/bin" --work-dir "C:/.../work/db-check"
const fs = require('node:fs');
const path = require('node:path');
const net = require('node:net');
const {spawn,spawnSync} = require('node:child_process');
const args = process.argv.slice(2);
const option = (name, fallback) => args.includes(name) ? args[args.indexOf(name)+1] : fallback;
const bin = option('--mysql-bin','');
const exe = name => bin ? path.join(bin,name+(process.platform==='win32'?'.exe':'')) : name;
const root = path.resolve(__dirname,'../..');
const runtime = path.resolve(option('--work-dir',path.join(root,'work','db-check-'+Date.now())));
if(fs.existsSync(runtime)) throw new Error('Verification directory already exists; choose a NEW directory.');
fs.mkdirSync(runtime,{recursive:true});
const dataDir = path.join(runtime,'data');
fs.mkdirSync(dataDir);
const report = {mysqlVersion:'',tests:[],tableCount:0,viewCount:0};
let server;
let port;
const delay = ms => new Promise(resolve=>setTimeout(resolve,ms));
function runSql(sql,allowError=false) {
  const r = spawnSync(exe('mysql'),['--no-defaults','--protocol=TCP','--host=127.0.0.1','--port='+port,'--user=root','--default-character-set=utf8mb4','--batch','--skip-column-names'],{input:sql,encoding:'utf8',windowsHide:true,cwd:root,maxBuffer:8*1024*1024});
  if(r.error) throw new Error(r.error.message+'; stderr: '+r.stderr+'; stdout: '+r.stdout);
  if(r.status!==0 && !allowError) throw new Error((r.stderr||'')+'\n'+(r.stdout||''));
  return r;
}
function pass(name,evidence) { report.tests.push({name,status:'PASS',evidence});console.log('PASS '+name); }
function scalar(sql) { return runSql('SET time_zone=\'+08:00\'; USE pzh_cinema; '+sql).stdout.trim(); }
function negative(name,sql,code) {
  const r=runSql('SET time_zone=\'+08:00\'; USE pzh_cinema; START TRANSACTION; '+sql+'; ROLLBACK;',true);
  if(r.status===0 || !r.stderr.includes('ERROR '+code+' ')) throw new Error(name+': expected MySQL '+code+', got '+r.status+' '+r.stderr);
  pass(name,'MySQL ERROR '+code+' rejected the invalid write; connection-close rollback');
}
function assertEqual(name,actual,expected) { if(String(actual)!==String(expected)) throw new Error(name+': expected '+expected+', got '+actual);pass(name,String(actual)); }
function positive(name,sql,expected='1') {
  const output=runSql("SET time_zone='+08:00'; USE pzh_cinema; START TRANSACTION; "+sql+'; ROLLBACK;').stdout.trim();
  assertEqual(name,output,expected);
}
const hold = (id,show=1,user=3) => `INSERT INTO seat_hold (id,hold_no,user_id,cinema_id,screening_id,token_hash,expires_at) VALUES (${id},'TEST-H-${id}',${user},1,${show},SHA2('TEST-H-${id}',256),NOW(3)+INTERVAL 5 MINUTE);`;
const order = (id,holdId=id,show=1,user=3) => `INSERT INTO ticket_order (id,order_no,user_id,cinema_id,screening_id,film_id,hold_id,ticket_count,original_amount,payable_amount,expires_at,film_name_snapshot,cinema_name_snapshot,hall_name_snapshot,starts_at_snapshot) VALUES (${id},'TEST-O-${id}',${user},1,${show},1,${holdId},1,40,40,NOW(3)+INTERVAL 5 MINUTE,'test','test','test',NOW(3)+INTERVAL 1 DAY);`;
const request = id => `INSERT INTO after_sale_request(id,request_no,request_type,original_order_id,user_id,cinema_id,reason) VALUES (${id},'TEST-AS-${id}','REFUND',1,3,1,'test');`;
async function concurrentSql(sql) {
  return new Promise((resolve,reject)=>{
    const p=spawn(exe('mysql'),['--no-defaults','--protocol=TCP','--host=127.0.0.1','--port='+port,'--user=root','--default-character-set=utf8mb4','--batch','--skip-column-names'],{windowsHide:true});
    let stdout='',stderr='';p.stdout.on('data',x=>stdout+=x.toString());p.stderr.on('data',x=>stderr+=x.toString());
    p.on('error',reject);p.on('close',code=>code===0?resolve(stdout.trim()):reject(new Error(stderr)));p.stdin.end(sql);
  });
}
async function main() {
  report.mysqlVersion=spawnSync(exe('mysqld'),['--version'],{encoding:'utf8',windowsHide:true}).stdout.trim();
  console.log(report.mysqlVersion);
  console.log('Initializing fresh isolated instance in '+runtime);
  const init=spawnSync(exe('mysqld'),['--no-defaults','--initialize-insecure','--datadir='+dataDir,'--log-error='+path.join(runtime,'initialize.log')],{encoding:'utf8',windowsHide:true,timeout:120000});
  if(init.error || init.status!==0) throw new Error('Initialization failed: '+(init.error||init.stderr));
  port=await new Promise((resolve,reject)=>{const p=net.createServer();p.on('error',reject);p.listen(0,'127.0.0.1',()=>{const v=p.address().port;p.close(()=>resolve(v));});});
  server=spawn(exe('mysqld'),['--no-defaults','--datadir='+dataDir,'--bind-address=127.0.0.1','--port='+port,'--mysqlx=OFF','--skip-log-bin','--innodb-buffer-pool-size=64M','--log-error='+path.join(runtime,'server.log'),'--pid-file='+path.join(runtime,'server.pid')],{windowsHide:true,stdio:'ignore'});
  let startupError;server.on('error',e=>{startupError=e;});
  for(let i=0;i<150;i++) {
    if(startupError || server.exitCode!==null) throw new Error('MySQL startup failed: '+(startupError||fs.readFileSync(path.join(runtime,'server.log'),'utf8')));
    const log=fs.existsSync(path.join(runtime,'server.log'))?fs.readFileSync(path.join(runtime,'server.log'),'utf8'):'';
    if(log.includes('ready for connections')) break;
    await delay(200);
    if(i===149) throw new Error('Isolated MySQL startup timed out');
  }
  pass('isolated_server','Loopback only, temporary datadir, dynamic port '+port+'; existing MySQL services not used');
  runSql(['01_schema.sql','02_seed.sql','03_demo.sql','04_views.sql'].map(f=>fs.readFileSync(path.join(root,'database',f),'utf8')).join('\n'));
  pass('import_all_sql_files','mysql batch import completed without error, including UTF-8 seed content');
  assertEqual('table_count',scalar("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='pzh_cinema' AND table_type='BASE TABLE'"),55);report.tableCount=55;
  assertEqual('view_count',scalar("SELECT COUNT(*) FROM information_schema.views WHERE table_schema='pzh_cinema'"),4);report.viewCount=4;
  assertEqual('chinese_seed_roundtrip',scalar('SELECT region_name FROM sys_region WHERE id=1'),'攀枝花市');
  assertEqual('demo_available_inventory',scalar("SELECT available_count FROM v_screening_inventory WHERE screening_id=1"),9);
  assertEqual('demo_sold_inventory',scalar("SELECT sold_count FROM v_screening_inventory WHERE screening_id=1"),1);
  assertEqual('demo_cinema_net_sales',scalar('SELECT all_time_net_sales FROM v_cinema_realtime WHERE cinema_id=1'),'40.00');
  assertEqual('platform_dau_distinct',scalar('SELECT active_user_count FROM v_platform_daily_activity WHERE stat_date=CURRENT_DATE'),1);
  assertEqual('role_permission_seed',scalar('SELECT COUNT(*) FROM sys_role_permission'),42);
  negative('duplicate_screening_seat',"INSERT INTO screening_seat(screening_id,cinema_id,hall_id,seat_id,seat_label_snapshot,sale_price) VALUES (1,1,1,1,'duplicate',40)",1062);
  negative('cross_cinema_seat_rejected',"INSERT INTO screening_seat(screening_id,cinema_id,hall_id,seat_id,seat_label_snapshot,sale_price) VALUES (1,1,1,201,'wrong cinema',40)",1452);
  negative('negative_ticket_price_rejected','UPDATE screening_seat SET sale_price=-1 WHERE id=2',3819);
  negative('invalid_lock_shape_rejected',"UPDATE screening_seat SET status='LOCKED' WHERE id=2",3819);
  negative('coupon_overissue_rejected','UPDATE coupon_template SET issued_quantity=total_quantity+1 WHERE id=1',3819);
  negative('rating_out_of_range_rejected',"INSERT INTO film_review(user_id,film_id,cinema_id,order_item_id,rating,content) VALUES (3,1,1,1,6,'test')",3819);
  negative('duplicate_favorite_rejected','INSERT INTO user_favorite_film(user_id,film_id) VALUES (3,1)',1062);
  negative('negative_points_rejected','UPDATE member_account SET points_balance=-1 WHERE id=1',3819);
  negative('duplicate_provider_trade_rejected',"INSERT INTO payment_transaction(payment_no,order_id,provider,provider_trade_no,idempotency_key,amount,status,succeeded_at) VALUES ('TEST-PAY',1,'MOCK','DEMO-TRADE-1','TEST-PAY',40,'SUCCESS',NOW(3))",1062);
  negative('cross_role_scope_rejected',"INSERT INTO sys_user_role(user_id,role_id,scope_type,cinema_id) VALUES (3,1,'CINEMA',1)",1452);
  negative('duplicate_global_grant_rejected',"INSERT INTO sys_user_role(user_id,role_id,scope_type,cinema_id) VALUES (3,3,'GLOBAL',NULL)",1062);
  negative('cross_user_order_hold_rejected',hold(100,2)+order(100,100,2,2),1452);
  negative('duplicate_active_sale_item_rejected',hold(101)+order(101)+"INSERT INTO ticket_order_item(order_id,user_id,cinema_id,screening_id,film_id,screening_seat_id,seat_id,seat_label_snapshot,original_amount,payable_amount,status) VALUES (101,3,1,1,1,1,1,'1排1座',40,40,'VALID')",1062);
  negative('sold_inventory_owner_mismatch_rejected',"UPDATE screening_seat SET status='SOLD',sold_order_item_id=1 WHERE id=2",1452);
  negative('duplicate_inflight_after_sale_rejected',request(100)+request(101)+"INSERT INTO after_sale_item(request_id,original_order_id,cinema_id,original_order_item_id) VALUES (100,1,1,1),(101,1,1,1)",1062);
  negative('duplicate_successful_verification_rejected',"INSERT INTO ticket_qr_token(id,ticket_id,cinema_id,nonce_hash,valid_from,expires_at) VALUES (100,1,1,SHA2('q100',256),NOW(3),NOW(3)+INTERVAL 30 SECOND),(101,1,1,SHA2('q101',256),NOW(3),NOW(3)+INTERVAL 30 SECOND); INSERT INTO ticket_verification_log(cinema_id,operator_id,ticket_id,qr_token_id,result) VALUES (1,2,1,100,'SUCCESS'),(1,2,1,101,'SUCCESS')",1062);
  negative('duplicate_coupon_claim_to_orders_rejected',hold(100,2)+order(100,100,2)+"INSERT INTO coupon_usage(user_coupon_id,user_id,order_id,cinema_id,discount_amount) VALUES (1,3,1,1,0),(1,3,100,1,0)",1062);
  negative('order_amount_mismatch_rejected','UPDATE ticket_order SET discount_amount=1 WHERE id=1',3819);
  negative('paid_order_requires_claimed_payment',hold(100)+order(100)+"UPDATE ticket_order SET paid_amount=40,status='PAID' WHERE id=100",3819);
  negative('refund_provider_mismatch_rejected',"INSERT INTO payment_refund(refund_no,order_id,payment_id,provider,refund_reason,idempotency_key,amount) VALUES ('TEST-R-1',1,1,'WECHAT','SYSTEM_CANCEL','TEST-R-1',1)",1452);
  negative('duplicate_provider_refund_rejected',"INSERT INTO payment_transaction(id,payment_no,order_id,provider,provider_trade_no,idempotency_key,amount) VALUES (100,'TEST-P-100',1,'MOCK','TEST-PT-100','TEST-P-100',40); INSERT INTO payment_refund(refund_no,order_id,payment_id,provider,refund_reason,provider_refund_no,idempotency_key,amount) VALUES ('TEST-R-1',1,1,'MOCK','SYSTEM_CANCEL','TEST-CHANNEL-R','TEST-R-1',1),('TEST-R-2',1,100,'MOCK','DUPLICATE_PAYMENT','TEST-CHANNEL-R','TEST-R-2',1)",1062);
  negative('change_new_item_order_mismatch_rejected',hold(100,2)+order(100,100,2)+"INSERT INTO after_sale_request(id,request_no,request_type,original_order_id,user_id,cinema_id,target_screening_id,new_order_id,reason) VALUES (100,'TEST-CHANGE','CHANGE',1,3,1,2,100,'test'); INSERT INTO after_sale_item(request_id,original_order_id,cinema_id,original_order_item_id,new_order_id,new_order_item_id) VALUES (100,1,1,1,100,1)",1452);
  negative('verification_cross_cinema_rejected',"INSERT INTO ticket_qr_token(id,ticket_id,cinema_id,nonce_hash,valid_from,expires_at) VALUES (100,1,1,SHA2('q100',256),NOW(3),NOW(3)+INTERVAL 30 SECOND); INSERT INTO ticket_verification_log(cinema_id,operator_id,ticket_id,qr_token_id,result) VALUES (2,4,1,100,'SUCCESS')",1452);
  positive('global_dau_deduplicates_cinemas',"INSERT INTO user_activity_event(event_no,user_id,cinema_id,event_type,occurred_at) VALUES ('TEST-EVENT-OTHER-CINEMA',3,2,'BROWSE',NOW(3)); SELECT active_user_count FROM v_platform_daily_activity WHERE stat_date=CURRENT_DATE");
  positive('zero_price_order_needs_no_fake_payment',hold(100,2)+order(100,100,2)+"UPDATE ticket_order SET discount_amount=40,payable_amount=0,status='PAID',paid_at=NOW(3) WHERE id=100; SELECT COUNT(*) FROM ticket_order WHERE id=100 AND paid_amount=0 AND settled_payment_id IS NULL AND status='PAID'");
  positive('refunded_seat_can_be_resold_with_history',hold(100)+order(100)+"UPDATE ticket_order_item SET status='REFUNDED',refunded_amount=40 WHERE id=1; UPDATE ticket SET status='REFUNDED',qr_version=qr_version+1 WHERE id=1; UPDATE screening_seat SET status='LOCKED',sold_order_item_id=NULL,active_hold_id=100,locked_until=NOW(3)+INTERVAL 5 MINUTE WHERE id=1; INSERT INTO ticket_order_item(order_id,user_id,cinema_id,screening_id,film_id,screening_seat_id,seat_id,seat_label_snapshot,original_amount,payable_amount,status) VALUES (100,3,1,1,1,1,1,'1排1座',40,40,'UNPAID'); SELECT COUNT(*) FROM ticket_order_item WHERE screening_seat_id=1 AND status='UNPAID'");
  const readChecks=runSql('source database/05_readonly_checks.sql\n').stdout;
  if(!readChecks.includes('order_items_amount_mismatch\t0')) throw new Error('Read-only checks did not complete');
  for(const key of ['broken_order_amount','sold_seat_owner_mismatch','duplicate_valid_tickets_for_inventory','order_items_amount_mismatch']) {
    if(!readChecks.includes(key+'\t0')) throw new Error('Read-only check failed: '+key);
  }
  pass('read_only_consistency_queries','All four business consistency issue counts are zero');
  runSql('USE pzh_cinema; '+hold(800001)+hold(800002));
  const raceSql=id=>`SET time_zone='+08:00'; USE pzh_cinema; START TRANSACTION; UPDATE screening_seat SET status='LOCKED',active_hold_id=${id},locked_until=NOW(3)+INTERVAL 5 MINUTE,version=version+1 WHERE id=3 AND status='AVAILABLE'; SELECT ROW_COUNT(); DO SLEEP(0.5); COMMIT;`;
  const race=(await Promise.all([concurrentSql(raceSql(800001)),concurrentSql(raceSql(800002))])).sort();
  assertEqual('two_connection_seat_race',race.join(','),'0,1');
  assertEqual('one_lock_winner_persisted',scalar("SELECT COUNT(*) FROM screening_seat WHERE id=3 AND status='LOCKED' AND active_hold_id IN (800001,800002)"),1);
  report.constraintCounts=scalar("SELECT CONSTRAINT_TYPE,COUNT(*) FROM information_schema.table_constraints WHERE table_schema='pzh_cinema' GROUP BY CONSTRAINT_TYPE ORDER BY CONSTRAINT_TYPE");
  report.result='PASS';
}
(async()=>{
  try {await main();}
  catch(e) {report.result='FAIL';report.error=e.message;console.error(e.stack);process.exitCode=1;}
  finally {
    if(server && server.exitCode===null && !server.killed) {
      try {runSql('SHUTDOWN;');await Promise.race([new Promise(r=>server.once('exit',r)),delay(8000)]);}catch(e){report.shutdownError=e.message;}
      if(server.exitCode===null) {
        // On Windows mysqld may spawn a monitored child; terminate only our own process tree.
        if(process.platform==='win32') spawnSync('taskkill.exe',['/PID',String(server.pid),'/T','/F'],{windowsHide:true,stdio:'ignore'});
        else server.kill('SIGKILL');
        await delay(200);
        report.forcedStop=true;
      }
    }
    report.serverStopped=!server || server.exitCode!==null;
    fs.writeFileSync(path.join(runtime,'result.json'),JSON.stringify(report,null,2));
    console.log(JSON.stringify({result:report.result,passed:report.tests.length,tableCount:report.tableCount,viewCount:report.viewCount,serverStopped:report.serverStopped,report:path.join(runtime,'result.json')}));
  }
})();
