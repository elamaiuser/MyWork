global class slwcOpportunityService {
    
    @AuraEnabled
    public static Opportunity cloneOpportunity(Id sourceOpportunityId, string newDriveDateIso, boolean cloneDrives) {
        skedTriggerUtils.CHANGES_INITIATED_FROM_SERVICE = true;
        string timezoneSidId = UserInfo.getTimeZone().getID();
        
        List<string> ignoredFields = new List<string>();
        ignoredFields.add('StageName');
        List<string> fieldsToClone = getSObjectFieldsToClone('Opportunity', ignoredFields);
        
        slwcQueryBuilder sourceRecordQueryBuilder = new slwcQueryBuilder();
        sourceRecordQueryBuilder.setFromClause('Opportunity');
        sourceRecordQueryBuilder.addFields(fieldsToClone);
        sourceRecordQueryBuilder.addCondition('Id = {0}', sourceOpportunityId);
        Opportunity sourceRecord = (Opportunity)Database.query(sourceRecordQueryBuilder.toString());
        Opportunity clonedOpportunity = new Opportunity(
        	StageName = slwcConstants.OPPORTUNITY_STAGE_NAME_PLANNING
        );
        for (string fieldToClone : fieldsToClone) {
            clonedOpportunity.put(fieldToClone, sourceRecord.get(fieldToClone));
        }
        
        integer daysDifference = 0;
        if (!string.isBlank(newDriveDateIso)) {
            Date newDriveDate = skedDateTimeUtils.getDateFromIsoString(newDriveDateIso);
            daysDifference = clonedOpportunity.Drive_Date__c.daysBetween(newDriveDate);
            clonedOpportunity.Drive_Date__c = newDriveDate;
        }
        insert clonedOpportunity;
        
        if (cloneDrives) {
            Map<Id, sObject> map_oppId_cloned = new Map<Id, sObject>();
            map_oppId_cloned.put(sourceOpportunityId, clonedOpportunity);
            List<string> ignoredDriveFields = new List<string>();
            ignoredDriveFields.add('sked_Status__c');
            ignoredDriveFields.add('sked_UFID__c');
            Map<Id, sObject> map_driveId_cloned = cloneRealtedCustomObjects('sked_Drive__c', ignoredDriveFields, map_oppId_cloned, 'sked_Opportunity__c');
            for (sObject record : map_driveId_cloned.values()) {
                sked_Drive__c clonedDrive = (sked_Drive__c)record;
				clonedDrive.sked_Status__c = slwcConstants.DRIVE_STATUS_DRAFT;
                clonedDrive.sked_Drive_Date__c = clonedDrive.sked_Drive_Date__c.addDays(daysDifference);
            }
            
            if (!map_driveId_cloned.isEmpty()) {
                insert map_driveId_cloned.values();
                
                //clone drive shifts
                List<string> ignoredDriveShiftFields = new List<string>();
                ignoredDriveShiftFields.add('sked_UFID__c');
                Map<Id, sObject> map_driveShiftId_cloned = cloneRealtedCustomObjects('sked_Drive_Shift__c', ignoredDriveShiftFields, map_driveId_cloned, 'sked_Drive__c');
                if (!map_driveShiftId_cloned.isEmpty()) {
                    for (sObject record : map_driveShiftId_cloned.values()) {
                        sked_Drive_Shift__c clonedDriveShift = (sked_Drive_Shift__c)record;
                        clonedDriveShift.sked_Start__c = skedDateTimeUtils.addDays(clonedDriveShift.sked_Start__c, daysDifference, timezoneSidId);
                        clonedDriveShift.sked_Finish__c = skedDateTimeUtils.addDays(clonedDriveShift.sked_Finish__c, daysDifference, timezoneSidId);
                    }
                    insert map_driveShiftId_cloned.values();
                    
                    //clone jobs
                    List<string> ignoredJobFields = new List<string>();
                    Map<Id, sObject> map_jobId_cloned = cloneRealtedCustomObjects('sked__Job__c', ignoredJobFields, map_driveShiftId_cloned, 'sked_Drive_Shift__c');
                    if (!map_jobId_cloned.isEmpty()) {
                        for (sObject record : map_jobId_cloned.values()) {
                            sked__Job__c clonedJob = (sked__Job__c)record;
                            clonedJob.sked__Job_Status__c = slwcConstants.JOB_STATUS_PENDING_ALLOCATION;
                            clonedJob.sked__Start__c = skedDateTimeUtils.addDays(clonedJob.sked__Start__c, daysDifference, timezoneSidId);
                            clonedJob.sked__Finish__c = skedDateTimeUtils.addDays(clonedJob.sked__Finish__c, daysDifference, timezoneSidId);
                        }
                        insert map_jobId_cloned.values();
                    }
                        
                    List<string> ignoredSlotFields = new List<string>();
                    Map<Id, sObject> map_slotId_cloned = cloneRealtedCustomObjects('sked__Slot__c', ignoredSlotFields, map_driveShiftId_cloned, 'sked_Drive_Shift__c');
                    if (!map_slotId_cloned.isEmpty()) {
                        for (sObject record : map_slotId_cloned.values()) {
                            sked__Slot__c clonedSlot = (sked__Slot__c)record;
                            clonedSlot.sked_Status__c = slwcConstants.SLOT_STATUS_OPEN;
                            clonedSlot.sked_Start__c  = skedDateTimeUtils.addDays(clonedSlot.sked_Start__c , daysDifference, timezoneSidId);
                            clonedSlot.sked_End__c  = skedDateTimeUtils.addDays(clonedSlot.sked_End__c , daysDifference, timezoneSidId);
                        }
                        insert map_slotId_cloned.values();
                    }
                }
            }
        }
        
        return clonedOpportunity;
    }
    
    private static Map<Id, sObject> cloneRealtedCustomObjects(string sObjectName, List<string> ignoredFields, Map<Id, sObject> map_parentId_cloned, string parentField) {
        List<string> fieldsToClone = getSObjectFieldsToClone(sObjectName, ignoredFields);
        skedQueryBuilder sourceRecordQueryBuilder = new skedQueryBuilder();
        sourceRecordQueryBuilder.setFromClause(sObjectName);
        sourceRecordQueryBuilder.addFields(fieldsToClone);
        sourceRecordQueryBuilder.addCondition(parentField + ' IN {0}', map_parentId_cloned.keySet());
        system.debug('#sourceRecordQueryBuilder.toString()#' + sourceRecordQueryBuilder.toString());
        List<sObject> sourceRecords = (List<sObject>)Database.query(sourceRecordQueryBuilder.toString());
        Map<Id, sObject> map_sourceId_clonedRecord = new Map<Id, sObject>();
        for (sObject sourceRecord : sourceRecords) {
            sObject clonedRecord = sourceRecord.clone();
            Id sourceRecordParentId = (Id)sourceRecord.get(parentField);
            sObject clonedParent = map_parentId_cloned.get(sourceRecordParentId);
            clonedRecord.put(parentField, clonedParent.Id);
            map_sourceId_clonedRecord.put(sourceRecord.Id, clonedRecord);
        }
        return map_sourceId_clonedRecord;
    }
    
    private static List<string> getSObjectFieldsToClone(string sObjectName, List<string> ignoredFields) {
        ignoredFields.add('Id');
        List<string> fieldsToClone = new List<string>();
        SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);
        Map<String, Schema.SObjectField> mapSObjectField = sObjectType.getDescribe().fields.getMap();
        
        for (Schema.SObjectField sObjectField : mapSObjectField.values()) {
            DescribeFieldResult sObjectFieldResult = sObjectField.getDescribe();
            if (!sObjectFieldResult.isCreateable() || sObjectFieldResult.isAutoNumber()) {
                continue;   
            }
            string apiName = sObjectFieldResult.getName();
            Schema.DisplayType dataType = sObjectFieldResult.getType();
            if (dataType == Schema.DisplayType.LOCATION) {
                string latitudeField = apiName.replace('__c', '__latitude__s');
                string longitudeField = apiName.replace('__c', '__longitude__s');
                fieldsToClone.add(latitudeField);
                fieldsToClone.add(longitudeField);
            }
            else if (!ignoredFields.contains(apiName)) {
                fieldsToClone.add(apiName);
            }
        }
        return fieldsToClone;
    }

}