#!/usr/bin/env node
// 可选的本地启动工具：安全解析 dotenv 为子进程环境，不执行文件内容、不输出凭据。
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync, spawn} = require('node:child_process');
const {parseEnv} = require('node:util');
if (!parseEnv) throw Error('此工具需要 Node.js 20.12+；也可以手动设置环境变量后使用 Maven。');
const args = process.argv.slice(2);
const mode = args[0] || 'run';
const goals = {run:['spring-boot:run'], test:['test'], verify:['verify'], 'verify-live':['-Plive','verify'], package:['package']};
if (!Object.hasOwn(goals,mode)) throw Error('操作仅支持 run / test / verify / verify-live / package');
const options = {};
for (let i=1;i<args.length;i+=2) {
  if (!['--java-home','--maven-home','--repo-local','--config-file'].includes(args[i]) || !args[i+1]) throw Error('无效选项');
  options[args[i]]=args[i+1];
}
const backend=path.resolve(__dirname,'..');
const envFile=path.resolve(options['--config-file'] || path.join(backend,'../.env.local'));
const local=fs.existsSync(envFile)?parseEnv(fs.readFileSync(envFile,'utf8').replace(/^\uFEFF/,'')):{};
const env={...process.env,...local};
const javaHome=options['--java-home'] || env.JAVA_HOME;
const java=javaHome?path.join(javaHome,'bin',process.platform==='win32'?'java.exe':'java'):'java';
const version=spawnSync(java,['-version'],{encoding:'utf8',windowsHide:true});
if (version.status!==0 || !/version "21\./.test(version.stderr+version.stdout)) {
  throw Error('请使用 JDK 21：设置 JAVA_HOME 或传入 --java-home。此工具不修改全局 Java 设置。');
}
let mavenHome=options['--maven-home'] || env.MAVEN_HOME || env.M2_HOME;
if (!mavenHome) {
  const found=spawnSync(process.platform==='win32'?'where.exe':'which',['mvn'],{encoding:'utf8',windowsHide:true});
  const executable=found.status===0?found.stdout.trim().split(/\r?\n/)[0]:null;
  if (executable) mavenHome=path.resolve(path.dirname(executable),'..');
}
if (!mavenHome) throw Error('未找到 Maven，请设置 MAVEN_HOME 或 --maven-home。');
const boot=path.join(mavenHome,'boot');
const jar=fs.readdirSync(boot).find(name=>/^plexus-classworlds-.*\.jar$/.test(name));
if (!jar) throw Error('Maven 安装目录缺少 plexus-classworlds。');
const javaArgs=['-Dfile.encoding=UTF-8','-Dmaven.home='+mavenHome,'-Dmaven.multiModuleProjectDirectory='+backend,
  '-Dclassworlds.conf='+path.join(mavenHome,'bin/m2.conf'),'-classpath',path.join(boot,jar),
  'org.codehaus.plexus.classworlds.launcher.Launcher','-B','-ntp'];
if (options['--repo-local']) javaArgs.push('-Dmaven.repo.local='+path.resolve(options['--repo-local']));
javaArgs.push(...goals[mode]);
if (javaHome) env.JAVA_HOME=javaHome;
const child=spawn(java,javaArgs,{cwd:backend,env,stdio:'inherit',windowsHide:true});
child.on('error',()=>{console.error('Maven 进程启动失败，请检查工具路径。');process.exitCode=1;});
child.on('exit',code=>{process.exitCode=code??1;});
