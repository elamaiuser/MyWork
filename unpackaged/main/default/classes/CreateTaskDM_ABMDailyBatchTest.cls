@isTest
public class CreateTaskDM_ABMDailyBatchTest {
    static testMethod void test(){
       
                
        User u=new User();
        u.LastName='user123';
        u.FirstName='user222';
        u.Username='john@acme5.com';
        u.Email='abc@gmail34.com';
        u.Alias='alias';
        u.TimeZoneSidKey='America/New_York';
        u.LocaleSidKey='en_US';
        u.EmailEncodingKey='ISO-8859-1';
        u.ProfileId='00eo0000000rmqFAAQ';
        u.LanguageLocaleKey ='en_US';
        insert u;
        
        User u1=new User();
        u1.LastName='user123';
        u1.FirstName='user222';
        u1.Username='john@acme6.com';
        u1.Email='abc@gmail35.com';
        u1.Alias='alias';
        u1.TimeZoneSidKey='America/New_York';
        u1.LocaleSidKey='en_US';
        u1.EmailEncodingKey='ISO-8859-1';
        u1.ProfileId='00eo0000000rmqFAAQ';
        u1.LanguageLocaleKey ='en_US';
        insert u1;
        
        Account a=new Account();
        a.name='account';
        a.District_Manager__c=u.id;
        insert a;
        
         Account a1=new Account();
        a1.name='account1';
        a1.District_Manager__c=u1.id;
        insert a1;
        

        List<Opportunity> opplist=new List<Opportunity>();
         Opportunity mobileOpp = new Opportunity(
            Name = 'Test Opportunity',
        	StageName = 'Draft',
           	Type_of_Drive__c = 'Mobile',
        	RecordTypeId =  Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Mobile Opp').getRecordTypeId(),
        	Drive_Name__c = 'Test Drive',
        	Drive_Date__c = System.today(),
        	CloseDate = System.today(),
        	Start_Time__c = Time.newInstance(10, 0, 0, 0),
      		End_Time__c = Time.newInstance(15, 30, 0, 0),
        	Flow_Start_Time_Field__c = '1000',
        	Flow_End_Time_Field__c = '1530',
        	WB_Projected_Procedures__c = 4,
        	X2RBC_Projected_Procedures__c = 2,
        	Anticipated_Registered_Donors__c = 25,
            Online_Scheduling_Enabled__c = 'No'
		);
           
		mobileOpp.AccountId = a.Id;
        mobileOpp.Source__c='Calendar Build';
        mobileOpp.Calendar_Build_Status__c='Qualified';
        opplist.add(mobileOpp);
        insert mobileOpp;
        
        
        list<Date> getAllDates = CreateTaskDM_ABMDailyBatchHelper.calculateDate(); 
        getAllDates[0]=system.today();
        system.debug('newdate'+getAllDates[0]);
		
        
        
       
        Opportunity opp=[select id,name,Source__c,Calendar_Build_Status__c from opportunity where CreatedDate >= LAST_N_DAYS:30 limit 1];
        system.debug('mobileOpp##'+mobileOpp);
        system.debug('opp###'+opp);
         
        Test.startTest();
        CreateTaskDM_ABMDailyBatchScheduler dmABMDailyTaskSch = new CreateTaskDM_ABMDailyBatchScheduler(100);
		System.schedule('Create DM AMB Task Batch1', '0 30 2 * * ?', dmABMDailyTaskSch );
        
        CreateTaskDM_ABMDailyBatch ba= new CreateTaskDM_ABMDailyBatch();
        Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
    }
}