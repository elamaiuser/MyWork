({
	getSiteRecordId : function(component, event, helper) {
        console.log(event.getParam('value'));
		component.set("v.recordId",event.getParam('value'));
        component.set("v.create", false);
        component.set("v.addAddress", true);
        console.log(component.get('v.addAddress'));
	},
    
    handleClose : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/lightning/r/sked__Location__c/'+component.get('v.recordId')+'/view'
        });
        urlEvent.fire(); 
    }
})