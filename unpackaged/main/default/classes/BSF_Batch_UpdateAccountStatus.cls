global class BSF_Batch_UpdateAccountStatus implements Database.Batchable<sObject>
{
    public DateTime startDt;
    public DateTime endDt;
    public DateTime nextStartDt;
	
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        String acctStatus=BSF_Constants.acctStatus;
        endDt = System.Now();
        startDt = System.Now().addHours(-1);
        String query = 'SELECT Id,AccountId FROM Opportunity where LastModifiedDate>=:startDt and LastModifiedDate<=:endDt ';
        return Database.getQueryLocator(query); 
        
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> oppList) 
    {
        Set<Id> accId = new Set<Id>();
		for(Opportunity opp : oppList)
        {
          accId.add(opp.Accountid);
        }
        AccountStatusUpdateHelper.updateAcc(accId);
    }   
    
    global void finish(Database.BatchableContext BC) 
    {
       
    }
}