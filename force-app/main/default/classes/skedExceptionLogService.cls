global class skedExceptionLogService extends skedDataService {
    
    public override void initialize() {
        this.sObjectApiName = 'skedHC__Exception__c';
        this.objectType = 'exceptionLog';
        this.domainType = Type.forName('skedModels.exceptionLog');
    }
    
    /*********************************************************** Public methods ***********************************************************/
    public List<skedHC__Exception__c> captureExceptionLogs(List<resourceUnavailabilityModel> unavailabilityList) {
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> sourceRecordIds = new Set<Id>();
        Set<Id> excludedIds = new Set<Id>();
        DateTime minDt, maxDt;
        boolean hasTermination = false;
        for (resourceUnavailabilityModel unavailability : unavailabilityList) {
            resourceIds.add(unavailability.resourceId);
            
            if (unavailability.recordId != NULL) {
            	sourceRecordIds.add(unavailability.recordId);
            }
            if (minDt == NULL || unavailability.startTime < minDt) {
                minDt = unavailability.startTime;
            }
            if (unavailability.endTime != NULL) {
                if (maxDt == NULL || unavailability.endTime > maxDt) {
                    maxDt = unavailability.endTime;
                }
            }
            else {
                hasTermination = true;
            }
        }
        if (hasTermination) {
            maxDt = NULL;
        }
        
        List<sked__Job_Allocation__c> conflictedAllocations = getConflictedAllocations(resourceIds, minDt, maxDt, excludedIds, false);
        
        List<skedHC__Exception__c> existingExceptionLogs = [
            SELECT Id, skedHC__Job_Allocation__c, skedHC__Exception__c,
            skedHC__Job__r.sked__Start__c, skedHC__Job__r.sked__Finish__c,
            skedHC__Availability__c, skedHC__Availability__r.sked__Start__c, 
            skedHC__Availability__r.sked__Finish__c, skedHC__Activity__c,
            skedHC__Activity__r.sked__Start__c, skedHC__Activity__r.sked__End__c
            FROM skedHC__Exception__c
            WHERE (skedHC__Availability__c IN :sourceRecordIds 
                    OR skedHC__Activity__c IN :sourceRecordIds
                    OR skedHC__Job_Allocation__c IN :sourceRecordIds)
            AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN
        ];
        Map<string, skedHC__Exception__c> mapExistingExceptionLog = new Map<string, skedHC__Exception__c>();
        List<skedHC__Exception__c> exceptionLogsToUpdate = new List<skedHC__Exception__c>();
        for (skedHC__Exception__c existingExceptionLog : existingExceptionLogs) {
            if (existingExceptionLog.skedHC__Availability__c != NULL 
                && (existingExceptionLog.skedHC__Job__r.sked__Start__c >= existingExceptionLog.skedHC__Availability__r.sked__Finish__c
                    || existingExceptionLog.skedHC__Job__r.sked__Finish__c <= existingExceptionLog.skedHC__Availability__r.sked__Start__c)) {
                        existingExceptionLog.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                        exceptionLogsToUpdate.add(existingExceptionLog);
                    }
            if (existingExceptionLog.skedHC__Activity__c != NULL 
                && (existingExceptionLog.skedHC__Job__r.sked__Start__c >= existingExceptionLog.skedHC__Activity__r.sked__End__c
                    || existingExceptionLog.skedHC__Job__r.sked__Finish__c <= existingExceptionLog.skedHC__Activity__r.sked__Start__c)) {
                        existingExceptionLog.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                        exceptionLogsToUpdate.add(existingExceptionLog);
                    }
            else {
                string key = existingExceptionLog.skedHC__Job_Allocation__c + ':' + existingExceptionLog.skedHC__Exception__c;
                mapExistingExceptionLog.put(key, existingExceptionLog);	
            }
        }
        if (!exceptionLogsToUpdate.isEmpty()) {
            update exceptionLogsToUpdate;
        }
        
        List<skedHC__Exception__c> newExceptionLogs = new List<skedHC__Exception__c>();
        for (resourceUnavailabilityModel unavailability : unavailabilityList) {
            for (sked__Job_Allocation__c conflictedAllocation : conflictedAllocations) {
                if (unavailability.relatedEventFieldApi == 'skedHC__Job_Allocation__c' && unavailability.recordId == conflictedAllocation.Id) continue;

                if (conflictedAllocation.sked__Resource__c != unavailability.resourceId
                        || conflictedAllocation.sked__Set_End__c < unavailability.startTime) {
                            continue;
                }
                if (unavailability.endTime != NULL && unavailability.endTime <= conflictedAllocation.sked__Start__c) {
                    break;
                }
                string key = conflictedAllocation.Id + ':' + unavailability.exceptionText;

                if (mapExistingExceptionLog.containsKey(key)) {
                    continue;
                }

                if (unavailability.relatedEventFieldApi == 'skedHC__Job_Allocation__c') {
                    resourceUnavailabilityModel unavailabilityModel = new resourceUnavailabilityModel();
                    unavailabilityModel.resourceId = conflictedAllocation.sked__Resource__c;
                    unavailabilityModel.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
                    unavailabilityModel.exceptionText = 'Conflict with ' +  unavailability.driveName;
                    unavailabilityModel.relatedEventFieldApi = unavailability.relatedEventFieldApi;
                    unavailabilityModel.recordId = unavailability.recordId;
                    unavailabilityModel.jobId = conflictedAllocation.sked__Job__c; 
                    unavailabilityModel.jobAllocationId = conflictedAllocation.Id; 
                    unavailabilityModel.driveId = conflictedAllocation.sked__Job__r.sked_Drive__c; 
                    unavailabilityModel.conflictedJobId = unavailability.jobId;
                    unavailabilityModel.conflictedJobAllocationId = unavailability.jobAllocationId;
                    unavailabilityModel.conflictedDriveId = unavailability.driveId;
                    unavailabilityModel.status = skedConstants.EXCEPTION_LOG_STATUS_OPEN;
                    newExceptionLogs.add(getExceptionLog(unavailabilityModel));
                }

                String jobId = unavailability.jobId != null ? unavailability.jobId : conflictedAllocation.sked__Job__c;
                String jobAllocationId = unavailability.jobAllocationId != null ? unavailability.jobAllocationId : conflictedAllocation.Id;
                String driveId = unavailability.driveId != null ? unavailability.driveId : conflictedAllocation.sked__Job__r.sked_Drive__c;
                String exceptionText = unavailability.exceptionText;

                if (!string.isBlank(unavailability.exceptionText)) {
                    if(driveId != conflictedAllocation.sked__Job__r.sked_Drive__c) {
                        exceptionText = 'Conflict with ' + conflictedAllocation.sked__Job__r.sked_Drive__r.Name;
                    }
                }

                resourceUnavailabilityModel unavailabilityModel = new resourceUnavailabilityModel();
                unavailabilityModel.resourceId = conflictedAllocation.sked__Resource__c;
                unavailabilityModel.exceptionCode = skedConstants.EXCEPTION_CODE_RESOURCE_TIME_CONFLICT;
                unavailabilityModel.exceptionText = exceptionText;
                unavailabilityModel.relatedEventFieldApi = unavailability.relatedEventFieldApi;
                unavailabilityModel.recordId = unavailability.recordId;
                unavailabilityModel.jobId = jobId;
                unavailabilityModel.jobAllocationId = jobAllocationId;
                unavailabilityModel.driveId = driveId;
                unavailabilityModel.conflictedJobId = conflictedAllocation.sked__Job__c;
                unavailabilityModel.conflictedJobAllocationId = conflictedAllocation.Id;
                unavailabilityModel.conflictedDriveId = conflictedAllocation.sked__Job__r.sked_Drive__c;
                unavailabilityModel.status = skedConstants.EXCEPTION_LOG_STATUS_OPEN;
                newExceptionLogs.add(getExceptionLog(unavailabilityModel));   
            }
        }

        if (!newExceptionLogs.isEmpty()) {
            insert newExceptionLogs;
        }
        
        return newExceptionLogs;
    }

    public void captureResourceExceptionLogs(List<resourceUnavailabilityModel> unavailabilityList) {
        DateTime minDt, maxDt;
        Map<Id, List<resourceUnavailabilityModel>> resourceUnavailabilityMap = new Map<Id, List<resourceUnavailabilityModel>>();
        for (resourceUnavailabilityModel unavailability : unavailabilityList) {
            if (!resourceUnavailabilityMap.containsKey(unavailability.resourceId)) {
                resourceUnavailabilityMap.put(unavailability.resourceId, new List<resourceUnavailabilityModel>());
            }
            resourceUnavailabilityMap.get(unavailability.resourceId).add(unavailability);

            if (minDt == NULL || unavailability.startTime < minDt) {
                minDt = unavailability.startTime;
            }
            if (maxDt == NULL || unavailability.endTime > maxDt) {
                maxDt = unavailability.endTime;
            }
        }

        List<sked__Job_Allocation__c> conflictedAllocations = getConflictedAllocations(resourceUnavailabilityMap.keySet(), minDt, maxDt, null, true);
        Map<Id, List<sked__Job_Allocation__c>> resourceConflictedAllocationsMap = new Map<Id, List<sked__Job_Allocation__c>>();
        for (sked__Job_Allocation__c conflictedAllocation : conflictedAllocations) {
            if (!resourceConflictedAllocationsMap.containsKey(conflictedAllocation.sked__Resource__c)) {
                resourceConflictedAllocationsMap.put(conflictedAllocation.sked__Resource__c, new List<sked__Job_Allocation__c>());
            }
            resourceConflictedAllocationsMap.get(conflictedAllocation.sked__Resource__c).add(conflictedAllocation);
        }

        List<String> includedExceptionCodes = new List<String> {
            skedConstants.EXCEPTION_CODE_RESOURCE_IS_INACTIVE,
            skedConstants.EXCEPTION_CODE_RESOURCE_PENDING_TERMINATION
        };
        List<skedHC__Exception__c> existingExceptionLogs = [
            SELECT Id, sked_Exception_Code__c, skedHC__Resource__c, skedHC__Job_Allocation__c,
            skedHC__Job_Allocation__r.sked__Start__c, skedHC__Job_Allocation__r.sked__Set_End__c
            FROM skedHC__Exception__c
            WHERE skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN
            AND skedHC__Resource__c IN :resourceUnavailabilityMap.keySet()
            AND sked_Exception_Code__c IN :includedExceptionCodes
        ];

        Map<string, skedHC__Exception__c> mapExistingExceptionLog = new Map<string, skedHC__Exception__c>();
        List<skedHC__Exception__c> exceptionLogsToUpdate = new List<skedHC__Exception__c>();
        for (skedHC__Exception__c existingExceptionLog : existingExceptionLogs) {
            Boolean keepOpen = false;
            if (resourceUnavailabilityMap.containsKey(existingExceptionLog.skedHC__Resource__c)) {
                for (resourceUnavailabilityModel unavailability : resourceUnavailabilityMap.get(existingExceptionLog.skedHC__Resource__c)) {
                    if (unavailability.exceptionCode == existingExceptionLog.sked_Exception_Code__c &&
                        unavailability.startTime <= existingExceptionLog.skedHC__Job_Allocation__r.sked__Start__c &&
                        unavailability.endTime >= existingExceptionLog.skedHC__Job_Allocation__r.sked__Set_End__c) {
                        keepOpen = true;
                        break;
                    }
                }
            } else {
                keepOpen = true;
            }

            if (!keepOpen) {
                existingExceptionLog.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                exceptionLogsToUpdate.add(existingExceptionLog);
            } else {
                string key = existingExceptionLog.skedHC__Job_Allocation__c + ':' + existingExceptionLog.sked_Exception_Code__c;
                mapExistingExceptionLog.put(key, existingExceptionLog);	
            }
        }
        if (!exceptionLogsToUpdate.isEmpty()) {
            update exceptionLogsToUpdate;
        }

        List<skedHC__Exception__c> newExceptionLogs = new List<skedHC__Exception__c>();
        for (resourceUnavailabilityModel unavailability : unavailabilityList) {
            if (resourceConflictedAllocationsMap.containsKey(unavailability.resourceId)) {
                for (sked__Job_Allocation__c conflictedAllocation : resourceConflictedAllocationsMap.get(unavailability.resourceId)) {
                    if (unavailability.startTime <= conflictedAllocation.sked__Set_End__c && unavailability.endTime >= conflictedAllocation.sked__Start__c) {
                        string key = conflictedAllocation.Id + ':' + unavailability.exceptionCode;
                        if (!mapExistingExceptionLog.containsKey(key)) {
                            skedHC__Exception__c newExceptionLog = new skedHC__Exception__c(
                                skedHC__Job__c = conflictedAllocation.sked__Job__c,
                                sked_Conflicted_Job__c = conflictedAllocation.sked__Job__c,
                                skedHC__Job_Allocation__c = conflictedAllocation.Id,
                                sked_Conflicted_Job_Allocation__c = conflictedAllocation.Id,
                                sked_Drive__c = conflictedAllocation.sked__Job__r.sked_Drive__c,
                                sked_Conflicted_Drive__c = conflictedAllocation.sked__Job__r.sked_Drive__c,
                                skedHC__Resource__c = conflictedAllocation.sked__Resource__c,
                                sked_Exception_Code__c = unavailability.exceptionCode,
                                skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                            );
                            newExceptionLogs.add(newExceptionLog);
                            mapExistingExceptionLog.put(key, newExceptionLog);
                        }
                    }
                }
            }
        }

        if (!newExceptionLogs.isEmpty()) {
            insert newExceptionLogs;
        }
    }
    
    public void removeExceptionLogs(Set<Id> relatedRecordIds) {
        Id firstRecordId;
        for (Id relatedRecordId : relatedRecordIds) {
            firstRecordId = relatedRecordId;
            break;
        }
        string relatedObjApiName = firstRecordId.getSobjectType().getDescribe().getName();
        string relatedFieldApi;
        if (relatedObjApiName == sked__Availability__c.getSobjectType().getDescribe().getName()) {
            relatedFieldApi = 'skedHC__Availability__c';
        }
        else if (relatedObjApiName == sked__Activity__c.getSobjectType().getDescribe().getName()) {
            relatedFieldApi = 'skedHC__Activity__c';
        }
        else if (relatedObjApiName == sked__Job_Allocation__c.getSobjectType().getDescribe().getName()) {
            relatedFieldApi = 'skedHC__Job_Allocation__c';
        }
        queryModel query = new queryModel();
        skedQueryBuilder queryBuilder = query.getQueryBuilder('skedHC__Exception__c');
        string recordIdsCondition = queryBuilder.generateCondition(relatedFieldApi + ' IN {0}', relatedRecordIds);
        if (relatedObjApiName == sked__Job_Allocation__c.getSobjectType().getDescribe().getName()) {
            string subCondition1 = queryBuilder.generateCondition('skedHC__Job_Allocation__c IN {0}', relatedRecordIds);
            string subCondition2 = queryBuilder.generateCondition('sked_Conflicted_Job_Allocation__c IN {0}', relatedRecordIds);
            recordIdsCondition = '(' + subCondition1 + ' OR ' + subCondition2 + ')';
        }
        queryBuilder.addCondition(recordIdsCondition);
        queryBuilder.addCondition('skedHC__Status__c != {0}', skedConstants.EXCEPTION_LOG_STATUS_CLOSED);
        List<sObject> records = query(query);
        if (!records.isEmpty()) {
            for (sObject record : records) {
                record.put('skedHC__Status__c', skedConstants.EXCEPTION_LOG_STATUS_CLOSED);
            }
            update records;
        }
    }
    
    public void removeExceptionLogsWhenCancellingJobs(Set<Id> jobIds) {
        List<skedHC__Exception__c> skedExceptionLogs = [SELECT Id, skedHC__Status__c
                                                        FROM skedHC__Exception__c
                                                        WHERE (skedHC__Job__c IN :jobIds OR sked_Conflicted_Job__c IN :jobIds)
                                                        AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN];
        if (!skedExceptionLogs.isEmpty()) {
            for (skedHC__Exception__c skedExceptionLog : skedExceptionLogs) {
                skedExceptionLog.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
            }
            update skedExceptionLogs;
        }
    }
    
    public void captureFSWBException(Set<Id> driveIds) {
        List<string> opportunitySources = new List<string>();
        opportunitySources.add('Adhoc Calendar Build');
        opportunitySources.add('Calendar Build');

        List<sked_Drive_Shift__c> recordsToValidate = [
            SELECT Id, sked_Drive__c, sked_Start_Time__c, sked_End_Time__c, sked_Drive_Type__c, sked_Drive_Operation_Type__c, sked_Time_Block__c
            FROM sked_Drive_Shift__c
            WHERE sked_Drive__c IN :driveIds
            AND sked_Drive__r.sked_Opportunity__r.Source__c IN :opportunitySources
        ];
        System.debug('Retrieved drive shifts size: ' + recordsToValidate.size());

        if (!recordsToValidate.isEmpty()) {
            captureFSWBException(recordsToValidate);
        }
    }
    
    public void captureFSWBException(List<sked_Drive_Shift__c> driveShifts) {
        Set<Id> driveIds = new Set<Id>();
        Set<Id> assignedTimeBlockIds = new Set<Id>();
        
        for (sked_Drive_Shift__c driveShift : driveShifts) {
            driveIds.add(driveShift.sked_Drive__c);
            
            if (driveShift.sked_Time_Block__c != NULL) {
                assignedTimeBlockIds.add(driveShift.sked_Time_Block__c);
            }
        }
        
        Map<Id, sked_Drive__c> mapDrive = new Map<Id, sked_Drive__c>([
            SELECT Id, sked_Collection_Operation__c, sked_Drive_Date__c, sked_Day_of_Week__c
            FROM sked_Drive__c
            WHERE Id IN :driveIds
        ]);
        
        Map<Id, Time_Block__c> mapAssignedTimeBlock = new Map<Id, Time_Block__c>();
        if (!assignedTimeBlockIds.isEmpty()) {
            mapAssignedTimeBlock = new Map<Id, Time_Block__c>([
                SELECT Id, Start_Time__c, End_Time__c
                FROM Time_Block__c
                WHERE Id IN :assignedTimeBlockIds
            ]);
        }
        
        Date minDate, maxDate;
        Set<Id> collectionOperationIds = new Set<Id>();
        for (sked_Drive__c drive : mapDrive.values()) {
            collectionOperationIds.add(drive.sked_Collection_Operation__c);
            
            if (minDate == NULL || minDate > drive.sked_Drive_Date__c) {
                minDate = drive.sked_Drive_Date__c;
            }
            if (maxDate == NULL || maxDate < drive.sked_Drive_Date__c) {
                maxDate = drive.sked_Drive_Date__c;
            }
        }
        
        Map<Id, Biomed_Collection_Op_Center__c> mapCO = new Map<Id, Biomed_Collection_Op_Center__c>([
            SELECT Id, sked_Minimum_Drive_Start_Time__c, sked_Maximum_Drive_End_Time__c,
            (SELECT Id, Collection_Operation__c, Time_Block__c, Effective_Start_Date__c, Effective_End_Date__c,
             Time_Block__r.Days_of_Week__c, Time_Block__r.Start_Time__c, Time_Block__r.End_Time__c
             FROM Collection_Operation_Time_Blocks__r
             WHERE Effective_Start_Date__c <= :maxDate
             AND Effective_End_Date__c >= :minDate)
            FROM Biomed_Collection_Op_Center__c
            WHERE Id IN :collectionOperationIds
        ]);
        
        Map<string, skedHC__Exception__c> mapActiveException = new Map<string, skedHC__Exception__c>();
        for (sked_Drive_Shift__c driveShift : driveShifts) {
            sked_Drive__c drive = mapDrive.get(driveShift.sked_Drive__c);
            Biomed_Collection_Op_Center__c collectionOperation = mapCO.get(drive.sked_Collection_Operation__c);
            
            List<Collection_Operation_Time_Block__c> usedCOTBs = new List<Collection_Operation_Time_Block__c>();
            
            List<Collection_Operation_Time_Block__c> qualifiedCOTBs = new List<Collection_Operation_Time_Block__c>();
            for (Collection_Operation_Time_Block__c coTB : collectionOperation.Collection_Operation_Time_Blocks__r) {
                boolean isWeekdayMatched = coTB.Time_Block__r.Days_of_Week__c.contains(drive.sked_Day_of_Week__c);
                boolean isEffective = coTB.Effective_Start_Date__c <= drive.sked_Drive_Date__c && drive.sked_Drive_Date__c <= coTB.Effective_End_Date__c;
                boolean isShiftTimeMatched = driveShift.sked_Start_Time__c >= coTB.Time_Block__r.Start_Time__c && driveShift.sked_End_Time__c <= coTB.Time_Block__r.End_Time__c;
                
                if (isEffective && isWeekdayMatched && isShiftTimeMatched) {
                    qualifiedCOTBs.add(coTB);
                }
                if (isEffective && isWeekdayMatched) {
                    usedCOTBs.add(coTB);
                }
            }
            
            string exceptionCode;
            if (!usedCOTBs.isEmpty()) {
                if (driveShift.sked_Time_Block__c == NULL) {
                    exceptionCode = qualifiedCOTBs.size() > 1 ? skedConstants.EXCEPTION_CODE_FITS_MULTIPLE_TIME_BLOCKS : skedConstants.EXCEPTION_CODE_MISSING_TIME_BLOCK;
                }
                else {
                    Time_Block__c assignedTimeBlock = mapAssignedTimeBlock.get(driveShift.sked_Time_Block__c);
                    boolean isShiftTimeMatched = driveShift.sked_Start_Time__c >= assignedTimeBlock.Start_Time__c 
                        && driveShift.sked_End_Time__c <= assignedTimeBlock.End_Time__c; 
                    if (!isShiftTimeMatched) {
                        exceptionCode = skedConstants.EXCEPTION_CODE_OUT_OF_TIME_BLOCK;
                    }
                }
            }
            else {
                if (collectionOperation.sked_Minimum_Drive_Start_Time__c != NULL && collectionOperation.sked_Maximum_Drive_End_Time__c != NULL) {
                    boolean isShiftTimeMatched = driveShift.sked_Start_Time__c >= collectionOperation.sked_Minimum_Drive_Start_Time__c 
                        && driveShift.sked_End_Time__c <= collectionOperation.sked_Maximum_Drive_End_Time__c; 
                    if (!isShiftTimeMatched) {
                        exceptionCode = skedConstants.EXCEPTION_CODE_OUT_OF_OPERATIONAL_HOURS;
                    }
                }
            }
            
            if (!string.isBlank(exceptionCode)) {
                skedHC__Exception__c activeException = new skedHC__Exception__c(
                    sked_Drive__c = driveShift.sked_Drive__c,
                    sked_Drive_Shift__c = driveShift.Id,
                    sked_Exception_Code__c = exceptionCode,
                    skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                );
                string key = activeException.sked_Drive_Shift__c + ':' + activeException.sked_Exception_Code__c;
                mapActiveException.put(key, activeException);
            }
        }
        
        upsertTimeBlockExceptionLog(driveShifts, mapActiveException);
    }
    
    public void captureAPExceptionLogs(List<sked__Activity_Resource__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        Map<Id, skedModels.resource> mapResource = new Map<Id, skedModels.resource>();
        DateTime minStart;
        DateTime maxEnd;
        Set<Date> inputDates = new Set<Date>();
        
        for (sked__Activity_Resource__c newRecord : newRecords) {
            resourceIds.add(newRecord.sked__Resource__c);
        }
        
        Map<Id, sked__Resource__c> mapSkedResource = new Map<Id, sked__Resource__c>([
            SELECT Id, sked__Primary_Region__r.sked__Timezone__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
        
        for (sked__Activity_Resource__c newRecord : newRecords) {
            sked__Resource__c skedResource = mapSkedResource.get(newRecord.sked__Resource__c);
            
            skedModels.resource resource = new skedModels.resource();
            resource.id = skedResource.Id;
            resource.timezoneSidId = skedResource.sked__Primary_Region__r.sked__Timezone__c;
            
            mapResource.put(resource.id, resource);
            
            if (minStart == NULL || minStart > newRecord.sked_Start1__c) {
                minStart = newRecord.sked_Start1__c;
            }
            if (maxEnd == NULL || maxEnd < newRecord.sked_End__c) {
                maxEnd = newRecord.sked_End__c;
            }
            
            inputDates.add(newRecord.sked_Start_Date__c);
            inputDates.add(newRecord.sked_End_Date__c);
        }
        
        if (minStart != NULL && maxEnd != NULL) {
            List<skedHC__Exception__c> exceptionLog = new List<skedHC__Exception__c>();
            
            DateTime startTime = skedDateTimeUtils.getStartOfDate(minStart, UserInfo.getTimeZone().getID());
            DateTime endTime = skedDateTimeUtils.getEndOfDate(maxEnd, UserInfo.getTimeZone().getID());

            skedResourceService resourceService = (skedResourceService)skedServiceFactory.instance.resolve('sked__Resource__c');
            resourceService.populateNonWorkingEvents(mapResource.values(), inputDates, startTime, endTime);
            
            for (sked__Activity_Resource__c newRecord : newRecords) {
                skedModels.resource resource = mapResource.get(newRecord.sked__Resource__c);
                string resourceTimezoneSidId = resource.timezoneSidId != NULL ? resource.timezoneSidId : UserInfo.getTimeZone().getID();
                
                boolean conflictNonWorkingTime = false;
                for (skedModels.event event : resource.availability) {
                    DateTime resourceEventStart = skedDateTimeUtils.newDateTimeInstance(event.startDate, 0, resourceTimezoneSidId);
                    if (resourceEventStart != NULL && event.startTimeInMinutes != NULL) {
                        resourceEventStart = resourceEventStart.addMinutes(event.startTimeInMinutes);
                    }
                    
                    DateTime resourceEventFinish = skedDateTimeUtils.newDateTimeInstance(event.endDate, 0, resourceTimezoneSidId);
                    if (resourceEventFinish != NULL && event.endTimeInMinutes != NULL) {
                        resourceEventFinish = resourceEventFinish.addMinutes(event.endTimeInMinutes);
                    }

                    if (resourceEventStart != NULL && resourceEventFinish != NULL) {
                        if (resourceEventStart < newRecord.sked_End__c && resourceEventFinish > newRecord.sked_Start1__c) {
                            conflictNonWorkingTime = TRUE;
                            break;
                        }
                    }
                }
                if (conflictNonWorkingTime) {
                    skedHC__Exception__c skedException = new skedHC__Exception__c (
                        skedHC__Activity__c = newRecord.sked__Activity__c,
                        //skedHC__Job_Allocation__c = newRecord.Id,
                        skedHC__Resource__c = resource.id,
                        sked_Exception_Code__c = skedConstants.EXCEPTION_CODE_ACTIVITY_OUTSIDE_OF_AVAILABILITY_PATTERN,
                        skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                    );
                    exceptionLog.add(skedException);
                }
            }
            
            if (!exceptionLog.isEmpty()) {
                insert exceptionLog;
            }
        }
    }
    
    private void upsertTimeBlockExceptionLog(List<sked_Drive_Shift__c> driveShifts, Map<string, skedHC__Exception__c> mapActiveException) {
        List<skedHC__Exception__c> exceptionLogToInsert = new List<skedHC__Exception__c>();
        List<skedHC__Exception__c> exceptionLogToUpdate = new List<skedHC__Exception__c>();
        
        List<string> timeBlockExceptionCodes = new List<string>();
        timeBlockExceptionCodes.add(skedConstants.EXCEPTION_CODE_MISSING_TIME_BLOCK);
        timeBlockExceptionCodes.add(skedConstants.EXCEPTION_CODE_FITS_MULTIPLE_TIME_BLOCKS);
        timeBlockExceptionCodes.add(skedConstants.EXCEPTION_CODE_OUT_OF_TIME_BLOCK);
        timeBlockExceptionCodes.add(skedConstants.EXCEPTION_CODE_OUT_OF_OPERATIONAL_HOURS);
        
        Set<string> timeBlockExceptionKeys = new Set<string>();
        for (sked_Drive_Shift__c driveShift : driveShifts) {
            for (string exceptionCode : timeBlockExceptionCodes) {
                timeBlockExceptionKeys.add(driveShift.Id + ':' + exceptionCode);
            }
        }
        List<skedHC__Exception__c> existingExceptionLog = [
            SELECT Id, sked_UniqueKey__c, sked_Drive_Shift__c, sked_Exception_Code__c
            FROM skedHC__Exception__c
            WHERE sked_UniqueKey__c IN :timeBlockExceptionKeys
            AND skedHC__Status__c = :skedConstants.EXCEPTION_LOG_STATUS_OPEN
        ];
        Map<string, skedHC__Exception__c> mapExistingException = new Map<string, skedHC__Exception__c>();
        for (skedHC__Exception__c existingException : existingExceptionLog) {
            mapExistingException.put(existingException.sked_UniqueKey__c, existingException);
            
            if (!mapActiveException.containsKey(existingException.sked_UniqueKey__c)) {
                existingException.skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_CLOSED;
                exceptionLogToUpdate.add(existingException);
            }
        }
        
        for (string key : mapActiveException.keySet()) {
            if (!mapExistingException.containsKey(key)) {
                skedHC__Exception__c activeException = mapActiveException.get(key);
                exceptionLogToInsert.add(activeException);
            }
        }
        
        if (!exceptionLogToInsert.isEmpty()) {
            insert exceptionLogToInsert;
        }
        if (!exceptionLogToUpdate.isEmpty()) {
            update exceptionLogToUpdate;
        }
    }
    
    /*********************************************************** Private methods ***********************************************************/
    private List<sked__Job_Allocation__c> getConflictedAllocations(Set<Id> resourceIds, DateTime startTime, DateTime endTime, Set<Id> excludedIds, boolean futureOnly) {
        skedQueryBuilder jobAllocationBuilder = new skedQueryBuilder();
        jobAllocationBuilder.setFromClause('sked__Job_Allocation__c');
        jobAllocationBuilder.addField('Id');
        jobAllocationBuilder.addField('Name');
        jobAllocationBuilder.addField('sked__Job__c');
        jobAllocationBuilder.addField('sked__Resource__c');
        jobAllocationBuilder.addField('sked__Start__c');
        jobAllocationBuilder.addField('sked__Set_End__c');
        jobAllocationBuilder.addField('sked__Job__r.sked__Type__c');
        jobAllocationBuilder.addField('sked__Job__r.sked_Drive__c');
        jobAllocationBuilder.addField('sked__Job__r.sked_Drive__r.Name');
        
        jobAllocationBuilder.addCondition('sked__Resource__c IN {0}', resourceIds);
        if (startTime != NULL && endTime != NULL) {
            jobAllocationBuilder.addCondition('sked__Start__c < {0}', endTime);
            jobAllocationBuilder.addCondition('sked__Set_End__c > {0}', startTime);
        }
        else if (startTime != NULL) {
            jobAllocationBuilder.addCondition('sked__Start__c >= {0}', startTime);			
        }
        if (futureOnly) {
            jobAllocationBuilder.addCondition('sked_Start_Date__c >= TODAY');
        }
        List<string> jobAllocationDeletedStatuses = new List<string>();
        jobAllocationDeletedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DELETED);
        jobAllocationDeletedStatuses.add(skedConstants.JOB_ALLOCATION_STATUS_DECLINED);
        jobAllocationBuilder.addCondition('sked__Status__c NOT IN {0}', jobAllocationDeletedStatuses);
        if (excludedIds != NULL && !excludedIds.isEmpty()) {
            jobAllocationBuilder.addCondition('Id NOT IN {0}', excludedIds);
        }
        jobAllocationBuilder.orderClause = 'ORDER BY sked__Start__c ASC';
        
        string queryString = jobAllocationBuilder.toString();
        system.debug('#queryString#' + queryString);
        return (List<sked__Job_Allocation__c>)Database.query(queryString);
    }

    private skedHC__Exception__c getExceptionLog(resourceUnavailabilityModel unavailability) {
        skedHC__Exception__c newExceptionLog = new skedHC__Exception__c(
            skedHC__Job__c = unavailability.jobId,
            sked_Conflicted_Job__c = unavailability.conflictedJobId,
            skedHC__Job_Allocation__c = unavailability.jobAllocationId,
            sked_Conflicted_Job_Allocation__c = unavailability.conflictedJobAllocationId,
            sked_Drive__c = unavailability.driveId,
            sked_Conflicted_Drive__c = unavailability.conflictedDriveId,
            skedHC__Resource__c = unavailability.resourceId,
            sked_Exception_Code__c = unavailability.exceptionCode,
            skedHC__Status__c = unavailability.status,
            skedHC__Exception__c = unavailability.exceptionText
        );
        if (!string.isBlank(unavailability.relatedEventFieldApi)) { 
            newExceptionLog.put(unavailability.relatedEventFieldApi, unavailability.recordId);
        }
        return newExceptionLog;
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    public class resourceUnavailabilityModel {
        public string resourceId;
        public string relatedEventFieldApi;
        public string recordId;
        public DateTime startTime;
        public DateTime endTime;
        public string exceptionCode;
        public string exceptionText;
        public string jobId;
        public string jobAllocationId;
        public string driveId;
        public string conflictedJobId;
        public string conflictedJobAllocationId;
        public string conflictedDriveId;
        public string status;
        public string driveName;
    }

    global class queryModel extends skedDataService.queryModelBase {}
    
}