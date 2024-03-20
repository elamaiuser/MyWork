({
   
    /**
     * this method call when component load and set count to the tab 
     */ 
    doInit : function(component, event, helper) {
        var tabHeader = component.get("v.headerName");
         var fieldWithOrderBy = component.get("v.fieldwithOrderBy");
        console.log('fieldWithOrderBy @@'+fieldWithOrderBy);
        console.log('tabHeader-->'+tabHeader);
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: tabHeader
            });
        })
        .catch(function(error) {
            console.log(error);
        });
        helper.fetchRecord(component, event, helper);
    },
    
    handleRowAction: function ( component, event, helper ) {
       
        var action = event.getParam( 'action' );
        var row = event.getParam( 'row' );
        var recId = row.Id;
        switch ( action.name ) {
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
                var action = component.get('c.deleteRecords');
                // pass the all selected record's Id's to apex method 
                action.setParams({
                "lstRecordId": recId
                });
                action.setCallback(this, function(response) {
                    
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        $A.get('e.force:refreshView').fire();
                     }
                });
                    $A.enqueueAction(action);
            break;
        }
        component.set("v.value", 0);
        helper.toggle(component);
    },
    navigateToListView: function (component, event) {
        var oppId = component.get('v.recordId');
        console.log('oppId-->'+oppId);
        var strOppId = oppId.toString();
        var objectIdentity = strOppId.substring(0,3);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
        "url": "/"+objectIdentity+"/o"
        });
        console.log('URL'+urlEvent);
        urlEvent.fire();
    },
    navigateToRecordView: function (component, event) {
        var oppId = component.get('v.recordId');
        var strOppId = oppId.toString();
        var objectIdentity = strOppId.substring(0,3);
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
        "recordId": oppId,
        "slideDevName": "detail"
        });
        navEvt.fire();
    },

    updateColumnSorting: function (component, event, helper) {
        console.log('updateColumnSorting');
        var fieldName = event.getParam('fieldName');
        var columns = component.get("v.columns");
        var sortByCol = columns.find(column => fieldName === column.fieldName);
        var lableName = sortByCol.label;
        component.set("v.sortedByLabel", lableName);
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        console.log('fieldName-->'+fieldName);
        
        console.log('fieldwithOrderBy'+component.get('v.fieldwithOrderBy'));
        if (!fieldName || !sortDirection) {
        var fieldwithOrderBy = component.get('v.fieldwithOrderBy');
        if (fieldwithOrderBy) {
            var parts = fieldwithOrderBy.split(' ');
            fieldName = parts[0];
            sortDirection = parts[1];
        }
    }
        
        helper.sortData(component, fieldName, sortDirection);
        component.set("v.value", 0);
        helper.toggle(component);
    },

    handleLoadMore : function(component,event,helper){
        //To display the spinner
        component.set("v.spinner", true); 
        if(!(component.get("v.recordOffset") >= component.get("v.numberOfRecords"))){
            
            //To handle data returned from Promise function
            helper.getMoreData(component).then(function(data){ 
                var currentData = component.get("v.data");
                var newData = currentData.concat(data);
                component.set("v.data", newData);
                console.log(component.get("v.numberOfRecords")+'newData-->'+newData.length);
                if((component.get("v.recordOffset") >= component.get("v.numberOfRecords"))){
                    component.set("v.enableInfiniteLoading",false);
                }
                //To hide the spinner
                component.set("v.spinner", false); 
            });
        }
        else{
            //To stop loading more rows
            component.set("v.enableInfiniteLoading",false);
            component.set("v.spinner", false);
            var toastReference = $A.get("e.force:showToast");
            toastReference.setParams({
                "type":"Success",
                "title":"Success",
                "message":"All records are loaded",
                "mode":"dismissible"
            });
            toastReference.fire();
        }
    },
    waiting: function(component, event, helper) {
        component.set("v.spinner", true);
       },
       doneWaiting: function(component, event, helper) {
        component.set("v.spinner", false);
       }
})