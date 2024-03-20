global class Bsf_BatchCancelBloodDrivePendingOpp implements Database.Batchable<sObject>{
    global Id accId;
    global date selEffectiveDate;
    global String closereason;
    
    global Bsf_BatchCancelBloodDrivePendingOpp(Id accId,date selEffectiveDate,string closereason){
        system.debug('entered this batch');
        this.accId=accId;
        this.selEffectiveDate=selEffectiveDate;
        this.closereason=closereason;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('entered this batch1');
        String query = 'SELECT Id,Start_Time__c,End_Time__c,Online_Scheduling_Enabled__c, AccountId, Name, Description, StageName,Drive_Date__c FROM Opportunity where AccountId =:accId and Drive_Date__c >= :selEffectiveDate ';
        return Database.getQueryLocator(query); 
        //List<Opportunity> oppList =[SELECT Id,Start_Time__c,End_Time__c,Online_Scheduling_Enabled__c, AccountId, Name, Description, StageName,Drive_Date__c FROM Opportunity where AccountId =:accId and Drive_Date__c >= :selEffectiveDate];
		
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> listOfOpportunity){
        //system.debug('entered this batch2'+listOfOpportunity);
        for (Opportunity opp:listOfOpportunity){
            opp.StageName ='Cancelled';
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Fixed Site Opp').getRecordTypeId();
            opp.Initiated_By__c = 'ARC Initiated-Fixed' ;
            opp.sked_Cancellation_Reason__c = 'ARC Management';
            opp.Start_Time__c = System.now().time();
            opp.End_Time__c = System.now().addMinutes(5).time();
            opp.Online_Scheduling_Enabled__c = 'No';
            System.debug( 'Opp_Start_Time===>' + opp.Start_Time__c +  '  opp_End_Time==>' + opp.End_Time__c+ ' online scheduling##' + opp.Online_Scheduling_Enabled__c );
        }
        try{
            
            update listOfOpportunity;
            Account acc = new account();
            acc.id =accId;            
            acc.Defunct_Effective_Date__c = selEffectiveDate;
            acc.Account_Status__c ='Closed';
            acc.Closure_Reason__c =closereason;
            //OpportunityService.isExecuted=true; 
            update acc;
        }catch (Exception ex) {
             System.debug( 'debug-mesg1==>' + ex.getLineNumber() + ' debug-mesg2==>' + ex.getMessage() );
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC){}

}