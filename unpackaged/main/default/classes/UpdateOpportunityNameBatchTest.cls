/* The following test class is covering the below mentioned batch class
 * UpdateOpportunityNameBatch
 * */

@isTest(seeAllData = false)
public class UpdateOpportunityNameBatchTest {
    
    @testSetup
    public static void prepareDataSetup()
    {   
    
    	BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
    	Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
    
    	// insert mobile account  and fixed site account
    	List<Account> accountInsertList = new List<Account>();
        
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        testMobileAccount.Internal_Name__c =  'TEST ACCOUNT 1';
        accountInsertList.add(testMobileAccount);
        
        Account testFixedSiteAccount = (Account)mapTestData.get('FIXED_SITE_ACCOUNT');
        testFixedSiteAccount.Internal_Name__c =  'TEST ACCOUNT 2';
        accountInsertList.add(testFixedSiteAccount);
        
        insert accountInsertList;
    
    	// insert mobile site nad fixed site
    	List<sked__Location__c> siteInsertList = new List<sked__Location__c>();
        
        sked__Location__c testMobileSite = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        siteInsertList.add(testMobileSite);
        
        sked__Location__c testFixedSite = (sked__Location__c)mapTestData.get('FIXED_SITE');
        siteInsertList.add(testFixedSite);
        
        insert siteInsertList;
        
        // insert mobile & fixed site opportunity 
        List<Opportunity> oppInsertList = new List<Opportunity>();
        
        Opportunity testMobileOpp1 = (Opportunity)mapTestData.get('MOBILE_OPP');
        testMobileOpp1.accountId = testMobileAccount.Id;
        testMobileOpp1.Drive_Site__c = siteInsertList[0].Id;
        testMobileOpp1.Drive_Date__c = system.today().addDays(-1);
        testMobileOpp1.CloseDate = system.today().addDays(-20);
        oppInsertList.add(testMobileOpp1);
        
        Opportunity testfixedSiteOpp = (Opportunity)mapTestData.get('FIXED_OPP');
        testfixedSiteOpp.accountId = testMobileAccount.Id;
        testfixedSiteOpp.Drive_Site__c = siteInsertList[1].Id;
        testfixedSiteOpp.Drive_Date__c = system.today().addDays(20);
        testfixedSiteOpp.CloseDate = system.today().addDays(1);
        oppInsertList.add(testfixedSiteOpp);
        
        insert oppInsertList;
    }
    
    static testMethod void updateOppNameTest1()
    {
        List<Opportunity> oppList = [select id, Name from Opportunity limit 2];
        
        for(Opportunity opp : oppList)
        {
           opp.Name = 'Test Opportunity Updated 1';
        }
                
        UpdateOpportunityNameBatch nameBulkUpdateBatch1 = new UpdateOpportunityNameBatch(oppList);
                
        Test.startTest();
        
        Database.executeBatch(nameBulkUpdateBatch1);
                        
        Test.stopTest();
        
        system.assertEquals('Test Opportunity Updated 1', [select Id, Name from Opportunity where Id IN :oppList limit 1].Name);
    }
    
    static testMethod void updateOppNameTest2()
	{
        List<Opportunity> oppList = [select id, Name, is_template__c from Opportunity limit 2];
    
    	for(Opportunity opp : oppList)
    	{
        	opp.Name = 'Test Opportunity Updated 2';
    	}
   
    	String query = 'Select Id, is_template__c, Drive_Site__c, Account_Internal_Name__c, Site_Building_Name__c, Name from Opportunity';
                   
    	UpdateOpportunityNameBatch nameBulkUpdateBatch = new UpdateOpportunityNameBatch(true, query);
    
    	Test.startTest();
    
    	Database.executeBatch(nameBulkUpdateBatch);
                    
    	Test.stopTest();
       
	}

     static testMethod void updateOppNameTest3()
	 {
         
    	List<Opportunity> oppList = [select id, Name from Opportunity limit 2];
        
        Map<Id,Opportunity> oppOldMap = new Map<Id,Opportunity>();
        List<Opportunity> oppNewList = new List<Opportunity>();
        
        for(Opportunity opp : oppList)
    	{
        	oppOldMap.put(opp.Id , opp);
        }
    
    	for(Opportunity opp : oppList)
    	{
        	opp.Name = 'Test Opportunity Updated 3';
            oppNewList.add(opp);
    	}
   
                   
    	UpdateOpportunityNameBatch nameBulkUpdateBatch = new UpdateOpportunityNameBatch(oppNewList,oppOldMap);
    
    	Test.startTest();
    
    	Database.executeBatch(nameBulkUpdateBatch);
                    
    	Test.stopTest();
    
    	List<Opportunity> updateOpp = [select id , Name from Opportunity where Id IN :oppNewList];
         
        for(Opportunity opp : updateOpp)
        {
            system.assert(opp.Name == 'Test Opportunity Updated 3');
        }
        
	}   
        
}