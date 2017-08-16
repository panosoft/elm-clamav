// compile with:
//		elm make Test/App.elm --output elm.js

// load Elm module
const elm = require('./elm.js');
// run with:
//  node main.js targetFilename configFilename --debug
//
//      targetFilename = name of file to scan.
//      configFilename = filename for ClamAV config. "" defaults to ./sampleConfig.js.  must follow 'node require' syntax (i.e. precede with ./ if in current directory).
//      --debug = optional, if --debug is specified, then debug logging will be enabled.

const targetFilename = process.argv[2];
const config = require(process.argv[3] || './sampleConfig.js');
const debug = process.argv[4] || '';

const flags = {
    targetFilename,
    config,
    debug
};

// get Elm ports
const ports = elm.App.worker(flags).ports;

// keep our app alive until we get an exitCode from Elm or SIGINT or SIGTERM (see below)
setInterval(id => id, 86400);

ports.exitApp.subscribe(exitCode => {
	console.log('Exit code from Elm:', exitCode);
	process.exit(exitCode);
});

process.on('uncaughtException', err => {
	console.log(`Uncaught exception:\n`, err);
	process.exit(1);
});

process.on('SIGINT', _ => {
	console.log(`SIGINT received.`);
	ports.externalStop.send(null);
});

process.on('SIGTERM', _ => {
	console.log(`SIGTERM received.`);
	ports.externalStop.send(null);
});
