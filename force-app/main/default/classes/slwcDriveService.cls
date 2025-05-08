global class slwcDriveService {
    
    @AuraEnabled
    public static slwcAuraResult captureDriveImpact(driveChangeRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        SavePoint sp = Database.setSavepoint();
        try {
            List<driveChangeRequestModel> lsRequests = new List<driveChangeRequestModel>();
            lsRequests.add(request);
            
            Map<String, Schema.SObjectField> mapSObjectDriveField = Schema.SObjectType.sked_Drive__c.fields.getMap();
            
            Set<Id> driveChangeRequestIds = new Set<Id>();
            
            List<sked_Drive_Change_Request_Item__c> skedRequestItemsToInsert = new List<sked_Drive_Change_Request_Item__c>();
            for (driveChangeRequestModel captureReq : lsRequests) {
                driveChangeRequestIds.add(captureReq.id);
                
                for (driveChangeRequestItemModel item : request.driveChangeRequestItems) {
                    if (mapSObjectDriveField.containsKey(item.fieldApiName)) {
                        Schema.SObjectField sObjectField = mapSObjectDriveField.get(item.fieldApiName);
                        DescribeFieldResult sObjectFieldResult = sObjectField.getDescribe();
                        
                        string fieldLabel = sObjectFieldResult.getLabel();
                        string fieldType = string.valueOf(sObjectFieldResult.getType()).toLowerCase();
                        
                        sked_Drive_Change_Request_Item__c skedRequestItem = new sked_Drive_Change_Request_Item__c(
                            sked_Drive_Change_Request__c = captureReq.id,
                            sked_Object_Api_Name__c = item.objectApiName,
                            sked_Field_Api_Name__c = item.fieldApiName,
                            sked_Field_Label__c = fieldLabel,
                            sked_Field_Type__c = fieldType,
                            sked_New_Value__c = item.newValue,
                            sked_Old_Value__c = item.oldValue,
                            sked_Type__c = 'Impact'
                        );
                        skedRequestItemsToInsert.add(skedRequestItem);
                    }
                }
            }
            
            List<sked_Drive_Change_Request_Item__c> currentDriveImpacts = [SELECT Id
                                                                           FROM sked_Drive_Change_Request_Item__c
                                                                           WHERE sked_Drive_Change_Request__c IN :driveChangeRequestIds
                                                                           AND sked_Type__c = 'Impact'];
            if (!currentDriveImpacts.isEmpty()) {
                delete currentDriveImpacts;
            }
            if (!skedRequestItemsToInsert.isEmpty()) {
                insert skedRequestItemsToInsert;
            }
        }
        catch (Exception ex) {
            Database.rollback(sp);
            throw ex;
        }
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult dispatchDrives(dispatchDrivesRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        if (request.driveIds != NULL && !request.driveIds.isEmpty()) {
            DateTime currentTime = system.now();
            
            Set<Id> jobAllocationIdsNeedToNotify = new Set<Id>();
            List<sked__Job_Allocation__c> jobAllocations = [SELECT Id, sked__Status__c, sked__Resource__r.sked__Resource_Type__c
                                                            FROM sked__Job_Allocation__c
                                                            WHERE sked__Job__r.sked_Drive__c IN :request.driveIds
                                                            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_COMPLETE
                                                            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DELETED
                                                            AND sked__Status__c != :skedConstants.JOB_ALLOCATION_STATUS_DECLINED];
            
            List<sked__Job_Allocation__c> dispatchedJobAllocations = new List<sked__Job_Allocation__c>();
            for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
                if (jobAllocation.sked__Status__c == skedConstants.JOB_ALLOCATION_STATUS_PENDING_DISPATCH) {
                    jobAllocation.sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DISPATCHED;
                    dispatchedJobAllocations.add(jobAllocation);
                    if (jobAllocation.sked__Resource__r.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_PERSON) {
                        jobAllocationIdsNeedToNotify.add(jobAllocation.Id);
                    }
                }else if (jobAllocation.sked__Resource__r.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_ASSET) {
                    jobAllocation.sked_Locked__c = TRUE;
                    dispatchedJobAllocations.add(jobAllocation);
                }
            }
            if (!dispatchedJobAllocations.isEmpty()) {
                update dispatchedJobAllocations;
            }
            
            Id loginUserId = UserInfo.getUserId();
            List<sked_Drive__c> drivesToUpdate = new List<sked_Drive__c>();
            for (string driveId : request.driveIds) {
                sked_Drive__c skedDrive = new sked_Drive__c(
                    Id = driveId,
                    sked_Dispatched_At__c = currentTime,
                    sked_Dispatched_By__c = loginUserId,
                    sked_Drive_Dispatched__c = TRUE
                );
                drivesToUpdate.add(skedDrive);
            }
            if (!drivesToUpdate.isEmpty()) {
                update drivesToUpdate;
            }
            
            //Send notification email and oneoff
            if (request.resend == TRUE) {
                for (sked__Job_Allocation__c jobAllocation : jobAllocations) {
                    jobAllocationIdsNeedToNotify.add(jobAllocation.Id);
                }
            }
            if (!jobAllocationIdsNeedToNotify.isEmpty()) {
                List<string> notificationSettingNames = new List<string>();
                notificationSettingNames.add('sked_Job_Allocation_Email');
                notificationSettingNames.add('sked_Job_Allocation_OneOff');
                notificationSettingNames.add('sked_Job_Allocation_SF_Push');
                
                List<sked__Job_Allocation__c> jobAllocationsNeedToNotify = new List<sked__Job_Allocation__c>();
                for (Id jobAllocationId : jobAllocationIdsNeedToNotify) {
                    sked__Job_Allocation__c jobAllocation = new sked__Job_Allocation__c(Id = jobAllocationId);
                    jobAllocationsNeedToNotify.add(jobAllocation);
                }

                new skedCustomNotificationService(notificationSettingNames).generateNotifications(jobAllocationsNeedToNotify);
            }
        }
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult searchDriveSite(searchDriveSiteRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        
        Biomed_Collection_Op_Center__c collectionOperation = [SELECT Id, sked_Territory__r.sked_Parent__c
                                                              FROM Biomed_Collection_Op_Center__c
                                                              WHERE Id = :request.collectionOperationId];
        
        Id arcRegionId = collectionOperation.sked_Territory__r.sked_Parent__c;
        Date inputDate = skedDateTimeUtils.getDateFromIsoString(request.inputDate);
        string queryTextPadded = '%' + request.queryText + '%';
        
        List<sked_Site_Collection_Operation__c> siteCollectionOperations = [SELECT Id, sked_Site__c
                                                                            FROM sked_Site_Collection_Operation__c
                                                                            WHERE sked_Collection_Operation__r.sked_Territory__r.sked_Parent__c = :arcRegionId
                                                                            AND sked_Site__r.Name LIKE :queryTextPadded
                                                                            AND (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :inputDate)
                                                                            AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :inputDate)
                                                                            ORDER BY sked_Site__r.Name ASC
                                                                            LIMIT 200];
        Set<Id> validSiteIds = new Set<Id>();
        for (sked_Site_Collection_Operation__c siteCollectionOperation : siteCollectionOperations) {
            validSiteIds.add(siteCollectionOperation.sked_Site__c);
        }
        
        siteDataModel data = new siteDataModel();
        data.sites = [SELECT Id, Name
                      FROM sked__Location__c
                      WHERE Id IN :validSiteIds
                      ORDER BY Name ASC];
        result.returnedData = data;
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult getTerritoryKeys(getTerritoryKeysRequestModel request) {
        slwcAuraResult result = new slwcAuraResult();
        
        Biomed_Collection_Op_Center__c collectionOperation = [SELECT Id,
                                                              (SELECT Id, sked_Territory__r.sked_Parent__c
                                                               FROM sked_Territory_Collection_Operations__r
                                                               WHERE (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :request.startDate)
                                                               AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :request.startDate))
                                                              FROM Biomed_Collection_Op_Center__c
                                                              WHERE Id = :request.collectionOperationId];
        Id arcRegionId;
        if (collectionOperation.sked_Territory_Collection_Operations__r != NULL && !collectionOperation.sked_Territory_Collection_Operations__r.isEmpty()) {
            arcRegionId = collectionOperation.sked_Territory_Collection_Operations__r.get(0).sked_Territory__r.sked_Parent__c;
        }
        
        if (arcRegionId != NULL) {
            Date lowerThresholdDate = request.startDate.addDays(-1);
            Date higherThresholdDate = request.endDate.addDays(1);
            
            List<sked_Territory_Collection_Operation__c> territoryCOs = [SELECT Id, sked_Collection_Operation__c, sked_Territory__c
                                                                         FROM sked_Territory_Collection_Operation__c
                                                                         WHERE sked_Territory__r.sked_Parent__c = :arcRegionId
                                                                         AND (sked_Start_Date__c = NULL OR sked_Start_Date__c <= :request.startDate)
                                                                         AND (sked_End_Date__c = NULL OR sked_End_Date__c >= :request.startDate)];
            List<string> territoryKeys = new List<string>();
            for (sked_Territory_Collection_Operation__c territoryCO : territoryCOs) {
                string key = territoryCO.sked_Territory__c + ':' + territoryCO.sked_Collection_Operation__c;
                territoryKeys.add(key);
            }
            result.returnedData = territoryKeys;
        }
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult updateDriveStatuses(updateDriveStatusRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
        
        Map<Id, driveModel> mapDrive = new Map<Id, driveModel>();
        for (driveModel drive : request.drives) {
            mapDrive.put(drive.id, drive);
        }
        Map<Id, sked_Drive__c> mapSkedDrive = new Map<Id, sked_Drive__c>([
            SELECT Id, sked_Drive_Date__c, sked_Status__c, sked_Cancellation_Reason__c,
            sked_Pending_Action__c, sked_Replacement_Drive__c,
            sked_Is_Surrogate__c, sked_Linked_Drives__c
            FROM sked_Drive__c
            WHERE Id IN :mapDrive.keySet()
        ]);
        Date currentDate = system.today();
        
        Integer noOfDaysRequireCancellationApproval = 42;
        
        Set<string> driveStatusesRequireCancellationApproval = new Set<string>();
        driveStatusesRequireCancellationApproval.add(skedConstants.DRIVE_STATUS_CONFIRMED);
        for (driveModel drive : request.drives) {
            boolean canUpdateStatus = TRUE;
            sked_Drive__c skedDrive = mapSkedDrive.get(drive.id);
            if (drive.status == skedConstants.DRIVE_STATUS_CANCEL)
            {
                decimal daysBetween = currentDate.daysBetween(skedDrive.sked_Drive_Date__c);
                Boolean inside42days = daysBetween <= noOfDaysRequireCancellationApproval;
                Boolean isLinkedDrive = skedDrive.sked_Linked_Drives__c != null;
                Boolean rule1 = driveStatusesRequireCancellationApproval.contains(skedDrive.sked_Status__c) && inside42days;
                Boolean rule2 = isLinkedDrive;
                
                if ((rule1 || rule2) && skedDrive.sked_Is_Surrogate__c == FALSE) {
                    skedDrive.sked_Pending_Action__c = skedConstants.DRIVE_PENDING_ACTION_CANCEL_IN_PROCESS;
                    skedDrive.sked_Approval_Status__c = 'Submitted';
                    if (isLinkedDrive) {
                        skedDrive.sked_Pending_Action_Reason_Code__c = 'Part of Linked Drive';
                    }
                    canUpdateStatus = FALSE;
                }
                skedDrive.sked_Cancellation_Reason__c = drive.cancellationReason;
                skedDrive.sked_Replacement_Drive__c = drive.replacementDriveId;
            }
            if (canUpdateStatus) {
                skedDrive.sked_Status__c = drive.status;
            }
        }
        update mapSkedDrive.values();
        return result;
    }
    
    @AuraEnabled
    public static slwcAuraResult validateDraftDrive(validateDraftDriveRequestModel request) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        slwcAuraResult result = new slwcAuraResult();
       
        sked_Drive__c draftDrive = [SELECT Id, sked_Type_of_Drive__c, sked_Account_Type__c,
                                    sked_Account__r.Military_Authority_Name__c,
                                    sked_Account__r.Military_Authority_Phone__c,
                                    sked_Opportunity__r.AcceptblankMilitaryAuthNamePhone__c
                                    FROM sked_Drive__c
                                    WHERE Id = :request.driveId];
        boolean isMilitaryAccount = draftDrive.sked_Account_Type__c == 'Military';
        boolean isMissingAuthorityInfo = (draftDrive.sked_Account__r.Military_Authority_Name__c == NULL || draftDrive.sked_Account__r.Military_Authority_Phone__c == NULL) &&
            draftDrive.sked_Opportunity__r.AcceptblankMilitaryAuthNamePhone__c == false;
        if (isMilitaryAccount && isMissingAuthorityInfo) {
            throw new skedException('A drive can only be submitted for a military account if Military Authority Name and Military Authority Phone field of Account is not empty or Accept Blank Military Authority Name/Phone is True.');
        }
        return result;
    }
    
    public static void skedCaptureNonUserChangeDCRs(captureNonUserChangeDCRsModel request) {
        Map<Id, sked_Drive_Change_Request__c> existingDCRsByDriveId = new Map<Id, sked_Drive_Change_Request__c>();
        for (sked_Drive_Change_Request__c existingDCR : [
            SELECT sked_Drive__c, Id, sked_Type__c,
            (SELECT Id, sked_Drive_Change_Request__c, sked_Object_API_Name__c,
             sked_Field_API_Name__c, sked_Field_Label__c, sked_Field_Type__c, sked_Type__c
             FROM sked_Drive_Change_Request_Items__r
             WHERE sked_Field_API_Name__c = :request.fieldApiName)
            FROM sked_Drive_Change_Request__c
            WHERE sked_Drive__c IN :request.impactedDrives
            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED
            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM
            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_REJECTED
            AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED
        ]) {
            existingDCRsByDriveId.put(existingDCR.sked_Drive__c, existingDCR);
        }
        
        List<sked_Drive_Change_Request__c> dcrsToUpsert = new List<sked_Drive_Change_Request__c>();
        List<sked_Drive_Change_Request_Item__c> dcrisToInsert = new List<sked_Drive_Change_Request_Item__c>();
        for (sked_Drive__c drive : request.impactedDrives) {
            sked_Drive_Change_Request__c dcr = existingDCRsByDriveId.get(drive.Id);
            if (dcr == NULL) {
                dcr = new sked_Drive_Change_Request__c(
                    sked_Drive__c = drive.Id,
                    sked_Type__c = request.driveChangeRequestType
                );
            }
            
            List<string> dcrTypes = dcr.sked_Type__c != null ? dcr.sked_Type__c.split(';') : new List<string>();
            if (!dcrTypes.contains(request.driveChangeRequestType)) {
                dcrTypes.add(request.driveChangeRequestType);
            }
            dcr.sked_Type__c = string.join(dcrTypes, ';');
            
            dcrsToUpsert.add(dcr);
        }

        upsert dcrsToUpsert;
        
        for (sked_Drive_Change_Request__c dcr : dcrsToUpsert) {
            if (dcr.sked_Drive_Change_Request_Items__r == NULL || dcr.sked_Drive_Change_Request_Items__r.isEmpty()) {
                dcrisToInsert.add(new sked_Drive_Change_Request_Item__c(
                    sked_Drive_Change_Request__c = dcr.Id,
                    sked_Object_API_Name__c = 'sked_Drive__c',
                    sked_Field_API_Name__c = request.fieldApiName,
                    sked_Field_Label__c = request.fieldLabel,
                    sked_Field_Type__c = request.fieldType,
                    sked_Type__c = 'Change'
                ));
            }
        }
        
        if (!dcrisToInsert.isEmpty()) {
            insert dcrisToInsert;
        }
    }
    
    public static void captureUserChangeDriveChangeRequests(List<driveChangeRequestModel> lsRequests) {
        List<driveChangeRequestModel> filteredRequests = filterDriveChangeRequests(lsRequests);
        
        if (!filteredRequests.isEmpty()) {
            LookupData ref = new LookupData();
            
            generateMapKeyToNewChangeItem(filteredRequests, ref);
            
            generateMapKeyToExistingChangeItem(ref);
            
            processNewWithExistingChangeReqs(ref);
            
            deleteDcrWithoutItem(ref);
            
            notifyDriveChanges(ref);
        }
    }
    
    public static void populateNextPreviousDrive(List<sked_Drive__c> records) {
        Map<Id, sked_Drive__c> mapDrivesToUpdate = new Map<Id, sked_Drive__c>();
        for (sked_Drive__c drive : records) {
            if (drive.sked_Previous_Drive__c != NULL) {
                sked_Drive__c previousDrive = new sked_Drive__c(
                    Id = drive.sked_Previous_Drive__c,
                    sked_Next_Drive__c = NULL
                );
                if (drive.sked_Next_Drive__c != NULL) {
                    previousDrive.sked_Next_Drive__c = drive.sked_Next_Drive__c;
                }
                mapDrivesToUpdate.put(previousDrive.Id, previousDrive);
            }
            
            if (drive.sked_Next_Drive__c != NULL) {
                sked_Drive__c nextDrive = new sked_Drive__c(
                    Id = drive.sked_Next_Drive__c,
                    sked_Previous_Drive__c = NULL
                );
                if (drive.sked_Previous_Drive__c != NULL) {
                    nextDrive.sked_Previous_Drive__c = drive.sked_Previous_Drive__c;
                }
                mapDrivesToUpdate.put(nextDrive.Id, nextDrive);
            }
            
            List<sked_Drive__c> previousDriveQuery = [SELECT Id, sked_Next_Drive__c
                                                      FROM sked_Drive__c
                                                      WHERE sked_Account__c = :drive.sked_Account__c
                                                      AND sked_Drive_Date__c < :drive.sked_Drive_Date__c
                                                      ORDER BY sked_Drive_Date__c DESC
                                                      LIMIT 1];
            drive.sked_Previous_Drive__c = NULL;
            if (previousDriveQuery != NULL && !previousDriveQuery.isEmpty()) {
                sked_Drive__c previousDrive = previousDriveQuery.get(0);
                drive.sked_Previous_Drive__c = previousDrive.Id;
                mapDrivesToUpdate.put(drive.Id, drive);
                
                if (mapDrivesToUpdate.containsKey(previousDrive.Id)) {
                    previousDrive = mapDrivesToUpdate.get(previousDrive.Id);
                }
                previousDrive.sked_Next_Drive__c = drive.Id;
                mapDrivesToUpdate.put(previousDrive.Id, previousDrive);
            }
            
            List<sked_Drive__c> nextDriveQuery = [SELECT Id, sked_Previous_Drive__c
                                                  FROM sked_Drive__c
                                                  WHERE sked_Account__c = :drive.sked_Account__c
                                                  AND sked_Drive_Date__c > :drive.sked_Drive_Date__c
                                                  ORDER BY sked_Drive_Date__c ASC
                                                  LIMIT 1];
            drive.sked_Next_Drive__c = NULL;
            if (nextDriveQuery != NULL && !nextDriveQuery.isEmpty()) {
                sked_Drive__c nextDrive = nextDriveQuery.get(0);
                drive.sked_Next_Drive__c = nextDrive.Id;
                mapDrivesToUpdate.put(drive.Id, drive);
                
                if (mapDrivesToUpdate.containsKey(nextDrive.Id)) {
                    nextDrive = mapDrivesToUpdate.get(nextDrive.Id);
                }
                nextDrive.sked_Previous_Drive__c = drive.Id;
                mapDrivesToUpdate.put(nextDrive.Id, nextDrive);
            }
        }
        if (!mapDrivesToUpdate.isEmpty()) {
            update mapDrivesToUpdate.values();
        }
    }
    
    /* Private methods */
    private static List<driveChangeRequestModel> filterDriveChangeRequests(List<driveChangeRequestModel> lsRequests) {
        Map<string, string> map_oppField_driveField = new Map<string, string>();
        map_oppField_driveField.put('Drive_Date__c', 'sked_Drive_Date__c');
        map_oppField_driveField.put('Start_Time__c', 'sked_Start_Time__c');
        map_oppField_driveField.put('End_Time__c', 'sked_End_Time__c');
        map_oppField_driveField.put('Drive_Site__c', 'sked_Drive_Site__c');
        map_oppField_driveField.put('Anticipated_Registered_Donors__c', 'sked_Projected_Registered_Donors__c');
        map_oppField_driveField.put('WB_Projected_Procedures__c', 'sked_WB_Projected_Procedures__c');
        map_oppField_driveField.put('X2RBC_Projected_Procedures__c', 'sked_2RBC_Projected_Procedures__c');
        map_oppField_driveField.put('Platelet_Projected_Procedures__c', 'sked_Platelet_Projected_Procedures__c');
        map_oppField_driveField.put('Plasma_Pheresis_Projected_Procedures__c', 'sked_Plasma_Projected_Procedures__c');
        map_oppField_driveField.put('Number_of_2RBC_Assets__c', 'sked_Number_of_2RBC_Assets__c');
        map_oppField_driveField.put('Number_of_Plasma_Assets__c', 'sked_Number_of_Plasma_Assets__c');
        map_oppField_driveField.put('Number_of_Platelet_Assets__c', 'sked_Number_of_Platelet_Assets__c');
        map_oppField_driveField.put('Redcross_Volunteer_Required__c', 'sked_Redcross_Volunteer_Required__c');
        map_oppField_driveField.put('Redcross_Volunteer_Quantity__c', 'sked_Redcross_Volunteer_Quantity__c');
        
        List<driveChangeRequestModel> filteredRequests = new List<driveChangeRequestModel>();
        
        Set<Id> oppIds = new Set<Id>();
        for (driveChangeRequestModel captureReq : lsRequests) {
            if (captureReq.opportunityId != null) {
                oppIds.add(captureReq.opportunityId);
            }
        }
        
        List<sked_Drive_Change_Request__c> changeRequestQuery = [SELECT Id, Name, sked_Drive__c, sked_Opportunity_Id__c, sked_Status__c, 
                                                                 sked_Process_Counter__c,
                                                                 (SELECT Id, sked_Old_Value__c, sked_New_Value__c, sked_Object_API_Name__c, 
                                                                  sked_Field_API_Name__c, sked_Field_Label__c, sked_Field_Type__c, 
                                                                  sked_Change_Reason__c
                                                                  FROM sked_Drive_Change_Request_Items__r)
                                                                 FROM sked_Drive_Change_Request__c
                                                                 WHERE sked_Opportunity_Id__c IN :oppIds
                                                                 AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED
                                                                 AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM
                                                                 AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_REJECTED
                                                                 AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED];
        Map<Id, sked_Drive_Change_Request__c> map_oppId_ExistingChangeReq = new Map<Id, sked_Drive_Change_Request__c>();
        for (sked_Drive_Change_Request__c existingChangeReq : changeRequestQuery) {
            map_oppId_ExistingChangeReq.put(existingChangeReq.sked_Opportunity_Id__c, existingChangeReq);
        }
        
        List<sked_Drive__c> driveQuery = [SELECT Id, sked_Opportunity__c,
                                          sked_Drive_Date__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Site__c, sked_Projected_Registered_Donors__c,
                                          sked_WB_Projected_Procedures__c, sked_2RBC_Projected_Procedures__c, sked_Platelet_Projected_Procedures__c,
                                          sked_Plasma_Projected_Procedures__c, sked_Number_of_2RBC_Assets__c, sked_Number_of_Plasma_Assets__c,
                                          sked_Number_of_Platelet_Assets__c, sked_APT_Required__c,
                                          sked_Redcross_Volunteer_Required__c, sked_Redcross_Volunteer_Quantity__c //HRP-13146
                                          FROM sked_Drive__c
                                          WHERE sked_Opportunity__c IN :oppIds];
        Map<Id, sked_Drive__c> map_oppId_drive = new Map<Id, sked_Drive__c>();
        for (sked_Drive__c drive : driveQuery) {
            map_oppId_drive.put(drive.sked_Opportunity__c, drive);
        }
        
        for (driveChangeRequestModel captureReq : lsRequests) {
            if (!map_oppId_ExistingChangeReq.containsKey(captureReq.opportunityId)) {
                if (map_oppId_drive.containsKey(captureReq.opportunityId)) {
                    boolean isAnyValidItem = FALSE;
                    sked_Drive__c skedDrive = map_oppId_drive.get(captureReq.opportunityId);
                    for (driveChangeRequestItemModel driveChangeRequestItem : captureReq.driveChangeRequestItems) {
                        boolean isRevertingPurpose = driveChangeRequestItem.objectApiName == 'Opportunity' && !map_oppField_driveField.containsKey(driveChangeRequestItem.fieldApiName);
                        if (!isRevertingPurpose) {
                            string driveField = driveChangeRequestItem.fieldApiName;
                            if (driveChangeRequestItem.objectApiName == 'Opportunity') {
                                string oppField = driveChangeRequestItem.fieldApiName;
                                driveField = map_oppField_driveField.get(oppField);
                            }
                            string driveFieldValue = JSON.serialize(skedDrive.get(driveField)).replace('"', '');
                            if (driveChangeRequestItem.newValue != driveFieldValue) {
                                isAnyValidItem = TRUE;
                                break;
                            } 
                        }
                        else {
                            isAnyValidItem = TRUE;
                            break;
                        }
                    }
                    if (isAnyValidItem) {
                        filteredRequests.add(captureReq);
                    }
                }
            }
            else {
                filteredRequests.add(captureReq);
            }
        }
        
        return filteredRequests;
    }
    
    private static void generateMapKeyToNewChangeItem(List<driveChangeRequestModel> lsRequests, LookupData ref) {
        // get Driveids/oppIds
        Set<Id> setOppIds = new Set<Id>();
        for (driveChangeRequestModel captureReq : lsRequests) {
            if (captureReq.driveId != null) {
                ref.setDriveIds.add(captureReq.driveId);
            }
            if (captureReq.opportunityId != null) {
                setOppIds.add(captureReq.opportunityId);
            }
        }
        
        // get mapOppToDriveId (with assumption that drive has 1:1 with opp)
        Map<Id, Id> mapOppToDriveId = new Map<Id, Id>();
        if (!setOppIds.isEmpty()) {
            for (sked_Drive__c driveRec : [SELECT Id, sked_Opportunity__c 
                                           FROM sked_Drive__c 
                                           WHERE sked_Opportunity__c IN :setOppIds
                                           AND sked_Status__c != :skedConstants.DRIVE_STATUS_CANCEL]) {
                                               mapOppToDriveId.put(driveRec.sked_Opportunity__c, driveRec.Id);
                                           }
            ref.setDriveIds.addAll(mapOppToDriveId.values());
        }
        
        // generate mapKeyToChangeItem
        for (driveChangeRequestModel captureReq : lsRequests) {
            Id driveId = captureReq.driveId != null ? captureReq.driveId : mapOppToDriveId.get(captureReq.opportunityId);
            if (driveId != NULL) {
                for (driveChangeRequestItemModel item :captureReq.driveChangeRequestItems) {
                    String key = driveId + ':' + item.objectApiName.toLowerCase() + ':' + item.fieldApiName.toLowerCase();
                    ref.mapKeyToNewChangeItem.put(key, item);
                }
            }
        }
    }
    
    private static void generateMapKeyToExistingChangeItem(LookupData ref) {
        if (ref.setDriveIds.isEmpty()) return;
        
        // get 'Drive change requests' & generate two maps - mapDriveToExistingChangeReq & mapKeyToExistingChangeItem
        List<sked_Drive_Change_Request__c> changeRequestQuery = [SELECT Id, Name, sked_Drive__c, sked_Status__c, sked_Process_Counter__c, sked_Type__c,
                                                                 (SELECT Id, sked_Old_Value__c, sked_New_Value__c, sked_Object_API_Name__c, 
                                                                  sked_Field_API_Name__c, sked_Field_Label__c, sked_Field_Type__c,
                                                                  sked_Change_Reason__c
                                                                  FROM sked_Drive_Change_Request_Items__r)
                                                                 FROM sked_Drive_Change_Request__c
                                                                 WHERE sked_Drive__c = :ref.setDriveIds
                                                                 AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED
                                                                 AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM
                                                                 AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_REJECTED
                                                                 AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED];
        for (sked_Drive_Change_Request__c existingChangeReq :changeRequestQuery) {
            ref.mapDriveToExistingChangeReq.put(existingChangeReq.sked_Drive__c, existingChangeReq);
            
            for (sked_Drive_Change_Request_Item__c changeItem : existingChangeReq.sked_Drive_Change_Request_Items__r) {
                String key = existingChangeReq.sked_Drive__c + ':' + changeItem.sked_Object_API_Name__c.toLowerCase() + ':' + changeItem.sked_Field_API_Name__c.toLowerCase();
                ref.mapKeyToExistingChangeItem.put(key, changeItem);
            }
        }
        
        // create 'change request' for drives where 'change req' not exists already & add to existing map
        List<Id> lsDriveIdChangeReq_NotExisting = new List<Id>(ref.setDriveIds);
        Map<Id, sked_Drive_Change_Request__c> mapDriveToNewChangeReq = new Map<Id, sked_Drive_Change_Request__c>();
        List<sked_Drive_Change_Request__c> dcrsToUpsert = new List<sked_Drive_Change_Request__c>();
        for (Id driveId : ref.setDriveIds) {
            sked_Drive_Change_Request__c skedDcr = ref.mapDriveToExistingChangeReq.get(driveId);
            if (skedDcr == NULL) {
                skedDcr = new sked_Drive_Change_Request__c(
                    sked_Drive__c = driveId
                );
                mapDriveToNewChangeReq.put(driveId, skedDcr);
            }
            List<string> dcrTypes = skedDcr.sked_Type__c != null ? skedDcr.sked_Type__c.split(';') : new List<string>();
            if (!dcrTypes.contains(skedConstants.DRIVE_CHANGE_REQUEST_TYPE_USER_CHANGE)) {
                dcrTypes.add(skedConstants.DRIVE_CHANGE_REQUEST_TYPE_USER_CHANGE);
                skedDcr.sked_Type__c = string.join(dcrTypes, ';');
                dcrsToUpsert.add(skedDcr);
            }
            skedDcr.sked_Status__c = 'Pending';
        }
        if(!dcrsToUpsert.isEmpty()){
            upsert dcrsToUpsert;
        }
        if (!mapDriveToNewChangeReq.isEmpty()) {
            upsert mapDriveToNewChangeReq.values();
            
            //add this to existing map
            ref.mapDriveToExistingChangeReq.putAll(mapDriveToNewChangeReq);
        }
    }
    
    private static void processNewWithExistingChangeReqs(LookupData ref) {
        // loop through the requests & compare with existing 'change request item' and do upserts
        Map<String, Map<String, Schema.SObjectField>> map_objectApi_mapField = new Map<String, Map<String, Schema.SObjectField>>();
        
        Map<String, Schema.SObjectField> mapSObjectDriveField = Schema.SObjectType.sked_Drive__c.fields.getMap();
        map_objectApi_mapField.put('sked_drive__c', mapSObjectDriveField);
        
        Map<String, Schema.SObjectField> mapSObjectOpporunityField = Schema.SObjectType.Opportunity.fields.getMap();
        map_objectApi_mapField.put('opportunity', mapSObjectOpporunityField);
        
        List<sked_Drive_Change_Request_Item__c> skedRequestItemsToDelete = new List<sked_Drive_Change_Request_Item__c>();
        List<sked_Drive_Change_Request_Item__c> skedRequestItemsToUpsert = new List<sked_Drive_Change_Request_Item__c>();
        for (String key : ref.mapKeyToNewChangeItem.keySet()) {
            string[] keyParts = key.split(':');
            String driveId = keyParts[0];
            String objectApiName = keyParts[1];
            String fieldApiName = keyParts[2];
            driveChangeRequestItemModel item = ref.mapKeyToNewChangeItem.get(key);
            
            if (ref.mapKeyToExistingChangeItem.containsKey(key)) {
                sked_Drive_Change_Request_Item__c existingItem = ref.mapKeyToExistingChangeItem.get(key);
                if (item.newValue != existingItem.sked_Old_Value__c) {
                    existingItem.sked_New_Value__c = item.newValue;
                    skedRequestItemsToUpsert.add(existingItem);
                }
                else {
                    skedRequestItemsToDelete.add(existingItem);
                }
            }
            else {
                Id driveChangeReqId = ref.mapDriveToExistingChangeReq.get(driveId)?.Id;
                if (driveChangeReqId != NULL) {
                    Map<String, Schema.SObjectField> mapSObjectField = map_objectApi_mapField.get(objectApiName);
                    if (mapSObjectField.containsKey(fieldApiName)) {
                        Schema.SObjectField sObjectField = mapSObjectField.get(fieldApiName);
                        DescribeFieldResult sObjectFieldResult = sObjectField.getDescribe();
                        
                        string fieldLabel = sObjectFieldResult.getLabel();
                        string fieldType = string.valueOf(sObjectFieldResult.getType()).toLowerCase();
                        
                        sked_Drive_Change_Request_Item__c skedRequestItem = new sked_Drive_Change_Request_Item__c(
                            sked_Drive_Change_Request__c = driveChangeReqId,
                            sked_Object_Api_Name__c = item.objectApiName,
                            sked_Field_Api_Name__c = item.fieldApiName,
                            sked_Field_Label__c = fieldLabel,
                            sked_Field_Type__c = fieldType,
                            sked_New_Value__c = item.newValue,
                            sked_Old_Value__c = item.oldValue,
                            sked_Change_Reason__c = item.changeReason,
                            sked_Type__c = 'Change'
                        );
                        skedRequestItemsToUpsert.add(skedRequestItem);
                    }
                }
            }
        }
        if (!skedRequestItemsToDelete.isEmpty()) {
            delete skedRequestItemsToDelete;
        }
        if (!skedRequestItemsToUpsert.isEmpty()) {
            upsert skedRequestItemsToUpsert;
        }
    }
    
    private static void deleteDcrWithoutItem(LookupData ref) {
        List<sked_Drive_Change_Request__c> dcrsToVerifyItem = [SELECT Id,
                                                               (SELECT Id
                                                                FROM sked_Drive_Change_Request_Items__r)
                                                               FROM sked_Drive_Change_Request__c
                                                               WHERE Id IN :ref.mapDriveToExistingChangeReq.values()];
        List<sked_Drive_Change_Request__c> dcrsWithoutItems = new List<sked_Drive_Change_Request__c>();
        for (sked_Drive_Change_Request__c dcrToVerifyItem : dcrsToVerifyItem) {
            if (dcrToVerifyItem.sked_Drive_Change_Request_Items__r.isEmpty()) {
                dcrsWithoutItems.add(dcrToVerifyItem);
            }
        }
        if (!dcrsWithoutItems.isEmpty()) {
            delete dcrsWithoutItems;
        }
    }
    
    private static void notifyDriveChanges(LookupData ref) {
        if (!ref.mapDriveToExistingChangeReq.isEmpty()) {
            Set<Id> driveChangeRequestIds = new Set<Id>();
            for (sked_Drive_Change_Request__c driveChangeReq : ref.mapDriveToExistingChangeReq.values()) {
                driveChangeRequestIds.add(driveChangeReq.Id);
            }
            
            List<sked_Drive_Change_Request__c> driveChangeRequests = [SELECT Id, Name, sked_Drive__c, sked_Status__c, sked_Process_Counter__c,
                                                                      (SELECT Id, sked_Old_Value__c, sked_New_Value__c, sked_Object_API_Name__c, 
                                                                       sked_Field_API_Name__c, sked_Field_Label__c, sked_Field_Type__c,
                                                                       sked_Change_Reason__c
                                                                       FROM sked_Drive_Change_Request_Items__r
                                                                       WHERE sked_Type__c = 'Change')
                                                                      FROM sked_Drive_Change_Request__c
                                                                      WHERE Id = :driveChangeRequestIds
                                                                      AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED
                                                                      AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_APPROVED_BY_SYSTEM
                                                                      AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_REJECTED
                                                                      AND sked_Status__c != :skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED];
            for (sked_Drive_Change_Request__c driveChangeReq : driveChangeRequests) {
                if (driveChangeReq.sked_Drive_Change_Request_Items__r != NULL && !driveChangeReq.sked_Drive_Change_Request_Items__r.isEmpty()) {
                    driveChangeReq.sked_Process_Counter__c = driveChangeReq.sked_Process_Counter__c != NULL ? driveChangeReq.sked_Process_Counter__c + 1 : 1;
                }
                else {
                    driveChangeReq.sked_Status__c = skedConstants.DRIVE_CHANGE_REQUEST_STATUS_CANCELLED;
                }
            }
            update driveChangeRequests;
        }
    }
    
    /* Nest classes */
    public class LookupData {
        Set<Id> setDriveIds = new Set<Id>();
        Map<String, driveChangeRequestItemModel> mapKeyToNewChangeItem = new Map<String, driveChangeRequestItemModel>();
        Map<Id, sked_Drive_Change_Request__c> mapDriveToExistingChangeReq = new Map<Id, sked_Drive_Change_Request__c>();
        Map<String, sked_Drive_Change_Request_Item__c> mapKeyToExistingChangeItem = new Map<String, sked_Drive_Change_Request_Item__c>();
    }
    
    public class dispatchDrivesRequestModel {
        @AuraEnabled public List<string> driveIds {get; set;}
        @AuraEnabled public Boolean resend {get; set;}
    }
    
    public class updateDriveStatusRequestModel {
        @AuraEnabled public List<driveModel> drives {get;set;}
    }
    
    public class driveChangeRequestModel {
        @AuraEnabled public string id {get; set;}
        @AuraEnabled public string driveId {get; set;}
        @AuraEnabled public string opportunityId {get; set;}
        @AuraEnabled public List<driveChangeRequestItemModel> driveChangeRequestItems {get; set;}
    }
    
    public class driveChangeRequestItemModel {
        @AuraEnabled public string id {get; set;}
        @AuraEnabled public string changeReason {get; set;}
        @AuraEnabled public string fieldApiName {get; set;}
        @AuraEnabled public string fieldLabel {get; set;}
        @AuraEnabled public string fieldType {get; set;}
        @AuraEnabled public string objectApiName {get; set;}
        @AuraEnabled public string oldValue {get; set;}
        @AuraEnabled public string newValue {get; set;}
    }
    
    public class searchDriveSiteRequestModel {
        @AuraEnabled public string queryText {get;set;}
        @AuraEnabled public string collectionOperationId {get;set;}
        @AuraEnabled public string inputDate {get;set;}
        
        public List<string> additionalResourceIds;
    }
    
    global class getTerritoryKeysRequestModel {
        @AuraEnabled public string collectionOperationId {get;set;}
        @AuraEnabled public Date endDate {get;set;}
        @AuraEnabled public Date startDate {get;set;}
    }
    
    global class validateDraftDriveRequestModel {
        @AuraEnabled public string driveId {get;set;}
    }
    
    public class driveDataModel {
        @AuraEnabled public object drives {get;set;}
    }
    
    public class siteDataModel {
        @AuraEnabled public object sites {get;set;}
    }
    
    public class driveModel {
        public string id;
        public string status;
        public string cancellationReason;
        public string replacementDriveId;
    }
    
    public class captureNonUserChangeDCRsModel {
        public List<sked_Drive__c> impactedDrives;
        public string fieldLabel;
        public string fieldApiName;
        public string fieldType;
        public string driveChangeRequestType;
    }
    
}