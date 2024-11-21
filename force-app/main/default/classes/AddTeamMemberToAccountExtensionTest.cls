/*
* This Test class covering following class
* AddTeamMemberToAccountExtension
*/
@isTest(SeeAllData=false)
public class AddTeamMemberToAccountExtensionTest {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Account' );
    }
    
    @isTest static void getSelectedRecords() {
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
            System.debug( 'recTypeId is ' + recTypeId );
            List<Account> mobileAccList = new List<Account>();
            
            Account accobj;
            
            accobj = new Account();
            accobj.RecordTypeId = recTypeId;
            accobj.Name = 'Exavalu';
            accobj.BillingPostalCode = '30146';
            
            mobileAccList.add(accobj);
            
            accobj = new Account();
            accobj.RecordTypeId = recTypeId;
            accobj.Name = 'Exavalu 2';
            accobj.BillingPostalCode = '30147';
            
            mobileAccList.add(accobj);
            
            
            
            insert mobileAccList;
            
            // setting visualforce page
            PageReference pageRef = Page.AddTeamMemberToAccountPage;      
            Test.setCurrentPage(pageRef);
            
            // Initialising StandardSetController Extension
            ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, OwnerId FROM Account LIMIT 2]));
            setCon.setSelected([SELECT Id, OwnerId FROM Account LIMIT 2]); // this method gives selected records
            
            AddTeamMemberToAccountExtension atmext = new AddTeamMemberToAccountExtension(setCon);
            
            List<Account> acclist = [SELECT Id, OwnerId FROM Account LIMIT 2];
            
            System.assertEquals(2, acclist.size() );
            
        }
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