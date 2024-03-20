({
    
    createOpportunity : function(cmp, event, helper) {
        
        event.preventDefault();
        var fields = event.getParam("fields");
		 cmp.set("v.loading", true);
        //pass populated field values to controller
        let action = cmp.get("c.cloneOpportunityFields");
        action.setParams({
            opportunityId: cmp.get("v.recordId"),
            opportunityJson: JSON.stringify(fields),
            isTemplate: false
        });
        action.setCallback( this, function( response ) {
             cmp.set("v.loading", false);
            let state = response.getState();
            if (state === "SUCCESS") {
                
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                  "recordId": response.getReturnValue()
                  
                });
                navEvt.fire()
                //cmp.set('v.clonedOppId', response.getReturnValue());
                $A.get("e.force:closeQuickAction").fire();  
                $A.get('e.force:refreshView').fire(); 

            }
            else if (state === "INCOMPLETE") {
                helper.handleErrors([{message: 'network error getting opportunity lines'}], cmp);
            }
            else if (state === "ERROR") {
                helper.handleErrors(response.getError(), cmp, 'info');
            }
        } );

        $A.enqueueAction(action);
    },

    /**
     * Close the modal window and destroy the component
     * */
    cancelClone : function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        cmp.destroy();
    }
    

})