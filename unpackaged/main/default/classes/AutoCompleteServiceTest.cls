/* This test class is covering the below apex class
 *  AutoCompleteService
 * */

@isTest(SeeAllData=false)
public class AutoCompleteServiceTest {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Fixed Site Account';
    public static String fixedOppRecType = 'Fixed Site Opp';
    public static String taskRecType = '72 Hour Check In';
    public static Map<String,Id> accrecordTypeMap  = new Map<String,Id>();
    
    @testSetup static void prepareDataset()
    {
        User AdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            FirstName='SystemAdmin',
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        
        UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
            FirstName = 'Amy',
            LastName = 'Brown',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = urole.Id
        );
        
        
        System.runAs( AdminUser ){
            insert DRDAMUser;
        }
        
        System.runAs( AdminUser ){
            accrecordTypeMap = recordTypeMap( 'Account' );
            Id recTypeId = accrecordTypeMap.get(mobileAccRecType);
            List<Account> mobileAccList = new List<Account>(); 
            
            Account accobj;
            accobj= new Account();
            accobj.RecordTypeId = recTypeId;
            accobj.Name = 'Exavalu 1';
            accobj.Internal_Name__c = 'Exavalu 1';
            accobj.District_Manager__c = UserInfo.getUserId();
        	accobj.BillingStreet = '2204 Westcrt ln, Apt 213'; 
        	accobj.BillingCity = 'Herndon';
        	accobj.BillingStateCode = 'MI';
        	accobj.BillingPostalCode = '48420';
            mobileAccList.add(accobj);
            
            accobj= new Account();
            accobj.RecordTypeId = recTypeId;
            accobj.Name = 'Exavalu Company';
            accobj.Internal_Name__c = 'Exavalu Company';
        	accobj.BillingStreet = '2204 Westcrt ln, Apt 213';
        	accobj.BillingCity = 'Herndon';
        	accobj.BillingStateCode = 'MI';
        	accobj.BillingPostalCode = '48421';
            mobileAccList.add(accobj);
            
            
            insert mobileAccList;
    	}
    }
    
    @isTest static void getAcValuesTest()
    {
        List<Account> accList = new List<Account>();
        accList = [select Id , Name from Account where name in ('Exavalu 1' , 'Exavalu Company')];
        Test.startTest();
        List<AutoCompleteService.Option> optionList =  AutoCompleteService.getACValues('Account', 'Name' , 'Internal_Name__c' , 'Exavalu' , '1');
        Test.stopTest();
        system.assert(optionList.size()==1); // one record will be appeared as the limit has been set as 1
    }
    
    //Method to get the map of recordType Name as key and recordTypeId as value 
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