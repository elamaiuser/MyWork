public class skedDriveDeliveryJobHandler extends skedTriggerHub {
	
    public override void onBeforeInsert() {
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords);
        }
    }
    
    public override void onBeforeUpdate() {
        if (skedSetting.instance.Admin.dateTimeConversion) {
            doDateTimeConversion(this.context.newRecords, (Map<Id, sked_Drive_Delivery_Job__c>)this.context.oldMap);
        }
    }
    
    /************************************************** Privated Methods ***************************************************/
    private void doDateTimeConversion(List<sked_Drive_Delivery_Job__c> newRecords) {
        for (sked_Drive_Delivery_Job__c newRecord : newRecords) {
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Arrive__c', 'sked_Arrive_Date__c', 'sked_Arrive_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Pick_Up__c', 'sked_Pick_Up_Date__c', 'sked_Pick_Up_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, 'sked_Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
        }
    }

    private void doDateTimeConversion(List<sked_Drive_Delivery_Job__c> newRecords, Map<Id, sked_Drive_Delivery_Job__c> oldMap) {
        for (sked_Drive_Delivery_Job__c newRecord : newRecords) {
            sked_Drive_Delivery_Job__c oldData = oldMap.get(newRecord.Id);
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Arrive__c', 'sked_Arrive_Date__c', 'sked_Arrive_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_End__c', 'sked_End_Date__c', 'sked_End_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Pick_Up__c', 'sked_Pick_Up_Date__c', 'sked_Pick_Up_Time__c', 'sked_Timezone__c');
            skedTriggerUtils.maintainDateTimeField(newRecord, oldData, 'sked_Start__c', 'sked_Start_Date__c', 'sked_Start_Time__c', 'sked_Timezone__c');
        }
    }
    
}