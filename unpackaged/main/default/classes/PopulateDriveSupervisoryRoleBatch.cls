/**
 * @description: This batch class is used to populate Drive Lead / Charge (Supervisory Role) on Drive..
 * @createdby: Raktim Ghosal 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * ***********************************************************************************************************************************************
 *  4/25/2024                Raktim Ghosal            Populate Drive Lead / Charge (Supervisory Role) on Drive. (HRP-12493)
 *************************************************************************************************************************************************
**/
public class PopulateDriveSupervisoryRoleBatch implements Database.Batchable<sObject>{
    DateTime startDate;
    DateTime endDate;

    public PopulateDriveSupervisoryRoleBatch(Date sDate, Date edate){
        this.startDate = DateTime.newInstance(sDate.year(),sDate.month(),sDate.day());
        this.endDate = DateTime.newInstance(edate.year(),edate.month(),edate.day());
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Supervisory_Role__c FROM sked_Drive__c WHERE'+
                                        ' sked_Drive_Date__c >= '+this.startDate.format('yyyy-MM-dd')+
                                        ' AND sked_Drive_Date__c <= '+this.endDate.format('yyyy-MM-dd'));
    }

    public void execute(Database.BatchableContext bc, List<sked_Drive__c> scope) {
        TriggerHandler.bypass('DriveTriggerHandler');
        skedHubBase.BypassUpdateTriggers = true;
        DriveTriggerService.populateDriveSupervisoryRole((new Map<Id,sked_Drive__c>(scope)).keySet());
    }

    public void finish(Database.BatchableContext bc) {}
}