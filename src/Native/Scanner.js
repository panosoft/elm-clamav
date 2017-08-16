var _panosoft$elm_clamav$Native_Scanner = function() {
    const stream = require('stream');
    const clamav = require('clamav.js');
    const { nativeBinding, succeed, fail } = _elm_lang$core$Native_Scheduler

    const scan = F3((config, name, buffer) =>
        nativeBinding(callback => {
            try {
                config.debug ? console.log('NATIVE --', {config: config, name: name, buffer_length: buffer.length,
                    bufferAsString: buffer.toString('hex', 0, (buffer.length > 80 ? 80 : buffer.length)), partialBufferDisplay: (buffer.length > 80)}) : null;
                const bufferStream = new stream.PassThrough();
                bufferStream.end(buffer);
                clamav.createScanner(config.clamavPort, config.clamavHost).scan(bufferStream, (err, object, malicious) => {
                    config.debug ? console.log('NATIVE --', {name: name, err: err, malicious: malicious}) : null;
                    callback(err
                        ? fail(_elm_lang$core$Native_Utils.Tuple2(name, {message: 'Error scanning \'' + name + '\': ' + err.message, virusName: _elm_lang$core$Maybe$Nothing}))
                        : (malicious
                            ? fail(_elm_lang$core$Native_Utils.Tuple2(name, {message: 'Virus found scanning \'' + name + '\': ' + malicious, virusName: _elm_lang$core$Maybe$Just(malicious)}))
                            : succeed(name)
                          )
                        )
                    });
            }
            catch (error) {
                callback(fail(_elm_lang$core$Native_Utils.Tuple2(name, {message: 'Error scanning \'' + name + '\': ' + err.message, virusName: _elm_lang$core$Maybe$Nothing})));
            }
        }));
        return { scan };
}();
