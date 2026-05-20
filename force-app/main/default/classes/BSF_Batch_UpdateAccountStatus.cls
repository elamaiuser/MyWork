/* 
 * Modification Log 
 * Date					     Developer Name			     Comments
 * **********************************************************************************************************************************************************************************
 * 5/6/2026                  Souvik Mukherjee           Logic for HRP-17050 (Exclding fixed site accounts from automated status changes) 
 ************************************************************************************************************************************************************************************
*/
global class BSF_Batch_UpdateAccountStatus implements Database.Batchable<sObject>
{
    public DateTime startDt;
    public DateTime endDt;
    public DateTime nextStartDt;
	
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        String acctStatus=BSF_Constants.acctStatus;
        endDt = System.Now();
        startDt = System.Now().addHours(-1);
        //Start - Added for HRP-17050 
        Id mobileAccRecTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByName()
            .get(BSF_Constants.MOBILE_ACCOUNT_RECORD_TYPE)
            .getRecordTypeId();
        //End - Added for HRP-17050
        String query = 'SELECT Id,AccountId FROM Opportunity where LastModifiedDate>=:startDt and LastModifiedDate<=:endDt and Account.RecordTypeId = :mobileAccRecTypeId';     //Modified for HRP-17050
        //system.debug('*****' + query);
        return Database.getQueryLocator(query); 
        
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> oppList) 
    {
        Set<Id> accId = new Set<Id>();
		for(Opportunity opp : oppList)
        {
            //system.debug('*****' + opp.Accountid);
            accId.add(opp.Accountid);
        }
        AccountStatusUpdateHelper.updateAcc(accId);
    }   
    
    global void finish(Database.BatchableContext BC) 
    {
       
    }
}