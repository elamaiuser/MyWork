@isTest
public class AccountPortfolioAssignmentTrigger_Test 
{
  @testSetup static void createData(){
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Account mobileAcc1 = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420',
            Internal_Name__c ='TEst Test Account 1'
        );
        Account mobileAcc2 = new Account(
            name = 'Test Account 2',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = 'PO BOX 1', 
        	BillingCity = 'COLUMBIAVILLE',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48421',
            Internal_Name__c ='TEst Test Account 2'
        );
        accList.add(mobileAcc1);
        accList.add(mobileAcc2);
      TriggerHandler.bypass('AccountTriggerHandler');
        insert accList;
TriggerHandler.clearbypass('AccountTriggerHandler');        
      list<BSF_Portfolio__c> bsflist = new list<BSF_Portfolio__c>();
        BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
      	DMPortfolio.start_date__c=system.today()-100;
      	DMPortfolio.End_date__c = system.today()+80;
        bsflist.add(DMPortfolio);
        
        
      
      BSF_Portfolio__c DMPortfolio1 = new BSF_Portfolio__c();
        DMPortfolio1.Portfolio_Code__c = 'MICH_Detroit';
        DMPortfolio1.Portfolio_Name__c = 'MICH_Detroit';
        DMPortfolio1.Portfolio_Type__c = 'District Manager';
        DMPortfolio1.Account_Based_Portfolio__c = false;
        DMPortfolio1.Territory_Portfolio__c = true;
      	DMPortfolio1.start_date__c=system.today()-100;
      	DMPortfolio1.End_date__c = system.today()+80;
        bsflist.add(DMPortfolio1);
      
        BSF_Portfolio__c ASPortfolio = new BSF_Portfolio__c();
        ASPortfolio.Portfolio_Code__c = 'MICH_Detroit S ';
        ASPortfolio.Portfolio_Name__c = 'MICH_Detroit S AS';
        ASPortfolio.Portfolio_Type__c = 'Account specialist';
        ASPortfolio.Account_Based_Portfolio__c = True;
        ASPortfolio.Territory_Portfolio__c = false;
        ASPortfolio.Taxonomy_Type__c=bsf_constants.ACCOUNT_SPECIALIST;
      	ASPortfolio.start_date__c=system.today()-100;
      	ASPortfolio.End_date__c = system.today()+80;
        bsflist.add(ASPortfolio);
        
      
        BSF_Portfolio__c ASPortfolio1 = new BSF_Portfolio__c();
        ASPortfolio1.Portfolio_Code__c = 'MICH_Detroit';
        ASPortfolio1.Portfolio_Name__c = 'MICH_Detroit AS';
        ASPortfolio1.Portfolio_Type__c = 'Account specialist';
        ASPortfolio1.Account_Based_Portfolio__c = True;
        ASPortfolio1.Territory_Portfolio__c = false;
        ASPortfolio1.Taxonomy_Type__c=bsf_constants.ACCOUNT_SPECIALIST;
      	ASPortfolio1.start_date__c=system.today()-100;
      	ASPortfolio1.End_date__c = system.today()+80;
      	bsflist.add(ASPortfolio1);
        
      insert bsflist;
        
        BSF_Portfolio__c ABMPortfolio = new BSF_Portfolio__c();
        ABMPortfolio.Portfolio_Code__c = 'NA_Detorit_ABM_1';
        ABMPortfolio.Portfolio_Name__c = 'NA_Detorit_ABM_1';
        ABMPortfolio.Portfolio_Type__c = BSF_Constants.AREA_BOOKING_MANAGER;
        ABMPortfolio.Account_Based_Portfolio__c = false;
        ABMPortfolio.Territory_Portfolio__c = true;
        ABMPortfolio.Parent_Portfolio__c = DMPortfolio.Id; 
        
        insert ABMPortfolio;
        
