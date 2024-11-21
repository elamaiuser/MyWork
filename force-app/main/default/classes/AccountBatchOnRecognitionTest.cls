/***********************************************************************************************************
 * Modification Log:    
 * --------------------------------------------------------------------------------------------------------
 * Date         Author                 Description                              Covering Class Name
 * 10/17/23     Ankit Kundu         The batch implemented based on HRP-11077.   AccountBatchOnRecognition
 *
 **********************************************************************************************************/
@isTest
private class AccountBatchOnRecognitionTest {
    static testMethod void testBatch(){
           
        
        List<Account> accList = new List<Account>();
        Account acc = new account(name='testAccount',IsPumpedItUpCurrent__c = true);
        Account acc1 = new account(name='testAccount1',IsPremierCurrent__c = true);
        accList.add(acc);
        accList.add(acc1);
        insert accList; 
        
        Id RccognitionId = Schema.SObjectType.Marketing_Program__c.getRecordTypeInfosByName().get('Sponsor Recognition').getRecordTypeId();
        list<Marketing_Program__c> mpclist = new list<Marketing_Program__c>();
        //HRP-11077 Start->
        Marketing_Program__c mp = new Marketing_Program__c(Name = label.Premier_Bonus_Prior, Start_Date__c=system.today(),End_Date__c=system.today()+5,
                            Scope__c = 'account' ,
                            RecordTypeId=RccognitionId,Drive_Type__c = 'N/A',External_Name__c = 'Test Account Marketing Program');
        mpclist.add(mp);
        Marketing_Program__c mp1 = new Marketing_Program__c(Name = label.PremierPrior, Start_Date__c=system.today(),End_Date__c=system.today()+5,
                                    Scope__c = 'account',
                                    RecordTypeId=RccognitionId,Drive_Type__c = 'N/A',External_Name__c = 'Test Account Marketing Program1');
        mpclist.add(mp1);
        Marketing_Program__c mp2 = new Marketing_Program__c(Name = label.Premier_Bonus_Current, 
                                            Scope__c = 'account' ,Start_Date__c=system.today(),End_Date__c=system.today()+5,
                                            RecordTypeId=RccognitionId,Drive_Type__c = 'N/A',External_Name__c = 'Test Account Marketing Program');
        mpclist.add(mp2);
        Marketing_Program__c mp3 = new Marketing_Program__c(Name = label.PremierCurrent, 
                                    Scope__c = 'account',Start_Date__c=system.today(),End_Date__c=system.today()+5,
                                    RecordTypeId=RccognitionId,Drive_Type__c = 'N/A',External_Name__c = 'Test Account Marketing Program1');
        mpclist.add(mp3);
        
        
        Marketing_Program__c mp4 = new Marketing_Program__c(Name = label.PremierPrior, 
                                    Scope__c = 'account',Start_Date__c=system.today(),End_Date__c=system.today()+5,
                                    RecordTypeId=RccognitionId,Drive_Type__c = 'N/A',External_Name__c = 'Test Account Marketing Program1');
        mpclist.add(mp4);
        
        insert mpclist;
       // <-End [HRP-11077]
        
        List<Account_Marketing_Program__c> newAmpList = new List<Account_Marketing_Program__c>();
       Account_Marketing_Program__c amp = new Account_Marketing_Program__c();
        amp.Account__c =acc.Id;
        amp.Date_Assigned__c=system.today().adddays(-50);
        amp.Date_Removed__c=system.today()+5;
        amp.Account_Affiliation_External_Key__c=String.valueOf(System.now()+100);
        amp.Marketing_Program__c = mp2.Id;
        newAmpList.add(amp);
        Account_Marketing_Program__c amp1 = new Account_Marketing_Program__c();
        amp1.Account__c =acc1.Id;
        amp1.Date_Assigned__c=system.today();
        amp.Date_Removed__c=system.today()+5;
        amp.Account_Affiliation_External_Key__c=String.valueOf(System.now()+200);   
        amp1.Marketing_Program__c = mp3.Id;
        newAmpList.add(amp1);
        /*Account_Marketing_Program__c amp2 = new Account_Marketing_Program__c();
        amp2.Account__c=acc.Id;
        amp2.Marketing_Program__c=mp.Id;
        newAmpList.add(amp2);
        Account_Marketing_Program__c amp3 = new Account_Marketing_Program__c();
        amp2.Account__c=acc1.Id;
        amp2.Marketing_Program__c=mp1.Id;
        newAmpList.add(amp3);*/
        insert newAmpList;
        
      
        AccountBatchOnRecognitionScheduler acctSponsorRecognSch = new AccountBatchOnRecognitionScheduler(100);
		System.schedule('Update Account Sponsor Recognition Batch1', '0 0 21 * * ?', acctSponsorRecognSch );
        
        AccountBatchOnRecognition test = new AccountBatchOnRecognition();
        Id jobid=Database.executeBatch(test,5);
        
         List<Account_Marketing_Program__c> updatedRecords = [SELECT Id FROM Account_Marketing_Program__c WHERE Account__c = :acc.Id];
        Assert.areEqual(1, updatedRecords.size(), 'Record should be updated/deleted/inserted');
        
        
    }
}