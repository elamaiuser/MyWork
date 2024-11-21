({
	saveRedirect : function(cmp, event, helper) {
        
        console.log("save and redirect");
        
        //This is important.  Notice how i get the event.
        var redirectEvent = $A.get("e.c:RedirectAccountListViewEvent");
        //updateEvent.setParams({"lookupVal": objectId, "lookupLabel": objectLabel});
        redirectEvent.fire();
		
	}
})