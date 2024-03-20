/*
 * This Test class covering following class
 * TaskInvokable
 */
@isTest(SeeAllData=false)
public class TaskInvokableTest {
	public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
	
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Account' );
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
    
    @isTest static void sendNotificationToTaskOwner() {
        
        
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
        
        System.runAs( DRDAMUser ){
            recordTypeMap = recordTypeMap( 'Account' );
			Id recTypeId = recordTypeMap.get(mobileAccRecType);
			List<Account> mobileAccList = new List<Account>();
			
			Account accobj;
			
			accobj = new Account();
			accobj.RecordTypeId = recTypeId;
			accobj.Name = 'Exavalu';
			accobj.BillingPostalCode = '30146';
			
			mobileAccList.add(accobj);
			
			insert mobileAccList;
			
			
            
            Task t = new Task();
			t.OwnerId = UserInfo.getUserId();
            t.whatId = mobileAccList[0].Id;
			t.Subject='Call';
			t.Status='Not Started';
			t.Priority='Normal';

			insert t;
            
            List<Task> tasklist = [select Id from Task];
            
            System.assert(tasklist!=null);
        }        
        
    }	
    
 
    
    
}