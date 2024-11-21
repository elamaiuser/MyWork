/*
* This Test class covering following class
* ARCFileUploadController
*/
@isTest(SeeAllData=false)
public class ARCFileUploadControllerTest {
    
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup 
    public static void prepareDataset(){
        recordTypeMap = recordTypeMap( 'Account' );
    }
    
    @isTest static void getAvailableFileTypes() {
        
        
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
            
            insert mobileAccList;
            
            // insert file
			// contentversion
            ContentVersion contentVersionInsert = new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content Data'),
                IsMajorVersion = true
            );
            insert contentVersionInsert;
            
            
            ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
            //System.debug( 'filesUploaded is##' + contentVersionSelect.ContentDocumentId  );
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            System.assertEquals(documents.size(), 1);
            
            
            //Create ContentDocumentLink 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = mobileAccList[0].Id;
            cdl.ContentDocumentId = contentVersionSelect.ContentDocumentId;
            cdl.shareType = 'V';
            Insert cdl;
            
            
            List<String> uploadedFileIds = new List<String>();
            uploadedFileIds.add(contentVersionSelect.ContentDocumentId );
            
            List<ContentVersion> filesUploaded = new List<ContentVersion>();
            filesUploaded = [SELECT Id,
                             Title,
                             ContentDocumentId,
                             FileExtension,
                             FileType,
                             Description 
                             FROM ContentVersion 
                             WHERE ContentDocumentId IN :uploadedFileIds];
            
            
            ARCFileUploadController.getFileTypeAndInsert( 'Community Agreements', uploadedFileIds);
            ARCFileUploadController.getContentDocumentId(mobileAccList[0].Id);
            
            List<String> fileIds = new List<String>();
            fileIds.add(contentVersionSelect.ContentDocumentId);
			ARCFileUploadController.getFilesAndDelete( fileIds );
			
			
            
            ARCFileUploadController.getAvailableFileTypes( mobileAccList[0].Id );
            ARCFileUploadController.getAvailableFileFormats();
			
            
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