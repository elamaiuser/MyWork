({

    fetchRecord : function(component, event, helper) {
        component.set("v.spinner", true);
        component.set("v.value", 0);
        helper.toggle(component);
        component.set("v.recordOffset",20);
        component.set("v.recordToDisplay",20);
        component.set("v.enableInfiniteLoading",true);
    
        var action = component.get("c.getRecords");
        action.setParams({
            "recordId" : component.get("v.recordId"),
            "columnName" : component.get("v.ColumnName"),
            "soqlQuery" : component.get("v.SOQLQuery"),
            "limits" : 2000,
            "recordOffset" : 0,
            "fieldwithOrderBy" : component.get("v.fieldwithOrderBy")
        });
        
        action.setCallback(this, function(response) {

            var state = response.getState();
            console.log('state111-->'+state);
            var result = response.getReturnValue();
            if (state === "SUCCESS") { 
                component.set("v.numberOfRecords",result.counts);
                if((component.get("v.recordOffset") >= result.counts)){
                    component.set("v.enableInfiniteLoading",false);
                }
                component.set("v.data",result.sObjectList);
                
                var filtterdArray = result.columnNames.split(",");
                var columnName = component.get("v.ColumnName").split(",");
                var columnArray = [];
                
				var dateFieldNames = [];
                for(var i = 0 ; i < columnName.length ; i++){
                    if(i===0)
                        component.set("v.sortedBy", filtterdArray[i]);
                    console.log( "hyperLinkColumn is ", component.get("v.hyperLinkColumn")  );
                    var hyperlinkArray = [];
                    if( component.get("v.hyperLinkColumn") ){
                        hyperlinkArray = component.get("v.hyperLinkColumn").split(',');
                    }
                    
                    var obj = {};
                    obj["label"] = columnName[i];
                    if(hyperlinkArray.includes(columnName[i])){
                        if(filtterdArray[i] == 'Account_Link__c'){
                            obj["fieldName"] = 'accountlinkName';
                        }else if(filtterdArray[i] == 'Related_Record_Link__c'){
                            obj["fieldName"] = 'relatedRecordlinkName';
                        }else{
                        	obj["fieldName"] = 'linkName';
                        }
                    }else{
                        obj["fieldName"] = filtterdArray[i];
                    }
                    obj["sortable"] = true;
                    console.log('column name34$$#',columnName[i]);
                    if(columnName[i] === ' Drive Date'){
                        console.log('check drive date');
                    }
                    
                    if(columnName[i] === ' Drive Date' || columnName[i] === '  Drive Date' || columnName[i] === '   Drive Date'){//|| columnName[i] === 'Logged Date' || columnName[i] === 'Due Date'  || columnName[i] === 'Close Date'
                       console.log('column name22 ',columnName[i]);
                        var dayFormat = {};
                        var dateFormat = component.get("v.dateFormatType");
                       console.log('entered into date##1');
                        if(dateFormat === 'Custom Date Format'){
                            console.log('coming Custom Date Format');
                            dayFormat["month"] = 'numeric';
                            dayFormat["day"] = 'numeric';
                            dayFormat["year"] = 'numeric';
                            obj["type"] = 'date-local';
                            
                            console.log('dateFieldNames1');
                            //dateFieldNames.push(columnName[i]);
                            //console.log('dateFieldNames2'+dateFieldNames);
                        }else if(dateFormat === 'SF OOTB Date Format'){
                            dayFormat["day"] = 'numeric';
                            dayFormat["month"] = 'short';
                            dayFormat["year"] = 'numeric';
                            dayFormat["hour"] = '2-digit';
                            dayFormat["minute"] = '2-digit';
                            dayFormat["second"] = '2-digit';
                            dayFormat["hour12"] = true;
                            obj["type"] = 'date';
                            //obj["wrapText"] = true;
                        }
                        else if(dateFormat === '01/01/2020'){
                            
                            obj["type"] = 'date';
                        }
                        obj["typeAttributes"] = dayFormat;
                    }else{
                        if(hyperlinkArray.includes(columnName[i])){
                            var viewLink1 = {};
                                viewLink1["fieldName"] = filtterdArray[i];
                            var viewLink2 = {};
                                viewLink2["label"] = viewLink1;
                                viewLink2["target"] = '_self';
                            obj["type"] = 'url';
                            obj["typeAttributes"] = viewLink2;
                        }
                    }
                    columnArray.push(obj);
                }
                if(dateFieldNames.length > 0) {
                    console.log('dateFieldNames##');
                    console.log('result.sObjectList@@'+result.sObjectList);
                    helper.formatDateFields(result.sObjectList, dateFieldNames);
                }
                var records = result.sObjectList;
                records.forEach(function(record){
                    if(record.Account_Link__c != null && record.Account_Link__c != undefined){
                        var firstSubString = record.Account_Link__c.substr(record.Account_Link__c.indexOf('com//') + 5);
                        var secondSubString = firstSubString.split('"');
                        var resultId = secondSubString[0];
                        var afterMark = firstSubString.substr(firstSubString.indexOf('>') + 1);
                        var resultName = afterMark.split('<');
                        record.accountlinkName = '/'+resultId;
                        record.Account_Link__c = resultName[0];
                    }
                    if(record.Related_Record_Link__c != null && record.Related_Record_Link__c != undefined){
                        var firstSubString = record.Related_Record_Link__c.substr(record.Related_Record_Link__c.indexOf('com//') + 5);
                        var secondSubString = firstSubString.split('"');
                        var resultId = secondSubString[0];
                        var afterMark = firstSubString.substr(firstSubString.indexOf('>') + 1);
                        var resultName = afterMark.split('<');
                        record.relatedRecordlinkName = '/'+resultId;
                        record.Related_Record_Link__c = resultName[0];
                    }
                    record.linkName = '/'+record.Id;
                });
                component.set("v.data",result.sObjectList);
                //Record Action Button Logic Start
                var buttonActions = component.get("v.recordButton");
                var buttonActionSplit = [];
                if(buttonActions != null && buttonActions != '' && buttonActions != undefined){
                    buttonActionSplit = buttonActions.split(",");
                    var displayActionButton = [];
                    for(var i = 0 ; i < buttonActionSplit.length ; i++){
                        var rowAction = {};
                        var actionLabel = buttonActionSplit[i].trim();
                        //actionLabel = actionLabel.charAt(0).toUpperCase() + actionLabel.slice(1).toLowerCase();
                        var actionName = buttonActionSplit[i].trim();
                        if(buttonActionSplit[i].trim() != null && buttonActionSplit[i].trim() != ''){
                            actionName = actionName.toLowerCase();
                            rowAction["label"] = actionLabel;
                            rowAction["name"] = actionName;
                            displayActionButton.push(rowAction);
                        }
                    }
                }
                
                var obj2 = {};
                var obj1 = {};
                obj1["rowActions"] = displayActionButton;
                obj2["type"] = 'action';
                obj2["typeAttributes"] = obj1;
                columnArray.push(obj2);

                component.set("v.columns", columnArray);
                //helper.sortData(component, component.get("v.sortedBy"), component.get("v.sortedDirection"));
                var fieldWithOrderBy = component.get("v.fieldwithOrderBy");
                console.log('fieldWithOrderBy##'+fieldWithOrderBy);
                if (fieldWithOrderBy) {
                    var [sortField, sortDirection] = fieldWithOrderBy.split(' ');
                    helper.sortData(component, sortField, sortDirection);
                }
                component.set("v.spinner", false);
        	}else{
                component.set("v.spinner", false);
            }
        });
        $A.enqueueAction(action);
    },
    
    formatDateFields: function(data, dateFieldNames) {
    console.log('Called formatDateFields with dateFieldNames:', dateFieldNames);
	console.log('Called##'+JSON.stringify(data)); 
    data.forEach(function(record, index) {
        console.log('Record123 ' + index + ':', JSON.stringify(record));

        dateFieldNames.forEach(function(fieldName) {
            var trimmedFieldName = '  '+fieldName;//      fieldName.trim();
			console.log('Checking field:', trimmedFieldName, 'in record:', index, 'Value:', record[trimmedFieldName]);
            if (record[trimmedFieldName]) {
                var date = new Date(record[trimmedFieldName]);
                var day = ("0" + date.getDate()).slice(-2);
                var month = ("0" + (date.getMonth() + 1)).slice(-2);
                var year = date.getFullYear();
                record[fieldName] = month + '/' + day + '/' + year;
            } else {
                console.log('Field ' + fieldName + ' is undefined or null in record ' + index);
            }
        });
    });
},



    getMoreData: function(component){

        return new Promise($A.getCallback(function(resolve, reject) {
            var recordOffset = component.get("v.recordOffset");
            var recordLimit = component.get("v.recordToDisplay");

            var action = component.get("c.getRecords");
            action.setParams({
                "recordId" : component.get("v.recordId"),
                "columnName" : component.get("v.ColumnName"),
                "soqlQuery" : component.get("v.SOQLQuery"),
                "limits" : component.get("v.recordToDisplay"),
                "recordOffset" : recordOffset
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log('state-->'+state);
                if(state === "SUCCESS"){
                    var resultData = response.getReturnValue();
                    var ddd = resultData.sObjectList;
                    var datas= [];
                    
                    for (var i = 0; i < ddd.length; i++){
                        datas.push(ddd[i]);
                    }
                    resolve(datas);
                    recordOffset = recordOffset + recordLimit;
                    component.set("v.recordOffset", recordOffset);  
                }                    
            });
            $A.enqueueAction(action); 
        }));
    },
	/*
    sortData: function (component, fieldName, sortDirection) {
            var data = component.get("v.data");
            //function to return the value stored in the field
            var key = function(a) { return a[fieldName]; }
            var reverse = sortDirection == 'asc' ? 1: -1;
            
            // to handel number/currency type fields 
            if(fieldName == 'NumberOfEmployees'){ 
                data.sort(function(a,b){
                    var a = key(a) ? key(a) : '';
                    var b = key(b) ? key(b) : '';
                    return reverse * ((a>b) - (b>a));
                }); 
            }
            else{// to handel text type fields 
                data.sort(function(a,b){ 
                    var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                    var b = key(b) ? key(b).toLowerCase() : '';
                    return reverse * ((a>b) - (b>a));
                });    
            }
            //set sorted data to accountData attribute
            component.set("v.data",data);
    },
    */
    
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.data");
        
        // Determine the sorting direction. If 'ASC', reverse is false, and if 'DESC', reverse is true.
        var reverse = sortDirection.toLowerCase() === 'desc';
        
        data.sort(function(a, b) {
            var aVal = a[fieldName] ? a[fieldName] : '';
            var bVal = b[fieldName] ? b[fieldName] : '';
            
            if (aVal < bVal) {
                return reverse ? 1 : -1;
            }
            if (aVal > bVal) {
                return reverse ? -1 : 1;
            }
            return 0;
        });
        
        component.set("v.data", data);
    },

    
    toggle: function(component) {
        if(this.timerId) {
            clearInterval(this.timerId);
            this.timerId = null;
        } else {
            this.timerId = setInterval($A.getCallback(this.next.bind(this, component)), 60000);
        }
        if(component.get("v.value") == 0){
            component.set("v.timerText", 'Updated a few seconds ago');
        }
    },
    next: function(component) {
        var value = component.get("v.value");
        value = value + 1;
        component.set("v.value", value);
        var timerText = '';
        
        if(value == 1){
            timerText = 'Updated a minute ago';
        }
        if(value > 1){
            timerText = 'Updated '+value+' minutes ago';
        }
        component.set("v.timerText", timerText)
    },    
    
})