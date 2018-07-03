
(function($) {
    // Custom ComboBox
    $.fn.kndyRemoteComboBox = function(options) {
        var defaults = {
            sobject : null, // will be sobject to query
            placeholder : 'Type to search...',
            autoBind : false,
            minLength : 2,
            dataValueField : 'Id',
            dataTextField : 'Name',
            filter : 'contains',
            criterias : null, // map structure with key value combinations
            orderByField : null,
            sortOrder : null,
            recordLimit : 100,
            additionalFields: null
        };
        var defaultOptions = $.extend({}, defaults, options);

        var that = this;

        var comboBox = that.kendoComboBox({
            autoBind : defaultOptions.autoBind,
            filter : defaultOptions.filter,
            placeholder : defaultOptions.placeholder,
            minLength : defaultOptions.minLength,
            dataValueField : defaultOptions.dataValueField,
            dataTextField : defaultOptions.dataTextField,
            template: (defaultOptions.template) ? defaultOptions.template : null,
            value : defaultOptions.value,
            text : defaultOptions.text,
            dataSource : {
                transport : {
                    read : function(readOptions) {

                        var criterias = [];
                        var comboBoxVal = that.data('kendoComboBox').text();
                        if (comboBoxVal && comboBoxVal.length > 0) {
                            criterias.push({
                                'field' : defaultOptions.dataTextField,
                                'operator' : 'like',
                                'value' : '%' + comboBoxVal + '%',
                                'wrapValueInQuotes' : true
                            });
                        }
                        if (defaultOptions.criterias) {
                            if ($.isArray(defaultOptions.criterias)) {
                                criterias = criterias.concat(defaultOptions.criterias);
                            }

                            if ($.isFunction(defaultOptions.criterias)) {
                                criterias = criterias.concat(defaultOptions.criterias());
                            }
                        }

                        var sobjInfo = {
                            sobjectName : defaultOptions.sobject,
                            valueFieldName : defaultOptions.dataValueField,
                            textFieldName : defaultOptions.dataTextField,
                            orderByField : defaultOptions.orderByField,
                            sortOrder : defaultOptions.sortOrder,
                            recordLimit : defaultOptions.recordLimit,
                            criterias : criterias,
                            filterInfo : defaultOptions.relatedFilterInfo ? defaultOptions.relatedFilterInfo() : null,
                            additionalFields: defaultOptions.additionalFields
                        };

                        // remoteActionLoadRecords to come from caller
                        Visualforce.remoting.Manager.invokeAction(defaultOptions.remoteActionLoadRecords, sobjInfo, function(result, event) {
                            if (event.type == 'exception') {
                                KenandyErp.Alert(event.message);
                            } else {
                                KenandyErp.CleanNamespace(result, KenandyErp.NamespacePrefix);
                                readOptions.success(result);
                            }
                        }, {
                            escape : false
                        });
                    }
                },
                serverFiltering : true
            }
        }).data('kendoComboBox');
        
        comboBox.input.keyup(function(e){
            if (!this.value || this.value.length < 0) {
                comboBox.value('');
            }
        });
        
        return this;
    };

})(jQuery);