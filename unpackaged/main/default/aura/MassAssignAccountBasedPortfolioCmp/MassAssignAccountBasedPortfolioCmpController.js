({
    doOnload : function(cmp, event, helper) {
        
        let accountids = cmp.get("v.accountids");
        //console.log( "account id are ", accountids );
        let accountIdArray = [];
        accountIdArray = accountids.split(";");
        
        
        let modifiedArray = [];
        accountIdArray.forEach( (item)=>{
            if(item){
            	modifiedArray.push(item);
        	}
        });
        
        //console.log( "modifiedArray are ", modifiedArray);
        cmp.set( "v.AccountIdArrays", modifiedArray);
        cmp.set("v.accountidsplited", true);
    },
    saveRedirect : function(cmp, event, helper) {
        //This is important.  Notice how i get the event.
        var redirectEvent = $A.get("e.c:RedirectAccountListViewEvent");
        redirectEvent.fire();
        
    }
})