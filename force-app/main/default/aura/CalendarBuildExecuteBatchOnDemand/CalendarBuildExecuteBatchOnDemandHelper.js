({
    // Function to fetch data from server called in initial loading of page
    fetchDraftBatchSize: function(component, event, helper) {
        
        // Assign server method to action variable
        var action = component.get("c.getDraftDrivesBatchSize");        
        action.setCallback(this, function(response) {
            var state = response.getState();
            // Check if response state is success
            if(state === 'SUCCESS') {
                // Getting the list of contacts from response and storing in js variable
                var draftBatchSize = response.getReturnValue();
                
                // Set the list attribute in component with the value returned by function
                component.set("v.draftBatchSize",draftBatchSize);
            }
            else {   
                // Show an alert if the state is incomplete or error
                alert('Error in getting data');
            }
        });
        // Adding the action variable to the global action queue      
        $A.enqueueAction(action);
    },
    
    fetchSysGenBatchSize: function(component, event, helper) {
        // Assign server method to action variable
        var action2 = component.get("c.getSysGenDrivesBatchSize");        
        action2.setCallback(this, function(response) {
            var state = response.getState();
            // Check if response state is success
            if(state === 'SUCCESS') {
                // Getting the list of contacts from response and storing in js variable
                var sysGenBatchSize = response.getReturnValue();
                
                // Set the list attribute in component with the value returned by function
                component.set("v.sysGenBatchSize",sysGenBatchSize);
            }
            else {   
                // Show an alert if the state is incomplete or error
                alert('Error in getting data');
            }
        });
        // Adding the action variable to the global action queue      
        $A.enqueueAction(action2);
    }
})