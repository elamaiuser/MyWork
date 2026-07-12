({
    doOnload : function(cmp, event, helper) {
        cmp.set("v.displayRelatedList", false);

        if (cmp.get("v.loggedinuserid")) {
            var userId = $A.get("$SObjectType.CurrentUser.Id");
            cmp.set("v.genericrecordid", [userId]);

            helper.setDefaultFilterFieldIfNeeded(cmp);

            cmp.set("v.displayRelatedList", true);
        } else {
            var action = cmp.get("c.getContentDocumentId");
            action.setParams({ recordid : cmp.get("v.recordId") });

            action.setCallback(this, function(response) {
                var state = response.getState();

                if (state === "SUCCESS") {
                    var contentdocid = response.getReturnValue() || [];
                    cmp.set("v.genericrecordid", contentdocid);

                    helper.setDefaultFilterFieldIfNeeded(cmp);

                    cmp.set("v.displayRelatedList", true);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    } else {
                        console.log("Unknown error");
                    }
                }
            });

            $A.enqueueAction(action);
        }
    },

    refreshCustomComp : function(cmp, event, helper) {
        console.log("component event fired");
        cmp.set("v.displayRelatedList", false);
        cmp.reInit();
    }
})