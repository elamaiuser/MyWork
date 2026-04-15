public with sharing class skedUpdateCoApRoleTargetsBatchHelper {
    private static final string fccCodesFixedSite = skedSetting.instance.Admin.fccCodeFixedSite;
    private static final string fccCodesMobile = skedSetting.instance.Admin.fccCodeMobile;

    public static List<BSF_Error_Log__c> autoAssignCollectionOpAvailabilityRecordsAndGetErrorLogs(Map<String, Set<String>> map_coId_uniqueApIds) {
        List<Collection_Operation_Availability__c> coApListToInsert = new List<Collection_Operation_Availability__c>();
        Set<Id> coIds = new Set<Id>();
        Set<Id> apIds = new Set<Id>();
        
        for(String coIdName : map_coId_uniqueApIds.keySet()) {
            coIds.add(coIdName.split(':')[0]);
            for(String apIdname : map_coId_uniqueApIds.get(coIdName)) {
                apIds.add(apIdname.split(':')[0]);
            }
        }
		
        //Find existing CoAp records with the same ApIds
        List<Collection_Operation_Availability__c> existingCoApRecords = [
            SELECT Id, Collection_Operation__c,
            Collection_Operation__r.Name,
            Availability_Pattern__c, Availability_Pattern__r.Name 
            FROM Collection_Operation_Availability__c 
            WHERE Collection_Operation__c IN :coIds 
            AND Availability_Pattern__c IN :apIds
            AND (Effective_End_Date__c = null OR Effective_End_Date__c >= TODAY)
        ];

        for(Collection_Operation_Availability__c coAp :  existingCoApRecords) {
            String mapKey = coAp.Collection_Operation__c + ':' + coAp.Collection_Operation__r.Name;
            String mapValue = coAp.Availability_Pattern__c + ':' + coAp.Availability_Pattern__r.Name;
            if(map_coId_uniqueApIds.containsKey(mapKey) && map_coId_uniqueApIds.get(mapKey).contains(mapValue)) {
                map_coId_uniqueApIds.get(mapKey).remove(mapValue);
            }
        }

        for(String coIdName : map_coId_uniqueApIds.keySet()) {
            if(map_coId_uniqueApIds.get(coIdName) == null || map_coId_uniqueApIds.get(coIdName).isEmpty()) continue;

            for(String apIdName : map_coId_uniqueApIds.get(coIdName)) {
                coApListToInsert.add(new Collection_Operation_Availability__c(
                    Name = coIdName.split(':')[1] + ' ' + apIdName.split(':')[1],
                    Collection_Operation__c = coIdName.split(':')[0],
                    Availability_Pattern__c = apIdName.split(':')[0],
                    Effective_Start_Date__c = Date.today(),
                    Effective_End_Date__c = skedDateTimeUtils.MAX_DATE
                ));
            }
        }

        Database.SaveResult[] insertResults = Database.insert(coApListToInsert, false);
        List<BSF_Error_Log__c> errorLogToInsert = BSF_Utilities.createErrorLog(
            insertResults,
            'CO AP Records insert',
            'skedUpdateCoApRoleTargetsBatchHelper',
            'autoAssignCollectionOpAvailabilityRecords',
            'Error',
            'Error in CO AP Record Creation'
        );
        return errorLogToInsert;
    }

    public static List<BSF_Error_Log__c> calculateTotalsAndUpdateCoApStatusOnResources(
        Map<String, Set<String>> map_coId_uniqueApIds, 
        Map<String, Map<String, Decimal>> map_coIdapIdKey_roleVsNoOfResourcesMap
    ) {
        Map<String, Map<String, Decimal>> map_coIdapIdKey_driveTypeVsNoOfResourcesMap = new Map<String, Map<String, Decimal>>();
        Map<String, Map<String, Decimal>> map_coIdKey_driveTypeVsNoOfResourcesMap = new Map<String, Map<String, Decimal>>();
        Set<Id> colIds = new Set<Id>();
        Set<Id> apIds = new Set<Id>();
        
        for(String coIdName : map_coId_uniqueApIds.keySet()) {
            colIds.add(coIdName.split(':')[0]);
            for(String apIdname : map_coId_uniqueApIds.get(coIdName)) {
                apIds.add(apIdname.split(':')[0]);
            }
        }

        List<sked__Resource__c> resourceList = [
            SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, CO_AP_Status__c,
            sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Grand_Total_Needed_Fixed_Site__c,
            sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Grand_Total_Needed_Mobile__c,
            sked_FCC_Code__c,
            (
                SELECT Id, sked__Tag__r.Name
                FROM sked__ResourceTags__r 
                WHERE sked_Role_Status__c = 'Active'
                AND sked_Tag_Type__c = 'Role'
            ),
            (
                SELECT Id, sked__Availability_Pattern__c
                FROM sked__Availability_Pattern_Resources__r
                WHERE sked__Availability_Pattern__c IN :apIds
                AND sked_Start_Date__c <= TODAY
                AND (sked_End_Date__c = null OR sked_End_Date__c >= TODAY)
            )
            FROM sked__Resource__c
            WHERE sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c IN :colIds
            AND sked_FCC_Code__c != null
            AND sked__Resource_Type__c = 'Person'
            AND sked__Is_Active__c = TRUE
        ];

        for(sked__Resource__c resource : resourceList) {
            if(resource.sked__Availability_Pattern_Resources__r == null || resource.sked__Availability_Pattern_Resources__r.isEmpty()) continue;
            
            String driveType = fccCodesFixedSite.contains(resource.sked_FCC_Code__c) ? 'Fixed Site' : 'Mobile';

            if(!map_coIdKey_driveTypeVsNoOfResourcesMap.containsKey(resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c)) {
                map_coIdKey_driveTypeVsNoOfResourcesMap.put(resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, new Map<String, Decimal>());
            }
            Map<String, Decimal> map_driveType_noOfCumulativeResourcesOnCOLevel = map_coIdKey_driveTypeVsNoOfResourcesMap.get(resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c);
            Decimal resourceCount = map_driveType_noOfCumulativeResourcesOnCOLevel.containsKey(driveType) ? map_driveType_noOfCumulativeResourcesOnCOLevel.get(driveType) : 0;
            map_driveType_noOfCumulativeResourcesOnCOLevel.put(driveType, resourceCount + 1);

            for(sked__Availability_Pattern_Resource__c apResource : resource.sked__Availability_Pattern_Resources__r) {
                String key = resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c + '_' + apResource.sked__Availability_Pattern__c;
                if(!map_coIdapIdKey_driveTypeVsNoOfResourcesMap.containsKey(key)) {
                    map_coIdapIdKey_driveTypeVsNoOfResourcesMap.put(key, new Map<String, Decimal>());
                }
                Map<String, Decimal> map_driveType_noOfCumulativeResources = map_coIdapIdKey_driveTypeVsNoOfResourcesMap.get(key);
                Decimal resourceCountOnCOLevel = map_driveType_noOfCumulativeResources.containsKey(driveType) ? map_driveType_noOfCumulativeResources.get(driveType) : 0;
                map_driveType_noOfCumulativeResources.put(driveType, resourceCountOnCOLevel + 1);

                for(sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r) {
                    if(!map_coIdapIdKey_roleVsNoOfResourcesMap.containsKey(key)) {
                        map_coIdapIdKey_roleVsNoOfResourcesMap.put(key, new Map<String, Decimal>());
                    }
                    Map<String, Decimal> map_role_noOfCumulativeRoles = map_coIdapIdKey_roleVsNoOfResourcesMap.get(key);
                    Decimal roleCount = map_role_noOfCumulativeRoles.containsKey(resourceTag.sked__Tag__r.Name) ? map_role_noOfCumulativeRoles.get(resourceTag.sked__Tag__r.Name) : 0;
                    map_role_noOfCumulativeRoles.put(resourceTag.sked__Tag__r.Name, roleCount + 1);
                }
            }
        }

        List<Collection_Operation_Availability__c> coApList = [
            SELECT Id, Name, Total_Actual_Resources_Fixed_Site__c, Total_Actual_Resources_Mobile__c,
            Total_Target_Fixed_Site__c, Total_Target_Mobile__c,
            Collection_Operation__c, Collection_Operation__r.Name,
            Availability_Pattern__c,
            (
                SELECT Id, Role__c,
                Min_Nbr_of_Role__c, Actual_Count_of_Role__c
                FROM Availability_Pattern_Roles__r
            )
            FROM Collection_Operation_Availability__c
            WHERE Collection_Operation__c IN :colIds
            AND Availability_Pattern__c IN :apIds
            AND (Effective_End_Date__c = null OR Effective_End_Date__c >= TODAY)
            ORDER BY Collection_Operation__c
        ];

        List<sObject> objectsToUpdate = new List<sObject>();

        for(Collection_Operation_Availability__c coAp : coApList) {
            String key = coAp.Collection_Operation__c + '_' + coAp.Availability_Pattern__c;
            coAp.Total_Actual_Resources_Fixed_Site__c = (map_coIdapIdKey_driveTypeVsNoOfResourcesMap.get(key) ?? new Map<String, Decimal>()).get('Fixed Site') ?? 0;
            coAp.Total_Actual_Resources_Mobile__c = (map_coIdapIdKey_driveTypeVsNoOfResourcesMap.get(key) ?? new Map<String, Decimal>()).get('Mobile') ?? 0;
                    
            for(Availability_Pattern_Role__c apRole : coAp.Availability_Pattern_Roles__r) {
                apRole.Actual_Count_of_Role__c = (map_coIdapIdKey_roleVsNoOfResourcesMap.get(key) ?? new Map<String, Decimal>()).get(apRole.Role__c) ?? 0;
                objectsToUpdate.add(apRole);
            }
            objectsToUpdate.add(coAp);
        }

        objectsToUpdate.addAll(getCalculateGrandTotalAvailableOnColOp(map_coIdKey_driveTypeVsNoOfResourcesMap));
        objectsToUpdate.addAll(getUpdatedCoApStatusOnResources(resourceList, coApList));
        objectsToUpdate.sort();

        Database.SaveResult[] updateResults = Database.update(objectsToUpdate, false);
        List<BSF_Error_Log__c> errorLogToInsert = BSF_Utilities.createErrorLogWithObjectId(
            updateResults,
            'CO AP / CO / Resource Records update',
            'skedUpdateCoApRoleTargetsBatchHelper',
            'calculateTotalsAndUpdateCoApStatusOnResources',
            'Error',
            'Records Update'
        );
        return errorLogToInsert;
    }

    public static List<Biomed_Collection_Op_Center__c> getCalculateGrandTotalAvailableOnColOp(Map<String, Map<String, Decimal>> map_coIdKey_driveTypeVsNoOfResourcesMap) {
        List<Biomed_Collection_Op_Center__c> coUpdateList = new List<Biomed_Collection_Op_Center__c>();

        for(String mapKey : map_coIdKey_driveTypeVsNoOfResourcesMap.keySet()) {
            Biomed_Collection_Op_Center__c updatedCo = new Biomed_Collection_Op_Center__c(
                Id = mapKey,
                Grand_Total_Available_Fixed_Site__c = map_coIdKey_driveTypeVsNoOfResourcesMap.get(mapKey).get('Fixed Site') ?? 0,   
                Grand_Total_Available_Mobile__c = map_coIdKey_driveTypeVsNoOfResourcesMap.get(mapKey).get('Mobile') ?? 0
            );
    
            coUpdateList.add(updatedCo);
        }

        return coUpdateList;
    }

    public static List<sked__Resource__c> getUpdatedCoApStatusOnResources(List<sked__Resource__c> resourceList, List<Collection_Operation_Availability__c> coApList) {
        List<sked__Resource__c> resourceListToUpdate = new List<sked__Resource__c>();

        for(sked__Resource__c resource : resourceList) {
            Boolean isResourceUpdateNeeded = false, isResourceNeedsFurtherProcessing = false;
            for(Collection_Operation_Availability__c coAp : coApList) {
                if(coAp.Collection_Operation__c != resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c) continue;
                if(coAp.Total_Actual_Resources_Fixed_Site__c > 0 && coAp.Total_Actual_Resources_Mobile__c > 0 && coAp.Total_Target_Fixed_Site__c != null && coAp.Total_Target_Mobile__c != null) {
                    if(coAp.Availability_Pattern_Roles__r != null && !coAp.Availability_Pattern_Roles__r.isEmpty()) {
                        for(Availability_Pattern_Role__c apRole : coAp.Availability_Pattern_Roles__r) {
                            if(apRole.Min_Nbr_of_Role__c > 0 && apRole.Actual_Count_of_Role__c > 0) {
                                if(resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Grand_Total_Needed_Fixed_Site__c > 0
                                    && resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Grand_Total_Needed_Mobile__c > 0) {
                                    resource.CO_AP_Status__c = skedConstants.CO_AP_STATUS_PROCESSED;
                                    isResourceUpdateNeeded = true;
                                } else {
                                    isResourceNeedsFurtherProcessing = true;
                                }
                                break;
                            }
                        }
                    } else isResourceNeedsFurtherProcessing = true;
                    
                } else isResourceNeedsFurtherProcessing = true;
            }
           
            if(isResourceNeedsFurtherProcessing) {
                resource.CO_AP_Status__c = skedConstants.CO_AP_STATUS_YET_TO_PROCESS_TOTALS;
                isResourceUpdateNeeded = true;
            }
            
            if(isResourceUpdateNeeded) resourceListToUpdate.add(resource);
        }
        
        return resourceListToUpdate;
    }
}