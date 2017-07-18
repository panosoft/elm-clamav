var _panosoft$elm_clamav$Native_Scanner = function() {
    const stream = require('stream');
    const clamav = require('clamav.js');
    const { nativeBinding, succeed, fail } = _elm_lang$core$Native_Scheduler

    const scan = F4((config, name, buffer, debug) =>
        nativeBinding(callback => {
            try {

                debug ? console.log('NATIVE --', {config: config, name: name, buffer_length: buffer.length,
                    bufferAsString: buffer.toString('hex', 0, (buffer.length > 80 ? 80 : buffer.length))}) : null;
                const bufferStream = new stream.PassThrough();
                bufferStream.end(buffer);
                clamav.createScanner(config.clamavPort, config.clamavHost).scan(bufferStream, (err, object, malicious) => {
                    debug ? console.log('NATIVE --', {name: name, err: err, malicious: malicious}) : null;
                    callback(err
                        ? fail(_elm_lang$core$Native_Utils.Tuple2(name, 'Error scanning ' + name + ':' + err.message))
                        : (malicious ? fail(_elm_lang$core$Native_Utils.Tuple2(name, 'Virus found scanning ' + name + ':' + malicious)) : succeed(name)))
                    });
            }
            catch (error) {
                callback(fail(_elm_lang$core$Native_Utils.Tuple2(name, 'Error scanning ' + name + ':' + err.message)));
            }
        }));
        return { scan };
}();
