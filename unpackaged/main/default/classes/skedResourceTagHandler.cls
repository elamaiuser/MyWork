public class skedResourceTagHandler extends skedTriggerHub {
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
        populateExpiryData(this.context.newRecords);
        
        if (!skedSetting.instance.Admin.migrationMode) {
            updateApprovedAvailability(this.context.newRecords);
        }
    }
    
    public override void onAfterInsert() {
        updateResourceRoles(this.context.newRecords);
        maintainTraineeRoleTags(getPendingTagsToMaintain(this.context.newRecords));
    }
    
    public override void onBeforeUpdate() {
        populateExpiryData(this.context.newRecords, (Map<Id, sked__Resource_Tag__c>)this.context.oldMap);
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            manageExceptions(this.context.newRecords, (Map<Id, sked__Resource_Tag__c>)this.context.oldMap);
        }
        updateResourcePremiumPayRoles(this.context.newRecords, (Map<Id, sked__Resource_Tag__c>)this.context.oldMap);
        maintainTraineeRoleTags(getPendingTagsToMaintain(this.context.newRecords, (Map<Id, sked__Resource_Tag__c>) this.context.oldMap));
    }
    
    public override void onAfterDelete() {
        updateResourceRoles(this.context.oldMap.values());
        updateApprovedAvailability(this.context.oldMap.values());
        maintainTraineeRoleTags(getPendingTagsToMaintain(this.context.oldMap.values()));
        
        if (!skedSetting.instance.Admin.migrationMode) {
            manageExceptions(this.context.oldMap.values());
        }
    }

    private void populateData(List<sked__Resource_Tag__c> newRecords) {
        Set<Id> tagIds = new Set<Id>();
        for (sked__Resource_Tag__c rt : newRecords) {
            tagIds.add(rt.sked__Tag__c);
        }
        Map<Id, sked__Tag__c> tagsById = new Map<Id, sked__Tag__c>([
            SELECT Id, Name
            FROM sked__Tag__c
            WHERE Id IN :tagIds
        ]);


        Id standardRecordTypeId = Schema.SObjectType.sked__Resource_Tag__c.getRecordTypeInfosByDeveloperName()
            .get('Standard').getRecordTypeId();
            
        Set<String> premiumRoleTags = skedUtils.getMapRoleToPremiumOpPay().keySet();
        for (sked__Resource_Tag__c rt : newRecords) {
            sked__Tag__c tag = tagsById.get(rt.sked__Tag__c);
            if (premiumRoleTags.contains(tag.Name)) {
                rt.sked_Premium_Pay__c = true;
            }

            if (rt.RecordTypeId == null) {
                rt.RecordTypeId = standardRecordTypeId;
            }
        }
    }
    
    /*********************************************************** Trainee / No Trainee ***********************************************************/
    private List<sked__Resource_Tag__c> getPendingTagsToMaintain(List<sked__Resource_Tag__c> newRecords) {
        List<sked__Resource_Tag__c> resourceTagsToMaintainTraineeRole = new List<sked__Resource_Tag__c>();
        for (sked__Resource_Tag__c newRecord : newRecords) {
            if (newRecord.sked_Tag_Type__c == skedConstants.TAG_TYPE_ROLE && newRecord.sked_Role_Status__c == skedConstants.TAG_ROLE_STATUS_PENDING) {
                resourceTagsToMaintainTraineeRole.add(newRecord);
            }
        }
        
        return resourceTagsToMaintainTraineeRole;
    }
    
    private List<sked__Resource_Tag__c> getPendingTagsToMaintain(List<sked__Resource_Tag__c> newRecords, Map<Id, sked__Resource_Tag__c> oldMap) {
        Map<Id, sked__Resource_Tag__c> mapResourceTagsToMaintain = new Map<Id, sked__Resource_Tag__c>();
        for (sked__Resource_Tag__c newRecord : newRecords) {
            if (newRecord.sked_Tag_Type__c == skedConstants.TAG_TYPE_ROLE) {
                sked__Resource_Tag__c oldData = oldMap.get(newRecord.Id);
                if (newRecord.sked_Role_Status__c != oldData.sked_Role_Status__c) {
                    if (newRecord.sked_Role_Status__c == skedConstants.TAG_ROLE_STATUS_PENDING || oldData.sked_Role_Status__c == skedConstants.TAG_ROLE_STATUS_PENDING) {
                        mapResourceTagsToMaintain.put(newRecord.Id, newRecord);
                    }
                }
                if (newRecord.sked_Start_Date__c != oldData.sked_Start_Date__c || newRecord.sked_Expiry_Date__c != oldData.sked_Expiry_Date__c) {
                    mapResourceTagsToMaintain.put(newRecord.Id, newRecord);
                }
            }
        }
        
        return mapResourceTagsToMaintain.values();
    }

    private void maintainTraineeRoleTags(List<sked__Resource_Tag__c> resourceTags) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Resource_Tag__c resTag : resourceTags) {
            resourceIds.add(resTag.sked__Resource__c);
        }

        if (resourceIds.isEmpty()) return;

        List<String> rolesAndCertifications = new List<String>{skedConstants.TAG_TYPE_ROLE, skedConstants.TAG_TYPE_CERTIFICATION};
        List<sked__Resource__c> skedResources = [
            SELECT Id,
            (SELECT 
                Id, sked__Tag__r.Name, sked_Start_Date__c,
                sked_Expiry_Date__c, sked_Role_Status__c
                FROM sked__ResourceTags__r
                WHERE sked__Tag__r.sked__Type__c IN :rolesAndCertifications
                AND sked_Role_Status__c != :skedConstants.TAG_ROLE_STATUS_INACTIVE
                ORDER BY sked_Start_Date__c ASC)
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ];

        List<sked__Resource_Tag__c> traineeTagsToInsert = new List<sked__Resource_Tag__c>();
        List<sked__Resource_Tag__c> traineeTagsToDelete = new List<sked__Resource_Tag__c>();

        for (sked__Resource__c resource : skedResources) {
            List<sked__Resource_Tag__c> pendingRoleTags = new List<sked__Resource_Tag__c>();
            List<sked__Resource_Tag__c> resourceTraineeTagsToInsert = new List<sked__Resource_Tag__c>();

            for (sked__Resource_Tag__c resourceTag : resource.sked__ResourceTags__r) {
                if (resourceTag.sked__Tag__r.Name == skedConstants.TAG_TRAINEE || 
                        resourceTag.sked__Tag__r.Name == skedConstants.TAG_NO_TRAINEE)
                {
                    traineeTagsToDelete.add(resourceTag);
                }
                else if (resourceTag.sked_Role_Status__c == skedConstants.TAG_ROLE_STATUS_PENDING) {
                    pendingRoleTags.add(resourceTag);
                }
            }

            if (!pendingRoleTags.isEmpty()) {
                resourceTraineeTagsToInsert.addAll(getNewTraineeTagsForResource(resource, pendingRoleTags));
            }

            traineeTagsToInsert.addAll(resourceTraineeTagsToInsert);
            traineeTagsToInsert.addAll(getNewNoTraineeTagsForResource(resource, resourceTraineeTagsToInsert));
        }

        if (!traineeTagsToInsert.isEmpty()) insert traineeTagsToInsert;
        if (!traineeTagsToDelete.isEmpty()) delete traineeTagsToDelete;
    }

    @testVisible
    public static List<sked__Resource_Tag__c> getNewTraineeTagsForResource(sked__Resource__c resource, List<sked__Resource_Tag__c> pendingRoleTags) {
        List<sked__Resource_Tag__c> traineeTagsToCreate = new List<sked__Resource_Tag__c>();
        sked__Tag__c traineeTag = skedResourceTagHandler_Cache.getTraineeTagFromCache();

        Set<Id> coveredPendingRoles = new Set<Id>();
        boolean hasPendingRoleWithoutExpiryDate = false;
        for (sked__Resource_Tag__c pendingRoleTag : pendingRoleTags) {
            if (coveredPendingRoles.contains(pendingRoleTag.Id)) continue;

            sked__Resource_Tag__c newTraineeTag = getNewResourceTag(traineeTag.Id, resource.Id, pendingRoleTag.sked_Start_Date__c, pendingRoleTag.sked_Expiry_Date__c);
            for (sked__Resource_Tag__c otherPendingRoleTag : pendingRoleTags) {
                if (otherPendingRoleTag.Id == pendingRoleTag.Id || 
                        coveredPendingRoles.contains(otherPendingRoleTag.Id) ||
                        otherPendingRoleTag.sked_Start_Date__c < pendingRoleTag.sked_Start_Date__c) {
                    continue;
                }
                
                if (otherPendingRoleTag.sked_Start_Date__c <= pendingRoleTag.sked_Expiry_Date__c &&
                        (otherPendingRoleTag.sked_Expiry_Date__c >= pendingRoleTag.sked_Expiry_Date__c ||
                            otherPendingRoleTag.sked_Expiry_Date__c == null)) {
                    newTraineeTag.sked_Expiry_Date__c = otherPendingRoleTag.sked_Expiry_Date__c;
                    coveredPendingRoles.add(otherPendingRoleTag.Id);
                }
            }

            traineeTagsToCreate.add(newTraineeTag);
            coveredPendingRoles.add(pendingRoleTag.Id);

            if (newTraineeTag.sked_Expiry_Date__c == null) break;
        }
        
        return traineeTagsToCreate;
    }

    @testVisible
    public static List<sked__Resource_Tag__c> getNewNoTraineeTagsForResource(sked__Resource__c resource, List<sked__Resource_Tag__c> traineeTagsForResource) {
        List<sked__Resource_Tag__c> noTraineeTagsToCreate = new List<sked__Resource_Tag__c>();
        sked__Tag__c noTraineeTag = skedResourceTagHandler_Cache.getNoTraineeTagFromCache();

        Date nextNoTraineeTagStartDate = System.today();
        if (!traineeTagsForResource.isEmpty()) {
            for (sked__Resource_Tag__c traineeTag : traineeTagsForResource) {
                sked__Resource_Tag__c newNoTraineeTag = getNewResourceTag(noTraineeTag.Id, resource.Id, nextNoTraineeTagStartDate, traineeTag.sked_Start_Date__c.addDays(-1));
                if (traineeTag.sked_Start_Date__c > nextNoTraineeTagStartDate) {
                    noTraineeTagsToCreate.add(newNoTraineeTag);
                }
                nextNoTraineeTagStartDate = traineeTag.sked_Expiry_Date__c == null ? null : traineeTag.sked_Expiry_Date__c.addDays(1);
            }

            if (nextNoTraineeTagStartDate != null) {
                noTraineeTagsToCreate.add(getNewResourceTag(noTraineeTag.Id, resource.Id, nextNoTraineeTagStartDate, null));
            }
        } else {
            sked__Resource_Tag__c newNoTraineeTag = getNewResourceTag(noTraineeTag.Id, resource.Id, nextNoTraineeTagStartDate, null);
            newNoTraineeTag.sked__Tag__c = noTraineeTag.Id;
            newNoTraineeTag.sked__Resource__c = resource.Id;
    
            noTraineeTagsToCreate.add(newNoTraineeTag);
        }

        return noTraineeTagsToCreate;
    }

    private static sked__Resource_Tag__c getNewResourceTag(Id tagId, Id resourceId, Date startDate, Date expiryDate) {
        return new sked__Resource_Tag__c(
            sked__Tag__c = tagId,
            sked__Resource__c = resourceId,
            sked_Start_Date__c = startDate, 
            sked_Expiry_Date__c = expiryDate,
            sked_Role_Status__c = skedConstants.TAG_ROLE_STATUS_ACTIVE
        );
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void manageExceptions(List<sked__Resource_Tag__c> newRecords, Map<Id, sked__Resource_Tag__c> oldMap) {
        Set<Id> resourceTagIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> tagIds = new Set<Id>();
        for (sked__Resource_Tag__c newRecord : newRecords) {
            resourceTagIds.add(newRecord.Id);
            resourceIds.add(newRecord.sked__Resource__c);
            tagIds.add(newRecord.sked__Tag__c);
        }

        Map<Id, sked__Tag__c> tagById = new Map<Id, sked__Tag__c>([
            SELECT Id, Name
            FROM sked__Tag__c
            WHERE Id IN :tagIds
        ]);

        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([
            SELECT Id, Name,
            (SELECT Id, sked__Job__c, sked__Job__r.sked_Drive__c, sked__Job__r.sked_Drive__r.sked_Drive_Date__c, 
                sked__Resource__c, sked__Job__r.sked_Resource_Role__c, sked_Resource_Role__c, sked_Additional_Roles__c
            FROM sked__Job_Allocations__r
            WHERE sked__Job__r.sked_Drive__r.sked_Drive_Date__c > TODAY
            AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED),
            (SELECT Id, sked_Exception_Code__c, skedHC__Exception__c, skedHC__Job_Allocation__c FROM skedHC__Exception_Log__r)
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
        
        List<skedHC__Exception__c> exceptionsToUpsert = new List<skedHC__Exception__c>();
        for (sked__Resource_Tag__c newRecord : newRecords) {
            sked__Resource_Tag__c oldData = oldMap.get(newRecord.Id);
            sked__Resource__c skedResource = mapResource.get(newRecord.sked__Resource__c);
            sked__Tag__c tag = tagById.get(newRecord.sked__Tag__c);
            manageRoleStatusChangedExceptions(exceptionsToUpsert, tag, newRecord, oldData, skedResource);
            manageRoleRestrictedExceptions(exceptionsToUpsert, tag, newRecord, oldData, skedResource);
        }
        if (!exceptionsToUpsert.isEmpty()) {
            upsert exceptionsToUpsert;
        }
    }
    
    private void populateExpiryData(List<sked__Resource_Tag__c> skedResourceTags) {
        integer tagExpiryAlertDays = skedSetting.instance.admin.tagExpiryAlertDays;
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Resource_Tag__c skedResourceTag : skedResourceTags) {
            resourceIds.add(skedResourceTag.sked__Resource__c);
        }
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Primary_Region__r.sked__Timezone__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        for (sked__Resource_Tag__c skedResourceTag : skedResourceTags) {
            sked__Resource__c skedResource = mapResource.get(skedResourceTag.sked__Resource__c);
            string timezoneSidId = skedResource.sked__Primary_Region__r != NULL ? skedResource.sked__Primary_Region__r.sked__Timezone__c : UserInfo.getTimeZone().getID();
            
            skedResourceTag.sked_Start__c = NULL;
            if (skedResourceTag.sked_Start_Date__c != NULL) {
                skedResourceTag.sked_Start__c = skedDateTimeUtils.getStartOfDate(skedResourceTag.sked_Start_Date__c, timezoneSidId);
            }
            
            skedResourceTag.sked__Expiry_Date__c = NULL;
            if (skedResourceTag.sked_Expiry_Date__c != NULL) {
                skedResourceTag.sked__Expiry_Date__c = skedDateTimeUtils.getEndOfDate(skedResourceTag.sked_Expiry_Date__c, timezoneSidId);
            }
        }
    }
    
    private void populateExpiryData(List<sked__Resource_Tag__c> newRecords, Map<Id, sked__Resource_Tag__c> oldMap) {
        List<sked__Resource_Tag__c> recordsToPopulateData = new List<sked__Resource_Tag__c>();
        for (sked__Resource_Tag__c newRecord : newRecords) {
            sked__Resource_Tag__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Start_Date__c != oldData.sked_Start_Date__c || newRecord.sked_Expiry_Date__c != oldData.sked_Expiry_Date__c) {
                recordsToPopulateData.add(newRecord);
            }
        }
        if (!recordsToPopulateData.isEmpty()) {
            populateExpiryData(recordsToPopulateData);
        }
    }
    
    private void updateResourceRoles(List<sked__Resource_Tag__c> newRecords) {
        Map<Id, sked__Tag__c> mapRole = new Map<Id, sked__Tag__c>([SELECT Id
                                                                   FROM sked__Tag__c
                                                                   WHERE sked__Type__c = :skedConstants.TAG_TYPE_ROLE]);
        Set<Id> resourceIdsToUpdateRoles = new Set<Id>();
        for (sked__Resource_Tag__c newRecord : newRecords) {
            if (mapRole.containsKey(newRecord.sked__Tag__c)) {
                resourceIdsToUpdateRoles.add(newRecord.sked__Resource__c);
            }
        }
        if (!resourceIdsToUpdateRoles.isEmpty()) {
            skedResourceHandler.canUpdateResourceRole = true;
            List<sked__Resource__c> skedResources = [SELECT Id,
                                                     (SELECT Id, sked__Tag__r.Name, sked_Premium_Pay__c
                                                      FROM sked__ResourceTags__r
                                                      WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE)
                                                     FROM sked__Resource__c
                                                     WHERE Id IN :resourceIdsToUpdateRoles];
            for (sked__Resource__c skedResource : skedResources) {
                List<string> roles = new List<string>();
                List<string> premiumPayRoles = new List<string>();
                for (sked__Resource_Tag__c skedResourceTag : skedResource.sked__ResourceTags__r) {
                    roles.add(skedResourceTag.sked__Tag__r.Name);
                    if (skedResourceTag.sked_Premium_Pay__c == TRUE) {
                        premiumPayRoles.add(skedResourceTag.sked__Tag__r.Name);
                    }
                }
                skedResource.sked_Roles__c = string.join(roles, ';');
                skedResource.sked_Premium_Pay_Roles__c = string.join(premiumPayRoles, ';');
            }
            update skedResources;
        }
    }
    
    private void updateResourcePremiumPayRoles(List<sked__Resource_Tag__c> newRecords, Map<Id, sked__Resource_Tag__c> oldMap) {
        Map<Id, sked__Tag__c> mapRole = new Map<Id, sked__Tag__c>([SELECT Id
                                                                   FROM sked__Tag__c
                                                                   WHERE sked__Type__c = :skedConstants.TAG_TYPE_ROLE]);
        Set<Id> resourceIdsToUpdate = new Set<Id>();
        for (sked__Resource_Tag__c newRecord : newRecords) {
            sked__Resource_Tag__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Premium_Pay__c != oldData.sked_Premium_Pay__c) {
                resourceIdsToUpdate.add(newRecord.sked__Resource__c);
            }
        }
        if (!resourceIdsToUpdate.isEmpty()) {
            List<sked__Resource__c> skedResources = [SELECT Id,
                                                     (SELECT Id, sked__Tag__r.Name, sked_Premium_Pay__c
                                                      FROM sked__ResourceTags__r
                                                      WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE)
                                                     FROM sked__Resource__c
                                                     WHERE Id IN :resourceIdsToUpdate];
            for (sked__Resource__c skedResource : skedResources) {
                List<string> premiumPayRoles = new List<string>();
                for (sked__Resource_Tag__c skedResourceTag : skedResource.sked__ResourceTags__r) {
                    if (skedResourceTag.sked_Premium_Pay__c == TRUE) {
                        premiumPayRoles.add(skedResourceTag.sked__Tag__r.Name);
                    }
                }
                skedResource.sked_Premium_Pay_Roles__c = string.join(premiumPayRoles, ';');
            }
            update skedResources;
        }
    }
    
    private void updateApprovedAvailability(List<sked__Resource_Tag__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> tagIds = new Set<Id>();
        for (sked__Resource_Tag__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
            tagIds.add(newRecord.sked__Tag__c);
        }
        Map<Id, sked__Tag__c> mapTag = new Map<Id, sked__Tag__c>([
            SELECT Id, sked_Priority__c 
            FROM sked__Tag__c 
            WHERE Id IN :tagIds
        ]);

        List<sked__Resource__c> resources = [
            SELECT Id, 
            (SELECT Id, sked__Tag__r.sked_Priority__c
            FROM sked__ResourceTags__r
            WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE AND sked__Tag__r.sked_Priority__c != NULL
            ORDER BY sked__Tag__r.sked_Priority__c ASC
            LIMIT 1)
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ];
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>(resources);
        Set<Id> impactResourceIds = new Set<Id>();
        for (sked__Resource_Tag__c newRecord : newRecords) {
            sked__Tag__c tag = mapTag.get(newRecord.sked__Tag__c);
            sked__Resource__c resource = mapResource.get(newRecord.sked__Resource__c);
            if (resource.sked__ResourceTags__r == NULL 
                || (resource.sked__ResourceTags__r != NULL && !resource.sked__ResourceTags__r.isEmpty()
                    && tag.sked_Priority__c < resource.sked__ResourceTags__r.get(0).sked__Tag__r.sked_Priority__c)) {
                        impactResourceIds.add(resource.Id);
                    }
        }
        
        if (!impactResourceIds.isEmpty()) {
            Datetime currentTime = system.now();
            List<sked__Availability__c> impactedAvailabilities = [
                SELECT Id, sked_Exception_Code__c
                FROM sked__Availability__c
                WHERE sked__Resource__c IN :impactResourceIds
                AND sked__Start__c > :currentTime
                AND sked_Custom_Status__c  = :skedConstants.AVAILABILITY_STATUS_APPROVED
                AND sked__Is_Available__c = FALSE
                AND sked__Type__c = :skedConstants.AVAILABILITY_TYPE_PTO
            ];
            for (sked__Availability__c item : impactedAvailabilities) {
                item.sked_Exception_Code__c = skedConstants.AVAILABILITY_EXEPTION_CODE;
            }

            skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
            update impactedAvailabilities;
        }
    }

    private void manageRoleStatusChangedExceptions(List<skedHC__Exception__c> exceptionsToUpsert, sked__Tag__c tag, sked__Resource_Tag__c resourceTag, sked__Resource_Tag__c oldResourceTag, sked__Resource__c resource) {
        string exceptionCodeTemplate = '{{resourceName}} has Role Status changed from {{oldValue}} to {{newValue}}';
        
        if (resourceTag.sked_Role_Status__c != oldResourceTag.sked_Role_Status__c && resourceTag.sked_Role_Status__c != 'Active') {
            if (resource.sked__Job_Allocations__r != NULL && !resource.sked__Job_Allocations__r.isEmpty()) {
                string exceptionCode = exceptionCodeTemplate.replace('{{resourceName}}', resource.Name)
                    .replace('{{oldValue}}', (string.isNotBlank(oldResourceTag.sked_Role_Status__c) ? oldResourceTag.sked_Role_Status__c : ''))
                    .replace('{{newValue}}', (string.isNotBlank(resourceTag.sked_Role_Status__c) ? resourceTag.sked_Role_Status__c : ''));
                
                for (sked__Job_Allocation__c impactedAllocation : resource.sked__Job_Allocations__r) {
                    if (impactedAllocation.sked__Job__r.sked_Resource_Role__c == tag.Name) {
                        exceptionsToUpsert.add(new skedHC__Exception__c(
                            sked_Drive__c = impactedAllocation.sked__Job__r.sked_Drive__c,
                            skedHC__Job__c = impactedAllocation.sked__Job__c,
                            skedHC__Job_Allocation__c = impactedAllocation.Id,
                            skedHC__Resource__c = impactedAllocation.sked__Resource__c,
                            skedHC__Exception__c = exceptionCode,
                            skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN,
                            sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_ROLE_STATUS_CHANGED
                        ));
                    }
                }
            }
        }
    }

    private void manageRoleRestrictedExceptions(List<skedHC__Exception__c> exceptionsToUpsert, sked__Tag__c tag, sked__Resource_Tag__c resourceTag, sked__Resource_Tag__c oldResourceTag, sked__Resource__c resource) {
        if (resourceTag.sked_Restriction_Start_Date__c != oldResourceTag.sked_Restriction_Start_Date__c || resourceTag.sked_Restriction_End_Date__c != oldResourceTag.sked_Restriction_End_Date__c) {
            Boolean isRestrictionEnded = resourceTag.sked_Restriction_Start_Date__c == null && resourceTag.sked_Restriction_End_Date__c == null;
            if (resource.sked__Job_Allocations__r != NULL && !resource.sked__Job_Allocations__r.isEmpty()) {
                for (sked__Job_Allocation__c impactedAllocation : resource.sked__Job_Allocations__r) {
                    List<String> performedRoles = new List<String>();
                    performedRoles.add(impactedAllocation.sked_Resource_Role__c);
                    if (String.isNotBlank(impactedAllocation.sked_Additional_Roles__c)) {
                        performedRoles.addAll(impactedAllocation.sked_Additional_Roles__c.split(';'));
                    }
                    if (performedRoles.contains(tag.Name)) {
                        Date driveDate = impactedAllocation.sked__Job__r.sked_Drive__r.sked_Drive_Date__c;
                        Boolean requiresException = 
                            !isRestrictionEnded && 
                            resourceTag.sked_Restriction_Start_Date__c <= driveDate &&
                            (resourceTag.sked_Restriction_End_Date__c == null || resourceTag.sked_Restriction_End_Date__c >= driveDate);
                            
                        skedHC__Exception__c exceptionToUpsert;
                        if (resource.skedHC__Exception_Log__r != null && !resource.skedHC__Exception_Log__r.isEmpty()) {
                            for (skedHC__Exception__c skedException : resource.skedHC__Exception_Log__r) {
                                Boolean matchesExceptionCode = skedException.sked_Exception_Code__c == skedConstants.EXCEPTION_CODE_RESOURCE_ROLE_RESTRICTED;
                                Boolean matchesJobAllocation = skedException.skedHC__Job_Allocation__c == impactedAllocation.Id;
                                Boolean matchesTagName = false;
                                if (matchesExceptionCode && String.isNotBlank(skedException.skedHC__Exception__c) && skedException.skedHC__Exception__c.contains(':')) {
                                    List<String> parts = skedException.skedHC__Exception__c.split(': ');
                                    String tagName = parts[1];
                                    matchesTagName = tag.Name == tagName;
                                }
                                if (matchesExceptionCode && matchesJobAllocation && matchesTagName) {
                                    skedException.skedHC__Status__c = requiresException ? skedConstants.EXCEPTION_LOG_STATUS_OPEN : skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                                    exceptionToUpsert = skedException;
                                }
                            }
                        }
    
                        if (requiresException && exceptionToUpsert == null) {
                            exceptionToUpsert = new skedHC__Exception__c (
                                sked_Drive__c = impactedAllocation.sked__Job__r.sked_Drive__c,
                                skedHC__Job__c = impactedAllocation.sked__Job__c,
                                skedHC__Job_Allocation__c = impactedAllocation.Id,
                                skedHC__Resource__c = resource.Id,
                                sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_RESOURCE_ROLE_RESTRICTED,
                                skedHC__Exception__c = 'Resource Role Restricted: ' + tag.Name,
                                skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                            );
                        }
    
                        if (exceptionToUpsert != null) {
                            exceptionsToUpsert.add(exceptionToUpsert);
                        }
                    }
                }
            }
        }
    }

    private void manageExceptions(List<sked__Resource_Tag__c> deletedResourceTags) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Resource_Tag__c resourceTag : deletedResourceTags) {
            resourceIds.add(resourceTag.sked__Resource__c);
        }

        List<sked__Job_Allocation__c> affectedJobAllocations = [
            SELECT Id, sked__Resource__c, sked__Job__c, sked__Job__r.sked_Drive__c
            FROM sked__Job_Allocation__c
            WHERE sked__Job__r.sked_Drive__r.sked_Drive_Date__c > TODAY
            AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED
            AND sked__Resource__c IN :resourceIds
        ];

        if (affectedJobAllocations != null && !affectedJobAllocations.isEmpty()) {
            Set<Id> affectedJobIds = new Set<Id>();
            Map<Id, List<sked__Job_Allocation__c>> jobAllocationsByResource = new Map<Id, List<sked__Job_Allocation__c>>();
            for (sked__Job_Allocation__c ja : affectedJobAllocations) {
                affectedJobIds.add(ja.sked__Job__c);
                List<sked__Job_Allocation__c> allocationsForResource = jobAllocationsByResource.get(ja.sked__Resource__c);

                if (allocationsForResource == null) {
                    allocationsForResource = new List<sked__Job_Allocation__c>();
                }

                allocationsForResource.add(ja);
                jobAllocationsByResource.put(ja.sked__Resource__c, allocationsForResource);
            }

            Map<Id, sked__Job__c> relatedJobsById = new Map<Id, sked__Job__c>([
                SELECT Id, sked_Drive__c,
                    (SELECT Id, sked__Tag__c, sked__Tag__r.Name FROM sked__JobTags__r WHERE sked__Required__c = TRUE)
                FROM sked__Job__c
                WHERE Id IN :affectedJobIds
            ]);

            List<skedHC__Exception__c> newExceptions = new List<skedHC__Exception__c>();
            for (sked__Resource_Tag__c rt : deletedResourceTags) {
                List<sked__Job_Allocation__c> jobAllocations = jobAllocationsByResource.get(rt.sked__Resource__c);
                
                if(jobAllocations != null && !jobAllocations.isEmpty()){
                    for (sked__Job_Allocation__c ja : jobAllocations) {
                        sked__Job__c job = relatedJobsById.get(ja.sked__Job__c);

                        if (job.sked__JobTags__r != null && !job.sked__JobTags__r.isEmpty()) {
                            for (sked__Job_Tag__c jobTag : job.sked__JobTags__r) {
                                if (jobTag.sked__Tag__c == rt.sked__Tag__c) {
                                    newExceptions.add(skedExceptionUtils.generateException(ja, skedConstants.EXCEPTION_CODE_MISSING_REQUIRED_TAG, 'Missing required tag ' + jobTag.sked__Tag__r.Name));
                                }
                            }
                        }
                    }
                }
            }

            if (!newExceptions.isEmpty()) {
                insert newExceptions;
            }
        }
    }
}