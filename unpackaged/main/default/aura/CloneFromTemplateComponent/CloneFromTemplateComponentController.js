({
    
    doInit: function( component, event, helper ) {
        var action = component.get("c.activeOpportunity");
        action.setParams({
            opportunityId: component.get("v.recordId")
        });
		action.setCallback(this, function(response) {
        	var state = response.getState();
			if (state === "SUCCESS") {
                var oppRec = response.getReturnValue();
                //console.log( 'templateStatus====='+oppRec.Is_Template__c);
                component.set('v.isTemplateVal', oppRec.Is_Template__c);
                if(oppRec.Template_Status__c == 'Inactive'){
                	component.set('v.loading', false);
                    component.set('v.activetemplate', false);
                    $A.get("e.force:closeQuickAction").fire();
        			component.find('OppMessage').setError('Template Status is InActive');
                	var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Info',
                        message: 'You are unable to clone an opportunity from an InActive Template.',
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'error',
                        mode: 'dismissible'
                    });
                    toastEvent.fire();
                }
                else{
                    //component.set('v.loading', true);
                    component.set('v.activetemplate', true);
                    
                }
            }
            else if (state === "INCOMPLETE") {
                 helper.handleErrors([{message: 'network error clone Template opportunity '}], component);
                      }
            else if (state === "ERROR") {
               helper.handleErrors(response.getError(), component, 'info');
               
            }
        });
        
        $A.enqueueAction(action);
    },
    
    createOpportunity : function(cmp, event, helper) {
        
        event.preventDefault();
        console.log('======'+cmp.get("v.isTemplateVal"));
        var fields = event.getParam("fields");
		 cmp.set("v.loading", true);
        //pass populated field values to controller
        let action = cmp.get("c.cloneOpportunityFields");
        action.setParams({
            opportunityId: cmp.get("v.recordId"),
            opportunityJson: JSON.stringify(fields),
            isTemplate: cmp.get("v.isTemplateVal")
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
                helper.handleErrors([{message: 'network error clone Template opportunity'}], cmp);
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