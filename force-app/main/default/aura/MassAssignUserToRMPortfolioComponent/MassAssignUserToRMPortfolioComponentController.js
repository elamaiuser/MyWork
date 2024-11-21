({
 doOnload : function(cmp, event, helper) {
        
        let portfolioIds = cmp.get("v.portfolioIds");
        console.log( "portfolio id are ", portfolioIds );
        let portfolioIdArray = [];
        portfolioIdArray = portfolioIds.split(";");
        
        
        let modifiedArray = [];
        portfolioIdArray.forEach( (item)=>{
            if(item){
            	modifiedArray.push(item);
        	}
        });
        
        //console.log( "modifiedArray are ", modifiedArray);
        cmp.set( "v.PortfolioIdArrays", modifiedArray);
        cmp.set("v.portfolioIdsplited", true);
    },
    saveRedirect : function(cmp, event, helper) {
        //This is important.  Notice how i get the event.
        console.log('Inside saveRedirect:');
        var redirectEvent = $A.get("e.c:RedirectAccountListViewEvent");
        redirectEvent.fire();
        
    }
})