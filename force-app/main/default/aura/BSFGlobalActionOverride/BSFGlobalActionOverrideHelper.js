({
    loadDynamicComponent : function(component) {
        var action = component.get("c.getTargetConfig");
        
        action.setParams({
            objectName: component.get("v.sObjectName"),
            actionType: component.get("v.actionType")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var config = response.getReturnValue();

                if (config.notFound) {
                    component.set("v.isLoading", false);
                    component.set("v.warningMessage", 'No Configuration Found for button "' + component.get("v.actionType") + '" on ' + component.get("v.sObjectName"));
                    return;
                } 
                
                if (!config.hasAccess) {
                    component.set("v.isLoading", false);
                    component.set("v.errorMessage", $A.get("$Label.c.Error_No_Access"));
                    return;
                } 
                
                component.set("v.isModalView", config.isModalView);
                component.set("v.customTargetLabel", config.customTargetLabel);
                component.set("v.isLoading", false);
                window.setTimeout(
                    $A.getCallback(function () {
                        var container = component.find("dynamicComponentContainer");

                        if (config.isFlow) {
                            $A.createComponent(
                                "lightning:flow",
                                {
                                    "onstatuschange": component.getReference("c.handleFlowStatusChange")
                                },
                                function(newFlow, status, errorMessage) {
                                    if (status === "SUCCESS") {
                                        container.set("v.body", newFlow);
                                        
                                        var inputVariables = [];
                                        if (component.get("v.recordId")) inputVariables.push({ name: "recordId", type: "String", value: component.get("v.recordId") });
                                        if (component.get("v.sObjectName")) inputVariables.push({ name: "objectApiName", type: "String", value: component.get("v.sObjectName") });
                                        if (component.get("v.parentRecordId")) inputVariables.push({ name: "parentRecordId", type: "String", value: component.get("v.parentRecordId") });
                                        if (component.get("v.actionType")) inputVariables.push({ name: "actionType", type: "String", value: component.get("v.actionType") });

                                        newFlow.startFlow(config.targetName, inputVariables);
                                        
                                    } else {
                                        component.set("v.isLoading", false);
                                        component.set("v.errorMessage", "Failed to load flow: " + errorMessage);
                                    }
                                }
                            );
                        } 
                        else {
                            var lwcName = config.targetName;
                            
                            if (!lwcName.includes(':') && !lwcName.includes('/')) {
                                lwcName = 'c:' + lwcName;
                            } else if (lwcName.includes('/')) {
                                lwcName = lwcName.replace('/', ':');
                            }

                            $A.createComponent(
                                lwcName,
                                {
                                    "recordId": component.get("v.recordId"),
                                    "objectApiName": component.get("v.sObjectName"),
                                    "parentRecordId": component.get("v.parentRecordId"),
                                    "actionType": component.get("v.actionType"),
                                    "onclose": component.getReference("c.handleClose")
                                },
                                function(newLwc, status, errorMessage) {
                                    component.set("v.isLoading", false);
                                    if (status === "SUCCESS") {
                                        container.set("v.body", newLwc);
                                    } else {
                                        component.set("v.errorMessage", "Failed to load Custom LWC: " + errorMessage);
                                    }
                                }
                            );
                        }
                    }),
                    50
                );
            } else {
                component.set("v.isLoading", false);
                component.set("v.errorMessage", "Failed to fetch routing configuration from server.");
            }
        });

        $A.enqueueAction(action);
    }
})