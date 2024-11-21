@isTest
public class BSF_Batch_UpdateContactForBPL_Test {

    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static String mobileOppRecType = 'Mobile Opp';
    public static String fixedOppRecType = 'Fixed Site Opp';
    public static String mobileSiteRecType = 'Mobile Site';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Account' );       
        Id recTypeId = recordTypeMap.get(mobileAccRecType);
        
        recordTypeMap = recordTypeMap( 'Opportunity' );        
        Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);
        Id fixedoptyRecTypeId = recordTypeMap.get(fixedOppRecType);
        
        List<ARC_Market_Mapping__c> mmapList = new List<ARC_Market_Mapping__c>();
        ARC_Market_Mapping__c mmap ;
        
        mmap = new ARC_Market_Mapping__c();
        mmap.Zip_Code__c = '30622';
        mmap.Market__c = 'Alpharetta';
        mmapList.add(mmap);
        
        mmap = new ARC_Market_Mapping__c();
        mmap.Zip_Code__c = '30146';
        mmap.Market__c = 'Marietta GA FS';
        mmapList.add(mmap);
        
        mmap = new ARC_Market_Mapping__c();
        mmap.Zip_Code__c = '30147';
        mmap.Market__c = 'Stone Mountain';
        mmapList.add(mmap);
        
        insert mmapList;
        
        Map <String,Schema.RecordTypeInfo> recordTypesadjustment = Taxonomy__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id RecTypeIdTax = recordTypesadjustment.get('Bio Recruitment CD').getRecordTypeId();        
        Date startDate1 = System.today().addMonths(-6);
        Date endDate1   = System.today().addMonths(4);    
        Date startDate2 = System.today().addMonths(2);
        Date endDate2   = System.today().addMonths(6);        
        
        List<Taxonomy__c> taxList = new List<Taxonomy__c>();
        Taxonomy__c tax1 = new Taxonomy__c(Division_Code__c ='BD34',Division_Name__c='North Central',
                                           DRD_Territory_Code__c='HProdSEMR_1836',DRD_Territory_Name__c='Detroit South 05',  
                                           DS_Region_Code__c='13Z18Z', DS_Region_Name__c='Michigan',   End_Date__c = endDate1,
                                           RecordTypeId=RecTypeIdTax, Start_Date__c=startDate1, Team_Code__c='MICH_Detroit S',
                                           Team_Name__c='MICH_Detroit S',Type__c='Bio Recruitment',  Version_Key__c=108.0, Zip_Code__c='30622');
        
        taxList.add(tax1);        
        insert taxList;
        BSF_Portfolio__c DMPortfolio = new BSF_Portfolio__c();
        DMPortfolio.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio.Portfolio_Type__c = 'District Manager';
        DMPortfolio.Account_Based_Portfolio__c = false;
        DMPortfolio.Territory_Portfolio__c = true;
        DMPortfolio.External_Key__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c+'_'+taxList[0].Start_Date__c;
        DMPortfolio.External_Key_BackEnd__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c;
        
        insert DMPortfolio;
        
        /*BSF_Portfolio__c AMPortfolio = new BSF_Portfolio__c();
        AMPortfolio.Portfolio_Code__c = 'HProdSEMR_1836';
        AMPortfolio.Portfolio_Name__c = 'Detroit South 05';
        AMPortfolio.Portfolio_Type__c = 'Account Manager';
        AMPortfolio.Account_Based_Portfolio__c = false;
        AMPortfolio.Parent_Portfolio__c=DMPortfolio.id;
        AMPortfolio.Territory_Portfolio__c = true;
        AMPortfolio.External_Key__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c+'_'+taxList[0].Start_Date__c;
        AMPortfolio.External_Key_BackEnd__c='Bio Recruitment CD'+'_'+taxList[0].Division_Code__c +'_'+taxList[0].DS_Region_Code__c+'_'+taxList[0].Team_Code__c+'_'+taxList[0].DRD_Territory_Code__c;
        insert AMPortfolio;*/
       
        
        BSF_Portfolio__c DMPortfolio1 = new BSF_Portfolio__c();
        DMPortfolio1.Portfolio_Code__c = 'MICH_Detroit S';
        DMPortfolio1.Portfolio_Name__c = 'MICH_Detroit S';
        DMPortfolio1.Portfolio_Type__c = 'District Manager';
        DMPortfolio1.Account_Based_Portfolio__c = false;
        DMPortfolio1.Territory_Portfolio__c = true;
        DMPortfolio1.Taxonomy_Type__c=BSF_Constants.TAXO_SUPERVISOR_RECORD_TYPE;      
        insert DMPortfolio1;
        
        //Portfolio_Assignment__c am = new Portfolio_Assignment__c(BSF_Portfolio__c=DMPortfolio.Id,User__c=userInfo.getUserId(),Start_Date__c=startDate1 ,End_Date__c=endDate1,Assignment_Type__c='District Manager');
        
        //insert am;
        List<Account> mobileAccList = new List<Account>();
        
        Account accobj;
        
        accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30622';
        
        Account acc1=new Account();
        acc1.name='testAcct01';
        acc1.RecordTypeId = recTypeId;
        acc1.BillingPostalCode = '30623';
        acc1.Days_of_Week_Declined__c ='Monday;Tuesday';
        
        mobileAccList.add(accobj);
        mobileAccList.add(acc1);
        
        insert mobileAccList;
        
        Contact conObj = new Contact();
        conObj.AccountId = [SELECT Id FROM Account WHERE Name = 'testAcct01'].Id;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
		conObj.OtherCity = 'Ashburn';
        conObj.OtherCountryCode ='US';
        conObj.OtherPostalCode = '20148';
        conObj.OtherStateCode = 'VA';
        conObj.OtherStreet = '23070 Learning Cir';
        conObj.Email = 'testContact@gmail.com';
        conObj.Primary_Phone__c = 'Mobile Phone';
        conObj.MobilePhone = '752-781-0090';
        insert conObj;
        
        List<Opportunity> oppsobjlist = new List<Opportunity>();
        Opportunity optyObj ; // = new Opportunity();
        optyObj = new Opportunity();
        optyObj.RecordTypeId = fixedoptyRecTypeId;
        optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'testAcct01'].Id;
        // optyObj.Drive_Site__c = [SELECT Id FROM sked__Location__c WHERE Name = 'Test Site'].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today()+1;
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.WB_Projected_Procedures__c = 1;
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.Anticipated_Registered_Donors__c = 1;
        
        oppsobjlist.add( optyObj );
		
		optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'testAcct01'].Id;
        // optyObj.Drive_Site__c = [SELECT Id FROM sked__Location__c WHERE Name = 'Test Site'].Id;
        optyObj.Name = 'Test Drive';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today()+1;
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.WB_Projected_Procedures__c = 1;
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.Anticipated_Registered_Donors__c = 1;
        
        oppsobjlist.add( optyObj );
        
        optyObj = new Opportunity();
        optyObj.RecordTypeId = optyRecTypeId;
        optyObj.AccountId = [SELECT Id FROM Account WHERE Name = 'testAcct01'].Id;
        //optyObj.Drive_Site__c = [SELECT Id FROM sked__Location__c WHERE Name = 'Test Site'].Id;
        optyObj.Name = 'Test Drive2';
        optyObj.StageName = 'Discovery';
        optyObj.Drive_Date__c = System.today();
        optyObj.CloseDate = System.today();
        optyObj.Start_Time__c = System.now().Time();
        optyObj.End_Time__c = System.now().Time()+1;
        optyObj.WB_Projected_Procedures__c = 1;
        optyObj.X2RBC_Projected_Procedures__c = 1;
        optyObj.Anticipated_Registered_Donors__c = 1;
        
        oppsobjlist.add( optyObj );
        
        
        insert oppsobjlist;
        Account_Service_Role__c asr = new Account_Service_Role__c(Account__c=acc1.Id,
        Contact__c=conObj.Id,
        Account_Service_Role__c = 'Blood Program Leader',
        Start_Date__c = Date.Today());
        insert asr;
        
    }
    
    
    @isTest 
    static void UpdateContactForBPL_Test1(){
        Test.startTest();
            BSF_Batch_UpdateContactForBPL batchObject = new BSF_Batch_UpdateContactForBPL();
            Database.executeBatch(batchObject,200);
        Test.stopTest();
    }
    @isTest 
    static void UpdateContactForBPL_Test2(){
        Test.startTest();
            BSF_Batch_UpdateContactForBPL testsche = new BSF_Batch_UpdateContactForBPL();
            String sch = '0 0 23 * * ?';
            system.schedule('Test Scheduler batch', sch, testsche );
        Test.stopTest();
    }
    public static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    } 
}