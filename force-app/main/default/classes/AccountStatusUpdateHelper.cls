public with sharing class AccountStatusUpdateHelper 
{
    public static void updateAcc(Set<Id> accId)
    {
        Date tDay = system.today();
        Id recordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Mobile Account').getRecordTypeId();
        List<Account> accOppFuture = [Select id,Account_Status__c,(Select Id,Drive_Date__c,AccountId,StageName from Opportunities where Drive_Date__c >= :tDay and (StageName = 'Closed' or StageName = 'Discovery') order by Drive_Date__c asc Limit 1) from Account where Id IN:accId and RecordTypeId=:recordTypeID ];
        List<Account> accOppPast = [Select id,Account_Status__c,CreatedDate,(Select Id,Drive_Date__c,AccountId,StageName from Opportunities where Drive_Date__c < :tDay and StageName = 'Closed' order by Drive_Date__c desc Limit 1) from Account where Id IN:accId and RecordTypeId=:recordTypeID ];
        
        
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
            if(acc.opportunities == null || acc.opportunities.isEmpty()){
                Integer daysSinceLastDrive = tDay.daysBetween(acc.CreatedDate.date());
                accWithDaysSinceLastDrive.put(acc.Id,daysSinceLastDrive);
            }
        }

        List<Account> accountsToUpdate = new List<Account>();
        Date today = System.today();

        // Pull Accounts with Opportunities
        List<Account> accWithOpps = [
            SELECT Id, 
                    Account_Status__c, 
                    CreatedDate,
                   (SELECT Id, 
                            Drive_Date__c, 
                            StageName, 
                            DriveStatus__c, 
                            Is_Template__c
                    FROM Opportunities
                    WHERE Is_Template__c = FALSE
                    AND StageName != :BSF_Constants.STAGE_CANCELLED
                    ORDER BY Drive_Date__c DESC)
            FROM Account
            WHERE Id IN :accountIds
        ];

        for (Account acc : accWithOpps) {

            if (acc.Opportunities.isEmpty()) {
                Integer monthsOld = acc.CreatedDate.date().monthsBetween(today);

                if (monthsOld <= 12 && acc.Account_Status__c != 'Active') {
                    acc.Account_Status__c = 'Active';
                    accountsToUpdate.add(acc);
                }else if (monthsOld >= 13 && monthsOld <= 24 && acc.Account_Status__c != 'Inactive') {
                    acc.Account_Status__c = 'Inactive';
                    accountsToUpdate.add(acc);
                }else if (monthsOld > 24 && acc.Account_Status__c != 'Lapsed') {
                    acc.Account_Status__c = 'Lapsed';
                    accountsToUpdate.add(acc);
                }
                continue;
            }

            Opportunity latestCompletedDrive;
            Opportunity futureDrive;

            for (Opportunity opp : acc.Opportunities) {
                if (opp.Drive_Date__c == null){
                    continue;
                }

                if (opp.Drive_Date__c >= today && opp.DriveStatus__c != BSF_Constants.driveStatusComplete) {
                    futureDrive = opp;
                }

                if (opp.DriveStatus__c == BSF_Constants.driveStatusComplete &&
                    (latestCompletedDrive == null || opp.Drive_Date__c > latestCompletedDrive.Drive_Date__c)) {
                    latestCompletedDrive = opp;
                }
            }

            if (futureDrive != null && acc.Account_Status__c != 'Active') {
                acc.Account_Status__c = 'Active';
                accountsToUpdate.add(acc);
            }else if (futureDrive != null && 
                futureDrive.Drive_Date__c >= today &&
                futureDrive.StageName == BSF_Constants.STAGE_DISCOVERY &&
                (acc.Account_Status__c == 'Lost' || acc.Account_Status__c == 'Defunct')) {
                acc.Account_Status__c = 'Reactivate';
                accountsToUpdate.add(acc);
            }else if (latestCompletedDrive != null) {
                Integer monthsSinceLastDrive = latestCompletedDrive.Drive_Date__c.monthsBetween(today);

                if (monthsSinceLastDrive <= 12) {
                    if (acc.Account_Status__c != 'Active') {
                        acc.Account_Status__c = 'Active';
                        accountsToUpdate.add(acc);
                    }
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
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'updating Account Status to Inactive','AccountStatusUpdateHelper','updateAcc','Error','Error in updating Account Status to Inactive');
            InsertBsfErrorLog.insertBsfErrors(logList);
            
            /*for (Database.SaveResult sr : srList) 
            {
                if (sr.isSuccess()) 
                {
                    System.debug('Successfully updated Account status Account ID: ' + sr.getId());
                }
                else if (monthsSinceLastDrive > 24) {
                    if (acc.Account_Status__c != 'Lapsed') {
                        acc.Account_Status__c = 'Lapsed';
                        accountsToUpdate.add(acc);
                    }
                }
            }*/
        }

        if (!accountsToUpdate.isEmpty()) {
            Database.SaveResult[] srList = Database.update (accountsToUpdate,false);
            List<BSF_Error_Log__c> logList = BSF_Utilities.createErrorLog(srList, 'updating Account Status to Inactive','AccountStatusUpdateHelper','updateAcc','Error','Error in updating Account Status to Inactive');
            InsertBsfErrorLog.insertBsfErrors(logList);
        }
    }
}