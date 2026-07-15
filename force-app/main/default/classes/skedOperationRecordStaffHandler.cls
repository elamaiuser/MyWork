public class skedOperationRecordStaffHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
        applyWorkdayIgnoreForVolunteers(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        applyWorkdayIgnoreForVolunteers(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked_Operation_Record_Staff__c>)this.context.oldMap);
            populateData(this.context.newRecords, (Map<Id, sked_Operation_Record_Staff__c>)this.context.oldMap);
        }
    }
    
    public override void onBeforeDelete() {
       deleteRelatedStaffAndMealBreakRecords((Map<Id, sked_Operation_Record_Staff__c>)this.context.oldMap);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/

    /**
     * Volunteers (Resource Category) are not submitted to Workday — stamp staff status Ignore.
     */
    private void applyWorkdayIgnoreForVolunteers(List<sked_Operation_Record_Staff__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }
        Set<Id> resourceIds = new Set<Id>();
        for (sked_Operation_Record_Staff__c staff : newRecords) {
            if (staff.sked_Resource__c != null) {
                resourceIds.add(staff.sked_Resource__c);
            }
        }
        if (resourceIds.isEmpty()) {
            return;
        }
        Map<Id, sked__Resource__c> resourceById = new Map<Id, sked__Resource__c>([
            SELECT Id, sked__Category__c
            FROM sked__Resource__c
            WHERE Id IN :resourceIds
        ]);
        for (sked_Operation_Record_Staff__c staff : newRecords) {
            sked__Resource__c resource = resourceById.get(staff.sked_Resource__c);
            if (resource != null
                && resource.sked__Category__c == BSF_WorkdayDirectSubmissionConfig.RESOURCE_CATEGORY_VOLUNTEER) {
                staff.sked_Workday_Submission_Status__c = BSF_WorkdayDirectSubmissionConfig.STAFF_STATUS_IGNORE;
            }
        }
    }

	private void doDateTimeConversion(List<sked_Operation_Record_Staff__c> newRecords) {
        for (sked_Operation_Record_Staff__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Actual_Shift_Start__c', 'sked_Actual_Shift_Start_Date__c', 'sked_Actual_Shift_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Actual_Shift_End__c', 'sked_Actual_Shift_End_Date__c', 'sked_Actual_Shift_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Early_Departure_DateTime_Received__c', 'sked_Early_Departure_Date_Received__c', 'sked_Early_Departure_Time_Received__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Late_Arrival_DateTime_Received__c', 'sked_Late_Arrival_Date_Received__c', 'sked_Late_Arrival_Time_Received__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'Scheduled_Shift_Start__c', 'Scheduled_Shift_Start_Date__c', 'Scheduled_Shift_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'Scheduled_Shift_End__c', 'Scheduled_Shift_End_Date__c', 'Scheduled_Shift_End_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked_Operation_Record_Staff__c> newRecords, Map<Id, sked_Operation_Record_Staff__c> oldMap) {
        for (sked_Operation_Record_Staff__c newRecord : newRecords) {
            sked_Operation_Record_Staff__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Actual_Shift_Start__c', 'sked_Actual_Shift_Start_Date__c', 'sked_Actual_Shift_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Actual_Shift_End__c', 'sked_Actual_Shift_End_Date__c', 'sked_Actual_Shift_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Early_Departure_DateTime_Received__c', 'sked_Early_Departure_Date_Received__c', 'sked_Early_Departure_Time_Received__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Late_Arrival_DateTime_Received__c', 'sked_Late_Arrival_Date_Received__c', 'sked_Late_Arrival_Time_Received__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'Scheduled_Shift_Start__c', 'Scheduled_Shift_Start_Date__c', 'Scheduled_Shift_Start_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'Scheduled_Shift_End__c', 'Scheduled_Shift_End_Date__c', 'Scheduled_Shift_End_Time__c', 'sked_Timezone__c');
        }
    }

    private void populateData(List<sked_Operation_Record_Staff__c> newRecords) {
        Set<Id> jobAllocationIds = new Set<Id>();
        for (sked_Operation_Record_Staff__c opRecordStaff : newRecords) {
            jobAllocationIds.add(opRecordStaff.sked_Job_Allocation__c);
        }

        Map<Id, sked__Job_Allocation__c> jobAllocationsById = new Map<Id, sked__Job_Allocation__c>([
            SELECT Id, sked_CDL__c, sked_DOT__c, sked__Start__c, sked__End1__c,
            sked_Start_Date__c, sked_Start_Time__c, sked_Set_End_Date__c, sked_Set_End_Time__c
            FROM sked__Job_Allocation__c
            WHERE Id IN :jobAllocationIds
        ]);

        for (sked_Operation_Record_Staff__c newRecord : newRecords) {
            sked__Job_Allocation__c jobAllocation = jobAllocationsById.get(newRecord.sked_Job_Allocation__c);
            if(jobAllocation != NULL) {
                newRecord.Scheduled_Shift_Start_Date__c = jobAllocation.sked_Start_Date__c;
                newRecord.Scheduled_Shift_Start_Time__c = jobAllocation.sked_Start_Time__c;
                newRecord.Scheduled_Shift_End_Date__c = jobAllocation.sked_Set_End_Date__c;
                newRecord.Scheduled_Shift_End_Time__c = jobAllocation.sked_Set_End_Time__c;
            }
            if (newRecord.sked_Role__c != NULL && newRecord.sked_Actual_Roles__c == NULL) {
                List<String> roles = newRecord.sked_Role__c.split(',');
                List<String> newRolesStr = new List<String>();
                for (String role : roles) {
                    if (role == skedConstants.JOB_RESOURCE_ROLE_DRIVER) {
                        if (jobAllocation.sked_CDL__c) {
                            newRolesStr.add('Driver CDL B');
                        } else if (jobAllocation.sked_DOT__c) {
                            newRolesStr.add('Driver - DOT');
                        } else {
                            newRolesStr.add('Driver');
                        }
                    } else {
                        newRolesStr.add(role);
                    }
                }
                newRecord.sked_Actual_Roles__c = string.join(newRolesStr, ';');
            }
        }
    }
    
    private void deleteRelatedStaffAndMealBreakRecords(Map<Id, sked_Operation_Record_Staff__c> oldRecordsMap) {
        List<sked_Staff_Meal_Rest_Break_Setting__c> existingBreakTimeRecords = new List<sked_Staff_Meal_Rest_Break_Setting__c>();
        if(!oldRecordsMap.keyset().isEmpty()) {
            existingBreakTimeRecords = [SELECT Id FROM sked_Staff_Meal_Rest_Break_Setting__c WHERE sked_Operation_Record_Staff__c IN :oldRecordsMap.keySet()];
            if(!existingBreakTimeRecords.isEmpty()) {
                delete existingBreakTimeRecords;
            }
        }
    }
    
    private void populateData(List<sked_Operation_Record_Staff__c> newRecords, Map<Id, sked_Operation_Record_Staff__c> oldMap) {
        for (sked_Operation_Record_Staff__c newRecord : newRecords) {
            if(newRecords != NULL && oldMap != NULL) {
                sked_Operation_Record_Staff__c oldData = oldMap.get(newRecord.Id);
                if((newRecord.sked_Actual_Shift_Start_Time__c != NULL && newRecord.sked_Actual_Shift_End_Time__c != NULL) && (oldData.sked_Actual_Shift_Start_Time__c != newRecord.sked_Actual_Shift_Start_Time__c || oldData.sked_Actual_Shift_End_Time__c != newRecord.sked_Actual_Shift_End_Time__c)) {
                    compareAndPopulateMealAndRestBreaksRelatedData(new Set<Id>{oldData.sked_Operation_Record__c}, newRecords);
                }
            }
        }
    }
    
    private static void compareAndPopulateMealAndRestBreaksRelatedData(Set<Id> OpRecIds, List<sked_Operation_Record_Staff__c> newRecords) {
        Integer calculateInterval;
        Boolean isTimeDiffGreaterThanStartingRange;
        Boolean isTimeDiffLesserThanEndingRange;
        String StateCode;
        Set<String> stateCodeSet = new Set<String>();
        Map<String,List<Operation_Meals_And_Rest_Calculation__mdt>> map_stateCode_mealAndRestBreakmetadata = new Map<String,List<Operation_Meals_And_Rest_Calculation__mdt>>();
        List<Operation_Meals_And_Rest_Calculation__mdt> getMealAndRestCalcuationList = new List<Operation_Meals_And_Rest_Calculation__mdt>();
        Map<Id,sked_Operation_Record__c> getOpRecords = new Map<Id,sked_Operation_Record__c>();
        
       	getOpRecords = new Map<Id,sked_Operation_Record__c>([SELECT Id,sked_Drive_Site__r.sked_State__c FROM sked_Operation_Record__c WHERE Id IN :OpRecIds]);
        for(sked_Operation_Record__c getOpRecord : getOpRecords.values()) {
            stateCodeSet.add(getOpRecord.sked_Drive_Site__r.sked_State__c);
        }
       getMealAndRestCalcuationList = Operation_Meals_And_Rest_Calculation__mdt.getAll().values();
        
        for(Operation_Meals_And_Rest_Calculation__mdt getMetadataInfo: getMealAndRestCalcuationList) {
            if(stateCodeSet.contains(getMetadataInfo.StateCode__c)){
                if(!map_stateCode_mealAndRestBreakmetadata.containsKey(getMetadataInfo.StateCode__c)) {
                   map_stateCode_mealAndRestBreakmetadata.put(getMetadataInfo.StateCode__c, new List<Operation_Meals_And_Rest_Calculation__mdt>());
                    }
                map_stateCode_mealAndRestBreakmetadata.get(getMetadataInfo.StateCode__c).add(getMetadataInfo);
            }
        }
        for(sked_Operation_Record_Staff__c updateOpRecStaff: newRecords) {
            sked_Operation_Record__c getOpRecordStateCode = getOpRecords.get(updateOpRecStaff.sked_Operation_Record__c);
            StateCode = getOpRecordStateCode.sked_Drive_Site__r.sked_State__c;
            if(updateOpRecStaff.sked_Actual_Shift_Start__c != NULL && updateOpRecStaff.sked_Actual_Shift_End__c != NULL) {
                calculateInterval = skedDateTimeUtils.getDifferentMinutes(updateOpRecStaff.sked_Actual_Shift_Start__c, updateOpRecStaff.sked_Actual_Shift_End__c);
            }
            if(calculateInterval != NULL && map_stateCode_mealAndRestBreakmetadata.get(StateCode) != NULL) { 
                for(Operation_Meals_And_Rest_Calculation__mdt populateMetadataonRecord: map_stateCode_mealAndRestBreakmetadata.get(StateCode)) {
                    isTimeDiffGreaterThanStartingRange = calculateInterval >= skedDateTimeUtils.convertTimeStrToMinutes(populateMetadataonRecord.Starting_Hour__c);
                    isTimeDiffLesserThanEndingRange = calculateInterval <= skedDateTimeUtils.convertTimeStrToMinutes(populateMetadataonRecord.Ending_Hour__c);
                    if((populateMetadataonRecord.Break_Type__c).contains(skedConstants.OP_RECORD_STAFF_BREAK_TYPE_REST) && isTimeDiffGreaterThanStartingRange && isTimeDiffLesserThanEndingRange) {
                        updateOpRecStaff.sked_Rest_Breaks_Earned__c = populateMetadataonRecord.Breaks_Required__c;
                    }
                    if((populateMetadataonRecord.Break_Type__c).contains(skedConstants.OP_RECORD_STAFF_BREAK_TYPE_MEAL) && isTimeDiffGreaterThanStartingRange && isTimeDiffLesserThanEndingRange) {
                        updateOpRecStaff.sked_Meal_Breaks_Earned__c = populateMetadataonRecord.Breaks_Required__c;
                    }
                }
            }
        }
    }
}