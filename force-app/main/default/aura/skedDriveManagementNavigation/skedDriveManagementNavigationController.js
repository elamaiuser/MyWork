({
    doInit : function(cmp, event, helper) {
        var navService = cmp.find("navService");
        // Sets the route to /lightning/o/Account/home
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c:skedDriveManagement'
            },
            state : {
                c__recordId : cmp.get('v.recordId')
            }
        }
        
        var defaultUrl = "#";
        navService.generateUrl(pageReference).then($A.getCallback(function(url) {
            window.open(url, '_blank');
        }))
    },
    
    doneRendering: function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})