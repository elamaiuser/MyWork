({
    doInit : function(component, event, helper) {
        var action = component.get("c.updateNationNameStatus");
        action.setParams({ 
            recordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var result = response.getReturnValue();
            console.log('state-->'+state);
            console.log('response-->'+result);
            if (state === "SUCCESS") {
                if(result.startsWith('Error')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "Error",
                        "message": result
                    });
                    toastEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();
                }else if(result.startsWith('Success')){

                    /*var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "Success",
                        "message": result
                    });
                    toastEvent.fire();*/
                    console.log('result-->'+result);
                    component.set("v.message", result);
            	}else{
                	$A.get("e.force:closeQuickAction").fire();
            	}
            }else{
                $A.get("e.force:closeQuickAction").fire();
            }
            /*var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
              "recordId": component.get("v.recordId"),
              "slideDevName": "Detail"
            });
            navEvt.fire();*/
        });
        $A.enqueueAction(action);
    },
    closePopup : function(component, event, helper) {
        /*console.log('button clicked-->');
    	var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.recordId"),
            "slideDevName": "Chatter"
        });
        navEvt.fire();*/
         $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    },
})