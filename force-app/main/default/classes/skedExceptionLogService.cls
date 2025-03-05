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
            
            if (unavailability.relatedEventFieldApi == 'skedHC__Job_Allocation__c') {
                excludedIds.add(unavailability.recordId);
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
                if (conflictedAllocation.sked__Resource__c != unavailability.resourceId
                    || conflictedAllocation.sked__Set_End__c < unavailability.startTime) {
                        continue;
                    }
                if (unavailability.endTime != NULL && unavailability.endTime <= conflictedAllocation.sked__Start__c) {
                    break;
                }
                string key = conflictedAllocation.Id + ':' + unavailability.exceptionCode;
                if (mapExistingExceptionLog.containsKey(key)) {
                    continue;
                }

                String jobId = unavailability.jobId != null ? unavailability.jobId : conflictedAllocation.sked__Job__c;
                String jobAllocationId = unavailability.jobAllocationId != null ? unavailability.jobAllocationId : conflictedAllocation.Id;
                String driveId = unavailability.driveId != null ? unavailability.driveId : conflictedAllocation.sked__Job__r.sked_Drive__c;
                
                skedHC__Exception__c newExceptionLog = new skedHC__Exception__c(
                    skedHC__Job__c = jobId,
                    sked_Conflicted_Job__c = conflictedAllocation.sked__Job__c,
                    skedHC__Job_Allocation__c = jobAllocationId,
                    sked_Conflicted_Job_Allocation__c = conflictedAllocation.Id,
                    sked_Drive__c = driveId,
                    sked_Conflicted_Drive__c = conflictedAllocation.sked__Job__r.sked_Drive__c,
                    skedHC__Resource__c = conflictedAllocation.sked__Resource__c,
                    sked_Exception_Code__c = unavailability.exceptionCode,
                    skedHC__Status__c = skedConstants.EXCEPTION_LOG_STATUS_OPEN
                );
                if (!string.isBlank(unavailability.exceptionText)) {
                    newExceptionLog.skedHC__Exception__c = unavailability.exceptionText.contains('Conflict') ? unavailability.exceptionText: ('Conflict With '+conflictedAllocation.name);
                }

                if (!string.isBlank(unavailability.relatedEventFieldApi)) { 
                    newExceptionLog.put(unavailability.relatedEventFieldApi, unavailability.recordId);
                }
                newExceptionLogs.add(newExceptionLog);
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
    }

    global class queryModel extends skedDataService.queryModelBase {}
    
}