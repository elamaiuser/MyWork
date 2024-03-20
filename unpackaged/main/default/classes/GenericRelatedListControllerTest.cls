/*
* This Test class covering following class
* GenericRelatedListController
*/
@isTest(SeeAllData=false)
public class GenericRelatedListControllerTest {
    
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
        
        //UserRole urole  = [select id from userrole where developername =: rolename ];
        
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
            LocaleSidKey = 'en_US'
            //UserRoleId = urole.Id
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
            
            System.debug( 'mobileAccList is ' + mobileAccList );
            
            List<Task> taskList = new List<Task>();
            Task tsk = new Task();
            tsk.OwnerId = DRDAMUser.Id;
            tsk.Subject='Call';
            tsk.Status='Not Started';
            tsk.Priority='Normal';
            tsk.whatid =  mobileAccList[0].Id ;
            
            taskList.add( tsk );
            
            tsk = new Task();
            tsk.OwnerId = DRDAMUser.Id;
            tsk.Subject='Call';
            tsk.Status='Not Started';
            tsk.Priority='Normal';
            tsk.whatid =  mobileAccList[0].Id ;
            
            taskList.add( tsk );
            
            
            
            try{
                insert taskList;
            }catch(Exception e){
                System.debug( 'line # is ' + e.getLineNumber() + ' msg is ' + e.getMessage() );
            }
               
            
            String[] recordId = new List<String>();
            System.debug( 'recordId is before add' );
            recordId.add( mobileAccList[0].Id);
            //recordId.add( mobileAccList[1].Id);
            System.debug( 'recordId is ' + recordId );
            String columnName = 'Name';
            
            String soqlQuery = 'Select Name from Account where Id IN: ';
            Integer limits = 10;
            Integer recordOffset = 100;
            
            GenericRelatedListController.getRecords(recordId,columnName,soqlQuery,limits,recordOffset,null );
            GenericRelatedListController.getRecords(recordId,columnName,'select Id From Contact Where Name IN (\'Exavalu\', \'Exavalu 2\')  AND Id IN: ',limits,recordOffset,null );
            GenericRelatedListController.deleteRecords(taskList[0].Id );
            
            
            List<Task> tList = [select Id from Task]; 
            System.assertEquals( 1, tList.size() );
            
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