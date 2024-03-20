({
	doOnload : function(cmp, event, helper) {
        if( cmp.get("v.loggedinuserid") ){
            // Task Related List
            var userId = $A.get("$SObjectType.CurrentUser.Id");
            
            let useridarr = [];
            useridarr.push( userId );
            cmp.set("v.genericrecordid", useridarr );
            console.log( 'useridarr is ' , cmp.get("v.genericrecordid" ) );
            
            cmp.set("v.displayRelatedList", true);
        }else{
            // file related list
            let contentdocid = [];
            console.log( "record id id " , cmp.get("v.recordId") );
            var action = cmp.get("c.getContentDocumentId");
            action.setParams({ recordid : cmp.get("v.recordId") });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    contentdocid = response.getReturnValue();
                    
                    let finalquery;
                    finalquery = cmp.get("v.SOQLQuery");
                    if( !finalquery.includes( 'where ContentDocumentId IN:' ) ){ 
                        finalquery = finalquery + ' where ContentDocumentId IN: ' ; //+ contentdocid ;
                        cmp.set("v.SOQLQuery", finalquery);
                        
                        
                    }
                    cmp.set("v.genericrecordid", contentdocid );
                    
                    
                    
                    console.log("debug#1 ",  cmp.get("v.displayRelatedList"), " finalquery :" ,  finalquery, " contentdocid is " , contentdocid  );
                    
                    cmp.set("v.displayRelatedList", true);
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
            
        }
	},
    refreshCustomComp:function(cmp, event, helper) {
        console.log("component event fired");
        cmp.set("v.displayRelatedList", false);
        cmp.reInit();
    }
})