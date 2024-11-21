/*
 * This Test class covering following class
 * AddTeamMemberToAccount
 */
@isTest(SeeAllData=false)
public class AddTeamMemberToAccountTest {
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Account' );
    }
    
    
    @isTest static void addAccountTeamMember() {       
        
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
        
        User DRDAMUser2 = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             FirstName = 'Selena',
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
            insert DRDAMUser2;
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
            
            insert mobileAccList;
            
            List<String> selectedIdsList = new List<String>();
            selectedIdsList.add( mobileAccList[0].Id );
            
            Date currentdate = System.today();
            Date nextdate = System.today().addDays(5);

            String month = currentdate.month() <10 ? '0' + String.valueOf(currentdate.month()) : String.valueOf(currentdate.month()) ;
            String day = currentdate.day() <10 ? '0' + String.valueOf(currentdate.day()) : String.valueOf(currentdate.day()) ;
            String year = String.valueOf(currentdate.Year());
            String st_date = year + '-' + month + '-' + day ;

            month = nextdate.month() <10 ? '0' + String.valueOf(nextdate.month()) : String.valueOf(nextdate.month()) ;
            day = nextdate.day() <10 ? '0' + String.valueOf(nextdate.day()) : String.valueOf(nextdate.day()) ;
            year = String.valueOf(nextdate.Year());
            String ed_date = year + '-' + month + '-' + day ;

            AddTeamMemberToAccount.AddTeamMember  atm = new AddTeamMemberToAccount.AddTeamMember();
            atm.userId = DRDAMUser2.Id;
            atm.teamRole = 'Account Manager';
            atm.accountAccessLevel = 'Read';
            atm.caseAccessLevel = 'None';
            atm.bloodDriveAccessLevel = 'None';
            atm.startDate = st_date; // 2021-05-15;
            atm.endDate = ed_date ;
            String atmJson = JSON.serialize( atm );
            
            AddTeamMemberToAccount.addAccountTeamMember( atmJson, selectedIdsList);
            
            
            
        }
        
        List<AccountTeammember> atmem = [select Id from AccountTeammember limit 1]; 
            System.assert( atmem.size() == 1 );
    }   
    
    @isTest static void addAccountDistricManager() {       
        
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
        
        User DRDAMUser2 = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             FirstName = 'Selena',
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
            insert DRDAMUser2;
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
            
            insert mobileAccList;
            
            List<String> selectedIdsList = new List<String>();
            selectedIdsList.add( mobileAccList[0].Id );
            
            Date currentdate = System.today();
            Date nextdate = System.today().addDays(5);

            String month = currentdate.month() <10 ? '0' + String.valueOf(currentdate.month()) : String.valueOf(currentdate.month()) ;
            String day = currentdate.day() <10 ? '0' + String.valueOf(currentdate.day()) : String.valueOf(currentdate.day()) ;
            String year = String.valueOf(currentdate.Year());
            String st_date = year + '-' + month + '-' + day ;

            month = nextdate.month() <10 ? '0' + String.valueOf(nextdate.month()) : String.valueOf(nextdate.month()) ;
            day = nextdate.day() <10 ? '0' + String.valueOf(nextdate.day()) : String.valueOf(nextdate.day()) ;
            year = String.valueOf(nextdate.Year());
            String ed_date = year + '-' + month + '-' + day ;


            AddTeamMemberToAccount.AddTeamMember  atm = new AddTeamMemberToAccount.AddTeamMember();
            atm.userId = DRDAMUser2.Id;
            atm.teamRole = 'District Manager';
            atm.accountAccessLevel = 'Read';
            atm.caseAccessLevel = 'None';
            atm.bloodDriveAccessLevel = 'None';
            atm.startDate = st_date; // 2021-05-15;
            atm.endDate = ed_date ;
            String atmJson = JSON.serialize( atm );
            
            AddTeamMemberToAccount.addAccountTeamMember( atmJson, selectedIdsList);
            
            
            
        }
        
        List<AccountTeammember> atmem = [select Id from AccountTeammember limit 1]; 
            System.assert( atmem.size() == 1 );
    }
    
    @isTest static void addAccountTemporaryManager() {       
        
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
        
        User DRDAMUser2 = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             FirstName = 'Selena',
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
            insert DRDAMUser2;
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
            
            insert mobileAccList;
            
            List<String> selectedIdsList = new List<String>();
            selectedIdsList.add( mobileAccList[0].Id );
            
            Date currentdate = System.today();
            Date nextdate = System.today().addDays(5);
            
            String month = currentdate.month() <10 ? '0' + String.valueOf(currentdate.month()) : String.valueOf(currentdate.month()) ;
            String day = currentdate.day() <10 ? '0' + String.valueOf(currentdate.day()) : String.valueOf(currentdate.day()) ;
            String year = String.valueOf(currentdate.Year());
            String st_date = year + '-' + month + '-' + day ;
            
            month = nextdate.month() <10 ? '0' + String.valueOf(nextdate.month()) : String.valueOf(nextdate.month()) ;
            day = nextdate.day() <10 ? '0' + String.valueOf(nextdate.day()) : String.valueOf(nextdate.day()) ;
            year = String.valueOf(nextdate.Year());
            String ed_date = year + '-' + month + '-' + day ;
            
            
            AddTeamMemberToAccount.AddTeamMember  atm = new AddTeamMemberToAccount.AddTeamMember();
            atm.userId = DRDAMUser2.Id;
            atm.teamRole = 'Temporary Account Manager';
            atm.accountAccessLevel = 'Read';
            atm.caseAccessLevel = 'None';
            atm.bloodDriveAccessLevel = 'None';
            atm.startDate = st_date; // 2021-05-15;
            atm.endDate = ed_date ;
            String atmJson = JSON.serialize( atm );
            
            AddTeamMemberToAccount.addAccountTeamMember( atmJson, selectedIdsList);
            
            
            AddTeamMemberToAccount.getAccountNames( selectedIdsList);
            
            
            
        }
        
        List<AccountTeammember> atmem = [select Id from AccountTeammember limit 1]; 
            System.assert( atmem.size() == 1 );
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