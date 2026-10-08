public class skedDriveChangeRequestItemHandler extends skedTriggerHub {
    
    public override void onBeforeInsert() {
        populateData(this.context.newRecords);
        populateDisplayValue(this.context.newRecords);
    }
    
    public override void onBeforeUpdate() {
        populateDisplayValue(this.context.newRecords, (Map<Id, sked_Drive_Change_Request_Item__c>)this.context.oldMap);
    }

    public override void onAfterDelete() {
        deleteEmptyDcr(this.context.oldRecords);
    }
    
    /*********************************************************** Privated Methods ***********************************************************/
    private void deleteEmptyDcr(List<sked_Drive_Change_Request_Item__c> oldRecords) {
        Set<Id> deletedDcrIds = new Set<Id>();
        for (sked_Drive_Change_Request_Item__c oldRecord : oldRecords) {
            deletedDcrIds.add(oldRecord.Id);
        }
        List<sked_Drive_Change_Request__c> dcrs = [SELECT Id,
                                                  (SELECT Id
                                                   FROM sked_Drive_Change_Request_Items__r
                                                   LIMIT 1)
                                                   FROM sked_Drive_Change_Request__c
                                                   WHERE Id IN :deletedDcrIds];
		List<sked_Drive_Change_Request__c> dcrsToDelete = new List<sked_Drive_Change_Request__c>();
        for (sked_Drive_Change_Request__c dcr : dcrs) {
            if (dcr.sked_Drive_Change_Request_Items__r == NULL || dcr.sked_Drive_Change_Request_Items__r.isEmpty()) {
                dcrsToDelete.add(dcr);
            }
        }
        if (!dcrsToDelete.isEmpty()) {
            delete dcrsToDelete;
        }
    }
    
    private void populateData(List<sked_Drive_Change_Request_Item__c> newRecords) {
        Set<string> hiddenFields = new Set<string>();
        hiddenFields.add('Parent_Template_Id__c');
        hiddenFields.add('sked_Site_Collection_Operation__c');
        
        for (sked_Drive_Change_Request_Item__c newRecord : newRecords) {
            newRecord.sked_Is_Hidden__c = hiddenFields.contains(newRecord.sked_Field_API_Name__c);
        }
    }
    
    private void populateDisplayValue(List<sked_Drive_Change_Request_Item__c> newRecords, Map<Id, sked_Drive_Change_Request_Item__c> oldMap) {
        List<sked_Drive_Change_Request_Item__c> recordsToPopulate = new List<sked_Drive_Change_Request_Item__c>();
        for (sked_Drive_Change_Request_Item__c newRecord : newRecords) {
            sked_Drive_Change_Request_Item__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_New_Value__c != oldData.sked_New_Value__c || newRecord.sked_Old_Value__c != oldData.sked_Old_Value__c) {
                recordsToPopulate.add(newRecord);
            }
        }
        if (!recordsToPopulate.isEmpty()) {
            populateDisplayValue(recordsToPopulate);
        }
    }
    
    private void populateDisplayValue(List<sked_Drive_Change_Request_Item__c> newRecords) {
        Set<Id> siteIds = new Set<Id>();
        for (sked_Drive_Change_Request_Item__c newRecord : newRecords) {
            if (newRecord.sked_Field_API_Name__c == 'Drive_Site__c' || newRecord.sked_Field_API_Name__c == 'sked_Drive_Site__c') {
                siteIds.add(newRecord.sked_New_Value__c);
                siteIds.add(newRecord.sked_Old_Value__c);
            }
        }
        Map<Id, sked__Location__c> mapSite = new Map<Id, sked__Location__c>();
        if (!siteIds.isEmpty()) {
            mapSite = new Map<Id, sked__Location__c>([SELECT Id, Name
                                                      FROM sked__Location__c
                                                      WHERE Id IN :siteIds]);
        }
        
        for (sked_Drive_Change_Request_Item__c newRecord : newRecords) {
            if (newRecord.sked_Field_API_Name__c == 'sked_Collection_Operation__c') continue;
            if (newRecord.sked_Field_API_Name__c == 'Drive_Site__c' || newRecord.sked_Field_API_Name__c == 'sked_Drive_Site__c') {
                if (mapSite.containsKey(newRecord.sked_New_Value__c)) {
                    sked__Location__c skedSite = mapSite.get(newRecord.sked_New_Value__c);
                    newRecord.sked_New_Value_Display__c = skedSite.Name;
                }
                if (mapSite.containsKey(newRecord.sked_Old_Value__c)) {
                    sked__Location__c skedSite = mapSite.get(newRecord.sked_Old_Value__c);
                    newRecord.sked_Old_Value_Display__c = skedSite.Name;
                }
            }
            else {
                newRecord.sked_New_Value_Display__c = skedUtils.formatFieldValue(newRecord.sked_New_Value__c, newRecord.sked_Field_Type__c);
                newRecord.sked_Old_Value_Display__c = skedUtils.formatFieldValue(newRecord.sked_Old_Value__c, newRecord.sked_Field_Type__c);
            }
        }
    }

}