({
    fetchRecord : function(component, event, helper) {
        let recordids = component.get("v.recordId");
        let columnNames = component.get("v.ColumnName");
        let soqlQ = component.get("v.SOQLQuery");
        let recordTodisplay = component.get("v.recordToDisplay");
        let recordOffset = component.get("v.recordOffset");
        let fieldwithOrderBy = component.get("v.fieldwithOrderBy");
        
        var action = component.get("c.getRecords");
        action.setParams({
            "recordId" : recordids,
            "columnName" : columnNames,
            "soqlQuery" : soqlQ,
            "limits" : recordTodisplay,
            "recordOffset" : recordOffset,
            "fieldwithOrderBy" : fieldwithOrderBy
        });
        
        action.setCallback(this, function(response) {
           
            var state = response.getState();
            console.log('state in generic related list-->',  state );
            var result = response.getReturnValue();
            if (state === "SUCCESS") { 
                component.set("v.numberOfRecords",result.counts);
				
                console.log( "result is in helper ", JSON.stringify(result) );                
                component.set("v.objectName",result.objectName);
                if( result.recordName != null ){
                    component.set("v.recordName",result.recordName.Name);
                }
                
            try{
                
                var filtterdArray = result.columnNames.split(",");
				
                var columnName = component.get("v.ColumnName").split(",");
                var columnArray = [];
              
                // var obj3 = {};
                // obj3["type"] = 'button';
                // obj3["initialWidth"] = 30;
                // var viewLink = {};
                    // viewLink["label"] = 'View';
                    // viewLink["name"] = 'view';
                    // viewLink["title"] = 'view';
                    // viewLink["disabled"] = false;
                    // viewLink["value"] = 'edit';
                    // viewLink["iconPosition"] = 'right';
                    // viewLink["variant"] = 'base'; 
                // obj3["typeAttributes"] = viewLink;
                // columnArray.push(obj3);

                for(var i = 0 ; i < columnName.length ; i++){
                    
                    
                    var hyperlinkArray = [];
                    if( component.get("v.hyperLinkColumn") ){
                    	hyperlinkArray = component.get("v.hyperLinkColumn").split(',');
                    }

                    var obj = {};
                    obj["label"] = columnName[i];
                    if(hyperlinkArray.includes(columnName[i])){
                        obj["fieldName"] = 'linkName';
                    }else{
                        //console.log( "filtterdArray is ", filtterdArray[i] );
                        obj["fieldName"] = filtterdArray[i];
                    }
                    obj["hideDefaultActions"] = true;
                    //obj["type"] = 'date';
                    console.log('columnName[i]##111'+columnName[i]);
                    if(columnName[i] === ' Drive Date' || columnName[i] === 'Logged Date' || columnName[i] === 'Due Date' || columnName[i] === 'Close Date' ){
                        console.log('columnName[i]##2222'+columnName[i]);
                        var dayFormat = {};
                        var dateFormat = component.get("v.dateFormatType");
                        if(dateFormat === 'Custom Date Format'){
                            console.log('entered into this##')
                            dayFormat["month"] = 'numeric';
                            dayFormat["day"] = 'numeric';
                            dayFormat["year"] = 'numeric';
                            obj["type"] = 'date-local';
                            //obj["wrapText"] = true;
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
                        else if(dateFormat === 'Jan-1-2020'){
                            // dayFormat["year"] = 'numeric';
                            // dayFormat["month"] = 'numeric';
                            // dayFormat["day"] = 'numeric';
                            obj["type"] = 'date-local';
                        }
                        obj["typeAttributes"] = dayFormat;
                    }else{
                        console.log( "hyperlinkArray is ",  hyperlinkArray , " column name is ", columnName[i] );
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
                    
                    console.log( "obj before push " , JSON.stringify( obj ) );
                    columnArray.push(obj);
                }
                var records = result.sObjectList;
				
				console.log( "records is ", records );
                records.forEach(function(record){
					
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
                
                
                // var actions = [
                //     { label: 'Edit', name: 'edit' },
                //     { label: 'Delete', name: 'delete' }
                // ];
                var obj2 = {};
                var obj1 = {};  
                obj1["rowActions"] = displayActionButton;
                obj2["type"] = 'action';
                obj2["typeAttributes"] = obj1;
                columnArray.push(obj2);

                component.set("v.columns", columnArray);
                console.log('columnArray-->'+JSON.stringify(columnArray));
            }catch(e){
                console.log('Something Went wrong', e );
            }
        	}else{
                         
            }
            
            
        });
        $A.enqueueAction(action);
		
		
    },
    deleteRecord : function(component, event, helper,recId) {
        var action = component.get("c.deleteRecords");
        // pass the all selected record's Id's to apex method 
        action.setParams({
        "lstRecordId": recId
        });
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            console.log('state-->'+state);
            var result = response.getReturnValue();
            if (state === "SUCCESS") {
                var oppId = component.get('v.recordId');
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                "recordId": oppId,
                "slideDevName": "related"
                });
                navEvt.fire();
                this.fetchRecord(component, event, helper);
            }
        });
        $A.enqueueAction(action);
    }
})