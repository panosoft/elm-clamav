var _panosoft$elm_clamav$Native_Scanner = function() {
    const stream = require('stream');
    const clamav = require('clamav.js');
    const { nativeBinding, succeed, fail } = _elm_lang$core$Native_Scheduler

    const scan = F3((config, name, buffer) =>
        nativeBinding(callback => {
            try {

                console.log({config: config, name: name, buffer_length: buffer.length,
                    bufferAsString: buffer.toString(null, 0, (buffer.length > 100 ? 100 : buffer.length))});
                const bufferStream = new stream.PassThrough();
                bufferStream.end(buffer);
                clamav.createScanner(config.clamavPort, config.clamavHost).scan(bufferStream, (err, object, malicious) => {
                    console.log({name: name, err: err, malicious: malicious});
                    callback(err
                    	? fail('Error scanning ' + name + ':' + err.message)
                    	: (malicious ? fail('Virus found scanning ' + name + ':' + malicious) : succeed(name)))
                });
            }
            catch (error) {
            	callback(fail('Error scanning ' + name + ':' + err.message));
        	 }
        }));
        return { scan };
}();
