({
    /**
     * this method call when component load and set count to the tab 
     */ 
    doInit : function(component, event, helper) {
        console.log( 'debug#2' );
        helper.fetchRecord(component, event, helper);
    },
    
    /**
     * this method call when view all clicked
     */ 
    handleGotoRelatedList : function(component, event, helper) {
        
        var navigateEvent = $A.get("e.force:navigateToComponent");
        navigateEvent.setParams({
            componentDef: "c:GenericViewAllComponent",
            componentAttributes: {
                recordId: component.get("v.recordId"),
                SOQLQuery : component.get("v.SOQLQuery"),
                ColumnName : component.get("v.ColumnName"),
                headerName : component.get("v.headerName"),
                objectName : component.get("v.objectName"),
                recordName : component.get("v.recordName"),
                recordButton : component.get("v.recordButton"),
                hyperLinkColumn : component.get("v.hyperLinkColumn"),
                dateFormatType : component.get("v.dateFormatType"),
                fieldwithOrderBy : component.get("v.fieldwithOrderBy")
            }
        });
        navigateEvent.fire();
    },
    handleRowAction: function ( component, event, helper ) {
        
        var actionEvent = event.getParam( 'action' );
        var row = event.getParam( 'row' );
        var recId = row.Id;
        console.log('action-->'+actionEvent.name);
        switch ( actionEvent.name ) {
            case 'edit':
                var editRecordEvent = $A.get("e.force:editRecord");
                editRecordEvent.setParams({
                    "recordId": recId
                });
                editRecordEvent.fire();
                break;
            case 'view':
                var viewRecordEvent = $A.get("e.force:navigateToURL");
                viewRecordEvent.setParams({
                    "url": "/" + recId
                });
                viewRecordEvent.fire();
                break;
            case 'delete':
                helper.deleteRecord(component, event, helper,recId);
                break;
        }
    },
    showModel: function(component, event, helper) {
        component.set("v.showModal", true);
    },
    
    hideModel: function(cmp, event, helper) {
        cmp.set("v.showModal", false);
        //$A.get('e.force:refreshView').fire();
        var cmpEvent = cmp.getEvent("RefreshCustomComponent");       
        cmpEvent.fire();
        
    },
    
    saveDetails: function(component, event, helper) {
        component.set("v.showModal", false);
    },
})