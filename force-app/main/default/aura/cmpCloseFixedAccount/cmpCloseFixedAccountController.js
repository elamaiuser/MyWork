({
    doInit: function (component, event, helper) { 
        var action = component.get("c.fetchFSAccountDetails");
        var recId = component.get('v.recordId');
        action.setParams({
            "accId" : recId
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            var lstResponse = response.getReturnValue();
            if (state === "SUCCESS") {
                component.set('v.accountName',lstResponse.Name);
                component.set('v.closureReason',lstResponse.Closure_Reason__c);
                component.set('v.effDate',lstResponse.Defunct_Effective_Date__c);
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
        
        
        component.set('v.display', true); 
    },
    
    closeModal: function (component, event, helper) {
        component.set('v.display', false);
        component.set("v.isConfirmationRequired", false);
        // Close the action panel
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
        
    },
    
    handleCloseOpportunities: function (component, event, helper) {
        
        var action = component.get("c.cancelOpportunitiesOnFSAccountClosure");
        var recId = component.get('v.recordId');
        var effDate = component.get('v.effDate');
        var closeReason = component.get('v.closureReason');
        action.setParams({
            "accId" : recId,
            "selEffectiveDate" : effDate,
            "closeReason" : closeReason,
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            var lstResponse = response.getReturnValue();
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "type": "success",
                    "message": lstResponse
                });
                resultsToast.fire();
                component.set('v.display', false);
                component.set("v.isConfirmationRequired", false);
                // Close the action panel
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            } 
            else if (state === "ERROR") {
                var errorMsg;
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        errorMsg = errors[0].message;
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    errorMsg = 'Unknown Error';
                    console.log("Unknown error");
                }
                var toastEvent = $A.get("e.force:showToast");
            	toastEvent.setParams({
                	title: 'Error',
                	type: 'error',
                	message: errorMsg
            	});
                toastEvent.fire();
                component.set('v.display', false);
                component.set("v.isConfirmationRequired", false);
                //Close the action panel
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    handleSave: function (component, event, helper) {
        var action = component.get("c.getTotalNonCancelledFutureOpportunities");
        var recId = component.get('v.recordId');
        var effDate = component.get('v.effDate');
        var closeReason = component.get('v.closureReason');
        if(effDate == '' || effDate == null || effDate == undefined || closeReason == null || closeReason == undefined ||  closeReason == ''){
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "type": "error",
                "message": "Please Enter Missing Fields."
            });
            resultsToast.fire();
            return;
        }
        
        
        action.setParams({
            "accId" : recId,
            "selEffectiveDate" : effDate
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            var lstResponse = response.getReturnValue();
            if (state === "SUCCESS") {
                if(lstResponse > 0){
                    
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "warning",
                        "message": `There are ${lstResponse} drive(s) scheduled after the selected effective date that will be cancelled.`
                    });
                    resultsToast.fire();
                    
                    component.set("v.isConfirmationRequired", true);
                    var cmpTarget = component.find('Modalbox');
                    var cmpBack = component.find('Modalbackdrop');
                    $A.util.addClass(cmpTarget, 'slds-fade-in-open');
                    $A.util.addClass(cmpBack, 'slds-backdrop--open');
                }else{
                    var action = component.get("c.closeFSAccount");
                    var recId = component.get('v.recordId');
                    var effDate = component.get('v.effDate');
                    var closeReason = component.get('v.closureReason');
                    action.setParams({
                        "accId" : recId,
                        "selEffectiveDate" : effDate,
                        "closeReason" : closeReason,
                    });
                    action.setCallback(this, function (response) {
                        var state = response.getState();
                        var lstResponse = response.getReturnValue();
                        if (state === "SUCCESS") {
                            $A.get('e.force:refreshView').fire();
                            var resultsToast = $A.get("e.force:showToast");
                            resultsToast.setParams({
                                "type": "success",
                                "message": lstResponse
                            });
                            resultsToast.fire();
                            
                            component.set('v.display', false);
                            component.set("v.isConfirmationRequired", false);
                            // Close the action panel
                            var dismissActionPanel = $A.get("e.force:closeQuickAction");
                            dismissActionPanel.fire();
                            
                            
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
                    
                }
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
    
})