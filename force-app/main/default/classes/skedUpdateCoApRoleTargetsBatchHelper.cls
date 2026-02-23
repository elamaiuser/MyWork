public with sharing class skedUpdateCoApRoleTargetsBatchHelper {

    public static List<BSF_Error_Log__c> autoAssignCollectionOpAvailabilityRecordsAndGetErrorLogs(Map<String, Set<String>> map_coId_uniqueApIds) {
        List<Collection_Operation_Availability__c> coApListToInsert = new List<Collection_Operation_Availability__c>();
        Set<Id> coIds = new Set<Id>();
        Set<Id> apIds = new Set<Id>();
        
        for(String coIdName : map_coId_uniqueApIds.keySet()) {
            coIds.add(coIdName.split('_')[0]);
            for(String apIdname : map_coId_uniqueApIds.get(coIdName)) {
                apIds.add(apIdname.split('_')[0]);
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
            AND Effective_End_Date__c >= TODAY
        ];

        for(Collection_Operation_Availability__c coAp :  existingCoApRecords) {
            String mapKey = coAp.Collection_Operation__c + '_' + coAp.Collection_Operation__r.Name;
            String mapValue = coAp.Availability_Pattern__c + '_' + coAp.Availability_Pattern__r.Name;
            if(map_coId_uniqueApIds.containsKey(mapKey) && map_coId_uniqueApIds.get(mapKey).contains(mapValue)) {
                map_coId_uniqueApIds.get(mapKey).remove(mapValue);
            }
        }

        for(String coIdName : map_coId_uniqueApIds.keySet()) {
            if(map_coId_uniqueApIds.get(coIdName) == null || map_coId_uniqueApIds.get(coIdName).isEmpty()) continue;

            for(String apIdName : map_coId_uniqueApIds.get(coIdName)) {
                coApListToInsert.add(new Collection_Operation_Availability__c(
                    Name = coIdName.split('_')[1] + ' ' + apIdName.split('_')[1],
                    Collection_Operation__c = coIdName.split('_')[0],
                    Availability_Pattern__c = apIdName.split('_')[0],
                    Effective_Start_Date__c = Date.today(),
                    Effective_End_Date__c = skedDateTimeUtils.MAX_DATE
                ));
            }
        }

        Database.SaveResult[] insertResults = Database.insert(coApListToInsert, false);
        List<BSF_Error_Log__c> errorLogToInsert = BSF_Utilities.createErrorLogWithObjectId(
            insertResults,
            'CO AP Records insert',
            'skedUpdateCoApRoleTargetsBatchHelper',
            'autoAssignCollectionOpAvailabilityRecords',
            'Error',
            'Record Creation'
        );
        return errorLogToInsert;
    }

    public static List<BSF_Error_Log__c> calculateTotalsAndUpdateCoApStatusOnResources(Set<Id> resourceIds, Map<String, Set<String>> map_coId_uniqueApIds) {
        Map<Id, Decimal> map_apId_noOfAssignedResources = new Map<Id, Decimal>();
        Map<Id, Map<String, Decimal>> map_apId_roleVsNoOfResourcesMap = new Map<Id, Map<String, Decimal>>();
        Set<Id> colIds = new Set<Id>();
        Set<Id> apIds = new Set<Id>();
        
        for(String coIdName : map_coId_uniqueApIds.keySet()) {
            colIds.add(coIdName.split('_')[0]);
            for(String apIdname : map_coId_uniqueApIds.get(coIdName)) {
                apIds.add(apIdname.split('_')[0]);
            }
        }

        for (AggregateResult ar : [
            SELECT sked__Availability_Pattern__c apId,
            COUNT_DISTINCT(sked__Resource__c) totalActualResources
            FROM sked__Availability_Pattern_Resource__c
            WHERE sked__Resource__r.sked_Collection_Operation_Id__c IN : colIds
            AND sked__Availability_Pattern__c IN : apIds
            AND (sked_End_Date__c = NULL OR sked_End_Date__c >= TODAY)
            AND sked__Resource__r.sked__Resource_Type__c = 'Person'
            AND sked__Resource__r.sked__Is_Active__c = TRUE
            GROUP BY sked__Availability_Pattern__c
        ]) {
            map_apId_noOfAssignedResources.put((Id)ar.get('apId'), (Decimal)ar.get('totalActualResources'));
        }

        List<sked__Resource__c> resourceList = [
            SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c, CO_AP_Status__c,
            sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Grand_Total_Available_AP__c,
            sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Grand_Total_Needed_AP__c,
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
            )
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ];

        for(sked__Resource__c resource : resourceList) {
            for(sked__Availability_Pattern_Resource__c apResource : resource.sked__Availability_Pattern_Resources__r) {
                for(sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r) {
                    if(!map_apId_roleVsNoOfResourcesMap.containsKey(apResource.sked__Availability_Pattern__c)) {
                        map_apId_roleVsNoOfResourcesMap.put(apResource.sked__Availability_Pattern__c, new Map<String, Decimal>());
                    }
                    Map<String, Decimal> map_role_noOfCumulativeRoles = map_apId_roleVsNoOfResourcesMap.get(apResource.sked__Availability_Pattern__c);
                    Decimal roleCount = map_role_noOfCumulativeRoles.containsKey(resourceTag.sked__Tag__r.Name) ? map_role_noOfCumulativeRoles.get(resourceTag.sked__Tag__r.Name) : 0;
                    map_role_noOfCumulativeRoles.put(resourceTag.sked__Tag__r.Name, roleCount + 1);
                }
            }
        }

        List<Collection_Operation_Availability__c> coApList = [
            SELECT Id, Name, Total_Actual_Resources__c, Min_Nbr_of_Staff__c, Total_Target__c,
            Collection_Operation__c, Collection_Operation__r.Name,
            Collection_Operation__r.Grand_Total_Available_AP__c,
            Collection_Operation__r.Grand_Total_Needed_AP__c,
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
            coAp.Total_Actual_Resources__c = map_apId_noOfAssignedResources.get(coAp.Availability_Pattern__c) ?? 0;

            for(Availability_Pattern_Role__c apRole : coAp.Availability_Pattern_Roles__r) {
                apRole.Actual_Count_of_Role__c = (map_apId_roleVsNoOfResourcesMap.get(coAp.Availability_Pattern__c) ?? new Map<String, Decimal>()).get(apRole.Role__c) ?? 0;
                objectsToUpdate.add(apRole);
            }
            objectsToUpdate.add(coAp);
        }

        objectsToUpdate.addAll(getCalculateGrandTotalAvailableOnColOp(colIds));
        objectsToUpdate.addAll(getUpdatedCoApStatusOnResources(resourceList, coApList));

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

    public static List<Biomed_Collection_Op_Center__c> getCalculateGrandTotalAvailableOnColOp(Set<Id> colIds) {
        List<Biomed_Collection_Op_Center__c> coUpdateList = new List<Biomed_Collection_Op_Center__c>();
        Map<Id, Decimal> map_coId_grandTotalResources = new Map<Id, Decimal>();

        for (AggregateResult ar : [
            SELECT sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c resourcePrimaryCo,
            COUNT_DISTINCT(sked__Resource__c) totalActualResources
            FROM sked__Availability_Pattern_Resource__c
            WHERE sked__Resource__r.sked_Collection_Operation_Id__c IN : colIds
            AND (sked_End_Date__c = NULL OR sked_End_Date__c >= TODAY)
            AND sked__Resource__r.sked__Resource_Type__c = 'Person'
            AND sked__Resource__r.sked__Is_Active__c = TRUE
            GROUP BY sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c
        ]) {
            map_coId_grandTotalResources.put((Id)ar.get('resourcePrimaryCo'), (Decimal)ar.get('totalActualResources'));
        }

        for(Id coId : map_coId_grandTotalResources.keySet()) {
            coUpdateList.add(new Biomed_Collection_Op_Center__c(Id = coId, Grand_Total_Available_AP__c = map_coId_grandTotalResources.get(coId)));
        }

        return coUpdateList;
    }

    public static List<sked__Resource__c> getUpdatedCoApStatusOnResources(List<sked__Resource__c> resourceList, List<Collection_Operation_Availability__c> coApList) {
        List<sked__Resource__c> resourceListToUpdate = new List<sked__Resource__c>();

        for(sked__Resource__c resource : resourceList) {
            Boolean isResourceUpdateNeeded = false, isResourceNeedsFurtherProcessing = false;
            for(Collection_Operation_Availability__c coAp : coApList) {
                if(coAp.Collection_Operation__c != resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c) continue;
                if(coAp.Min_Nbr_of_Staff__c > 0 && coAp.Total_Actual_Resources__c > 0 && coAp.Total_Target__c != null) {
                    if(coAp.Availability_Pattern_Roles__r != null && !coAp.Availability_Pattern_Roles__r.isEmpty()) {
                        for(Availability_Pattern_Role__c apRole : coAp.Availability_Pattern_Roles__r) {
                            if(apRole.Min_Nbr_of_Role__c > 0 && apRole.Actual_Count_of_Role__c > 0) {
                                if(resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.Grand_Total_Needed_AP__c > 0) {
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