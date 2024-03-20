public class skedResourceUtils {

    public static Map<String, Set<String>> getResourceRolesByGroup() {
        List<sked_Resource_Role_Group__c> resourceRoleGroups = [
            SELECT Id, Name, sked_Resource_Role_Group__c, sked_Resource_Roles__c
            FROM sked_Resource_Role_Group__c
        ];

        Map<String, Set<String>> resourceRoleByGroup = new Map<String, Set<String>>();
        for (sked_Resource_Role_Group__c resourceRoleGroup : resourceRoleGroups) {
            Set<String> roles = new Set<String>(resourceRoleGroup.sked_Resource_Roles__c.split(';'));
            resourceRoleByGroup.put(resourceRoleGroup.sked_Resource_Role_Group__c, roles);
        }

        return resourceRoleByGroup;
    }

    public static Boolean getResourceBelongsToCollectionOp(sked__Resource__c skedResource, Id collectionOpId, Date driveDate) {
        Boolean resourceBelongsToCollectionOp = false;

        if (skedResource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c == collectionOpId) {
            resourceBelongsToCollectionOp = true;
        }

        if (skedResource.sked_Resource_Biomed_Collection_Ops__r != null && !skedResource.sked_Resource_Biomed_Collection_Ops__r.isEmpty()) {
            for (sked_Resource_Biomed_Collection_Op__c secondaryCO : skedResource.sked_Resource_Biomed_Collection_Ops__r) {
                boolean isStartDateMatched = secondaryCO.sked_Start_Date__c == NULL || secondaryCO.sked_Start_Date__c <= driveDate;
                boolean isEndDateMatched = secondaryCO.sked_End_Date__c == NULL || secondaryCO.sked_End_Date__c >= driveDate;
                
                if (collectionOpId == secondaryCO.sked_Biomed_Collection_Op_Center__c && isStartDateMatched && isEndDateMatched) {
                    resourceBelongsToCollectionOp = true;
                    break;
                }
            }
        }

        if (skedResource.sked__Resource_Overrides__r != null && !skedResource.sked__Resource_Overrides__r.isEmpty()) {
            for (sked__Resource_Override__c temporaryRegion : skedResource.sked__Resource_Overrides__r) {
                if (driveDate >= temporaryRegion.sked_Start_Date__c && driveDate <= temporaryRegion.sked_End_Date__c) {
                    resourceBelongsToCollectionOp = collectionOpId == temporaryRegion.sked_Collection_Operation__c;
                    break;
                } 
            }
        }

        return resourceBelongsToCollectionOp;
    }
}