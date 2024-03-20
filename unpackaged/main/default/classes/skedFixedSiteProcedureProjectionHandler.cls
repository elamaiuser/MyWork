public class skedFixedSiteProcedureProjectionHandler extends skedTriggerHub {

    public override void onBeforeUpdate() {
        populateData(this.context.newRecords, (Map<Id, sked_Fixed_Site_Procedure_Projection__c>)this.context.oldMap);
    }
    
    /*********************************************************** Nested classes ***********************************************************/
    private void populateData(List<sked_Fixed_Site_Procedure_Projection__c> newRecords, Map<Id, sked_Fixed_Site_Procedure_Projection__c> oldMap) {
        for (sked_Fixed_Site_Procedure_Projection__c newRecord : newRecords) {
            sked_Fixed_Site_Procedure_Projection__c oldData = oldMap.get(newRecord.Id);
            if (newRecord.sked_Deferral__c != oldData.sked_Deferral__c 
                || newRecord.sked_QNS__c != oldData.sked_QNS__c
                || newRecord.sked_Productive_Procedure_Goal__c != oldData.sked_Productive_Procedure_Goal__c) {
                newRecord.sked_Impact_Drives__c = TRUE;
            }
        }
    }
    
}