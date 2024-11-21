({
    getColumnDefinitions: function () {
        var columns = [
            {label: 'Opportunity name', fieldName: 'Name', type: 'text', sortable: true,
             
             cellAttributes: {
                 class: {
                     fieldName: 'format'
                 },
                 alignment: 'left'
             }
            },
            //{label: 'Account name', fieldName: 'accountName', type: 'text', sortable: true},Drive_Name__c
            {label: 'Drive name', fieldName: 'Drive_Name__c', type: 'text', sortable: true,
                         cellAttributes: {
                 class: {
                     fieldName: 'format'
                 },
                 alignment: 'left'
             }},
            {label: 'Start Time', fieldName: 'Startdatetime', type: 'text', sortable: true, cellAttributes: { iconName: 'utility:event',class: {
                     fieldName: 'format'
                 }, }},
            {label: 'End Time', fieldName: 'Enddatetime', type: 'text', sortable: true, cellAttributes: { iconName: 'utility:event',class: {
                     fieldName: 'format'
                 }, }},
        ];
            
            return columns;
            },
            
            fetchData: function (component, numberOfRecords) {
            
            var action = component.get("c.fetchAllSingleDayDrives");
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
        }
                             });
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
            /*var adjustedTimeEnd = (element.End_Time__c/3600000 > 12 ? ((element.End_Time__c/3600000) - 12) : element.End_Time__c/3600000 );
            adjustedTimeEnd = (Math.round(adjustedTimeEnd * 100) / 100).toFixed(2).toString().replace(".",":");*/
            
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
        });
        //this.contactData = reportResult;
        
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
    createSingleDriveLinkedRecord: function (cmp, event) {
        var selectedLinkedRecord = cmp.get('v.selectedSingleDriveRecord');
        var recId = cmp.get('v.recordId');
        if(recId == selectedLinkedRecord){
            var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "Error",
                        "message": "You cannot select the same drive."
                    });
            resultsToast.fire();
            return;
        }
        var action = cmp.get("c.createSingleDayLinkedDrives");
        action.setParams({
            "oppId1" : recId,
            "oppId2" : selectedLinkedRecord
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
                    cmp.set("v.isLinkedDriveExist",true);
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "Success",
                        "message": lstResponse
                    });
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
        
        
        fetchSingleDriveLinkedRecord: function (cmp, event, helper) {
            var linkedRecordId = cmp.get('v.linkedSingleDriveRecordId');
            
            
            var action = cmp.get("c.fetchSingleDayLinkedDrives");
            action.setParams({
                "linkedRecordId" : linkedRecordId
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                var lstResponse = response.getReturnValue();
                if (state === "SUCCESS") { 
                    //oppRecordId1
                    if(lstResponse != null){
                        cmp.set("v.oppRecordId1",lstResponse[0].Name);
                        cmp.set("v.oppRecordId2",lstResponse[1].Name);
                    }
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