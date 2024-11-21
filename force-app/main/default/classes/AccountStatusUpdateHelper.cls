public with sharing class AccountStatusUpdateHelper 
{
    public static void updateAcc(Set<Id> accId)
    {
        Date tDay = system.today();
        Id recordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Mobile Account').getRecordTypeId();
        List<Account> accOppFuture = [Select id,Account_Status__c,(Select Id,Drive_Date__c,AccountId,StageName from Opportunities where Drive_Date__c >= :tDay and (StageName = 'Closed' or StageName = 'Discovery') order by Drive_Date__c asc Limit 1) from Account where Id IN:accId and RecordTypeId=:recordTypeID ];
        List<Account> accOppPast = [Select id,Account_Status__c,(Select Id,Drive_Date__c,AccountId,StageName from Opportunities where Drive_Date__c < :tDay and StageName = 'Closed' order by Drive_Date__c desc Limit 1) from Account where Id IN:accId and RecordTypeId=:recordTypeID ];
        
        
        map<Id,Opportunity> accFutureOppMap	= new map<Id,Opportunity>();
        map<Id,Integer>  accWithDaysSinceLastDrive	     = new map<Id,Integer>();
        map<Id,Integer>  accWithDaysUntilNextClosedDrive = new map<Id,Integer>();
        List<Account> accToUpdate = new List<Account>();
        
        //Iterating account with past opportunity and populating map accFutureOppMap
        for(Account acc: accOppPast)
        {
            for(opportunity opp : acc.opportunities)
            {
                 //HRP-1982 Update Account Status to Active when opp is closed
                 /*if(opp.StageName == 'Closed'){
                    acc.Account_Status__c = 'Active';
                    accToUpdate.add(acc);
                 }*/

                if(acc.Account_Status__c != 'Defunct' && acc.Account_Status__c != 'Lost'
                   && opp.StageName == 'Closed')
                {
                        //Calculating daysSinceLastDrive
                        Integer daysSinceLastDrive = tDay.daysBetween(opp.Drive_Date__c);
                        accWithDaysSinceLastDrive.put(opp.AccountId,daysSinceLastDrive);
                }
            }
        }
        
        for(Account acc: accOppFuture)
        {
            for(opportunity opp : acc.opportunities)
            {
                //HRP-1982 Update Account Status to Active when opp is closed
                if(opp.StageName == 'Closed'){
                    acc.Account_Status__c = 'Active';
                    accToUpdate.add(acc);
                }
                if(opp.Drive_Date__c >= tDay && acc.Account_Status__c != 'Defunct' && acc.Account_Status__c != 'Lost'
                   && opp.StageName == 'Closed')
                {
                    Integer daysUntilNextClosedDrive = opp.Drive_Date__c.daysBetween(tDay);
                    accWithDaysUntilNextClosedDrive.put(opp.AccountId,daysUntilNextClosedDrive);
                }
                else if(opp.Drive_Date__c == tDay && (acc.Account_Status__c == 'Defunct' || acc.Account_Status__c == 'Lost')
                        && opp.StageName == 'Discovery' && acc.Account_Status__c != 'Reactivate')
                {
                    acc.Account_Status__c 		  = 'Reactivate';
                    acc.Defunct_Effective_Date__c = null;
                    acc.Lost_Reason__c			  = null;
                    accToUpdate.add(acc);
                }
                accFutureOppMap.put(opp.AccountId,opp);
            }
        }
        
       
        for(Account acc: accOppFuture)
        {
            integer lastDrive;
            integer nextDrive;
            if(accWithDaysSinceLastDrive.get(acc.id)!=null){lastDrive = -accWithDaysSinceLastDrive.get(acc.id);}
            if(accWithDaysUntilNextClosedDrive.get(acc.id)!=null){nextDrive = accWithDaysUntilNextClosedDrive.get(acc.id);}
            system.debug(acc.id);
            system.debug(lastDrive);
            system.debug(nextDrive);
            if(!accWithDaysSinceLastDrive.isEmpty() || !accWithDaysUntilNextClosedDrive.isEmpty() )
            {
                 system.debug('here');
                if((nextDrive != null || lastDrive != null) && (nextDrive == 0 || lastDrive < 366)
                  && acc.Account_Status__c != 'Active')
                {
                    acc.Account_Status__c 		  = 'Active';
                    acc.Defunct_Effective_Date__c = null;
                    acc.Lost_Reason__c			  = null;
                    accToUpdate.add(acc);
                }
            }
            if(!accWithDaysSinceLastDrive.isEmpty())
            {
                system.debug('here');
                if(lastDrive != null && accFutureOppMap.get(acc.id) == null && lastDrive >= 732
                   && acc.Account_Status__c != 'Lapsed' )
                {
                    acc.Account_Status__c 		  = 'Lapsed';
                    acc.Defunct_Effective_Date__c = null;
                    acc.Lost_Reason__c			  = null;
                    accToUpdate.add(acc);
                }
                else if((lastDrive != null && accFutureOppMap.get(acc.id) == null && lastDrive > 366 && lastDrive < 732)
                         && acc.Account_Status__c != 'Inactive')
                {
                    acc.Account_Status__c 		  = 'Inactive';
                    acc.Defunct_Effective_Date__c = null;
                    acc.Lost_Reason__c			  = null;
                    accToUpdate.add(acc);
                } 
            }
        }
        
        
        if(!accToUpdate.isEmpty())
        {
            Database.SaveResult[] srList = Database.update (accToUpdate,false);
            
            for (Database.SaveResult sr : srList) 
            {
                if (sr.isSuccess()) 
                {
                    System.debug('Successfully updated Account status Account ID: ' + sr.getId());
                }
                else 
                {        
                    for(Database.Error err : sr.getErrors()) 
                    {System.debug('The Error in updating the Account Status is : '+err.getStatusCode() + ': ' + err.getMessage());}
                }
            }
        }
    }
}