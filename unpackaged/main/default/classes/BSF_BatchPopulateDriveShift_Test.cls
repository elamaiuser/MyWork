@isTest
public class BSF_BatchPopulateDriveShift_Test 
{
 @testSetup
 public static void setupMethod()
 {
        
    
        Test.startTest();
            
     
 }
    
 @isTest
 public static void BSF_BatchPopulateDriveShift_TestMethod()
 {	
     BSF_TestDataSetup testDataSetup = new BSF_TestDataSetup(false);
        Map<string, sObject> mapTestData =  testDataSetup.createAndInsertCommonObjects();
                      
        Account testMobileAccount = (Account)mapTestData.get('MOBILE_ACCOUNT');
        insert testMobileAccount;

		sked__Tag__c tag = (sked__Tag__c)mapTestData.get('GLOBAL_TAG');
        insert tag;

        sked__Location__c site = (sked__Location__c)mapTestData.get('MOBILE_SITE');
        insert site;
        
        Opportunity templateOpp = (Opportunity)mapTestData.get('MOBILE_TEMPLATE_OPP');
        templateOpp.accountId = testMobileAccount.Id;
        templateOpp.Drive_Site__c = site.Id;
        insert templateOpp;
        
        Opportunity mobileOpportunityRecord = (Opportunity)mapTestData.get('MOBILE_OPP');
        mobileOpportunityRecord.accountId = testMobileAccount.Id;
        mobileOpportunityRecord.Parent_Template_Id__c = templateOpp.Id;
        mobileOpportunityRecord.Is_Template__c = false;
        insert mobileOpportunityRecord;
     
     test.startTest();
     Map<String,Id> recordTypeMap = recordTypeMap('Opportunity' );
        	Id recTypeId = recordTypeMap.get('Mobile Opp');
            
        	Opportunity templateOppNew = new Opportunity(Name='Test Parent opp', RecordTypeId = recTypeId, AccountId = testMobileAccount.Id, is_template__c = true, 
                                                         StageName = 'Discovery', CloseDate = Date.today().addDays(6), Procedure_Projections_Template__c = 25, 
                                                         Projected_Registered_Donors_Template__c = 35, Staffing_Template__c = 45, Volunteers_Template__c = 15, 
                                                         WholeBloodProceduresProjectedTemplate__c = 55, Double_Red_Procedures_Projected_Template__c = 35, 
                                                         Anticipated_Registered_Donors_Template__c = 25, Drive_Site__c = site.Id); 
            insert templateOppNew;
            mobileOpportunityRecord.Parent_Template_Id__c = templateOppNew.Id;
            update mobileOpportunityRecord;
        
     
        sked_Drive__c drive = new sked_Drive__c (sked_Account__c=testMobileAccount.id,sked_Drive_Site__c=site.id,sked_Opportunity__c=mobileOpportunityRecord.id,sked_Projected_Registered_Donors__c=30);
        drive.Sked_migrationid__c = '123456';
         insert drive;
     
        sked_Drive_Shift__c dShift= new sked_Drive_Shift__c (sked_Drive__c=drive.id,sked_Start_Time__c=Time.newInstance(18, 30, 2, 20));
        sked_Drive_Shift__c dShift1= new sked_Drive_Shift__c (sked_Drive__c=drive.id,sked_Start_Time__c=Time.newInstance(17, 30, 2, 20));
        insert dShift;
        insert dShift1;
     
     Date date1 = System.today() - 10;
     BSF_BatchPopulateDriveShift batch = new BSF_BatchPopulateDriveShift(date1);
     database.executeBatch(batch,200);
     test.stopTest();
      dShift =[select sked_Donors_Scheduled__c from sked_Drive_Shift__c Limit 1];
     //system.assert(dShift.sked_Donors_Scheduled__c!= null);
 }
    
    public static Map<String,Id> recordTypeMap(String obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }
}