        BSF_Portfolio__c AMPortfolioWithABM = new BSF_Portfolio__c();
        AMPortfolioWithABM.Portfolio_Name__c = 'Detroit South 05';
        AMPortfolioWithABM.Portfolio_Code__c = 'HProdSEMR_1836';
        AMPortfolioWithABM.Account_Based_Portfolio__c = false;
        AMPortfolioWithABM.Territory_Portfolio__c = true;
        AMPortfolioWithABM.Portfolio_Type__c = 'Account Manager';
        AMPortfolioWithABM.Parent_Portfolio__c =ABMPortfolio.Id; 
        
        insert AMPortfolioWithABM;
        
       list<BSF_Portfolio__c> bsflistAm = new list<BSF_Portfolio__c>();
        BSF_Portfolio__c AMPortfolioWithoutABM = new BSF_Portfolio__c();
        AMPortfolioWithoutABM.Portfolio_Name__c = 'Detroit South 07';
        AMPortfolioWithoutABM.Portfolio_Code__c = 'HProdSEMR_1837';
        AMPortfolioWithoutABM.Account_Based_Portfolio__c = false;
        AMPortfolioWithoutABM.Territory_Portfolio__c = true;
        AMPortfolioWithoutABM.Portfolio_Type__c = 'Account Manager';
        AMPortfolioWithoutABM.Parent_Portfolio__c = DMPortfolio.Id; 
        bsflistAm.add(AMPortfolioWithoutABM);
        
      
        BSF_Portfolio__c AMPortfolioWithoutABM1 = new BSF_Portfolio__c();
        AMPortfolioWithoutABM1.Portfolio_Name__c = 'Detroit South';
        AMPortfolioWithoutABM1.Portfolio_Code__c = 'HProdSEMR_1889';
        AMPortfolioWithoutABM1.Account_Based_Portfolio__c = true;
        AMPortfolioWithoutABM1.Territory_Portfolio__c = false;
        AMPortfolioWithoutABM1.Taxonomy_Type__c='Bio Account Portfolio';
        AMPortfolioWithoutABM1.Portfolio_Type__c = 'Account Manager';
        AMPortfolioWithoutABM1.Parent_Portfolio__c = DMPortfolio1.Id; 
        bsflistAm.add(AMPortfolioWithoutABM1);
        insert bsflistAm;
    }
    
    
    
    @isTest static void testAccountPortfolioAssignment1(){
        
        Account acc = [select id from account limit 1];
        list<BSF_Portfolio__c> bsfList = [select id,Portfolio_Type__c from BSF_Portfolio__c where (Portfolio_Code__c = 'HProdSEMR_1836' AND Portfolio_Type__c = 'Account Manager') 
                                          										or (Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager') 
                                          										or (Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c = 'Area Booking Manager')
                                         										or (Portfolio_Code__c = 'HProdSEMR_1837' AND Portfolio_Type__c = 'Account Manager')
                                         										or (Portfolio_Code__c = 'SAM Test Data 1' AND Portfolio_Type__c = 'Sickle Cell Account Manager')];
        map<string,id> bsfIdMap = new map<string,id>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            bsfIdMap.put(bsf.Portfolio_Type__c,bsf.id);
        }
        Account_portfolio_assignment__c apaTerr = new Account_portfolio_assignment__c();
        apaTerr.account__c=acc.id;
        apaTerr.BSF_Portfolio__c = bsfIdMap.get('Account Manager');
        apaTerr.Start_Date__c = system.today().addDays(-50);
        apaTerr.End_Date__c = system.today().addDays(10);
        
        insert apaTerr;
        
         
        
        
    }
    
    @isTest static void testAccountPortfolioAssignment2(){
        
        Account acc = [select id from account limit 1];
        list<BSF_Portfolio__c> bsfList = [select id,Portfolio_Type__c from BSF_Portfolio__c where (Portfolio_Code__c = 'HProdSEMR_1836' AND Portfolio_Type__c = 'Account Manager') 
                                          										or (Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager') 
                                          										or (Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c = 'Area Booking Manager')
                                         										or (Portfolio_Code__c = 'HProdSEMR_1837' AND Portfolio_Type__c = 'Account Manager')
                                         										or (Portfolio_Code__c = 'SAM Test Data 1' AND Portfolio_Type__c = 'Sickle Cell Account Manager')];
        map<string,id> bsfIdMap = new map<string,id>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            bsfIdMap.put(bsf.Portfolio_Type__c,bsf.id);
        }
        
        Account_portfolio_assignment__c apaTerr = new Account_portfolio_assignment__c();
        apaTerr.account__c=acc.id;
        apaTerr.BSF_Portfolio__c = bsfIdMap.get('Account Manager');
        apaTerr.Start_Date__c = system.today().addDays(-50);
        apaTerr.End_Date__c = system.today().addDays(10);
        
        insert apaTerr;
        
        Account_portfolio_assignment__c apaExcep = new Account_portfolio_assignment__c();
        apaExcep.account__c=acc.id;
        apaExcep.BSF_Portfolio__c = [select id,Portfolio_Type__c from BSF_Portfolio__c where Portfolio_Name__c = 'Detroit South 07'].id;
        apaExcep.Start_Date__c = system.today().addDays(11);
        apaExcep.End_Date__c = system.today().addDays(20);
        
        insert apaExcep;
        
        Account_portfolio_assignment__c apaTerr2 = new Account_portfolio_assignment__c();
        apaTerr2.account__c=acc.id;
        apaTerr2.BSF_Portfolio__c = bsfIdMap.get('Account Manager');
        apaTerr2.Start_Date__c = system.today().addDays(21);
        apaTerr2.End_Date__c = system.today().addDays(30);
        
        insert apaTerr2;
        //Database.executeBatch(new BSF_Batch_CreateDefaultPortfolioAssign(system.today()));
        
        
        
         
        
        
    }
    
    @isTest static void testAccountPortfolioAssignment3(){
        
        Account acc = [select id from account limit 1];
        list<BSF_Portfolio__c> bsfList = [select id,Portfolio_Type__c from BSF_Portfolio__c where (Portfolio_Code__c = 'HProdSEMR_1836' AND Portfolio_Type__c = 'Account Manager') 
                                          										or (Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager') 
                                          										or (Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c = 'Area Booking Manager')
                                         										or (Portfolio_Code__c = 'HProdSEMR_1837' AND Portfolio_Type__c = 'Account Manager')
                                         										or (Portfolio_Code__c = 'SAM Test Data 1' AND Portfolio_Type__c = 'Sickle Cell Account Manager')];
        map<string,id> bsfIdMap = new map<string,id>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            bsfIdMap.put(bsf.Portfolio_Type__c,bsf.id);
        }
        
        Account_portfolio_assignment__c apaTerr = new Account_portfolio_assignment__c();
        apaTerr.account__c=acc.id;
        apaTerr.BSF_Portfolio__c = bsfIdMap.get('Account Manager');
        apaTerr.Start_Date__c = system.today().addDays(-50);
        apaTerr.End_Date__c = system.today().addDays(10);
        
        insert apaTerr;
        
        Account_portfolio_assignment__c apaExcep = new Account_portfolio_assignment__c();
        apaExcep.account__c=acc.id;
        apaExcep.BSF_Portfolio__c = [select id,Portfolio_Type__c from BSF_Portfolio__c where Portfolio_Name__c = 'Detroit South'].id;
        apaExcep.Start_Date__c = system.today().addDays(11);
        apaExcep.End_Date__c = system.today().addDays(20);
        
        insert apaExcep;  
        
        Account_portfolio_assignment__c apaTerr2 = new Account_portfolio_assignment__c();
        apaTerr2.account__c=acc.id;
        apaTerr2.BSF_Portfolio__c = bsfIdMap.get('Account Manager');
        apaTerr2.Start_Date__c = system.today().addDays(21);
        apaTerr2.End_Date__c = system.today().addDays(30);
        
        insert apaTerr2;
        //Database.executeBatch(new BSF_Batch_CreateDefaultPortfolioAssign(system.today()));
         delete apaExcep;
        
        
         
        
        
    }
    
    @isTest static void testAccountPortfolioAssignment4(){
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        Account acc = [select id from account limit 1];
        list<BSF_Portfolio__c> bsfList = [select id,Portfolio_Type__c from BSF_Portfolio__c where (Portfolio_Code__c = 'HProdSEMR_1836' AND Portfolio_Type__c = 'Account Manager') 
                                          										or (Portfolio_Code__c = 'MICH_Detroit S' AND Portfolio_Type__c = 'District Manager') 
                                          										or (Portfolio_Code__c = 'NA_Detorit_ABM_1' AND Portfolio_Type__c = 'Area Booking Manager')
                                         										or (Portfolio_Code__c = 'HProdSEMR_1837' AND Portfolio_Type__c = 'Account Manager')
                                         										or (Portfolio_Code__c = 'SAM Test Data 1' AND Portfolio_Type__c = 'Sickle Cell Account Manager')];
        map<string,id> bsfIdMap = new map<string,id>();
        for(BSF_Portfolio__c bsf :bsfList)
        {
            bsfIdMap.put(bsf.Portfolio_Type__c,bsf.id);
        }
        
        List<portfolio_assignment__c> portfList = new List<portfolio_assignment__c>();
        
        portfolio_assignment__c pa2 = new portfolio_assignment__c ();
        pa2.user__c=userinfo.getuserid();
        pa2.start_date__c= system.today().addDays(20);
        pa2.End_Date__c=system.today().addDays(25);
        pa2.BSF_Portfolio__c=[select id,Portfolio_Type__c from BSF_Portfolio__c where Portfolio_Name__c = 'Detroit South'].id;
        pa2.Assignment_Type__c='Account Manager';
        portfList.add(pa2);
        
        portfolio_assignment__c pa1 = new portfolio_assignment__c ();
        pa1.user__c=userinfo.getuserid();
        pa1.start_date__c= system.today().addDays(-50);
        pa1.End_Date__c=system.today().addDays(10);
        pa1.BSF_Portfolio__c=bsfIdMap.get('Account Manager');
        pa1.Assignment_Type__c='Account Manager';
        portfList.add(Pa1);
        
        TriggerHandler.bypass('PortfolioAssignmentTriggerHandler');
        insert portfList;
        TriggerHandler.clearbypass('PortfolioAssignmentTriggerHandler');
        
        List<Account_portfolio_assignment__c> apaList = new List<Account_portfolio_assignment__c>();
        Account_portfolio_assignment__c apaTerr = new Account_portfolio_assignment__c();
        apaTerr.account__c=acc.id;
        apaTerr.BSF_Portfolio__c = bsfIdMap.get('Account Manager');
        apaTerr.Start_Date__c = system.today().addDays(-50);
        apaTerr.End_Date__c = system.today().addDays(10);
        apaList.add(apaTerr);
        
        
        
        
        Account_portfolio_assignment__c apaExcep = new Account_portfolio_assignment__c();
        apaExcep.account__c=acc.id;
        apaExcep.BSF_Portfolio__c =pa2.BSF_Portfolio__c ;
        apaExcep.Start_Date__c = system.today().addDays(20);
        apaExcep.End_Date__c = system.today().addDays(25);
        apaList.add(apaExcep);
        
        
        
        
        
        skedHubBase.BypassInsertTriggers = true;
        skedHubBase.BypassUpdateTriggers = true;
        Account_portfolio_assignment__c apaTerr2 = new Account_portfolio_assignment__c();
        apaTerr2.account__c=acc.id;
        apaTerr2.BSF_Portfolio__c = bsfIdMap.get('Account Manager');
        apaTerr2.Start_Date__c = system.today().addDays(26);
        apaTerr2.End_Date__c = system.today().addDays(30);
        apaList.add(apaTerr2);
        TriggerHandler.bypass('AccountPortfolioAssignmentTriggerHandler');
        insert apaList;
        TriggerHandler.clearbypass('AccountPortfolioAssignmentTriggerHandler');
        TriggerHandler.clearbypass('AccountTeamMemberTriggerHandler');
        opportunity opp = new opportunity(
        Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = system.today().addDays(22),
        	CloseDate = System.today().addDays(18),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No',
            //Drive_Site__c = mobileSite.id,
            accountid= acc.id);
        //Database.executeBatch(new BSF_Batch_CreateDefaultPortfolioAssign(system.today()));
         //delete apaExcep;
        TriggerHandler.bypass('OpportunityTriggerHandler');
        Insert opp;
        TriggerHandler.clearbypass('OpportunityTriggerHandler');
        skedHubBase.BypassInsertTriggers = false;
        skedHubBase.BypassUpdateTriggers = false;
        test.startTest();
        TriggerHandler.bypass('AccountTeamMemberTriggerHandler');
        AccountPortfolioAssignmentService.accTeamDateSyncOnAccPortUpdates(new list<id>{acc.id},null,new Set<id>(),new map<id,list<accountTeamMember>> (),new map<id,list<accountTeamMember>> ());
        TriggerHandler.clearbypass('AccountTeamMemberTriggerHandler');
        test.StopTest();
        
         
        
        
    }
    @isTest
    static void testEnsureTerritoryCoverage() {
        Account acc = new Account(Name='Coverage Test Account', BillingPostalCode='99999');
        insert acc;

        BSF_Portfolio__c abAmPortfolio = new BSF_Portfolio__c(
            Portfolio_Name__c='AB_AM_Portfolio',
            Portfolio_Code__c='AB_AM_01',
            Portfolio_Type__c='Account Manager',
            Taxonomy_Type__c='Bio Account Portfolio',
            Account_Based_Portfolio__c=true,
            Territory_Portfolio__c=false,
            Start_Date__c=System.today().addDays(-50),
            End_Date__c=System.today().addDays(5)
        );
        insert abAmPortfolio;

        Account_Portfolio_Assignment__c pendingAPA = new Account_Portfolio_Assignment__c(
            Account__c=acc.Id,
            BSF_Portfolio__c=abAmPortfolio.Id,
            Start_Date__c=System.today().addDays(-20),
            End_Date__c=System.today().addDays(5)
        );
        insert pendingAPA;

        Taxonomy__c taxo = new Taxonomy__c(
            Zip_Code__c='99999',
            Start_Date__c=System.today().addDays(-100),
            End_Date__c=System.today().addDays(300),
            DRD_Territory_Name__c='Test Territory',
            DRD_Territory_Code__c='TERR_001'
        );
        insert taxo;
        BSF_Portfolio__c terrPortfolio = new BSF_Portfolio__c(
            Portfolio_Name__c='Territory Portfolio',
            Portfolio_Code__c='TERR_001',
            Portfolio_Type__c='Account Manager',
            Taxonomy_Type__c='Bio Recruitment CD',
            Account_Based_Portfolio__c=false,
            Territory_Portfolio__c=true,
            Start_Date__c=System.today().addDays(-100),
            End_Date__c=System.today().addDays(400)
        );
        insert terrPortfolio;

        Test.startTest();
        List<Account_Portfolio_Assignment__c> result =
            AccountPortfolioAssignmentService.ensureTerritoryCoverage(
                new List<Account_Portfolio_Assignment__c>{pendingAPA}
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected non-null result list');
        System.assert(
            result.size() > 0,
            'Expected at least one tail APA to be generated for coverage gap'
        );
        System.assertEquals(acc.Id, result[0].Account__c);
        System.assertEquals(terrPortfolio.Id, result[0].BSF_Portfolio__c);
        System.assertEquals(Date.newInstance(4000, 12, 31), result[0].End_Date__c);
    }



}