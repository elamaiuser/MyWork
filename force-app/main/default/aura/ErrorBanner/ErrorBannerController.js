({
    doInit : function(component, event, helper) {
        var action = component.get("c.validateOpportunityOnBanner");

        action.setParams({
            "recordId": component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.errorMessage", response.getReturnValue());
            }
        });

        $A.enqueueAction(action);
    }
})