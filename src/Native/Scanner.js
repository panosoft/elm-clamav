var _panosoft$elm_clamav$Native_Scanner = function() {
    const stream = require('stream');
    const clamav = require('clamav.js');
    const { nativeBinding, succeed, fail } = _elm_lang$core$Native_Scheduler

    const scan = F3((config, name, buffer) =>
        nativeBinding(callback => {
            console.log(name, buffer.length);
            try {
                const bufferStream = new stream.PassThrough();
                bufferStream.end(buffer);
                clamav.createScanner(config.port, config.host).scan(bufferStream, (err, object, malicious) => {
                    console.log(err, object, malicious);
                    callback(err
                	? fail('Error scanning ' + name + ':' + err.message)
                	: (malicious ? fail('Virus found scanning ' + name + ':' + malicious) : succeed(name))
                });
            }
            catch (error) {
            	callback(fail('Error scanning ' + name + ':' + err.message));
        	 }
        }));
}();
