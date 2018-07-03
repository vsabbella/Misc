/**
 * JSBatch
 *
 * var batch = new JSBatch({
 *    batchSize     : { number },
 *    records       : { array },
 *    retry         : { number },
 *    retryLogic    : { function },
 *    executeAction : { function },
 *    errorCallback : { function }, //called if execute action has an error
 *    doneCallback  : { function }, //called once all batch have been processed
 * });
 *
 * batch.run();
 *
 */
var JSBatch = function(options) {
    return {
        _BATCH_SIZE       : options.batchSize || 10,
        _NUMBER_TOTAL     : 0,
        _NUMBER_REMAINING : 0,
        _NUMBER_COUNT     : 0,
        _RECORDS          : options.records || [],
        _RETRY            : options.retry || 0,
        _RETRY_LOGIC      : options.retryLogic || null,
        _IS_RUNNING       : false,
        _INVOKE_ACTION    : options.executeAction || null,
        _ACTION_ERROR     : options.errorCallback || null,
        _ACTION_FINISH    : options.doneCallback || null,

        _init: function() {
            this._NUMBER_TOTAL = 0;
            this._NUMBER_REMAINING = this._RECORDS.length;
            this._NUMBER_COUNT = this._RECORDS.length;

            if (this._RECORDS == null || !(this._RECORDS instanceof Array)) throw new Error('Invalid records to process.');

            var that = this;
            this._RECORDS = this._RECORDS.map(function(rec) { return { param: rec, retry: that._RETRY }; });
        },
    
        run: function() {
            this._init()
            this._startBatch();
        },
    
        _startBatch: function() {
            this._IS_RUNNING = true;
            if (this._NUMBER_COUNT > 0) {
                this._nextBatch();
            } else {
                this._end();
            }
        },

        _nextBatch: function() {
            if (this._NUMBER_REMAINING <= 0) {
                this._end();
                return;
            }

            var dataclip;
            if ((this._NUMBER_COUNT - this._NUMBER_TOTAL) < this._BATCH_SIZE) {
                dataclip =  this._RECORDS.slice(this._NUMBER_TOTAL);
            } else {
                dataclip = this._RECORDS.slice(this._NUMBER_TOTAL, this._BATCH_SIZE + this._NUMBER_TOTAL);
            }

            this._updateClips(dataclip.length);

            var pArr = this._execution_worker(dataclip);
            this._checkResponse(pArr);
        },
    
        _end: function() {
            this._IS_RUNNING = false;
            this._ACTION_FINISH.call(this);
        },
    
        _execution_worker: function(params) {
            var promiseArr = [];
            for (var idx = 0; idx < params.length; idx++) {
                var cpromise = this._processRequest(params[idx]);
                promiseArr.push(cpromise);
            }
            return promiseArr;
        },

        _updateClips: function(size) {
            this._NUMBER_TOTAL  +=  size;
            this._NUMBER_REMAINING -= size;
        },

        _addRecord: function(record) {
            this._RECORDS.push(record);
            this._NUMBER_COUNT += 1;
            this._NUMBER_REMAINING += 1;
        },
    
        _processRequest: function(obj) {
            var deferred = $.Deferred();
            this._INVOKE_ACTION.call(this, obj.param, this._callback.bind({
                promise: deferred,
                context: this,
                obj: obj
            }));
            return deferred;
        },
    
        _callback: function(err, res) {
            var deferred = this.promise;
            if (err) {
                if (this.context._RETRY > 0) {
                    if (this.obj.retry > 0 && (typeof this.context._RETRY_LOGIC !== "function" || this.context._RETRY_LOGIC(err) === true)) {
                        this.obj.retry -= 1;
                        this.context._addRecord.call(this.context, this.obj);
                        return;
                    } else if (!(this.obj.retry > 0) && typeof this.context._RETRY_LOGIC === "function" && this.context._RETRY_LOGIC(err) === true) {
                        err = { message: "Maximum number of database query retries (" + this.context._RETRY + ") reached.  Please refresh and try again.", severity: "ERROR" };
                    }
                }

                if (typeof this.context._ACTION_ERROR === "function") this.context._ACTION_ERROR.call(this, err);
                deferred.resolve(res, err);
            } else {
                deferred.resolve(res, err);
            }
        },
    
        _checkResponse: function(promises) {
            var that = this;
            $.when.apply($, promises).done(function() {
                that._nextBatch();
            });
        }
    };
}