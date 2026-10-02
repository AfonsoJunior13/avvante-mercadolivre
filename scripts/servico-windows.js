/**
 * Instala o worker como serviço do Windows via WinSW 1.17 (MIT), em scripts/winsw.
 * O Node não implementa o protocolo do Service Control Manager; o wrapper faz isso
 * e reinicia o processo se ele encerrar.
 *
 * Uso (prompt como Administrador): node scripts/servico-windows.js install|uninstall|start|stop|restart|status
 */
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const DAEMON_DIR = path.join(ROOT, 'daemon');
const WINSW_DIR = path.join(__dirname, 'winsw');
const SERVICE_ID = 'horusmercadolivre';
const SERVICE_NAME = 'Horus Mercado Livre';
const EXE = path.join(DAEMON_DIR, `${SERVICE_ID}.exe`);
const XML = path.join(DAEMON_DIR, `${SERVICE_ID}.xml`);

function escXml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function isAdmin() {
  try {
    execFileSync('net.exe', ['session'], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function requireAdmin() {
  if (isAdmin()) return;
  console.error('Execute este comando em um PowerShell ou prompt aberto como Administrador.');
  console.error('Exemplo: npm run service:install');
  process.exit(1);
}

function serviceExists() {
  try {
    execFileSync('sc.exe', ['query', SERVICE_ID], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function runWinsw(command, ignoreError = false) {
  try {
    execFileSync(EXE, [command], { stdio: 'inherit', cwd: DAEMON_DIR });
  } catch (error) {
    if (ignoreError) return;
    console.error(`Falha ao executar o serviço (${command}).`);
    process.exit(error.status || 1);
  }
}

function writeDaemon() {
  const winswExe = path.join(WINSW_DIR, 'winsw.exe');
  const winswConfig = path.join(WINSW_DIR, 'winsw.exe.config');
  if (!fs.existsSync(winswExe) || !fs.existsSync(winswConfig)) {
    console.error('Wrapper WinSW não encontrado em scripts/winsw.');
    process.exit(1);
  }

  fs.mkdirSync(DAEMON_DIR, { recursive: true });
  const logDir = path.join(ROOT, 'logs', 'servico');
  fs.mkdirSync(logDir, { recursive: true });

  fs.copyFileSync(winswExe, EXE);
  fs.copyFileSync(winswConfig, `${EXE}.config`);

  const xml = [
    '<service>',
    `  <id>${SERVICE_ID}</id>`,
    `  <name>${escXml(SERVICE_NAME)}</name>`,
    '  <description>Sincroniza Mercado Livre com o ERP Horus.</description>',
    `  <executable>${escXml(process.execPath)}</executable>`,
    `  <argument>${escXml(path.join(ROOT, 'src', 'app.js'))}</argument>`,
    `  <workingdirectory>${escXml(ROOT)}</workingdirectory>`,
    `  <logpath>${escXml(logDir)}</logpath>`,
    '  <logmode>rotate</logmode>',
    '  <startmode>Automatic</startmode>',
    '  <onfailure action="restart" delay="10 sec"/>',
    '  <onfailure action="restart" delay="30 sec"/>',
    '  <onfailure action="restart" delay="60 sec"/>',
    '  <resetfailure>1 hour</resetfailure>',
    '</service>',
    '',
  ].join('\r\n');

  fs.writeFileSync(XML, xml, 'utf8');
}

function configureDelayedStart() {
  execFileSync('sc.exe', ['config', SERVICE_ID, 'start=', 'delayed-auto'], { stdio: 'inherit' });
}

function install() {
  requireAdmin();

  if (!fs.existsSync(path.join(ROOT, '.env'))) {
    console.error('Arquivo .env não encontrado na raiz do projeto.');
    process.exit(1);
  }

  if (serviceExists() && fs.existsSync(EXE)) {
    runWinsw('stop', true);
  }

  writeDaemon();

  if (!serviceExists()) {
    runWinsw('install');
  }

  configureDelayedStart();
  runWinsw('start');
  console.log(`Serviço iniciado: ${SERVICE_NAME}`);
  console.log('Logs da rotina: logs\\exec');
  console.log('Logs do serviço: logs\\servico');
}

function uninstall() {
  requireAdmin();

  if (!serviceExists()) {
    console.log('Serviço não está instalado.');
    return;
  }

  if (fs.existsSync(EXE)) {
    runWinsw('stop', true);
    runWinsw('uninstall');
  } else {
    try {
      execFileSync('sc.exe', ['stop', SERVICE_ID], { stdio: 'ignore' });
    } catch {
      // serviço já parado
    }
    execFileSync('sc.exe', ['delete', SERVICE_ID], { stdio: 'inherit' });
  }

  for (const file of [EXE, `${EXE}.config`, XML]) {
    if (fs.existsSync(file)) fs.unlinkSync(file);
  }

  console.log('Serviço removido.');
}

function start() {
  requireAdmin();
  if (!serviceExists()) {
    console.error('Serviço não instalado. Execute: npm run service:install');
    process.exit(1);
  }
  runWinsw('start');
}

function stop() {
  requireAdmin();
  if (!serviceExists()) {
    console.error('Serviço não instalado.');
    process.exit(1);
  }
  runWinsw('stop');
}

function restart() {
  requireAdmin();
  if (!serviceExists()) {
    console.error('Serviço não instalado. Execute: npm run service:install');
    process.exit(1);
  }
  runWinsw('restart');
}

function status() {
  try {
    const output = execFileSync('sc.exe', ['query', SERVICE_ID], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    const line = String(output)
      .split(/\r?\n/)
      .map((item) => item.trim())
      .find((item) => /STATE|ESTADO/i.test(item));
    console.log(line || `${SERVICE_NAME}: instalado`);
  } catch {
    console.log('Serviço não instalado.');
    process.exit(1);
  }
}

const commands = {
  install,
  uninstall,
  start,
  stop,
  restart,
  status,
};

const command = process.argv[2];
if (!commands[command]) {
  console.log('Uso: node scripts/servico-windows.js install|uninstall|start|stop|restart|status');
  process.exit(command ? 1 : 0);
}

commands[command]();
