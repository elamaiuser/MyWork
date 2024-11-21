({
    doOnload:function(cmp, event, helper){
        console.log( "current account id is now " , cmp.get("v.recordId") );
        let action = cmp.get("c.getAccountInstance");
        action.setParams({
            accid: cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.accobject", response.getReturnValue() );
                console.log( "response is ", JSON.stringify( response.getReturnValue() ) );
                if( response.getReturnValue() ){
                    cmp.set("v.AccountFound", true);
                }
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
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
	closequickaction : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}
})