({
    setDefaultFilterFieldIfNeeded : function(cmp) {
        var filterFieldApiName = cmp.get("v.filterFieldApiName");
        var childObjectName = cmp.get("v.childObjectName");
        var loggedinuserid = cmp.get("v.loggedinuserid");

        if (!filterFieldApiName && loggedinuserid) {
            if (childObjectName === 'ContentVersion') {
                cmp.set("v.filterFieldApiName", "OwnerId");
            } else {
                cmp.set("v.filterFieldApiName", "OwnerId");
            }
        }

        if (!filterFieldApiName && !loggedinuserid && childObjectName === 'ContentVersion') {
            cmp.set("v.filterFieldApiName", "ContentDocumentId");
        }
    }
})