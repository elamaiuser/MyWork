({
    getColumnDefinitions: function () {
        var columns = [
            {label: 'Opportunity name', fieldName: 'Name', type: 'text', sortable: true,             
             cellAttributes: {class: {fieldName: 'format'},alignment: 'left'}},
            
            /*{label: 'Opportunity Id', fieldName: 'Id', type: 'text', sortable: true,             
             cellAttributes: {class: {fieldName: 'format'},alignment: 'left'}},*/
            
            {label: 'Drive name', fieldName: 'Drive_Name__c', type: 'text', sortable: true,
             cellAttributes: {class: {fieldName: 'format'},alignment: 'left'}},
            
            /*{label: 'Linked_Opportunity_Drives__c', fieldName: 'Linked_Opportunity_Drives__c', type: 'text', sortable: true,
             cellAttributes: {class: {fieldName: 'format'},alignment: 'left'}},*/
            
            {label: 'Drive Date', fieldName: 'Drive_Date__c', type: 'date', sortable: true,
             cellAttributes: { iconName: 'utility:event',class: {fieldName: 'format'},alignment: 'left'}},
            
            
            {label: 'Start Time', fieldName: 'Startdatetime', type: 'text', sortable: true, cellAttributes: { iconName: 'utility:clock',class: {
                fieldName: 'format'}, }},
            
            {label: 'End Time', fieldName: 'Enddatetime', type: 'text', sortable: true, cellAttributes: { iconName: 'utility:clock',class: {
                fieldName: 'format'}, }},
            
            {type: "button", typeAttributes: {
                label: { fieldName: 'isLinked'},
                name: { fieldName: 'isLinked'},
                title: { fieldName: 'isLinked'},
                disabled: false,
                value: 'view',
                iconPosition: 'right',
                variant: { fieldName: 'linkedRecordClass'},
            }},
        ];
            
            return columns;},
            
            fetchData: function (component, numberOfRecords) {
            
            var action = component.get("c.fetchAllMultiDayDrives");
            var recId = component.get('v.recordId');
            action.setParams({
            "oppId" : recId
            });
            action.setCallback(this, function (response) {
            var state = response.getState();
            var lstResponse = response.getReturnValue();
            if (state === "SUCCESS") {
            //component.set('v.accountName',lstResponse.Name);
            
            
            const reportResult = [...lstResponse];
        var linkedRecord ='';
        reportResult.forEach(ele=>{
            if(ele.Id == component.get('v.recordId')){
            linkedRecord = ele.Linked_Opportunity_Drives__c;
        }});
        reportResult.forEach(element=>{
            var ampmStart = (element.Start_Time__c/3600000 > 12 ? ' PM' : ' AM');
            
            var sec_num = parseInt(element.Start_Time__c/1000, 10);
            var hours   = Math.floor(sec_num / 3600);
            var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
            var seconds = sec_num - (hours * 3600) - (minutes * 60);
            
            if (hours   < 10) {hours   = "0"+hours;}
                             if (minutes < 10) {minutes = "0"+minutes;}
        if (seconds < 10) {seconds = "0"+seconds;}
        var adjustedTimeStart = hours + ':' + minutes + ':' + seconds;
        element.Startdatetime = adjustedTimeStart + ampmStart;
        
        var ampmEnd = (element.End_Time__c/3600000 > 12 ? ' PM' : ' AM');
        
        sec_num = parseInt(element.End_Time__c/1000, 10); // don't forget the second param
        hours   = Math.floor(sec_num / 3600);
        minutes = Math.floor((sec_num - (hours * 3600)) / 60);
        seconds = sec_num - (hours * 3600) - (minutes * 60);
        
        if (hours   < 10) {hours   = "0"+hours;}
        if (minutes < 10) {minutes = "0"+minutes;}
        if (seconds < 10) {seconds = "0"+seconds;}
        var adjustedTimeEnd = hours + ':' + minutes + ':' + seconds;
        
        
        element.format = ((linkedRecord != undefined && linkedRecord == element.Linked_Opportunity_Drives__c) ? 'linkedDriveClass' : '');
        
        element.Enddatetime = adjustedTimeEnd + ampmEnd;
        if(element.Linked_Opportunity_Drives__c != undefined){
            element.isLinked = 'Linked';
            element.linkedRecordClass = 'success';
        }else{
            element.isLinked = 'Link Drive';
            element.linkedRecordClass = 'brand';
        }
        
    });
    //this.contactData = reportResult;
    reportResult.sort(function(x,y){ return x.isLinked == 'Linked' ? -1 : y.isLinked == 'Linked' ? 1 : 0; });
    reportResult.sort(function(x,y){ return x.Id == recId ? -1 : y.Id == recId ? 1 : 0; });
    
    component.set('v.data', reportResult);
} else if (state === "ERROR") {
    var errors = response.getError();
    if (errors) {
        if (errors[0] && errors[0].message) {
            console.log("Error message: " +
                        errors[0].message);
        }
    } else {
        console.log("Unknown error");
    }
}
});
$A.enqueueAction(action);       


},
    
    
    linkRecord: function (row,cmp) {
        var selectedRecordId = row.Id;
        var baseRecordId = cmp.get('v.recordId');
        if(selectedRecordId == baseRecordId){
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "Error",
                "message": "You cannot select the same drive."
            });
            resultsToast.fire();
            return;
        }
        var action = cmp.get("c.createMultiDayLinkedDrives");
        action.setParams({
            "oppId1" : baseRecordId,
            "oppId2" : selectedRecordId
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            var lstResponse = response.getReturnValue();
            if (state === "SUCCESS") { 
                if(lstResponse.includes('Error:')){
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "Error",
                        "message": lstResponse
                    });
                }else{
                    //cmp.set("v.isLinkedDriveExist",true);
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "Success",
                        "message": lstResponse
                    });
                    
                    var actualdata = cmp.get('v.data');
                    
                    actualdata.forEach(ele=>{
                        if(ele.Id == selectedRecordId){
                        ele.isLinked = 'Linked';
                        ele.linkedRecordClass = 'success';
                    }});
                    cmp.set('v.data', actualdata);
                    
                }
                resultsToast.fire();
                
                
                
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                    errors[0].message);
                    }
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "Error",
                        "message": lstResponse
                    });
                    resultsToast.fire();
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);   
    },
        
        delinkRecord: function(cmp, rowId){
            
            var selectedRecordId = rowId;
            var baseRecordId = cmp.get('v.recordId');
            
            var action = cmp.get("c.deLinkMultiDayDrives");
            action.setParams({
                "oppId1" : baseRecordId,
                "oppId2" : selectedRecordId
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                var lstResponse = response.getReturnValue();
                if (state === "SUCCESS") { 
                    if(lstResponse.includes('Error:')){
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "type": "Error",
                            "message": lstResponse
                        });
                    }else{
                        //cmp.set("v.isLinkedDriveExist",true);
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "type": "Success",
                            "message": lstResponse
                        });
                        
                        var actualdata = cmp.get('v.data');                        
                        actualdata.forEach(ele=>{
                            if(ele.Id == selectedRecordId){
                            ele.isLinked = 'Link Drive';
                            ele.linkedRecordClass = 'brand';
                        }});
                        cmp.set('v.data', actualdata);
                        
                    }
                    resultsToast.fire();
                    

                    
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                        errors[0].message);
                        }
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "type": "Error",
                            "message": lstResponse
                        });
                        resultsToast.fire();
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);   
            
        },
            
});