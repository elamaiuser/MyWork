({
    doInit : function(component, event, helper) {
        var container = component.find("dynamicComponentContainer");
        if (container) {
            container.set("v.body", []); 
        }

        let pageRef = component.get("v.pageReference");
        let actionName = null;
        let isQuickAction = false;

        if (pageRef) {
            if (pageRef.attributes && pageRef.attributes.actionName) {
                actionName = pageRef.attributes.actionName;
            } 
            else if (pageRef.state && pageRef.state.actionName) {
                actionName = pageRef.state.actionName;
            } 
            else if (pageRef.attributes && pageRef.attributes.apiName) {
                actionName = pageRef.attributes.apiName;
            }
        }

        if (!actionName && component.get("v.recordId") && !pageRef.attributes.actionName) {
            isQuickAction = true;
            actionName = "QuickAction"; 
        }

        component.set("v.isQuickAction", isQuickAction);
        component.set("v.actionType", actionName);

        let parentId = null;
        const decodeContext = (contextStr) => {
            if (!contextStr) return null;
            if ((contextStr.length === 15 || contextStr.length === 18) && /^[a-zA-Z0-9]+$/.test(contextStr)) return contextStr;
            if (contextStr.startsWith("1.")) contextStr = contextStr.substring(2);
            try {
                contextStr = decodeURIComponent(contextStr);
                contextStr = contextStr.replace(/-/g, '+').replace(/_/g, '/');
                let decodedObj = JSON.parse(window.atob(contextStr));
                return decodedObj.attributes ? decodedObj.attributes.recordId : null;
            } catch(e) { return null; }
        };

        if (pageRef && pageRef.state) {
            if (pageRef.state.inContextOfRef) parentId = decodeContext(pageRef.state.inContextOfRef);
            if (!parentId && pageRef.state.inContextOfRecordId) parentId = decodeContext(pageRef.state.inContextOfRecordId);
            if (!parentId && pageRef.state.additionalParams) {
                let searchParams = new URLSearchParams(pageRef.state.additionalParams);
                parentId = decodeContext(searchParams.get("inContextOfRecordId")) || decodeContext(searchParams.get("inContextOfRef"));
            }
            if (!parentId && pageRef.state.backgroundContext) {
                let bgContextStr = pageRef.state.backgroundContext;
                if (bgContextStr.startsWith("/lightning/r/")) {
                    let parts = bgContextStr.split("/");
                    if (parts.length > 4) parentId = parts[4];
                } else {
                    parentId = decodeContext(bgContextStr);
                }
            }
        }
        
        if (!parentId) {
            let match = window.location.href.match(/inContextOfRef=([^&]+)/) || window.location.href.match(/inContextOfRecordId=([^&]+)/);
            if (match) parentId = decodeContext(decodeURIComponent(match[1]));
        }

        if (parentId) component.set("v.parentRecordId", parentId);
        
        if (actionName) {
            helper.loadDynamicComponent(component);
        } else {
            component.set("v.isLoading", false);
            component.set("v.errorMessage", "Could not detect Button API Name from the page context.");
        }
    },

    handleClose : function(component, event, helper) {
        var container = component.find("dynamicComponentContainer");
        if (container) {
            container.set("v.body", []);
        }

        $A.get('e.force:refreshView').fire();
        
        var isQuickAction = component.get("v.isQuickAction");
        var recordId = component.get("v.recordId");
        var parentId = component.get("v.parentRecordId");

        if (isQuickAction) {
            $A.get("e.force:closeQuickAction").fire();
        } else {
            var navEvt = $A.get("e.force:navigateToSObject");
            
            if (parentId) {
                navEvt.setParams({ "recordId": parentId });
                navEvt.fire();
            } else if (recordId) {
                navEvt.setParams({ "recordId": recordId });
                navEvt.fire();
            } else {
                window.history.back();
            }
        }
    },

    handleFlowStatusChange : function(component, event, helper) {
        if (event.getParam('status') === "FINISHED" || event.getParam('status') === "FINISHED_SCREEN") {
            if (component.get("v.isQuickAction")) {
                $A.get("e.force:closeQuickAction").fire();
            } else {
                window.history.back();
            }
            $A.get('e.force:refreshView').fire();
        }
    }
})