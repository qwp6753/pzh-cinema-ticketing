const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {parseEnv} = require('node:util');
const {spawnSync} = require('node:child_process');
const argv = process.argv.slice(2);
const option = (key, fallback) => argv.includes(key) ? argv[argv.indexOf(key) + 1] : fallback;
const project = path.resolve(option('--project', path.resolve(__dirname, '../..')));
const reportDir = path.resolve(option('--report-dir', path.join(project, 'work/database-audit')));
const client = option('--mysql-client', 'D:/MySQL/MySQL Server 8.0/bin/mysql.exe');
const database = 'pzh_cinema';
const config = parseEnv(fs.readFileSync(path.join(project, '.env.local'), 'utf8').replace(/^\uFEFF/, ''));
if (!config.SPRING_DATASOURCE_URL?.startsWith('jdbc:mysql://')) throw new Error('Expected a MySQL JDBC connection URL.');
const address = new URL(config.SPRING_DATASOURCE_URL.slice(5));
if (decodeURIComponent(address.pathname.slice(1)) !== database) throw new Error('Audit is restricted to pzh_cinema.');
const username = config.SPRING_DATASOURCE_USERNAME;
const password = config.SPRING_DATASOURCE_PASSWORD || '';
if (!username) throw new Error('Database username is missing.');
const model = JSON.parse(fs.readFileSync(path.join(project, 'database/schema-model.json'), 'utf8'));
const tables = model.tables.map(t => t.name).sort();
const viewNames = ['v_cinema_realtime','v_film_rating','v_platform_daily_activity','v_screening_inventory'];
const result = {date:'2026-10-23', database, checks:[], discrepancies:[], tables:[], uniqueIndexes:[], foreignKeys:[], functionalTests:[]};
const redact = text => password ? String(text).replaceAll(password, '[REDACTED]') : String(text);
const ident = name => {if (!/^[a-z_][a-z0-9_]*$/.test(name)) throw new Error('Unsafe identifier'); return '`' + name + '`';};
const literal = value => value === '' ? "''" : `CONVERT(0x${Buffer.from(String(value),'utf8').toString('hex')} USING utf8mb4)`;
function sql(input, allowError = false) {
  const r = spawnSync(client, ['--no-defaults','--protocol=TCP','--host='+address.hostname,'--port='+(address.port||3306),'--user='+username,'--connect-timeout=5','--batch','--raw','--skip-column-names','--default-character-set=utf8mb4'], {
    input:`SET time_zone='+08:00'; USE ${database};\n`+input,
    env:{...process.env, MYSQL_PWD:password}, encoding:'utf8', windowsHide:true, maxBuffer:16*1024*1024, timeout:120000
  });
  if ((r.error || r.status !== 0) && !allowError) throw new Error(redact(r.error?.message || r.stderr || 'MySQL query failed'));
  return {status:r.status, output:(r.stdout||'').trim(), error:redact(r.stderr||r.error?.message||'')};
}
const oneJson = query => JSON.parse(sql(query).output);
const jsonRows = query => {const value=sql(query).output;return value ? value.split(/\r?\n/).map(JSON.parse) : [];};
function assertCheck(name, ok, evidence) {result.checks.push({name,status:ok?'PASS':'FAIL',evidence});if(!ok)result.discrepancies.push({name,evidence});}
const eq = (a,b) => JSON.stringify(a)===JSON.stringify(b);
function normalizeType(value) {return String(value).toLowerCase().replace(/\b(bigint|int|tinyint|smallint|mediumint)\(\d+\)/g,'$1').replace(/\s+/g,' ').trim();}
function normalizeExpression(value) {
  // MySQL metadata represents generated-column string literals with escaped quotes.
  return String(value).replace(/\\'/g,"'").replace(/_utf8mb4(?=')/gi,'').replace(/`/g,'').replace(/[()\s]/g,'').toLowerCase();
}
function sameDefault(expected, actual) {
  if (expected === null) return actual === null;
  if (/^'.*'$/.test(expected)) return expected.slice(1,-1).replaceAll("''", "'") === actual;
  if (/^-?\d+(\.\d+)?$/.test(expected)) return actual !== null && Number(expected) === Number(actual);
  return String(expected).toLowerCase() === String(actual).toLowerCase();
}
function structureAudit() {
  result.serverVersion=sql('SELECT VERSION();').output;
  const actualTables=oneJson(`SELECT JSON_ARRAYAGG(JSON_OBJECT('name',TABLE_NAME,'kind',TABLE_TYPE,'engine',ENGINE,'collation',TABLE_COLLATION)) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${database}';`);
  const base=actualTables.filter(t=>t.kind==='BASE TABLE').map(t=>t.name).sort();
  const views=actualTables.filter(t=>t.kind==='VIEW').map(t=>t.name).sort();
  assertCheck('table_names',eq(base,tables),{expected:tables.length,actual:base.length,missing:tables.filter(x=>!base.includes(x)),unexpected:base.filter(x=>!tables.includes(x))});
  assertCheck('view_names',eq(views,[...viewNames].sort()),{expected:4,actual:views.length});
  assertCheck('storage_engine_charset',actualTables.filter(t=>t.kind==='BASE TABLE').every(t=>t.engine==='InnoDB'&&t.collation==='utf8mb4_0900_ai_ci'),{tables:base.length});
  const columns=oneJson(`SELECT JSON_ARRAYAGG(JSON_OBJECT('table',TABLE_NAME,'name',COLUMN_NAME,'position',ORDINAL_POSITION,'type',COLUMN_TYPE,'nullable',IS_NULLABLE,'default',COLUMN_DEFAULT,'extra',EXTRA,'generation',GENERATION_EXPRESSION,'charset',CHARACTER_SET_NAME,'collation',COLLATION_NAME)) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${database}' AND TABLE_NAME IN (${tables.map(literal).join(',')});`);
  const columnMap=new Map(columns.map(c=>[c.table+'.'+c.name,c]));
  const indexes=oneJson(`SELECT JSON_ARRAYAGG(JSON_OBJECT('table',TABLE_NAME,'name',INDEX_NAME,'seq',SEQ_IN_INDEX,'column',COLUMN_NAME,'nonUnique',NON_UNIQUE,'prefix',SUB_PART,'kind',INDEX_TYPE,'visible',IS_VISIBLE)) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='${database}';`);
  const indexMap=new Map();for(const x of indexes){const key=x.table+'.'+x.name;if(!indexMap.has(key))indexMap.set(key,[]);indexMap.get(key).push(x);}for(const x of indexMap.values())x.sort((a,b)=>a.seq-b.seq);
  const keys=oneJson(`SELECT JSON_ARRAYAGG(JSON_OBJECT('table',k.TABLE_NAME,'name',k.CONSTRAINT_NAME,'column',k.COLUMN_NAME,'seq',k.ORDINAL_POSITION,'parentTable',k.REFERENCED_TABLE_NAME,'parentColumn',k.REFERENCED_COLUMN_NAME,'deleteRule',r.DELETE_RULE,'updateRule',r.UPDATE_RULE)) FROM information_schema.KEY_COLUMN_USAGE k JOIN information_schema.REFERENTIAL_CONSTRAINTS r ON r.CONSTRAINT_SCHEMA=k.CONSTRAINT_SCHEMA AND r.TABLE_NAME=k.TABLE_NAME AND r.CONSTRAINT_NAME=k.CONSTRAINT_NAME WHERE k.TABLE_SCHEMA='${database}' AND k.REFERENCED_TABLE_NAME IS NOT NULL;`);
  const keyMap=new Map();for(const x of keys){const key=x.table+'.'+x.name;if(!keyMap.has(key))keyMap.set(key,[]);keyMap.get(key).push(x);}for(const x of keyMap.values())x.sort((a,b)=>a.seq-b.seq);
  const constraints=oneJson(`SELECT JSON_ARRAYAGG(JSON_OBJECT('table',TABLE_NAME,'name',CONSTRAINT_NAME,'kind',CONSTRAINT_TYPE,'enforced',ENFORCED)) FROM information_schema.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA='${database}';`);
  let expectedUnique=0, expectedOrdinary=0, identifierCount=0;
  for(const t of model.tables) {
    const failures=[];
    const actualColumns=columns.filter(c=>c.table===t.name);
    if(actualColumns.length!==t.columns.length)failures.push('column_count');
    for(const [i,definition] of t.columns.entries()) {
      const c=columnMap.get(t.name+'.'+definition.name);
      if(!c){failures.push('missing_column:'+definition.name);continue;}
      const expectedType=normalizeType(definition.type.split(/\s+/)[0]);
      if(normalizeType(c.type)!==expectedType)failures.push('column_type:'+definition.name);
      if(c.position!==i+1)failures.push('column_order:'+definition.name);
      if((c.nullable==='NO')!==/\bNOT NULL\b/.test(definition.type))failures.push('nullability:'+definition.name);
      if(c.extra.toLowerCase().includes('auto_increment')!==/\bAUTO_INCREMENT\b/.test(definition.type))failures.push('auto_increment:'+definition.name);
      const declaredDefault=definition.type.match(/\bDEFAULT\s+('(?:''|[^'])*'|\S+)/i)?.[1]??null;
      if(!sameDefault(declaredDefault,c.default))failures.push('default:'+definition.name);
      if(/\bON UPDATE CURRENT_TIMESTAMP/i.test(definition.type)!==/on update CURRENT_TIMESTAMP/i.test(c.extra))failures.push('on_update:'+definition.name);
      if(/^(varchar|text)/i.test(expectedType)){
        const expectedCollation=definition.type.match(/\bCOLLATE\s+(\w+)/i)?.[1]||'utf8mb4_0900_ai_ci';
        if(c.charset!=='utf8mb4'||c.collation!==expectedCollation)failures.push('collation:'+definition.name);
      }
      const generated=definition.type.match(/GENERATED ALWAYS AS \((.*)\) STORED/);
      if(generated&&(!c.extra.includes('STORED GENERATED')||normalizeExpression(generated[1])!==normalizeExpression(c.generation)))failures.push('generated_expression:'+definition.name);
      if(['user_id','cinema_id'].includes(definition.name)){
        identifierCount++;
        if(normalizeType(c.type)!=='bigint')failures.push('entity_id_type:'+definition.name);
      }
    }
    const primary=indexMap.get(t.name+'.PRIMARY')||[];
    const id=columnMap.get(t.name+'.id');
    if(!eq(primary.map(x=>x.column),['id'])||!id||normalizeType(id.type)!=='bigint'||id.nullable!=='NO'||!id.extra.includes('auto_increment'))failures.push('primary_key');
    for(const [i,c] of t.constraints.entries()) {
      if(!['PRIMARY KEY','UNIQUE KEY','KEY'].includes(c.kind))continue;
      const name=c.kind==='PRIMARY KEY'?'PRIMARY':`${t.name}_${c.kind==='KEY'?'ix':'uk'}_${i}`;
      const actual=indexMap.get(t.name+'.'+name)||[];
      if(!eq(actual.map(x=>x.column),c.cols)||actual.some(x=>x.nonUnique!==(c.kind==='KEY'?1:0)||x.prefix!==null||x.kind!=='BTREE'||x.visible!=='YES'))failures.push('index:'+name);
      if(c.kind==='UNIQUE KEY'){expectedUnique++;result.uniqueIndexes.push({table:t.name,name,columns:c.cols,verified:actual.length>0&&!failures.includes('index:'+name)});}
      if(c.kind==='KEY')expectedOrdinary++;
    }
    const checks=t.constraints.map((c,i)=>({c,i})).filter(x=>x.c.kind==='CHECK');
    for(const {i} of checks)if(!constraints.some(c=>c.table===t.name&&c.name===`${t.name}_ck_${i}`&&c.kind==='CHECK'&&c.enforced==='YES'))failures.push('check_constraint:'+i);
    const row={table:t.name,title:t.title,columns:actualColumns.length,primaryType:id?.type,uniqueIndexes:t.constraints.filter(c=>c.kind==='UNIQUE KEY').length,foreignKeys:keys.filter(k=>k.table===t.name&&k.seq===1).length,status:failures.length?'FAIL':'PASS'};
    result.tables.push(row);
    for(const problem of failures)result.discrepancies.push({table:t.name,problem});
  }
  const actualUnique=[...indexMap.values()].filter(x=>x[0].name!=='PRIMARY'&&x[0].nonUnique===0);
  assertCheck('unique_index_count',actualUnique.length===expectedUnique,{expected:expectedUnique,actual:actualUnique.length});
  const expectedForeign=[];
  for(const t of model.tables)t.constraints.forEach((c,i)=>{if(c.kind==='FOREIGN KEY')expectedForeign.push({source:t.name,name:`${t.name}_fk_${i}`,columns:c.cols,parent:c.table,targets:c.targets});});
  model.deferred.forEach((d,i)=>expectedForeign.push({source:d.table,name:`${d.table}_fk_${90+i}`,columns:d.constraint.cols,parent:d.constraint.table,targets:d.constraint.targets}));
  let foreignColumnPairs=0, typeMismatch=0;
  for(const fk of expectedForeign) {
    const actual=keyMap.get(fk.source+'.'+fk.name)||[];
    let ok=eq(actual.map(k=>k.column),fk.columns)&&eq(actual.map(k=>k.parentColumn),fk.targets)&&actual.every(k=>k.parentTable===fk.parent&&k.deleteRule==='RESTRICT'&&k.updateRule==='RESTRICT');
    const pairs=[];
    for(const [i,column] of fk.columns.entries()){
      const child=columnMap.get(fk.source+'.'+column),parent=columnMap.get(fk.parent+'.'+fk.targets[i]);
      const compatible=!!child&&!!parent&&normalizeType(child.type)===normalizeType(parent.type)&&child.charset===parent.charset&&child.collation===parent.collation;
      foreignColumnPairs++;if(!compatible){typeMismatch++;ok=false;}
      pairs.push({column,childType:child?.type,parentColumn:fk.targets[i],parentType:parent?.type,typeMatches:compatible});
    }
    const childIndex=[...indexMap.values()].some(rows=>rows[0].table===fk.source&&eq(rows.slice(0,fk.columns.length).map(r=>r.column),fk.columns));
    const parentUnique=[...indexMap.values()].some(rows=>rows[0].table===fk.parent&&rows[0].nonUnique===0&&eq(rows.map(r=>r.column),fk.targets));
    if(!childIndex||!parentUnique)ok=false;
    result.foreignKeys.push({...fk,pairs,deleteRule:actual[0]?.deleteRule,updateRule:actual[0]?.updateRule,childIndex,parentUnique,status:ok?'PASS':'FAIL'});
    if(!ok)result.discrepancies.push({table:fk.source,problem:'foreign_key:'+fk.name});
  }
  assertCheck('foreign_key_count',keyMap.size===expectedForeign.length,{expected:expectedForeign.length,actual:keyMap.size});
  assertCheck('foreign_key_types',typeMismatch===0,{columnPairs:foreignColumnPairs,mismatches:typeMismatch});
  assertCheck('all_table_definitions',result.tables.every(t=>t.status==='PASS'),{checkedColumns:columns.length,tables:model.tables.length,userAndCinemaIdFields:identifierCount});
  result.structure={tableCount:base.length,viewCount:views.length,columnCount:columns.length,primaryKeys:result.tables.length,uniqueIndexes:actualUnique.length,ordinaryIndexesDeclared:expectedOrdinary,foreignKeys:keyMap.size,foreignColumnPairs,typeMismatch,checkConstraints:constraints.filter(c=>c.kind==='CHECK').length};
  console.log(JSON.stringify({phase:'structure',...result.structure,discrepancies:result.discrepancies}));
}

function counts() {
  return oneJson(`SELECT JSON_OBJECT(${tables.map(t=>literal(t)+`,(SELECT COUNT(*) FROM ${ident(t)})`).join(',')});`);
}

function seedDemo() {
  const baseTables=new Set(['sys_region','sys_role','sys_permission','sys_role_permission','film_category','member_level']);
  const emptyBusiness=tables.filter(t=>!baseTables.has(t)).every(t=>result.dataBefore[t]===0);
  const hasDemo=Number(sql("SELECT COUNT(*) FROM cinema WHERE (id=1 AND cinema_code='DEMO_EAST') OR (id=2 AND cinema_code='DEMO_RENHE');").output)===2;
  if(emptyBusiness&&argv.includes('--seed-demo')) {
    const file='database/03_demo.sql';
    const manifest=fs.readFileSync(path.join(project,'SHA256SUMS.txt'),'utf8').trim().split(/\r?\n/);
    const expected=manifest.find(line=>line.slice(line.indexOf('  ')+2)===file)?.split('  ')[0];
    const bytes=fs.readFileSync(path.join(project,file));
    if(crypto.createHash('sha256').update(bytes).digest('hex')!==expected)throw new Error('Demo SQL does not match the verified manifest.');
    sql(bytes.toString('utf8'));
    result.demoAction='imported_into_empty_business_tables';
  } else if(hasDemo) result.demoAction='reused_existing_demo_without_overwrite';
  else throw new Error('No designated demo fixture found. No existing records overwritten. Use --seed-demo only with empty business tables.');
  result.dataAfterSeed=counts();
  const c=result.dataAfterSeed;
  assertCheck('baseline_seed_data',c.sys_region>=6&&c.sys_role>=4&&c.sys_permission>=41&&c.sys_role_permission>=42&&c.film_category>=8&&c.member_level>=3,
    {regions:c.sys_region,roles:c.sys_role,permissions:c.sys_permission,rolePermissions:c.sys_role_permission,filmCategories:c.film_category,memberLevels:c.member_level});
  assertCheck('development_catalog_data',c.film>=2&&c.cinema>=2&&c.cinema_hall>=2&&c.cinema_seat>=16&&c.cinema_screening>=3&&c.screening_seat>=26,
    {users:c.sys_user,films:c.film,cinemas:c.cinema,halls:c.cinema_hall,physicalSeats:c.cinema_seat,screenings:c.cinema_screening,screeningInventory:c.screening_seat,mockOrders:c.ticket_order});
  console.log(JSON.stringify({phase:'demo',action:result.demoAction,films:c.film,cinemas:c.cinema,halls:c.cinema_hall,seats:c.cinema_seat,screenings:c.cinema_screening,inventory:c.screening_seat}));
}

function integrityAudit() {
  const orphanQueries=result.foreignKeys.map(fk=>{
    const present=fk.columns.map(c=>'c.'+ident(c)+' IS NOT NULL').join(' AND ');
    const matching=fk.columns.map((c,i)=>'c.'+ident(c)+' = p.'+ident(fk.targets[i])).join(' AND ');
    return `SELECT JSON_OBJECT('name',${literal(fk.source+'.'+fk.name)},'count',COUNT(*)) FROM ${ident(fk.source)} c WHERE ${present} AND NOT EXISTS (SELECT 1 FROM ${ident(fk.parent)} p WHERE ${matching});`;
  });
  const orphans=jsonRows(orphanQueries.join('\n'));
  for(const fk of result.foreignKeys)fk.orphanRows=orphans.find(x=>x.name===fk.source+'.'+fk.name)?.count;
  assertCheck('foreign_key_existing_rows',orphans.length===result.foreignKeys.length&&orphans.every(x=>x.count===0),{relationshipsChecked:orphans.length,orphanRows:orphans.reduce((n,x)=>n+x.count,0)});
  const duplicateQueries=result.uniqueIndexes.map(index=>{
    const fields=index.columns.map(ident).join(',');
    const present=index.columns.map(c=>ident(c)+' IS NOT NULL').join(' AND ');
    return `SELECT JSON_OBJECT('name',${literal(index.table+'.'+index.name)},'count',COUNT(*)) FROM (SELECT ${fields} FROM ${ident(index.table)} WHERE ${present} GROUP BY ${fields} HAVING COUNT(*) > 1) duplicates;`;
  });
  const duplicates=jsonRows(duplicateQueries.join('\n'));
  for(const index of result.uniqueIndexes)index.duplicateGroups=duplicates.find(x=>x.name===index.table+'.'+index.name)?.count;
  assertCheck('unique_index_existing_rows',duplicates.length===result.uniqueIndexes.length&&duplicates.every(x=>x.count===0),{indexesChecked:duplicates.length,duplicateGroups:duplicates.reduce((n,x)=>n+x.count,0)});
}

function checksums() {
  const rows=sql('CHECKSUM TABLE '+tables.map(ident).join(',')+' EXTENDED;').output.split(/\r?\n/);
  const values={};for(const row of rows){const [table,value]=row.split('\t');if(value==='NULL'||!value)throw new Error('Table checksum unavailable');values[table.split('.').pop()]=value;}
  if(Object.keys(values).length!==tables.length)throw new Error('Incomplete table checksums');
  return values;
}

function functionalAudit() {
  const snapshot=checksums();
  const before=counts();
  const tag='AUDIT_'+crypto.randomBytes(8).toString('hex');
  let next=-Date.now();
  const id=()=>next--;
  function record(name,ok,evidence) {
    result.functionalTests.push({name,status:ok?'PASS':'FAIL',evidence});
    if(!ok)result.discrepancies.push({name,evidence});
    console.log((ok?'PASS ':'FAIL ')+name);
  }
  function reject(name,statement,errorCode) {
    const response=sql('START TRANSACTION;\n'+statement+'\nROLLBACK;',true);
    const actual=response.error.match(/ERROR (\d+)\b/)?.[1];
    record(name,response.status!==0&&actual===String(errorCode),{expectedError:errorCode,actualError:actual||null,transaction:'connection-close rollback on error'});
  }
  function transaction(name,statement,expectation) {
    const rows=jsonRows('START TRANSACTION;\n'+statement+'\nROLLBACK;');
    record(name,expectation(rows),{observed:rows,transaction:'rolled back'});
  }
  const catalog=oneJson(`SELECT JSON_OBJECT('screenings',COUNT(DISTINCT s.id),'inventory',COUNT(i.id),'sold',SUM(i.status='SOLD'),'available',SUM(i.status='AVAILABLE')) FROM film f JOIN cinema_film cf ON cf.film_id=f.id JOIN cinema c ON c.id=cf.cinema_id JOIN cinema_screening s ON s.cinema_id=cf.cinema_id AND s.film_id=cf.film_id JOIN cinema_hall h ON h.id=s.hall_id AND h.cinema_id=c.id JOIN screening_seat i ON i.screening_id=s.id WHERE c.cinema_code IN ('DEMO_EAST','DEMO_RENHE');`);
  record('multi_table_catalog_query',catalog.screenings===3&&catalog.inventory===26&&catalog.sold===1&&catalog.available===25,catalog);
  const view=oneJson("SELECT JSON_OBJECT('available',available_count,'sold',sold_count,'occupancy',occupancy_percent) FROM v_screening_inventory WHERE screening_id=1;");
  record('inventory_view_query',view.available===9&&view.sold===1&&Number(view.occupancy)===10,view);
  record('realtime_sales_view_query',Number(sql('SELECT all_time_net_sales FROM v_cinema_realtime WHERE cinema_id=1;').output)===40,{expectedDemoAmount:'40.00',provider:'MOCK'});
  const user=id();
  transaction('insert_update_delete_savepoint_and_rollback',`
    INSERT INTO sys_user(id,username,nickname,status) VALUES (${user},${literal(tag+'_USER')},${literal('临时核验用户')},'LOCKED');
    SELECT JSON_OBJECT('inserted',ROW_COUNT(),'exists',(SELECT COUNT(*) FROM sys_user WHERE id=${user}));
    UPDATE sys_user SET nickname=${literal('临时核验已更新')} WHERE id=${user};
    SELECT JSON_OBJECT('updated',ROW_COUNT(),'valueMatches',(SELECT nickname=${literal('临时核验已更新')} FROM sys_user WHERE id=${user}));
    SAVEPOINT before_delete;
    DELETE FROM sys_user WHERE id=${user};
    SELECT JSON_OBJECT('deleted',ROW_COUNT(),'exists',(SELECT COUNT(*) FROM sys_user WHERE id=${user}));
    ROLLBACK TO SAVEPOINT before_delete;
    SELECT JSON_OBJECT('restoredBySavepoint',(SELECT COUNT(*) FROM sys_user WHERE id=${user}));
    ROLLBACK;
    SELECT JSON_OBJECT('remainingAfterRollback',(SELECT COUNT(*) FROM sys_user WHERE id=${user}));
  `,rows=>rows.length===5&&rows[0].inserted===1&&rows[0].exists===1&&rows[1].updated===1&&rows[1].valueMatches===1&&rows[2].deleted===1&&rows[2].exists===0&&rows[3].restoredBySavepoint===1&&rows[4].remainingAfterRollback===0);
  const original=Number(sql('SELECT heat_score FROM film WHERE id=1;').output);
  transaction('update_existing_record_rollback',`
    UPDATE film SET heat_score=heat_score+1 WHERE id=1;
    SELECT JSON_OBJECT('duringTransaction',heat_score) FROM film WHERE id=1;
    ROLLBACK;
    SELECT JSON_OBJECT('afterRollback',heat_score) FROM film WHERE id=1;
  `,rows=>rows.length===2&&rows[0].duringTransaction===original+1&&rows[1].afterRollback===original);
  const chain=id();
  const chainTables=['sys_user','cinema','cinema_hall','cinema_seat','film','cinema_film','cinema_screening','screening_seat','seat_hold','seat_hold_item','ticket_order','ticket_order_item'];
  transaction('linked_catalog_lock_and_order_rollback',`
    INSERT INTO sys_user(id,username,nickname,status) VALUES (${chain},${literal(tag+'_CHAIN_USER')},'临时用户','LOCKED');
    INSERT INTO cinema(id,cinema_code,cinema_name,region_id,address,status) VALUES (${chain},${literal(tag+'_CINEMA')},'临时核验影院',2,'临时测试地址','ACTIVE');
    INSERT INTO cinema_hall(id,cinema_id,hall_name,row_count,column_count) VALUES (${chain},${chain},'临时厅',1,1);
    INSERT INTO cinema_seat(id,cinema_id,hall_id,row_no,column_no,seat_label) VALUES (${chain},${chain},${chain},1,1,'1排1座');
    INSERT INTO film(id,film_name,director,duration_minutes,synopsis,release_status,publish_status) VALUES (${chain},'临时核验影片','测试导演',120,'回滚测试','SHOWING','PUBLISHED');
    INSERT INTO cinema_film(id,cinema_id,film_id) VALUES (${chain},${chain},${chain});
    INSERT INTO cinema_screening(id,cinema_id,hall_id,film_id,starts_at,ends_at,hall_release_at,sale_starts_at,sale_ends_at,base_price,audio_language,projection_format,status) VALUES (${chain},${chain},${chain},${chain},NOW(3)+INTERVAL 1 DAY,NOW(3)+INTERVAL 26 HOUR,NOW(3)+INTERVAL 27 HOUR,NOW(3),NOW(3)+INTERVAL 23 HOUR,50,'普通话','2D','ON_SALE');
    INSERT INTO screening_seat(id,screening_id,cinema_id,hall_id,seat_id,seat_label_snapshot,sale_price) VALUES (${chain},${chain},${chain},${chain},${chain},'1排1座',50);
    INSERT INTO seat_hold(id,hold_no,user_id,cinema_id,screening_id,token_hash,expires_at) VALUES (${chain},${literal(tag+'_CHAIN_HOLD')},${chain},${chain},${chain},SHA2(${literal(tag+'_CHAIN_TOKEN')},256),NOW(3)+INTERVAL 5 MINUTE);
    UPDATE screening_seat SET status='LOCKED',active_hold_id=${chain},locked_until=NOW(3)+INTERVAL 5 MINUTE,version=version+1 WHERE id=${chain};
    INSERT INTO seat_hold_item(id,hold_id,screening_id,cinema_id,screening_seat_id,seat_id,price_snapshot) VALUES (${chain},${chain},${chain},${chain},${chain},${chain},50);
    INSERT INTO ticket_order(id,order_no,user_id,cinema_id,screening_id,film_id,hold_id,original_amount,payable_amount,expires_at,film_name_snapshot,cinema_name_snapshot,hall_name_snapshot,starts_at_snapshot) VALUES (${chain},${literal(tag+'_CHAIN_ORDER')},${chain},${chain},${chain},${chain},${chain},50,50,NOW(3)+INTERVAL 5 MINUTE,'临时核验影片','临时核验影院','临时厅',NOW(3)+INTERVAL 1 DAY);
    INSERT INTO ticket_order_item(id,order_id,user_id,cinema_id,screening_id,film_id,screening_seat_id,seat_id,seat_label_snapshot,original_amount,payable_amount) VALUES (${chain},${chain},${chain},${chain},${chain},${chain},${chain},${chain},'1排1座',50,50);
    UPDATE seat_hold SET status='ORDERED' WHERE id=${chain};
    SELECT JSON_OBJECT('joinedOrder',(SELECT COUNT(*) FROM ticket_order o JOIN ticket_order_item i ON i.order_id=o.id JOIN screening_seat s ON s.id=i.screening_seat_id AND s.active_hold_id=o.hold_id WHERE o.id=${chain}),'inventoryState',(SELECT status FROM screening_seat WHERE id=${chain}));
    ROLLBACK;
    SELECT JSON_OBJECT('remainingRows',${chainTables.map(t=>`(SELECT COUNT(*) FROM ${ident(t)} WHERE id=${chain})`).join('+')});
  `,rows=>rows.length===2&&rows[0].joinedOrder===1&&rows[0].inventoryState==='LOCKED'&&rows[1].remainingRows===0);

  const hold=(n,show=1,customer=3)=>`INSERT INTO seat_hold(id,hold_no,user_id,cinema_id,screening_id,token_hash,expires_at) VALUES (${n},${literal(tag+'_H_'+n)},${customer},1,${show},SHA2(${literal(tag+'_HT_'+n)},256),NOW(3)+INTERVAL 5 MINUTE);`;
  const order=(n,holdId=n,show=1,customer=3)=>`INSERT INTO ticket_order(id,order_no,user_id,cinema_id,screening_id,film_id,hold_id,original_amount,payable_amount,expires_at,film_name_snapshot,cinema_name_snapshot,hall_name_snapshot,starts_at_snapshot) VALUES (${n},${literal(tag+'_O_'+n)},${customer},1,${show},1,${holdId},40,40,NOW(3)+INTERVAL 5 MINUTE,'审计测试影片','审计测试影院','审计测试厅',NOW(3)+INTERVAL 1 DAY);`;
  reject('duplicate_username_rejected',`INSERT INTO sys_user(id,username,nickname) VALUES (${id()},'demo_customer','重复测试');`,1062);
  reject('duplicate_cinema_code_rejected',`INSERT INTO cinema(id,cinema_code,cinema_name,region_id,address) VALUES (${id()},'DEMO_EAST','重复测试',2,'测试');`,1062);
  reject('duplicate_hall_name_rejected',`INSERT INTO cinema_hall(id,cinema_id,hall_name) VALUES (${id()},1,'一号厅');`,1062);
  reject('duplicate_physical_seat_rejected',`INSERT INTO cinema_seat(id,cinema_id,hall_id,row_no,column_no,seat_label) VALUES (${id()},1,1,1,1,${literal(tag)});`,1062);
  reject('duplicate_screening_inventory_rejected',`INSERT INTO screening_seat(id,screening_id,cinema_id,hall_id,seat_id,seat_label_snapshot,sale_price) VALUES (${id()},1,1,1,1,'重复测试',40);`,1062);
  reject('duplicate_favorite_rejected',`INSERT INTO user_favorite_film(id,user_id,film_id) VALUES (${id()},3,1);`,1062);
  reject('duplicate_global_role_rejected',`INSERT INTO sys_user_role(id,user_id,role_id,scope_type,cinema_id) VALUES (${id()},3,3,'GLOBAL',NULL);`,1062);
  reject('duplicate_payment_trade_rejected',`INSERT INTO payment_transaction(id,payment_no,order_id,provider,provider_trade_no,idempotency_key,amount) VALUES (${id()},${literal(tag+'_PAY')},1,'MOCK','DEMO-TRADE-1',${literal(tag+'_PAY')},40);`,1062);
  const qr1=id(),qr2=id();
  reject('duplicate_qr_nonce_rejected',`INSERT INTO ticket_qr_token(id,ticket_id,cinema_id,nonce_hash,valid_from,expires_at) VALUES (${qr1},1,1,SHA2(${literal(tag+'_QR')},256),NOW(3),NOW(3)+INTERVAL 30 SECOND),(${qr2},1,1,SHA2(${literal(tag+'_QR')},256),NOW(3),NOW(3)+INTERVAL 30 SECOND);`,1062);
  const after1=id(),after2=id(),item1=id(),item2=id();
  reject('duplicate_inflight_after_sale_rejected',`INSERT INTO after_sale_request(id,request_no,request_type,original_order_id,user_id,cinema_id,reason) VALUES (${after1},${literal(tag+'_AS1')},'REFUND',1,3,1,'核验'),(${after2},${literal(tag+'_AS2')},'REFUND',1,3,1,'核验'); INSERT INTO after_sale_item(id,request_id,original_order_id,cinema_id,original_order_item_id) VALUES (${item1},${after1},1,1,1),(${item2},${after2},1,1,1);`,1062);
  const token1=id(),token2=id(),scan1=id(),scan2=id();
  reject('duplicate_successful_verification_rejected',`INSERT INTO ticket_qr_token(id,ticket_id,cinema_id,nonce_hash,valid_from,expires_at) VALUES (${token1},1,1,SHA2(${literal(tag+'_Q1')},256),NOW(3),NOW(3)+INTERVAL 30 SECOND),(${token2},1,1,SHA2(${literal(tag+'_Q2')},256),NOW(3),NOW(3)+INTERVAL 30 SECOND); INSERT INTO ticket_verification_log(id,cinema_id,operator_id,ticket_id,qr_token_id,result) VALUES (${scan1},1,2,1,${token1},'SUCCESS'),(${scan2},1,2,1,${token2},'SUCCESS');`,1062);
  const secondOrder=id(),usage1=id(),usage2=id();
  reject('duplicate_coupon_occupation_rejected',hold(secondOrder,2)+order(secondOrder,secondOrder,2)+`INSERT INTO coupon_usage(id,user_coupon_id,user_id,order_id,cinema_id,discount_amount) VALUES (${usage1},1,3,1,1,0),(${usage2},1,3,${secondOrder},1,0);`,1062);
  reject('duplicate_callback_event_rejected',`INSERT INTO payment_callback_event(id,provider,provider_event_id,event_type,business_no,payload_hash) VALUES (${id()},'MOCK',${literal(tag+'_EVENT')},'PAYMENT',${literal(tag)},SHA2(${literal(tag)},256)),(${id()},'MOCK',${literal(tag+'_EVENT')},'PAYMENT',${literal(tag)},SHA2(${literal(tag)},256));`,1062);
  const activeSale=id();
  reject('duplicate_active_sale_rejected',hold(activeSale)+order(activeSale)+`INSERT INTO ticket_order_item(id,order_id,user_id,cinema_id,screening_id,film_id,screening_seat_id,seat_id,seat_label_snapshot,original_amount,payable_amount) VALUES (${id()},${activeSale},3,1,1,1,1,1,'重复售票',40,40);`,1062);
  reject('unknown_parent_cinema_rejected',`INSERT INTO cinema_hall(id,cinema_id,hall_name) VALUES (${id()},${id()},'未知影院测试');`,1452);
  reject('cross_cinema_seat_rejected',`INSERT INTO screening_seat(id,screening_id,cinema_id,hall_id,seat_id,seat_label_snapshot,sale_price) VALUES (${id()},1,1,1,201,'跨影院测试',40);`,1452);
  reject('cross_cinema_screening_rejected',`INSERT INTO screening_seat(id,screening_id,cinema_id,hall_id,seat_id,seat_label_snapshot,sale_price) VALUES (${id()},3,1,1,2,'跨影院测试',40);`,1452);
  const otherUser=id();
  reject('order_hold_owner_mismatch_rejected',hold(otherUser)+order(otherUser,otherUser,1,2),1452);
  reject('role_scope_mismatch_rejected',`INSERT INTO sys_user_role(id,user_id,role_id,scope_type,cinema_id) VALUES (${id()},3,1,'CINEMA',1);`,1452);
  reject('sold_seat_owner_mismatch_rejected',"UPDATE screening_seat SET status='SOLD',sold_order_item_id=1 WHERE id=2;",1452);
  reject('refund_provider_mismatch_rejected',`INSERT INTO payment_refund(id,refund_no,order_id,payment_id,provider,refund_reason,idempotency_key,amount) VALUES (${id()},${literal(tag+'_REFUND')},1,1,'WECHAT','SYSTEM_CANCEL',${literal(tag+'_REFUND')},1);`,1452);
  reject('referenced_cinema_delete_rejected','DELETE FROM cinema WHERE id=1;',1451);
  reject('negative_price_rejected','UPDATE screening_seat SET sale_price=-1 WHERE id=2;',3819);
  reject('invalid_inventory_lock_rejected',"UPDATE screening_seat SET status='LOCKED' WHERE id=2;",3819);
  reject('negative_member_points_rejected','UPDATE member_account SET points_balance=-1 WHERE id=1;',3819);
  reject('inconsistent_order_amount_rejected','UPDATE ticket_order SET discount_amount=1 WHERE id=1;',3819);
  reject('invalid_review_rating_rejected',`INSERT INTO film_review(id,user_id,film_id,cinema_id,order_item_id,rating,content) VALUES (${id()},3,1,1,1,6,'评分测试');`,3819);
  reject('coupon_overissue_rejected','UPDATE coupon_template SET issued_quantity=total_quantity+1 WHERE id=1;',3819);
  const after=counts(),afterChecksum=checksums();
  const changed=tables.filter(t=>before[t]!==after[t]||snapshot[t]!==afterChecksum[t]);
  record('all_test_writes_rolled_back',changed.length===0,{tablesCompared:tables.length,changedTables:changed,rowCountsAndContentMatch:changed.length===0});
  result.dataAfterTests=after;
  result.rollbackProof={tablesCompared:tables.length,changedTables:changed};
}

function save() {
  fs.mkdirSync(reportDir,{recursive:true});
  fs.writeFileSync(path.join(reportDir,'audit-result.json'),JSON.stringify(result,null,2),'utf8');
}

try {
  structureAudit();
  result.dataBefore=counts();
  if(result.discrepancies.length)throw new Error('Structure audit found differences; no data changed.');
  if(argv.includes('--structure-only')) {
    result.status='STRUCTURE_PASS';save();
    console.log(JSON.stringify({phase:'data_counts',users:result.dataBefore.sys_user,films:result.dataBefore.film,cinemas:result.dataBefore.cinema,halls:result.dataBefore.cinema_hall,seats:result.dataBefore.cinema_seat,screenings:result.dataBefore.cinema_screening,inventory:result.dataBefore.screening_seat}));
  } else {
    seedDemo();
    if(result.discrepancies.length)throw new Error('Fixture validation failed.');
    integrityAudit();
    functionalAudit();
    result.status=result.discrepancies.length?'FAIL':'PASS';save();
    console.log(JSON.stringify({phase:'complete',status:result.status,structure:result.structure,functionalPassed:result.functionalTests.filter(t=>t.status==='PASS').length,functionalFailed:result.functionalTests.filter(t=>t.status==='FAIL').length,discrepancies:result.discrepancies}));
    if(result.discrepancies.length)process.exitCode=1;
  }
} catch(error) {
  result.status='FAIL';result.error=redact(error.message);save();console.error(result.error);process.exitCode=1;
}
