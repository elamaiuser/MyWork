public class skedAvailabilityHandler extends skedTriggerHub {

    private static final List<String> PERMITTED_INSERT_EDIT_PROFILES = new List<String>{
        'Global Admin', 'System Administrator', 'APS Scheduler', 'APS Management'
  	};
    
    private static final List<String> AVAILABILITY_APPROVED_STATUSES = new List<String>{
        skedConstants.AVAILABILITY_STATUS_APPROVED,
        skedConstants.AVAILABILITY_STATUS_APPROVED_FROM_PENDING,
        skedConstants.AVAILABILITY_STATUS_APPROVED_FROM_WAITLIST
    };
    
    private List<unavailabilityWrapper> mUnavailabilityWrappers;
    protected List<unavailabilityWrapper> unavailabilityWrappers {
        get {
            if (mUnavailabilityWrappers == NULL) {
                mUnavailabilityWrappers = new List<unavailabilityWrapper>();
                List<sked__Availability__c> newRecords = (List<sked__Availability__c>)this.context.newRecords;
                List<sked__Availability__c> unavailabilityRecords = new List<sked__Availability__c>();
                Set<Id> resourceIds = new Set<Id>();
                for (sked__Availability__c newRecord : newRecords) {
                    if (newRecord.sked__Is_Available__c == FALSE) {
                        unavailabilityRecords.add(newRecord);
                        resourceIds.add(newRecord.sked__Resource__c);
                    }
                }
                if (!unavailabilityRecords.isEmpty()) {
                    Set<Date> availabilityDates = new Set<Date>();
                    
                    Map<Id, sked__Resource__c> mapResources = new Map<Id, sked__Resource__c>([
                        SELECT Id, sked__Primary_Region__c, sked_FCC_Code__c,
                        sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c,
                        sked__Primary_Region__r.sked__Timezone__c,
                            (SELECT Id, sked__Tag__c, sked__Tag__r.Name, sked__Tag__r.sked_Priority__c
                            FROM sked__ResourceTags__r
                            WHERE sked__Tag__r.sked__Type__c = :skedConstants.TAG_TYPE_ROLE
                            AND sked_Role_Status__c = :skedConstants.TAG_ROLE_STATUS_ACTIVE
                            ORDER BY sked__Tag__r.sked_Priority__c ASC NULLS LAST),
                            (SELECT Id, sked__Location__c, sked_Location_Resource_Relationship__c
                            FROM sked__Location_Resource_Scores__r
                            WHERE sked_Location_Resource_Relationship__c = 'Preferred'
                            AND sked__Location__r.RecordType.Name = 'Fixed Site')
                        FROM sked__Resource__c
                        WHERE Id IN :resourceIds
                    ]);

                    for (sked__Availability__c unavailability : unavailabilityRecords) {
                        sked__Resource__c skedResource = mapResources.get(unavailability.sked__Resource__c);
                        if (skedResource.sked__ResourceTags__r != NULL && !skedResource.sked__ResourceTags__r.isEmpty()) {
                            unavailabilityWrapper wrapper = new unavailabilityWrapper();
                            wrapper.unavailability = unavailability;
                            wrapper.biomedCollectionOpId = skedResource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c;

                            List<String> primaryRoles = new List<String>();
                            
                            Decimal priority = 
                            skedResource.sked__ResourceTags__r.get(0).sked__Tag__r.sked_Priority__c != null ?
                            skedResource.sked__ResourceTags__r.get(0).sked__Tag__r.sked_Priority__c : 0;
                            
                            for(sked__Resource_Tag__c resourceTag : skedResource.sked__ResourceTags__r){
                                if (resourceTag.sked__Tag__r.Name != null && (priority == 0 || resourceTag.sked__Tag__r.sked_Priority__c == priority)) {
                            primaryRoles.add(resourceTag.sked__Tag__r.Name);
                             }
                            }
                            wrapper.role = primaryRoles;
                            wrapper.timezoneSidId = skedResource.sked__Primary_Region__r.sked__Timezone__c;
                            wrapper.unavailabilityDate = skedDateTimeUtils.getDate(unavailability.sked__Start__c, wrapper.timezoneSidId);
                            wrapper.key = wrapper.biomedCollectionOpId + ':' + unavailability.sked__Start__c.format(skedDateTimeUtils.DATE_ISO_FORMAT, wrapper.timezoneSidId);
                            wrapper.resource = skedResource;
                            wrapper.isResourcePreferredToFixedSites = skedResource.sked__Location_Resource_Scores__r != NULL && !skedResource.sked__Location_Resource_Scores__r.isEmpty();
                            mUnavailabilityWrappers.add(wrapper);
                        }
                    }
                }
            }
            return mUnavailabilityWrappers;
        }
    }
    
    public override void onBeforeInsert() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC);
        populateData(this.context.newRecords, null);
        handleAutoApprovals(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
        populateResourceType(this.context.newRecords);
    }
    
    public override void onAfterInsert() {
        try {
            populateStaffingBudgetAvailabilities(this.context.newRecords);
            captureExceptionLogs(this.context.newRecords);
            syncToResourceHoursRecord(this.context.newRecords);
            if (!skedSetting.instance.Admin.migrationMode) {
                if (!System.isBatch()) {
                    skedRecurringScheduleUtils.publishUpdateAvailabilityCountEvent(this.context.newRecords);
                    skedWorkdayUtils.publishWorkdayApprovalsEvent(skedWorkdayUtils.getApprovedRecordIds(this.context.newRecords));
                }
            }
        } catch (Exception ex) {
            sked__Debug_Log__c debugLog = skedTriggerUtils.prepareErrorLogEntry('Availability After Insert', ex, (Set<Id>)this.context.newMap.keySet());
            insert debugLog;
        }
    }

    
    public override void onBeforeUpdate() {
        skedTriggerUtils.validateServiceEntry(this.context.newRecords, skedConstants.AVAILABILITY_CRUD_MUST_COME_FROM_RAC, PERMITTED_INSERT_EDIT_PROFILES);
        populateData(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
        }
    }
    
    public override void onAfterUpdate() {
        if (!skedSetting.instance.Admin.migrationMode) {
            try {
                captureExceptionLogs(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
                syncToResourceHoursRecord(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
                syncToStaffingBudgetAvailabilities(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
                cancelCallOut(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
                onAvailabilityCallOutTypeChangeToCallOut(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
                sendCancelledApprovedTimeOffNotification(this.context.newRecords, (Map<Id, sked__Availability__c>)this.context.oldMap);
                skedWorkdayUtils.initiateFullWorkdaySync(this.context.newRecords, (Map<Id, sked__Availability__c>) this.context.oldMap);
                if (!System.isBatch()) {
                    skedRecurringScheduleUtils.publishUpdateAvailabilityCountEvent(this.context.newRecords);
                }
            } catch (Exception ex) {
                sked__Debug_Log__c debugLog = skedTriggerUtils.prepareErrorLogEntry('Availability After Update', ex, (Set<Id>)this.context.newMap.keySet());
                insert debugLog;
            }
        }
    }

    public override void onBeforeDelete() {
        skedTriggerUtils.validateServiceEntry(this.context.oldRecords, skedConstants.RECORD_CHANGES_INVALID_PERMISSIONS, new List<String>{'System Administrator'}, false);
        if (!skedSetting.instance.Admin.migrationMode) {
        	removeExceptionLogs((Map<Id, sked__Availability__c>)this.context.oldMap);
        	removeResourceHoursRecord(this.context.oldMap.values());
        }
    }

    public override void onAfterDelete() {
        try {
            skedRecurringScheduleUtils.publishUpdateAvailabilityCountEvent(this.context.oldRecords);
            deleteCallOut(this.context.oldRecords);
            skedWorkdayUtils.publishWorkdayCancellationsEvent(skedWorkdayUtils.getCancellationsContainer(this.context.oldRecords));
        } catch (Exception ex) {
            sked__Debug_Log__c debugLog = skedTriggerUtils.prepareErrorLogEntry('Availability After Delete', ex, (Set<Id>)this.context.oldMap.keySet());
            insert debugLog;
        }
    }

    /*********************************************************** Private methods ***********************************************************/
    private void cancelCallOut(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Set<Id> jobAllocationIdsToDelete = new Set<Id>();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Custom_Status__c != oldData.sked_Custom_Status__c && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_CANCELLED && newRecord.sked_Call_Out_Type__c != skedConstants.AVAILABILITY_CALLOUT_TYPE_EARLY_DEPARTURE && newRecord.sked_Call_Out_Type__c != skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL) {
                if (newRecord.sked_Call_Out_for_Job_Allocation__c != NULL) {
                    jobAllocationIdsToDelete.add(newRecord.sked_Call_Out_for_Job_Allocation__c);
                }
            }
        }
        if (!jobAllocationIdsToDelete.isEmpty()) {
            clearDeletedCallOutJobAllocationFromRevokingCallOut(jobAllocationIdsToDelete);
        }
    }

    private void onAvailabilityCallOutTypeChangeToCallOut(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Map<Id, sked__Job_Allocation__c> map_id_jobAllocationToDelete = new Map<Id, sked__Job_Allocation__c>();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Call_Out_Type__c != oldData.sked_Call_Out_Type__c
                && newRecord.sked_Call_Out_Type__c == skedConstants.AVAILABILITY_CALLOUT_TYPE_CALL_OUT
                && newRecord.sked_Custom_Status__c != skedConstants.AVAILABILITY_STATUS_CANCELLED
            ) {
                if (newRecord.sked_Call_Out_for_Job_Allocation__c != NULL && !map_id_jobAllocationToDelete.containsKey(newRecord.sked_Call_Out_for_Job_Allocation__c)) {
                    map_id_jobAllocationToDelete.put(
                        newRecord.sked_Call_Out_for_Job_Allocation__c,
                        new sked__Job_Allocation__c(
                            Id = newRecord.sked_Call_Out_for_Job_Allocation__c,
                            sked_Call_Out_Type__c = newRecord.sked_Call_Out_Type__c,
                            sked__Status__c = skedConstants.JOB_ALLOCATION_STATUS_DELETED
                        )
                    );
                }
            }
        }
        if (!map_id_jobAllocationToDelete.isEmpty()) {
            update map_id_jobAllocationToDelete.values();
        }
    }

    private void deleteCallOut(List<sked__Availability__c> deletedAvailabilities) {
        Set<Id> jobAllocationIdsToDelete = new Set<Id>();
        for (sked__Availability__c deletedAvailability : deletedAvailabilities) {
            if (deletedAvailability.sked_Call_Out_for_Job_Allocation__c != NULL) {
                jobAllocationIdsToDelete.add(deletedAvailability.sked_Call_Out_for_Job_Allocation__c);
            }
        }
        if (!jobAllocationIdsToDelete.isEmpty()) {
            clearDeletedCallOutJobAllocationFromRevokingCallOut(jobAllocationIdsToDelete);
        }
    }

    private void clearDeletedCallOutJobAllocationFromRevokingCallOut(Set<Id> jobAllocationIdsToDelete) {
        List<sked__Job_Allocation__c> callOutJobAllocations = [
            SELECT Id, sked__Job__c, sked__Resource__c, sked__Status__c,
            sked_CDL__c, sked_DOT__c, sked__Duration__c,
            sked__Set_End__c, sked_Set_End_Date__c, sked_Set_End_Time__c,
            sked__Start__c, sked_Start_Date__c, sked_Start_Time__c,
            sked__Time_Published__c, sked_Time_Published_Date__c, sked_Time_Published_Time__c, 
            sked_Start_With_Travel_Time__c, sked_Travel_Time_Back__c, sked_Travel_Time_To__c,
            sked_Geoservice_Travel_Time_Back__c, sked_Geoservice_Travel_Time_To__c,
            sked_Geoservice_Travel_Distance_Back__c, sked_Geoservice_Travel_Distance_To__c,
            sked_Is_Relocated_Resource__c, sked_Additional_Roles__c, 
            sked_Drive_Shift_Trade__c, sked_Locked__c
            FROM sked__Job_Allocation__c
            WHERE Id IN :jobAllocationIdsToDelete
            AND sked__Job__r.sked__Job_Status__c != :skedConstants.JOB_STATUS_CANCELLED
        ];

        if (!callOutJobAllocations.isEmpty()) {
            delete callOutJobAllocations;
        }
    }
    
    private void captureExceptionLogs(List<sked__Availability__c> newRecords) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
        List<String> excludedCalloutTypes = new List<String> {
            skedConstants.AVAILABILITY_CALLOUT_TYPE_EARLY_DEPARTURE,
            skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL
        };
        List<string> activeStatuses = new List<string> {
            skedConstants.AVAILABILITY_STATUS_APPROVED,
            skedConstants.AVAILABILITY_STATUS_PENDING,
            skedConstants.AVAILABILITY_STATUS_WAITLIST
        };

		for (sked__Availability__c newRecord : newRecords) {
			if (newRecord.sked__Is_Available__c 
                || !activeStatuses.contains(newRecord.sked__Status__c)
                || excludedCalloutTypes.contains(newRecord.sked_Call_Out_Type__c)) {
				continue;
			}
			skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
			unavailability.resourceId = newRecord.sked__Resource__c;
			unavailability.startTime = newRecord.sked__Start__c;
			unavailability.endTime = newRecord.sked__Finish__c;
			unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
            unavailability.exceptionText = newRecord.sked__Type__c;
            unavailability.relatedEventFieldApi = 'skedHC__Availability__c';
            unavailability.recordId = newRecord.Id;
			unavailabilityList.add(unavailability);
		}
		if (!unavailabilityList.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
			service.captureExceptionLogs(unavailabilityList);
		}
    }
    
    private void captureExceptionLogs(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> updatedRecords) {
        List<skedExceptionLogService.resourceUnavailabilityModel> unavailabilityList = new List<skedExceptionLogService.resourceUnavailabilityModel>();
        List<String> excludedCalloutTypes = new List<String> {
            skedConstants.AVAILABILITY_CALLOUT_TYPE_EARLY_DEPARTURE,
            skedConstants.AVAILABILITY_CALLOUT_TYPE_LATE_ARRIVAL
        };
        List<string> activeStatuses = new List<string> {
            skedConstants.AVAILABILITY_STATUS_APPROVED,
            skedConstants.AVAILABILITY_STATUS_PENDING,
            skedConstants.AVAILABILITY_STATUS_WAITLIST
        };

        for (sked__Availability__c record : newRecords) {
            if (record.sked__Is_Available__c 
                || !activeStatuses.contains(record.sked__Status__c)
                || excludedCalloutTypes.contains(record.sked_Call_Out_Type__c)) {
                continue;
            }
            sked__Availability__c oldRecord = updatedRecords.get(record.Id);
            if (record.sked__Start__c != oldRecord.sked__Start__c || record.sked__Finish__c != oldRecord.sked__Finish__c) {
                skedExceptionLogService.resourceUnavailabilityModel unavailability = new skedExceptionLogService.resourceUnavailabilityModel();
                unavailability.resourceId = record.sked__Resource__c;
                unavailability.startTime = record.sked__Start__c;
                unavailability.endTime = record.sked__Finish__c;
                unavailability.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
                unavailability.exceptionText = record.sked__Type__c;
                unavailability.relatedEventFieldApi = 'skedHC__Availability__c';
                unavailability.recordId = record.Id;
                unavailabilityList.add(unavailability);
            }
        }
        if (!unavailabilityList.isEmpty()) {
            skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
            service.captureExceptionLogs(unavailabilityList);
        }
    }
    
    private void populateData(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        DateTime currentTime = system.now();

        Set<Id> resourceIds = new Set<Id>();
        for (sked__Availability__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
        }

        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([
            SELECT Id, sked__Resource_Type__c, sked__Primary_Region__r.sked__Timezone__c, sked_Daily_Time_Off_Hours__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);

        for (sked__Availability__c newRecord : newRecords) {
            boolean isInserted = oldMap == null;
            boolean isStatusChanged = false;
            Boolean isCancelled = false;
            if (oldMap != null && oldMap.containsKey(newRecord.Id)) {
                sked__Availability__c oldAvailability = oldMap.get(newRecord.Id);
                isStatusChanged = oldAvailability.sked_Custom_Status__c != newRecord.sked_Custom_Status__c;
                if (isStatusChanged && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_CANCELLED) {
                    isCancelled = true;
                }

                if (oldAvailability.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_WAITLIST && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED) {
                    newRecord.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED_FROM_WAITLIST;
                }

                if (oldAvailability.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_PROCESSING_ADJUSTMENT) {
                    if (oldAvailability.sked_Duration__c == newRecord.sked_Duration__c) {
                        newRecord.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                    }
                }
            }

            sked__Resource__c skedResource = mapResource.get(newRecord.sked__Resource__c);
            newRecord.sked__Timezone__c = skedResource.sked__Primary_Region__r.sked__Timezone__c;
            if (!string.isBlank(newRecord.sked_Custom_Status__c)) {
                newRecord.sked__Status__c = newRecord.sked_Custom_Status__c;
                if (newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_WAITLIST 
                        || newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_PROCESSING_APPROVAL) {
                    newRecord.sked__Status__c = skedConstants.AVAILABILITY_STATUS_PENDING;    
                }
                else if (newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_CANCELLED
                        || newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_PENDING_EXPIRED
                        || newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_WAITLIST_EXPIRED
                        || newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_EXPIRED) {
                    newRecord.sked__Status__c = skedConstants.AVAILABILITY_STATUS_DECLINED;
                }
                else if (newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED_FROM_WAITLIST
                        || newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED_FROM_PENDING
                        || newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_PROCESSING_ADJUSTMENT
                        || newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_PROCESSING_CANCELLATION) {
                    newRecord.sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                }
            }
            else {
                newRecord.sked_Custom_Status__c = newRecord.sked__Status__c;
            }
            
            if (!isCancelled && (skedResource.sked__Resource_Type__c == skedConstants.RESOURCE_TYPE_ASSET || newRecord.sked__Is_Available__c == TRUE)) {
                newRecord.sked__Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                newRecord.sked_Custom_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
            }

            if (isInserted || isStatusChanged) {
                Id userId = UserInfo.getUserId();
                Id autoProcessUserId = skedTriggerHub_Cache.getAutoProcessUserFromCache().Id;
                newRecord.sked_Last_Modified_By__c = newRecord.sked_Approved_Via_Automation__c ?
                autoProcessUserId : userId;
                newRecord.sked_Approved_Via_Automation__c = false;
                if(userId != autoProcessUserId) {
                    newRecord.sked_Dispositioned_By_User__c = userId;
                    newRecord.sked_Disposition_Date__c = System.now();
                }
            }

            if (isInserted) {
                if (newRecord.sked_Call_Out_Type__c != null) {
                    newRecord.sked_DateTime_of_Call_Out__c = newRecord.sked_DateTime_of_Call_Out__c == null 
                        ? currentTime : newRecord.sked_DateTime_of_Call_Out__c;
                    newRecord.sked_DateTime_Call_Out_Received__c = newRecord.sked_DateTime_Call_Out_Received__c == null 
                        ? newRecord.sked_DateTime_of_Call_Out__c : newRecord.sked_DateTime_Call_Out_Received__c;
                    if (newRecord.sked_DateTime_Call_Out_Received__c != null && newRecord.sked__Start__c != null) {
                        newRecord.sked_Call_Out_Notice__c = skedDateTimeUtils.getDifferentMinutesText(newRecord.sked_DateTime_Call_Out_Received__c, newRecord.sked__Start__c);	
                    }
                }
                if (newRecord.sked_Related_Call_Out__c != NULL) {
                    newRecord.sked_Requested_Time_Off_Hours__c = skedWorkdayUtils.getWorkdayPtoHours(newRecord, skedResource);
                }
            }
        }
    }

    private void handleAutoApprovals(List<sked__Availability__c> availabilities) {
        List<String> autoApprovePermissionSets = new List<String>{'sked_Global_Admin', 'sked_APS', 'sked_APS_Admin', 'sked_APS_Manager', 'sked_APS_Planner'};
        if (skedTriggerUtils.hasAnyPermissionSetAssignment(autoApprovePermissionSets)) {
            Set<Id> resourceIds = new Set<Id>();
            for (sked__Availability__c availability : availabilities) {
                resourceIds.add(availability.sked__Resource__c);
            }

            Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([
                SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Auto_Approval_Cutoff_Days__c
                FROM sked__Resource__c
                WHERE Id IN :resourceIds
            ]);
            
            for (sked__Availability__c availability : availabilities) {
                Boolean requiresIntegration = availability.sked_Integrate_With_Workday__c;
                if (!availability.sked__Is_Available__c) {
                    sked__Resource__c skedResource = mapResource.get(availability.sked__Resource__c);
                    if (canBeAutoApproved(availability, skedResource, System.today())) {
                        availability.sked__Status__c = requiresIntegration ? skedConstants.AVAILABILITY_STATUS_PENDING : skedConstants.AVAILABILITY_STATUS_APPROVED;
                        availability.sked_Custom_Status__c = requiresIntegration ? skedConstants.AVAILABILITY_STATUS_PROCESSING_APPROVAL : skedConstants.AVAILABILITY_STATUS_APPROVED;
                    }
                }
            }
        }
    }

    private boolean canBeAutoApproved(sked__Availability__c availability, sked__Resource__c resource, Date currentDate) {
        Set<string> excludedTypes = new Set<String>{skedConstants.UNAVAILABILITY_TYPE_PTO, skedConstants.UNAVAILABILITY_TYPE_FLOATING_HOLIDAY, skedConstants.UNAVAILABILITY_TYPE_PERSONAL, skedConstants.UNAVAILABILITY_TYPE_SICK};
        Set<String> typesrequiresCutOffDays = new Set<String>{skedConstants.UNAVAILABILITY_TYPE_BEREAVEMENT};
        Set<String> bypassedTypes = new Set<String>{skedConstants.UNAVAILABILITY_TYPE_UNAVAILABLE, skedConstants.AVAILABILITY_TYPE_CALL_OUT};

        Date startDate = skedDateTimeUtils.getDate(availability.sked__Start__c, availability.sked__Timezone__c);

        Boolean autoApprovalRule1 = !typesrequiresCutOffDays.contains(availability.sked__Type__c) && !excludedTypes.contains(availability.sked__Type__c);
        Boolean autoApprovalRule2 = typesrequiresCutOffDays.contains(availability.sked__Type__c) && !skedStaffingBudgetUtils.isWithinCOAutoApprovalCutOffDays(resource, currentDate, startDate);
        Boolean autoApprovalRule3 = bypassedTypes.contains(availability.sked__Type__c);
        return autoApprovalRule1 || autoApprovalRule2 || autoApprovalRule3;
    }

    private void populateStaffingBudgetAvailabilities(List<sked__Availability__c> newRecords) {
        Set<string> unavailabilityTypesToPopulate = new Set<string>();
        unavailabilityTypesToPopulate.add('Floating Holiday');
        unavailabilityTypesToPopulate.add('PTO');
        
        List<sked__Availability__c> recordsToPopulate = new List<sked__Availability__c>();
        for (sked__Availability__c newRecord : newRecords) {
            if (newRecord.sked_Related_Call_Out__c == NULL && newRecord.sked__Type__c != NULL && unavailabilityTypesToPopulate.contains(newRecord.sked__Type__c)) {
                recordsToPopulate.add(newRecord);
            }
        }
        
        if (!recordsToPopulate.isEmpty()) {
            List<sked_Staffing_Budget_Availability__c> staffingBudgetAvailabilities = new List<sked_Staffing_Budget_Availability__c>();
            if (!unavailabilityWrappers.isEmpty()) {
                Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>();
                Map<Id, Set<Date>> datesByResourceId = new Map<Id, Set<Date>>();
                for (unavailabilityWrapper wrapper : unavailabilityWrappers) {
                    resourceById.put(wrapper.resource.Id, wrapper.resource);
                    
                    Set<Date> datesForResource = datesByResourceId.get(wrapper.resource.Id);
                    if (datesForResource == null) {
                        datesForResource = new Set<Date>();
                    }
                    datesForResource.add(wrapper.unavailabilityDate);
                    datesByResourceId.put(wrapper.resource.Id, datesForResource);
                }
                
                Map<Date, List<skedStaffingBudgetWrapper>> staffingBudgetWrappersByDate = skedStaffingBudgetUtils.getSkedStaffingBudgetWrappersByDate(datesByResourceId, resourceById);

                Set<Id> allStaffingBudgetIds = new Set<Id>();
                for (List<skedStaffingBudgetWrapper> sbWrappers : staffingBudgetWrappersByDate.values()) {
                    for (skedStaffingBudgetWrapper sbWrapper : sbWrappers) {
                        allStaffingBudgetIds.add(sbWrapper.staffingBudget.Id);
                    }
                }

                // A resource with multiple time-off records on the same day should only consume one slot
                Set<String> countedResourceBudgetPairs = new Set<String>();
                if (!allStaffingBudgetIds.isEmpty()) {
                    for (sked_Staffing_Budget_Availability__c existingSba : [
                        SELECT sked_Staffing_Budget__c, sked_Availability__r.sked__Resource__c
                        FROM sked_Staffing_Budget_Availability__c
                        WHERE sked_Staffing_Budget__c IN :allStaffingBudgetIds
                        AND sked_Availability_Status__c IN :skedConstants.AVAILABILITY_APPROVED_STATUSES
                    ]) {
                        countedResourceBudgetPairs.add(existingSba.sked_Availability__r.sked__Resource__c + '-' + existingSba.sked_Staffing_Budget__c);
                    }
                }

                for (unavailabilityWrapper wrapper : unavailabilityWrappers) {
                    Boolean hasMatchingStaffingBudgetSlot = false;
                    List<skedStaffingBudgetWrapper> staffingBudgetWrappersForDate = staffingBudgetWrappersByDate.get(wrapper.unavailabilityDate);
                    
                    if (staffingBudgetWrappersForDate == null) {
                        staffingBudgetWrappersForDate = new List<skedStaffingBudgetWrapper>();
                    }
                    
                    if (!staffingBudgetWrappersForDate.isEmpty()) {
                        for (skedStaffingBudgetWrapper staffingBudgetWrapper : staffingBudgetWrappersForDate) {
                            List<String> staffingBudgetRoles = staffingBudgetWrapper.staffingBudget.sked_Roles__c.split(';');
                            if ((wrapper.isResourcePreferredToFixedSites && !staffingBudgetWrapper.siteById.isEmpty()) || (!wrapper.isResourcePreferredToFixedSites && staffingBudgetWrapper.collectionOpById.keySet().contains(wrapper.resource.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__c))) {

                                Set<String> rolesFromStaffingBudget = new Set<String>(staffingBudgetRoles);
                                Set<String> wrapperRoles = new Set<String>(wrapper.role);
                                rolesFromStaffingBudget.retainAll(wrapperRoles);
                                if (!rolesFromStaffingBudget.isEmpty()) {
                                    hasMatchingStaffingBudgetSlot = true;
                                    String resourceBudgetKey = wrapper.resource.Id + '-' + staffingBudgetWrapper.staffingBudget.Id;
                                    if (!countedResourceBudgetPairs.contains(resourceBudgetKey)) {
                                        countedResourceBudgetPairs.add(resourceBudgetKey);
                                        staffingBudgetAvailabilities.add(new sked_Staffing_Budget_Availability__c(
                                            sked_Availability__c = wrapper.unavailability.Id,
                                            sked_Staffing_Budget__c = staffingBudgetWrapper.staffingBudget.Id,
                                            sked_Availability_Status__c = wrapper.unavailability.sked_Custom_Status__c
                                        ));

                                        if (wrapper.unavailability.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED) {
                                            staffingBudgetWrapper.approvedSlots++;
                                        }

                                        if (wrapper.unavailability.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED && staffingBudgetWrapper.availableSlots < 0) {
                                            wrapper.unavailability.addError(skedConstants.AVAILABILITY_STAFFING_BUDGET_NO_CAPACITY);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if (!hasMatchingStaffingBudgetSlot && !Test.isRunningTest()) {
                        wrapper.unavailability.addError(skedConstants.AVAILABILITY_STAFFING_BUDGET_NOT_FOUND);
                    }
                }
                
                if (!staffingBudgetAvailabilities.isEmpty()) {
                    insert staffingBudgetAvailabilities;
                }
            }
        }
    }

    private void syncToStaffingBudgetAvailabilities(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Set<String> unavailabilityTypesToSync = new Set<String>{ 'Floating Holiday', 'PTO' };

        Map<Id, sked__Availability__c> availabilityById = new Map<Id, sked__Availability__c>();
        Set<Id> cancellingApprovedIds = new Set<Id>();

        for (sked__Availability__c av : newRecords) {
            availabilityById.put(av.Id, av);
            sked__Availability__c old = oldMap.get(av.Id);
            if (
                skedConstants.AVAILABILITY_APPROVED_STATUSES.contains(old.sked_Custom_Status__c) &&
                !skedConstants.AVAILABILITY_APPROVED_STATUSES.contains(av.sked_Custom_Status__c) &&
                unavailabilityTypesToSync.contains(av.sked__Type__c)
            ) {
                cancellingApprovedIds.add(av.Id);
            }
        }

        List<sked_Staffing_Budget_Availability__c> sbaList = [
            SELECT Id, sked_Availability_Status__c, sked_Availability__c, sked_Staffing_Budget__c
            FROM sked_Staffing_Budget_Availability__c
            WHERE sked_Availability__c IN :availabilityById.keySet()
        ];

        if (!sbaList.isEmpty()) {
            if (!cancellingApprovedIds.isEmpty()) {
                Set<Id> resourceIds = new Set<Id>();
                Set<Date> startDates = new Set<Date>();
                for (Id cancelId : cancellingApprovedIds) {
                    sked__Availability__c av = availabilityById.get(cancelId);
                    resourceIds.add(av.sked__Resource__c);
                    startDates.add(av.sked_Start_Date__c);
                }

                // Find other approved PTO/FH availabilities for the same resources and dates
                List<sked__Availability__c> candidates = [
                    SELECT Id, sked__Resource__c, sked_Start_Date__c
                    FROM sked__Availability__c
                    WHERE sked__Resource__c IN :resourceIds
                    AND sked_Start_Date__c IN :startDates
                    AND sked_Custom_Status__c IN :skedConstants.AVAILABILITY_APPROVED_STATUSES
                    AND sked__Type__c IN :unavailabilityTypesToSync
                    AND Id NOT IN :cancellingApprovedIds
                    AND sked_Related_Call_Out__c = NULL
                    AND sked__Is_Available__c = FALSE
                ];

                // Skip candidates that already have their own SBA (already counted)
                Set<Id> candidateIds = new Map<Id, sked__Availability__c>(candidates).keySet();
                Set<Id> alreadyHasSba = new Set<Id>();
                if (!candidateIds.isEmpty()) {
                    for (sked_Staffing_Budget_Availability__c existingSba : [
                        SELECT sked_Availability__c
                        FROM sked_Staffing_Budget_Availability__c
                        WHERE sked_Availability__c IN :candidateIds
                    ]) {
                        alreadyHasSba.add(existingSba.sked_Availability__c);
                    }
                }

                // First eligible replacement per (resource, date) — takes over the SBA
                Map<String, Id> replacementByResourceDate = new Map<String, Id>();
                for (sked__Availability__c candidate : candidates) {
                    if (!alreadyHasSba.contains(candidate.Id)) {
                        String key = candidate.sked__Resource__c + '-' + candidate.sked_Start_Date__c;
                        if (!replacementByResourceDate.containsKey(key)) {
                            replacementByResourceDate.put(key, candidate.Id);
                        }
                    }
                }

                for (sked_Staffing_Budget_Availability__c sba : sbaList) {
                    sked__Availability__c av = availabilityById.get(sba.sked_Availability__c);
                    if (cancellingApprovedIds.contains(sba.sked_Availability__c)) {
                        String key = av.sked__Resource__c + '-' + av.sked_Start_Date__c;
                        Id replacementId = replacementByResourceDate.get(key);
                        if (replacementId != null) {
                            // Reassign SBA to the remaining active time-off so the slot stays consumed
                            sba.sked_Availability__c = replacementId;
                            sba.sked_Availability_Status__c = skedConstants.AVAILABILITY_STATUS_APPROVED;
                        } else {
                            sba.sked_Availability_Status__c = av.sked_Custom_Status__c;
                        }
                    } else {
                        sba.sked_Availability_Status__c = av.sked_Custom_Status__c;
                    }
                }
            } else {
                for (sked_Staffing_Budget_Availability__c sba : sbaList) {
                    sba.sked_Availability_Status__c = availabilityById.get(sba.sked_Availability__c).sked_Custom_Status__c;
                }
            }

            update sbaList;
        }
    }
    
    private void doDateTimeConversion(List<sked__Availability__c> newRecords) {
        for (sked__Availability__c newRecord : newRecords) {
        	skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Finish__c', 'sked_Finish_Date__c', 'sked_Finish_Time__c', 'sked__Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked__Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_DateTime_of_Call_Out__c', 'sked_Date_of_Call_Out__c', 'sked_Time_of_Call_Out__c', 'sked__Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_DateTime_Call_Out_Received__c', 'sked_Date_Call_Out_Received__c', 'sked_Time_Call_Out_Received__c', 'sked__Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldData = oldMap.get(newRecord.Id);
        	skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Finish__c', 'sked_Finish_Date__c', 'sked_Finish_Time__c', 'sked__Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked__Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked__Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_DateTime_of_Call_Out__c', 'sked_Date_of_Call_Out__c', 'sked_Time_of_Call_Out__c', 'sked__Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_DateTime_Call_Out_Received__c', 'sked_Date_Call_Out_Received__c', 'sked_Time_Call_Out_Received__c', 'sked__Timezone__c');
        }
    }
    
    private void onDeclined(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Map<Id, sked__Availability__c> mapDeclinedRecord = new Map<Id, sked__Availability__c>();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked__Status__c != oldData.sked__Status__c && newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_DECLINED) {
                mapDeclinedRecord.put(newRecord.Id, newRecord);
            }
        }
        if (!mapDeclinedRecord.isEmpty()) {
            removeExceptionLogs((Map<Id, sked__Availability__c>)this.context.oldMap);
        	removeResourceHoursRecord(mapDeclinedRecord.values());
        }
    }
    
    private void populateResourceType(List<sked__Availability__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Availability__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
        }
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Resource_Type__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        for (sked__Availability__c newRecord : newRecords) {
         	sked__Resource__c skedResource = mapResource.get(newRecord.sked__Resource__c);
            newRecord.sked_Resource_Type__c = skedResource.sked__Resource_Type__c;
        }
    }
    
    private void removeExceptionLogs(Map<Id, sked__Availability__c> oldMap) {
        skedExceptionLogService service = (skedExceptionLogService)skedServiceFactory.instance.resolve('skedHC__Exception__c');
        service.removeExceptionLogs(oldMap.keySet());
    }

    private void sendCancelledApprovedTimeOffNotification(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Availability__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
        }

        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([
            SELECT Id, sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Auto_Approval_Cutoff_Days__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);

        List<sked__Availability__c> cancelledApprovedTimeOffs = new List<sked__Availability__c>();

        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldData = oldMap.get(newRecord.Id);
            sked__Resource__c skedResource = mapResource.get(newRecord.sked__Resource__c);
            Date startDate = skedDateTimeUtils.getDate(newRecord.sked__Start__c, newRecord.sked__Timezone__c);
            Date cancelDate = System.today();

            if (newRecord.sked__Status__c == skedConstants.AVAILABILITY_STATUS_DECLINED && oldData.sked__Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED
                && newRecord.sked__Is_Available__c == FALSE && skedStaffingBudgetUtils.isWithinCOAutoApprovalCutOffDays(skedResource, cancelDate, startDate)) {
                cancelledApprovedTimeOffs.add(newRecord);
            }
        }

        if (!cancelledApprovedTimeOffs.isEmpty()) {
            new skedCustomNotificationService(new List<string> {'sked_Cancel_ATO_In_Auto_Approval_CutOff'}).generateNotifications(cancelledApprovedTimeOffs);
        }
    }

    /**************************************** RESOURCE HOURS RECORD ********************************************/
    private void syncToResourceHoursRecord(List<sked__Availability__c> newRecords) {
        Map<string, availabilityModel> mapUniqueKey_Availabilities = buildMapKey_AvailabilityModels(newRecords);
        Map<Id, sked__Resource__c> resourcesById = getResourceMapFromAvailabilities(newRecords);

        if (!mapUniqueKey_Availabilities.isEmpty()) {
            List<sked_Resource_Hours_Record__c> resourceHoursRecords = [
                SELECT Id, sked_End_Date__c, sked_Resource__c, sked_Start_Date__c, sked_Unique_Key__c
                FROM sked_Resource_Hours_Record__c
                WHERE sked_Unique_Key__c IN :mapUniqueKey_Availabilities.keySet()
                ORDER BY sked_Unique_Key__c ASC
            ];

            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                model.hasKey = FALSE;
                sked__Resource__c availabilityResource = resourcesById.get(model.resourceId);
                for (sked_Resource_Hours_Record__c resourceHoursRecord : resourceHoursRecords) {
                    if (model.key.equalsIgnoreCase(resourceHoursRecord.sked_Unique_Key__c)) {
                        for (sked__Availability__c availability : model.availabilities) {
                            sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                                sked_Resource_Hours_Record__c = resourceHoursRecord.Id, 
                                sked_Availability__c = availability.Id,
                                sked_Duration__c = getResourceHoursRecordDuration(availabilityResource, availability)
                            );

                            model.resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                        }
                        model.hasKey = TRUE;
                        break;
                    }
                }
                
                if (!model.hasKey) {
                    sked_Resource_Hours_Record__c resourceHoursRecord = new sked_Resource_Hours_Record__c(
                        sked_End_Date__c = model.endDate, 
                        sked_Resource__c = model.resourceId, 
                        sked_Start_Date__c = model.startDate, 
                        sked_Unique_Key__c = model.key
                    );
                    model.resourceHoursRecord = resourceHoursRecord;
                }
            }
            
            List<sked_Resource_Hours_Record__c> newResourceHoursRecords = new List<sked_Resource_Hours_Record__c>();
            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                if (!model.hasKey) {
                    newResourceHoursRecords.add(model.resourceHoursRecord);
                }
            }
            insert newResourceHoursRecords;
            
            List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                sked__Resource__c availabilityResource = resourcesById.get(model.resourceId);
                if (!model.hasKey) {
                    for (sked__Availability__c availability : model.availabilities) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                            sked_Availability__c = availability.Id,
                            sked_Duration__c = getResourceHoursRecordDuration(availabilityResource, availability)
                        );
                        resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                    }
                }
                else {
                    resourceHoursRecordDetails.addAll(model.resourceHoursRecordDetails);
                }
            }
            insert resourceHoursRecordDetails;
        }
    }

    private void syncToResourceHoursRecord(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Set<Id> ignoreRecordIds = syncHoursAfterChangeStatus(newRecords, oldMap);
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);
        Map<Id, sked__Resource__c> resourceById = getResourceMapFromAvailabilities(newRecords);

        Map<string, availabilityModel> mapUniqueKey_Availabilities = new Map<string, availabilityModel>();
        Map<Id, sked__Availability__c> mapAvailabilityNeedToSync = new Map<Id, sked__Availability__c>();
        List<sked__Availability__c> availabilitiesNeedToDeleteResourceHoursRecordDetail = new List<sked__Availability__c>();
        for (sked__Availability__c newRecord : newRecords) {
            if (newRecord.sked__Is_Available__c == FALSE && !ignoreRecordIds.contains(newRecord.Id)) {
                sked__Availability__c oldRecord = oldMap.get(newRecord.Id);
                if ((skedConstants.AVAILABILITY_APPROVED_STATUSES.contains(newRecord.sked_Custom_Status__c) && newRecord.sked_Custom_Status__c != oldRecord.sked_Custom_Status__c)
                   || oldRecord.sked__Start__c != newRecord.sked__Start__c || oldRecord.sked__Finish__c != newRecord.sked__Finish__c) {
                    string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                    Date oldEventDate = skedDateTimeUtils.getDate(oldRecord.sked__Start__c, oldRecord.sked__Timezone__c);
                    Date newEventDate = skedDateTimeUtils.getDate(newRecord.sked__Start__c, newRecord.sked__Timezone__c);
                    Date oldStartOfWeek = skedDateTimeUtils.findWeekStartDate(oldEventDate, workWeekday);
                    Date newStartOfWeek = skedDateTimeUtils.findWeekStartDate(newEventDate, workWeekday);
                    if (oldStartOfWeek != newStartOfWeek) {
                        availabilitiesNeedToDeleteResourceHoursRecordDetail.add(newRecord);

                        Date startOfWeek = newStartOfWeek;
                        Date endOfWeek = startOfWeek.addDays(6);
                        string key = skedResourceHoursRecordUtils.buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
                        
                        if (mapUniqueKey_Availabilities.containsKey(key)) {
                            availabilityModel model = mapUniqueKey_Availabilities.get(key);
                            model.availabilities.add(newRecord);
                        }
                        else {
                            availabilityModel model = new availabilityModel();
                            model.resourceId = newRecord.sked__Resource__c;
                            model.startDate = startOfWeek;
                            model.endDate = endOfWeek;
                            model.key = key;
                            model.availabilities = new List<sked__Availability__c>();
                            model.availabilities.add(newRecord);
                            mapUniqueKey_Availabilities.put(model.key, model);
                        }
                    }
                    else {
                        mapAvailabilityNeedToSync.put(newRecord.Id,  newRecord);
                    }
                }
            }
        }

        if (!mapAvailabilityNeedToSync.isEmpty()) {
            List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = [SELECT Id, sked_Duration__c, sked_Availability__c
                                                                                    FROM sked_Resource_Hours_Record_Detail__c
                                                                                    WHERE sked_Availability__c IN :mapAvailabilityNeedToSync.keySet()];
            for (sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail : resourceHoursRecordDetails) {
                sked__Availability__c availability = mapAvailabilityNeedToSync.get(resourceHoursRecordDetail.sked_Availability__c);
                sked__Resource__c availabilityResource = resourceById.get(availability.sked__Resource__c);
                resourceHoursRecordDetail.sked_Duration__c = getResourceHoursRecordDuration(availabilityResource, availability);
            }
            update resourceHoursRecordDetails;
        }
        
        if (!availabilitiesNeedToDeleteResourceHoursRecordDetail.isEmpty()) {
            delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Availability__c IN :availabilitiesNeedToDeleteResourceHoursRecordDetail];
            
            List<sked_Resource_Hours_Record__c> existingResourceHoursRecords = [SELECT Id, sked_Unique_Key__c
                                                                                FROM sked_Resource_Hours_Record__c
                                                                                WHERE sked_Unique_Key__c IN :mapUniqueKey_Availabilities.keySet()];
            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                model.hasKey = FALSE;
                sked__Resource__c availabilityResource = resourceById.get(model.resourceId);
                for (sked_Resource_Hours_Record__c existingResourceHoursRecord : existingResourceHoursRecords) {
                    if (model.key == existingResourceHoursRecord.sked_Unique_Key__c) {
                        for (sked__Availability__c availability : model.availabilities) {
                            sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                                sked_Resource_Hours_Record__c = existingResourceHoursRecord.Id, 
                                sked_Availability__c = availability.Id,
                                sked_Duration__c = getResourceHoursRecordDuration(availabilityResource, availability)
                            );
                            model.resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                        }
                        model.hasKey = TRUE;
                        break;
                    }
                }
                if (!model.hasKey) {
                    sked_Resource_Hours_Record__c resourceHoursRecord = new sked_Resource_Hours_Record__c(
                        sked_End_Date__c = model.endDate, 
                        sked_Resource__c = model.resourceId, 
                        sked_Start_Date__c = model.startDate, 
                        sked_Unique_Key__c = model.key
                    );
                    model.resourceHoursRecord = resourceHoursRecord;
                }
            }
            
            List<sked_Resource_Hours_Record__c> newResourceHoursRecords = new List<sked_Resource_Hours_Record__c>();
            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                if (!model.hasKey) {
                    newResourceHoursRecords.add(model.resourceHoursRecord);
                }
            }
            insert newResourceHoursRecords;

            List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
            for (availabilityModel model : mapUniqueKey_Availabilities.values()) {
                sked__Resource__c availabilityResource = resourceById.get(model.resourceId);
                if (!model.hasKey) {
                    for (sked__Availability__c availability : model.availabilities) {
                        sked_Resource_Hours_Record_Detail__c resourceHoursRecordDetail = new sked_Resource_Hours_Record_Detail__c(
                            sked_Resource_Hours_Record__c = model.resourceHoursRecord.Id, 
                            sked_Availability__c = availability.Id,
                            sked_Duration__c = getResourceHoursRecordDuration(availabilityResource, availability)
                        );
                        resourceHoursRecordDetails.add(resourceHoursRecordDetail);
                    }
                }
                else {
                    resourceHoursRecordDetails.addAll(model.resourceHoursRecordDetails);
                }
            }
            insert resourceHoursRecordDetails;
        }
    }

    private void removeResourceHoursRecord(List<sked__Availability__c> newRecords) {
        List<sked_Resource_Hours_Record_Detail__c> resourceHourDetailRecords = [SELECT Id 
                                                                                FROM sked_Resource_Hours_Record_Detail__c 
                                                                                WHERE sked_Availability__c IN :newRecords];
        if (!resourceHourDetailRecords.isEmpty()) {
            delete resourceHourDetailRecords;
        }
    }

    private Set<Id> syncHoursAfterChangeStatus(List<sked__Availability__c> newRecords, Map<Id, sked__Availability__c> oldMap) {
        Set<Id> ignoreRecordIds = new Set<Id>();

        Map<Id, sked__Availability__c> mapNeedToCreateRecords = new Map<Id, sked__Availability__c>();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldRecord = oldMap.get(newRecord.Id);
            if ((newRecord.sked__Is_Available__c == FALSE && oldRecord.sked__Is_Available__c != newRecord.sked__Is_Available__c && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED)
                || (newRecord.sked__Is_Available__c == FALSE && oldRecord.sked_Custom_Status__c != newRecord.sked_Custom_Status__c && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED)) {
                mapNeedToCreateRecords.put(newRecord.Id, newRecord);
                ignoreRecordIds.add(newRecord.Id);
            }
        }
        if (!mapNeedToCreateRecords.isEmpty()) {
            syncToResourceHoursRecord(mapNeedToCreateRecords.values());
        }

        Set<Id> needToDeleteRecords = new Set<Id>();
        for (sked__Availability__c newRecord : newRecords) {
            sked__Availability__c oldRecord = oldMap.get(newRecord.Id);
            if ((newRecord.sked__Is_Available__c == TRUE && oldRecord.sked__Is_Available__c != newRecord.sked__Is_Available__c)
                || (oldRecord.sked_Custom_Status__c != newRecord.sked_Custom_Status__c && newRecord.sked_Custom_Status__c != skedConstants.AVAILABILITY_STATUS_APPROVED)) {
                needToDeleteRecords.add(newRecord.Id);
                ignoreRecordIds.add(newRecord.Id);
            }
        }
        if (!needToDeleteRecords.isEmpty()) {
            delete [SELECT Id FROM sked_Resource_Hours_Record_Detail__c WHERE sked_Availability__c IN :needToDeleteRecords];
        }

        return ignoreRecordIds;
    }

    private Map<string, availabilityModel> buildMapKey_AvailabilityModels(List<sked__Availability__c> newRecords) {
        Map<string, availabilityModel> mapUniqueKey_Availabilities = new Map<string, availabilityModel>();
        Map<Id, string> mapRecord_WorkWeekday = getMapRecord_WorkWeekday(newRecords);

        for (sked__Availability__c newRecord : newRecords) {
            if (newRecord.sked__Type__c == skedConstants.UNAVAILABILITY_TYPE_UNAVAILABLE ||
                newRecord.sked__Type__c == skedConstants.AVAILABILITY_TYPE_CALL_OUT) continue;
                
            if (newRecord.sked__Is_Available__c == FALSE && newRecord.sked_Custom_Status__c == skedConstants.AVAILABILITY_STATUS_APPROVED) {
                string workWeekday = mapRecord_WorkWeekday.get(newRecord.Id);
                Date eventDate = skedDateTimeUtils.getDate(newRecord.sked__Start__c, newRecord.sked__Timezone__c);
                Date startOfWeek = skedDateTimeUtils.findWeekStartDate(eventDate, workWeekday);
                Date endOfWeek = startOfWeek.addDays(6);
                string key = skedResourceHoursRecordUtils.buildResourceHoursRecordUniqueKey(newRecord.sked__Resource__c, startOfWeek, endOfWeek);
                if (mapUniqueKey_Availabilities.containsKey(key)) {
                    availabilityModel model = mapUniqueKey_Availabilities.get(key);
                    model.availabilities.add(newRecord);
                }
                else {
                    availabilityModel model = new availabilityModel();
                    model.resourceId = newRecord.sked__Resource__c;
                    model.startDate = startOfWeek;
                    model.endDate = endOfWeek;
                    model.key = key;
                    model.availabilities = new List<sked__Availability__c>();
                    model.availabilities.add(newRecord);
                    mapUniqueKey_Availabilities.put(model.key, model);
                }
            }
        }
        return mapUniqueKey_Availabilities;
    }

    private Map<Id, string> getMapRecord_WorkWeekday(List<sked__Availability__c> newRecords) {
        Map<Id, string> mapRecord_WorkWeekday = new Map<Id, string>();
        List<sked__Availability__c> availabilities = [SELECT Id, sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c
                                                      FROM sked__Availability__c
                                                      WHERE Id IN :newRecords];
        for (sked__Availability__c availability : availabilities) {
            string workWeekday = 'Sunday';
            if (string.isNotBlank(availability.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c)) {
                workWeekday = availability.sked__Resource__r.sked__Primary_Region__r.sked_Biomed_Collection_Op_Center__r.sked_Work_Week_First_Day__c;
            }
            mapRecord_WorkWeekday.put(availability.Id, workWeekday);
        }

        return mapRecord_WorkWeekday;
    }
    
    /*********************************************************** Utility ***********************************************************/
    private static Map<Id, sked__Resource__c> getResourceMapFromAvailabilities(List<sked__Availability__c> availabilities) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked__Availability__c availability : availabilities) {
            resourceIds.add(availability.sked__Resource__c);
        }

        return new Map<Id, sked__Resource__c>([
            SELECT Id, Name, sked_Daily_Time_Off_Hours__c, sked_Employee_ID__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
    }

    public static Decimal getResourceHoursRecordDuration(sked__Resource__c resource, sked__Availability__c availability) {
        Decimal duration = 0.00;
        if (!availability.sked__Is_Available__c && availability.sked_Is_All_Day__c) {
            duration = resource.sked_Daily_Time_Off_Hours__c * 60;
        } else {
            duration = availability.sked_Duration__c;
        }

        return duration;
    }
    
    
    /*********************************************************** Nested classes ***********************************************************/
    private class unavailabilityWrapper {
        public sked__Availability__c unavailability {get;set;}
        public sked__Resource__c resource {get;set;}
        public string key {get;set;}
        public List<string> role {get;set;}
        public string biomedCollectionOpId {get;set;}
        public Date unavailabilityDate {get;set;}
        public string timezoneSidId {get;set;}
        public Boolean isResourcePreferredToFixedSites {get;set;}
    }
    
    public class availabilityModel {
        public Boolean hasKey;
        public string key;
        public string resourceId;
        public Date startDate;
        public Date endDate;
        public List<sked__Availability__c> availabilities;
        public List<sked_Resource_Hours_Record_Detail__c> resourceHoursRecordDetails;
        public sked_Resource_Hours_Record__c resourceHoursRecord;

        public availabilityModel() {
            availabilities = new List<sked__Availability__c>();
            resourceHoursRecordDetails = new List<sked_Resource_Hours_Record_Detail__c>();
        }
    }

}