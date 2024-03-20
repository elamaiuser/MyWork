({
    init: function (cmp, event, helper) {
        cmp.set('v.columns', helper.getColumnDefinitions());
        
        /*var fetchData = {
            opportunityName: "company.companyName",
            accountName : "name.findName",
            closeDate : "date.future",
            amount : "finance.amount",
            contact: "internet.email",
            phone : "phone.phoneNumber"

        },*/
        helper.fetchData(cmp,cmp.get('v.initialRows'));
        
        
    },
    
    saRecordUpdated: function(component, event, helper) {
        
        var changeType = event.getParams().changeType;
        
        if (changeType === "ERROR") { /* handle error; do this first! */ }
        else if (changeType === "LOADED") { 
            if(component.get('v.opportunityRecordFields.Linked_Opportunity_Drives__c') != undefined){
                component.set("v.linkedSingleDriveRecordId",component.get('v.opportunityRecordFields.Linked_Opportunity_Drives__c'));
                helper.fetchSingleDriveLinkedRecord(component, event, helper);
                component.set("v.isLinkedDriveExist",true);
                
                
            }
        }
            else if (changeType === "REMOVED") { /* handle record removal */ }
                else if (changeType === "CHANGED") { /* handle record change */ 
                    if(component.get('v.opportunityRecordFields.Linked_Opportunity_Drives__c') != undefined){
                        component.set("v.linkedSingleDriveRecordId",component.get('v.opportunityRecordFields.Linked_Opportunity_Drives__c'));
                        helper.fetchSingleDriveLinkedRecord(component, event, helper);
                        component.set("v.isLinkedDriveExist",true);
                        
                    }
                }
    },
    
    
    getSelectedRows: function (cmp, event) {
        
        var selectedRows = event.getParam('selectedRows');
        if(selectedRows.length >1) {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "error",
                "message": "Only one drive can be selected"
            });
            resultsToast.fire();
            
            return;
        }
        cmp.set('v.selectedRowsCount', selectedRows.length);
        // Display that fieldName of the selected rows
        for (var i = 0; i < selectedRows.length; i++){
            cmp.set('v.selectedSingleDriveRecord',selectedRows[i].Id);
        }
        
    },
    
    handleClick: function (cmp, event, helper) {
        var selectedRowsCount = cmp.get('v.selectedRowsCount');   
        
        if(selectedRowsCount.length >1) {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "error",
                "message": "Only one drive can be selected"
            });
            resultsToast.fire();
            return;
        }
        if(selectedRowsCount <1) {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "error",
                "message": "Please select a drive"
            });
            resultsToast.fire();
            return;
        }
        
        helper.createSingleDriveLinkedRecord(cmp, event);
    },
    
    handleDeLink: function (cmp, event, helper) {
        
       	var linkedRecordId = cmp.get('v.linkedSingleDriveRecordId');
        
        
        var action = cmp.get("c.deLinkSingleDayDrives");
        action.setParams({
            "linkedId" : linkedRecordId
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            var lstResponse = response.getReturnValue();
            if (state === "SUCCESS") { 
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "type": "Success",
                    "message": "Drives de-linked successfully"
                });
                cmp.set("v.isLinkedDriveExist",false);
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
    
    loadMoreData: function (cmp, event, helper) {
        var rowsToLoad = cmp.get('v.rowsToLoad'),
            fetchData = cmp.get('v.dataTableSchema'),
            promiseData;
        
        event.getSource().set("v.isLoading", true);
        cmp.set('v.loadMoreStatus', 'Loading');
        
        promiseData = helper.fetchData(cmp, fetchData, rowsToLoad);
        
        promiseData.then($A.getCallback(function (data) {
            if (cmp.get('v.data').length >= cmp.get('v.totalNumberOfRows')) {
                cmp.set('v.enableInfiniteLoading', false);
                cmp.set('v.loadMoreStatus', 'No more data to load');
            } else {
                var currentData = cmp.get('v.data');
                var newData = currentData.concat(data);
                cmp.set('v.data', newData);
                cmp.set('v.loadMoreStatus', '');
            }
            event.getSource().set("v.isLoading", false);
        }));
    }
});