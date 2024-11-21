({
    init: function (cmp, event, helper) {
        cmp.set('v.columns', helper.getColumnDefinitions());        
        helper.fetchData(cmp,cmp.get('v.initialRows'));
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
               // cmp.set("v.isLinkedDriveExist",false);
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
    },
    
    handleRowAction: function (cmp, event, helper) {
        //var action = event.getParam('action');
        var row = event.getParam('row');
        cmp.set("v.selectedRow", row.Id);   
        switch (row.isLinked) {
            case 'Link Drive':
                helper.linkRecord(row,cmp);
                break;
                // You might have other buttons as well, handle them in the same way
            case 'Linked':
                cmp.set("v.isconfirmationModalOpen", true);
                break;
        }
    },
    
    openModel: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isconfirmationModalOpen", true);
    },
    
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isconfirmationModalOpen", false);
    },
    
    submitDetails: function(component, event, helper) {        
        component.set("v.isconfirmationModalOpen", false);
        helper.delinkRecord(component, component.get('v.selectedRow'));
    },
});