({
    init : function (component) {
        // Find the component whose aura:id is "flowData"
        var flow = component.find("flowData");
        //Assigning Input Variables
        var inputVariables = [
            { name : "txt_RelatedAccountId", 
             type : "String", 
             value: component.get("v.selectedAccountId")            
            }
        ];        
        
        flow.startFlow("Mass_Update_Opportunity", inputVariables );        
    },
    
    handleStatusChange : function (component, event) {
        if(event.getParam("status") === "FINISHED") {
            var outputVariables = event.getParam("outputVariables");
            console.log(outputVariables);
            
            var outputVar;
            for(var i = 0; i < outputVariables.length; i++) {
                outputVar = outputVariables[i];
                if(outputVar.name === "txt_RelatedAccountId") {
                    
                    if(outputVar.value !== null && outputVar.value !== undefined && outputVar.value !== '') {
                        var urlEvent = $A.get("e.force:navigateToSObject");
                        urlEvent.setParams({
                            "recordId": outputVar.value,
                            "isredirect": "true"
                        });
                        urlEvent.fire();
                    }
                    else {
                        var homeEvent = $A.get("e.force:navigateToObjectHome");
                        homeEvent.setParams({
                            "scope": "Account"
                        });
                        homeEvent.fire();
                    }
                }  
            }
        }        
    },
    
    handleClose : function (component, event) {
        
        var accountId = component.get("v.selectedAccountId");
        
        console.log('flowHostCMP.handleClose() - accountId : ' + accountId);
        if(accountId !== null && accountId !== undefined && accountId !== '') {
            console.log('flowHostCMP.handleClose() - Navigating to Account ID Details Page');
            
            var urlEvent = $A.get("e.force:navigateToSObject");
            urlEvent.setParams({
                "recordId": accountId,
                "isredirect": "true"
            });
            urlEvent.fire();
        }
        else {
            console.log('flowHostCMP.handleClose() - Navigating to Account Home Page');
            var homeEvent = $A.get("e.force:navigateToObjectHome");
            homeEvent.setParams({
                "scope": "Account"
            });
            homeEvent.fire();
        }
    }
})