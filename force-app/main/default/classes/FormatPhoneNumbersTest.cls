/* 
 * @description: This class is the test class from FormatPhoneNumbers class.
 ************************************************************************************************************************************************
*/
@isTest
private class FormatPhoneNumbersTest {
    @TestSetup
    static void makeData(){
        Map<String,Id> recordTypeMap  = new Map<String,Id>();
        recordTypeMap = recordTypeMap( 'Account' );
        Id accRecTypeId = recordTypeMap.get('Mobile Account');

        List<Account> mobileAccList = new List<Account>();
            
        Account accObj;
        
        accObj = new Account();
        accObj.RecordTypeId = accRecTypeId;
        accObj.Name = 'Exavalu';
        accObj.BillingPostalCode = '30622';
        accObj.Internal_Name__c ='Exavalu';            
        mobileAccList.add(accobj); 
        
        triggerHandler.bypass('AccountTriggerHandler');
        insert mobileAccList;
        System.assertNotEquals(null,mobileAccList[0].Id,'Account Not inserted');

        Contact conObj = new Contact();
        conObj.AccountId = mobileAccList[0].Id;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact';
        conObj.MailingCity = 'Ashburn';
        conObj.MailingCountryCode ='US';
        conObj.MailingPostalCode = '20148';
        conObj.MailingStateCode = 'VA';
        conObj.MailingStreet = '23070 Learning Cir';
        conObj.Email = 'test.barno@mailinator.com';
        conObj.Primary_Phone__c = picklistValues('Contact','Primary_Phone__c');
        conObj.Original_Service_Date__c = Date.Today().addDays(-1000);
        conObj.HomePhone = '222-222-3333';
        conObj.MobilePhone = '222-222-3333';
        conObj.OtherPhone = '222-222-3333';
        triggerHandler.bypass('ContactTriggerHandler');
        insert conObj;
        System.assertNotEquals(null,conObj.Id,'Contact Not inserted');
    }
    @isTest
    private static void contactPhoneTest1(){
        List<Contact> con = [SELECT Id, OtherPhone,MobilePhone,HomePhone,Fax FROM Contact LIMIT 1];
        Test.startTest();
        triggerHandler.clearAllBypasses();
        try{
            con[0].MobilePhone = '222-333-3333';
            update con;
        }catch(Exception ex){
            con[0].MobilePhone = '2223333333';
            update con;
        }
        FormatPhoneNumbers classobj = new FormatPhoneNumbers();
        classobj.newRecords = con;
        classobj.format = true;
        classobj.getObjectSettings();
        classobj.formatPhoneNumbers();
        String unFormattedNo = FormatPhoneNumbers.formatPhoneNumbers('222-333-3333');
        System.assertNotEquals(null, con[0].MobilePhone, 'phone number is not updated');
        Test.stopTest();
    }
    
    @isTest
    private static void contactPhoneTest2(){
        List<Contact> con = [SELECT Id, OtherPhone,MobilePhone,HomePhone,Fax FROM Contact LIMIT 1];
        Test.startTest();
        triggerHandler.clearAllBypasses();
        try{
            con[0].MobilePhone = '222-333-333';
            update con;
        }catch(Exception ex){
            con[0].MobilePhone = '222333333';
            update con;
        }
        FormatPhoneNumbers classobj = new FormatPhoneNumbers();
        classobj.newRecords = con;
        classobj.format = true;
        classobj.getObjectSettings();
        classobj.formatPhoneNumbers();
        String unFormattedNo = FormatPhoneNumbers.formatPhoneNumbers('222-333-3333');
        System.assertNotEquals(null, con[0].MobilePhone, 'phone number is not updated');
        Test.stopTest();
    }
    
    private static String picklistValues(String objectName, String fieldName) {
        String result;

        List<Schema.DescribeSobjectResult> sobjectlist = Schema.describeSObjects(new List<String>{objectName});
        
        for(Schema.DescribeSobjectResult sobj : sobjectlist) {
            for (Schema.PicklistEntry entry : sobj.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    result = entry.getValue();
                    break;
                }
            }
        }

        return result;
    }
    private static Map<String,Id> recordTypeMap(string obj){
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null){
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values()){
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }
}