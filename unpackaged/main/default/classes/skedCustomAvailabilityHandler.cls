public class skedCustomAvailabilityHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked_Custom_Availability__c>)this.context.oldMap);
        }
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void populateData(List<sked_Custom_Availability__c> newRecords) {
        Set<Id> resourceIds = new Set<Id>();
        for (sked_Custom_Availability__c newRecord : newRecords) {
            if (!string.isBlank(newRecord.sked_Resource__c)) {
                resourceIds.add(newRecord.sked_Resource__c);
            }
        }
        Map<Id, sked__Resource__c> mapResource = new Map<Id, sked__Resource__c>([SELECT Id, sked__Primary_Region__c, sked__Primary_Region__r.sked__Timezone__c
                                                                                 FROM sked__Resource__c
                                                                                 WHERE Id IN :resourceIds]);
        for (sked_Custom_Availability__c newRecord : newRecords) {
            string timezoneSidId = UserInfo.getTimeZone().getID();
            sked__Resource__c resource = mapResource.get(newRecord.sked_Resource__c);
            if (resource != NULL && resource.sked__Primary_Region__r != NULL) {
            	timezoneSidId = resource.sked__Primary_Region__r.sked__Timezone__c;
            }
            newRecord.sked_Timezone__c = timezoneSidId;
        }
    }

    private void doDateTimeConversion(List<sked_Custom_Availability__c> newRecords) {
        for (sked_Custom_Availability__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Finish__c', 'sked_Finish_Date__c', 'sked_Finish_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
        }
    }
    
    private void doDateTimeConversion(List<sked_Custom_Availability__c> newRecords, Map<Id, sked_Custom_Availability__c> updatedRecords) {
        for (sked_Custom_Availability__c newRecord : newRecords) {
            sked_Custom_Availability__c oldData = updatedRecords.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Finish__c', 'sked_Finish_Date__c', 'sked_Finish_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
        }
    }

}