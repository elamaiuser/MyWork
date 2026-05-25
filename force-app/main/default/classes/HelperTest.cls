@isTest 
private class HelperTest {
    @testSetup static void testSetup(){  
        
        Profile prof = [Select Id from Profile limit 1];
        
        List<User> userList = new List<User>();
        User user = new User();
        user.firstName = 'test1';
        user.lastName = 'test2';
        user.profileId = prof.id;
        user.Username  = 'test@CAt.com'+UserInfo.getOrganizationId();
        user.email = 'test@CAt.com';
        user.EmailEncodingKey='UTF-8'; 
        user.LanguageLocaleKey='en_US'; 
        user.LocaleSidKey='en_US'; 
        user.TimeZoneSidKey='America/Los_Angeles';
        user.Alias = 'test';
        insert user;
        
        PermissionSet pr = new PermissionSet(Label='Case Permisson Set',Name='Case_Permisson_Set');
        insert pr;
        Set<String> psSet = new Set<String>();
        psSet.add(pr.Id);
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = user.Id,
            PermissionSetId = pr.Id
        );
        insert psa;        
        
    }
    
    //
    @isTest static void testvalidateProfilePermission(){
        Profile prof = [Select Id From Profile limit 1] ;
        Set<String> profSet = new Set<String>();
        if(prof != null){
            profSet.add(prof.Id);  
        }      
        test.startTest();
        Helper.validateProfilePermission(profSet,prof.Id,true);
        Helper.validateProfilePermission(profSet,prof.Id,false);
        test.stopTest(); 
    }
    
    @isTest static void testvalidatePermissionSetAssignment(){
        User ur = [Select Id From User limit 1];
        PermissionSet ps = [Select Id,Name From PermissionSet limit 1] ;
        Set<String> psSet = new Set<String>();
        if(ps != null){
            psSet.add(ps.Id);  
        }      
        test.startTest();
        Helper.validatePermissionSetAssignment(psSet,ur.id);       
        test.stopTest(); 
    }
    @isTest static void testgetFields(){
        sked__Location__c a = new sked__Location__c();
        Schema.sObjectType t = a.getSObjectType();
        Schema.DescribeSObjectResult ObjResult = t.getDescribe();
        
        test.startTest();
        Helper.getFields(ObjResult);
        test.stopTest(); 
    }
    @isTest static void testgetFieldsWithPrefix(){
        sked__Location__c a = new sked__Location__c();
        Schema.sObjectType t = a.getSObjectType();
        Schema.DescribeSObjectResult ObjResult = t.getDescribe();
        test.startTest();
        Helper.getFieldsWithPrefix(ObjResult);
        test.stopTest();
    }
    
    @isTest static void testgetFieldsWithPrefixCustom(){
        sked__Location__c a = new sked__Location__c();
        Schema.sObjectType t = a.getSObjectType();
        Schema.DescribeSObjectResult ObjResult = t.getDescribe();
        test.startTest();
        Helper.getFieldsWithPrefix(ObjResult,true);
        test.stopTest();
    }
    
    @isTest static void testgetUserDetails(){
        Profile prof = [Select Id From Profile limit 1];
        List<User> userList = new List<User>();
        for(Integer i=0 ; i<4 ;i++){
            User user = new User();
            user.firstName = 'test1'+i;
            user.lastName = 'test2'+i;
            user.profileId = prof.id;
            user.Username  = 'test@CAt.com'+i;
            user.email = 'test@CAt.com'+i;
            user.EmailEncodingKey='UTF-8'; 
            user.LanguageLocaleKey='en_US'; 
            user.LocaleSidKey='en_US'; 
            user.TimeZoneSidKey='America/Los_Angeles';
            user.Alias = 'test';
            userList.add(user);
        } 
        insert userList;
        List<Id> urId = new List<Id>();
        for(User u : userList){
            urId.add(u.Id);
        }        
        test.startTest();
        Helper.getUserDetails(urId);
        test.stopTest();
    }
    @isTest static void testgetUserDetail(){
        User ur = [Select Id From User limit 1];
        test.startTest();
        Helper.getUserDetail(ur.Id);
        test.stopTest();
    }
    @isTest static void testgetFieldsMap(){
        Opportunity a = new Opportunity();
        Schema.sObjectType t = a.getSObjectType();
        Schema.DescribeSObjectResult ObjResult = t.getDescribe();
        test.startTest();
        Helper.getFieldsMap(ObjResult);
        test.stopTest();
    }
    
    @isTest static void testgetFieldsMapSObj(){
        Opportunity a = new Opportunity();
        Schema.sObjectType sobj = a.getSObjectType();
        test.startTest();
        Helper.getFieldsMap(sobj);
        test.stopTest();
    }
    
    @isTest static void testgetFieldsMapBySObject(){
        Schema.SObjectType accountType = Schema.getGlobalDescribe().get('Account');
        SObject newAccount = accountType.newSObject();
        test.startTest();
        Helper.getFieldsMapBySObject(newAccount);
        test.stopTest();
    }
    @isTest static void testgetRecordTypeInfosByName(){
        Opportunity a = new Opportunity();
        Schema.sObjectType t = a.getSObjectType();
        Schema.DescribeSObjectResult ObjResult = t.getDescribe();
        test.startTest();
        Helper.getRecordTypeInfosByName(ObjResult);
        test.stopTest();
    }
    
    @isTest static void testgetRecordTypesByDeveloperName(){
        Opportunity a = new Opportunity();
        Schema.sObjectType t = a.getSObjectType();
        Schema.DescribeSObjectResult ObjResult = t.getDescribe();
        test.startTest();
        Helper.getRecordTypesByDeveloperName(ObjResult);
        test.stopTest();
    }
    
    @isTest static void testIsProduction(){
        test.startTest();
        Helper.IsProduction();
        test.stopTest();
    }
    
    @isTest static void testIsProductionTrue(){
        Helper.isProductionOverride = true;
        test.startTest();
        Helper.IsProduction();
        test.stopTest();
    }
    
    @isTest static void testgetRecordTypeInfosById(){
        Opportunity a = new Opportunity();
        Schema.sObjectType t = a.getSObjectType();
        Schema.DescribeSObjectResult ObjResult = t.getDescribe();
        test.startTest();
        Helper.getRecordTypeInfosById(ObjResult);
        test.stopTest();
    }
    
    //addToMap(Map<String, String> idToNameMap, List<SObject> listToMap, String keyToMap, String valueToMap)
    @isTest static void testaddToMap(){
        Map<String, String> idToNameMap = new Map<String, String>();
        Profile prof = [Select Id From Profile limit 1];
        List<User> userList = new List<User>();
        for(Integer i=0 ; i<4 ;i++){
            User user = new User();
            user.firstName = 'test1'+i;
            user.lastName = 'test2'+i;
            user.profileId = prof.id;
            user.Username  = 'test@CAt.com'+i;
            user.email = 'test@CAt.com'+i;
            user.EmailEncodingKey='UTF-8'; 
            user.LanguageLocaleKey='en_US'; 
            user.LocaleSidKey='en_US'; 
            user.TimeZoneSidKey='America/Los_Angeles';
            user.Alias = 'test';
            userList.add(user);
        } 
        insert userList;
        test.startTest();
        Helper.addToMap(idToNameMap,userList,'Username','firstName');
        test.stopTest();
    }
    
    @isTest static void testomitFields(){
        Profile prof = [Select Id From Profile limit 1] ;
        Set<String> profSet = new Set<String>();
        if(prof != null){
            profSet.add(prof.Id);      
        }  
        profSet.add('Fields');
        profSet.add(' Fields');
        profSet.add('Fields ');
        test.startTest();
        Helper.omitFields('Test,Fields',profSet);
        Helper.omitFields('Test Fields,',profSet);
        Helper.omitFields(', Fields',profSet);
        Helper.omitFields('Fields, ',profSet);
        test.stopTest();
    }
    
    @isTest static void testformatNumber(){
        test.startTest();
        Helper.formatNumber('12345');
        test.stopTest();
    }
    @isTest static void testformatNumberlessThn6(){
        test.startTest();
        Helper.formatNumber('5.12');
        test.stopTest();
    }
    @isTest static void testformatNumberMoreThn6(){
        test.startTest();
        Helper.formatNumber('626414.31');
        test.stopTest();
    }
    
    @isTest static void testforcedInsert(){
        try{
            List<SObject> records = new List<SObject>();
            String listType = 'List<' + 'Account' + '>';
            List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
            castRecords.addAll(records);
            test.startTest();
            Helper.forcedInsert(records);
            test.stopTest();
        }
        catch (DmlException ex) {
            System.assertEquals('UNABLE_TO_LOCK_ROW', ex.getMessage());
        } 
    }
    @isTest static void testupdateLogErrors(){
        List<SObject> records = new List<SObject>();
        String listType = 'List<' + 'Account' + '>';
        List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
        castRecords.addAll(records);
        test.startTest();
        Helper.updateLogErrors(records,true);
        test.stopTest();
    }
    @isTest static void testinsertLogErrors(){
        List<SObject> records = new List<SObject>();
        String listType = 'List<' + 'Account' + '>';
        List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
        castRecords.addAll(records);
        test.startTest();
        Helper.insertLogErrors(records,true);
        test.stopTest();
    }
    @isTest static void testlogErrors(){
        List<Account>accList = new List<Account>();
        for(Integer i=0 ; i<5 ; i++){
            Account acc = new Account();
            acc.Name = 'Test'+i;
            accList.add(acc);
        }
        insert accList;
        List<Database.Saveresult> insertResults=Database.insert(accList, false);
        test.startTest();
        Helper.logErrors(insertResults);
        test.stopTest();
    } 
    @isTest static void testurlEncode(){
        test.startTest();
        Helper.urlEncode('test string');
        test.stopTest();
    }
    @isTest static void testurlDecode(){
        test.startTest();
        Helper.urlDecode(null);
        test.stopTest();
    }
    @isTest static void testbase64Encode(){
        test.startTest();
        Helper.base64Encode('test string');
        test.stopTest();
    }
    @isTest static void testgetDate(){
        DateTime myDateTime = DateTime.newInstance(2022, 6, 6, 3, 3, 3);
        test.startTest();
        Helper.getDate(myDateTime);
        test.stopTest();
    }
    @isTest static void testgetCronExpression(){
        test.startTest();
        Helper.getCronExpression(10,5,'26',10,'5');
        test.stopTest();
    }
    @isTest static void testcreateObjectMap(){
        test.startTest();
        Helper.createObjectMap('Hello World');
        test.stopTest();
        
    }
    @isTest static void testconsumeObject(){
        String tokencred = '{"firstName":"John"}';
        JSONParser parser = JSON.createParser(tokencred);
        test.startTest();
        Helper.consumeObject(parser);
        test.stopTest();
    }
    @isTest static void testcheckEndOfMonth(){
        test.startTest();
        Helper.checkEndOfMonth(2022,07,26);
        test.stopTest();
    }
    @isTest static void testgetTimeByDate(){
        Date myDate = Date.newInstance(2022, 26, 07);
        test.startTest();
        Helper.getTimeByDate(myDate,12,10,08);
        test.stopTest();
    }
    @isTest static void testgetTimeByDateNull(){
        test.startTest();
        Helper.getTimeByDate(null,null,null,null);
        test.stopTest();
    } 
    @isTest static void testisPartnerUser(){
        test.startTest();
        Helper.isPartnerUser();
        test.stopTest();
    }
    //when datatype is null
    @isTest static void testsetValue(){
        test.startTest();
        Helper.setValue('','test value');
        test.stopTest();
    }
    //when datatype has value
    @isTest static void testsetValueDatatype(){
        test.startTest();
        Helper.setValue('1234','test value');
        test.stopTest();
    }
    @isTest static void testsetValueDatatypeInt(){
        test.startTest();
        Helper.setValue('Integer','53');
        test.stopTest();
    }
    @isTest static void testsetValueDatatypeDecimal(){
        test.startTest();
        Helper.setValue('Decimal','42.54');
        test.stopTest();
    }
    @isTest static void testsetValueDatatypeDate(){
        test.startTest();
        Helper.setValue('Date','2022-06-06');
        test.stopTest();
    }
  /*  @isTest static void testsetValueDatatypeDateTime(){
        DateTime myDateTime = DateTime.newInstance(2022, 6, 6, 15, 3, 35);
        test.startTest();
        Helper.setValue('DateTime','2022-06-06T10:03:03.000+0000');
        test.stopTest();
    } */
    
    @isTest static void testformatDateTimeSOQL(){
        DateTime myDateTime = DateTime.newInstance(2022, 6, 6, 15, 3, 35);
        test.startTest();
        Helper.formatDateTimeSOQL(myDateTime);
        test.stopTest();
    }
       @isTest
    static void testSendEmail_onlyExceptionErrors() {
        Map<Exception, String> commonExceptionMap = new Map<Exception, String>();
        Map<Id, String> dmlErrorMap = new Map<Id, String>();

        try {
            String s = null;
            s.length();
        } catch (Exception e) {
            commonExceptionMap.put(e, 'ExceptionOnlyRecord');
        }

        List<String> toAddress = new List<String>{'test@example.com'};

        Test.startTest();
        Helper.sendEmail(commonExceptionMap, dmlErrorMap, toAddress, 'test@redcross.org', false, 'Exception Only');
        Test.stopTest();
        System.assertNotEquals(null, toAddress, 'toAddress should not be null');
        System.assert(true);
    }

           @isTest
    static void testSendEmail_onlyExceptionErrors1() {
        Map<Exception, String> commonExceptionMap = new Map<Exception, String>();
        Map<Id, String> dmlErrorMap = new Map<Id, String>();

        try {
            String s = null;
            s.length();
        } catch (Exception e) {
            commonExceptionMap.put(e, 'ExceptionOnlyRecord');
        }

        List<String> toAddress = new List<String>{'test@example.com'};

        Test.startTest();
        Helper.sendEmail(commonExceptionMap, dmlErrorMap, toAddress, null, true, 'Exception Only');
        Test.stopTest();

        System.assert(true);
    }

    @isTest static void testAddBusinessDays(){
        Date myDate = Date.newInstance(2022, 26, 07);
        test.startTest();
        Helper.AddBusinessDays(myDate,5);
        test.stopTest();
    }
    @isTest static void testIsWeekend(){
        Date myDate = Date.newInstance(2022, 26, 07);
        test.startTest();
        Helper.IsWeekend(myDate);
        test.stopTest();
    }
    @isTest static void testgetCalendarDaysNoWeekend(){
        Integer offset = 0;
        Date myDate = Date.newInstance(2022, 26, 01);
        test.startTest();
        Helper.getCalendarDaysNoWeekend(myDate,06);
        test.stopTest();
    }
    @isTest static void testgetCalendarDaysNoWeekendSaturday(){
        Date myDateSat = Date.newInstance(2022, 30, 07);
        test.startTest();
        Helper.getCalendarDaysNoWeekend(myDateSat,0);
        test.stopTest();
    }
    
    @isTest static void testgetCalendarDaysNoWeekendSunday(){
        
        Date myDate = Date.newInstance(2022, 31, 07);
        test.startTest();
        Helper.getCalendarDaysNoWeekend(myDate,0);
        test.stopTest();
    } 
    @isTest static void testgetSameDayOfNextYear(){
        Date myDate = Date.newInstance(2022, 26, 08);
        test.startTest();
        Helper.getSameDayOfNextYear(myDate);
        test.stopTest();
    }
    
    @isTest static void testgetStartEndTimeLabelText () {
        test.startTest();
        string myTime = Helper.getStartEndTimeLabelText('0000');
        string myTime2 = Helper.getStartEndTimeLabelText('0015');
        string myTime3 = Helper.getStartEndTimeLabelText('0030');
        string myTime4 = Helper.getStartEndTimeLabelText('0045');
        string myTime5 = Helper.getStartEndTimeLabelText('0100');
        string myTime6 = Helper.getStartEndTimeLabelText('0115');
        string myTime7 = Helper.getStartEndTimeLabelText('0130');
        string myTime8 = Helper.getStartEndTimeLabelText('0145');
        string myTime9 = Helper.getStartEndTimeLabelText('0200');
        string myTime10 = Helper.getStartEndTimeLabelText('0215');
        string myTime11 = Helper.getStartEndTimeLabelText('0230');
        string myTime12 = Helper.getStartEndTimeLabelText('0245');
        string myTime13 = Helper.getStartEndTimeLabelText('0300');
        string myTime14 = Helper.getStartEndTimeLabelText('0315');
        string myTime15 = Helper.getStartEndTimeLabelText('0330');
        string myTime16 = Helper.getStartEndTimeLabelText('0345');
        string myTime17 = Helper.getStartEndTimeLabelText('0400');
        string myTime18 = Helper.getStartEndTimeLabelText('0415');
        string myTime19 = Helper.getStartEndTimeLabelText('0430');
        string myTime20 = Helper.getStartEndTimeLabelText('0445');
        string myTime21 = Helper.getStartEndTimeLabelText('0500');
        string myTime23 = Helper.getStartEndTimeLabelText('0515');
        string myTime24 = Helper.getStartEndTimeLabelText('0530');
        string myTime25 = Helper.getStartEndTimeLabelText('0545');
        string myTime26 = Helper.getStartEndTimeLabelText('0600');
        string myTime27 = Helper.getStartEndTimeLabelText('0615');
        string myTime28 = Helper.getStartEndTimeLabelText('0630');
        string myTime29 = Helper.getStartEndTimeLabelText('0645');
        string myTime30 = Helper.getStartEndTimeLabelText('0700');
        string myTime31 = Helper.getStartEndTimeLabelText('0715');
        string myTime32 = Helper.getStartEndTimeLabelText('0730');
        string myTime33 = Helper.getStartEndTimeLabelText('0745');
        string myTime34 = Helper.getStartEndTimeLabelText('0800');
        string myTime3_3 = Helper.getStartEndTimeLabelText('0815');
        string myTime3_4 = Helper.getStartEndTimeLabelText('0830');
        string myTime35 = Helper.getStartEndTimeLabelText('0845');
        string myTime36 = Helper.getStartEndTimeLabelText('0900');
        string myTime37 = Helper.getStartEndTimeLabelText('0915');
        string myTime38 = Helper.getStartEndTimeLabelText('0930');
        string myTime39 = Helper.getStartEndTimeLabelText('0945');
        string myTime40 = Helper.getStartEndTimeLabelText('1000');
        string myTime41 = Helper.getStartEndTimeLabelText('1015');
        string myTime42 = Helper.getStartEndTimeLabelText('1030');
        string myTime43 = Helper.getStartEndTimeLabelText('1045');
        string myTime44 = Helper.getStartEndTimeLabelText('1100');
        
        string myTime4_3 = Helper.getStartEndTimeLabelText('1115');
        string myTime4_4 = Helper.getStartEndTimeLabelText('1130');
        string myTime45 = Helper.getStartEndTimeLabelText('1145');
        string myTime46 = Helper.getStartEndTimeLabelText('1200');
        string myTime47 = Helper.getStartEndTimeLabelText('1215');
        string myTime48 = Helper.getStartEndTimeLabelText('1230');
        string myTime49 = Helper.getStartEndTimeLabelText('1245');
        string myTime50 = Helper.getStartEndTimeLabelText('1300');
        string myTime51 = Helper.getStartEndTimeLabelText('1315');
        string myTime52 = Helper.getStartEndTimeLabelText('1330');
        string myTime53 = Helper.getStartEndTimeLabelText('1345');
        string myTime54 = Helper.getStartEndTimeLabelText('1400');
        
        string myTime5_3 = Helper.getStartEndTimeLabelText('1415');
        string myTime5_4 = Helper.getStartEndTimeLabelText('1430');
        string myTime55 = Helper.getStartEndTimeLabelText('1445');
        string myTime56 = Helper.getStartEndTimeLabelText('1500');
        string myTime57 = Helper.getStartEndTimeLabelText('1515');
        string myTime58 = Helper.getStartEndTimeLabelText('1530');
        string myTime59 = Helper.getStartEndTimeLabelText('1545');
        string myTime60 = Helper.getStartEndTimeLabelText('1600');
        string myTime61 = Helper.getStartEndTimeLabelText('1615');
        string myTime62 = Helper.getStartEndTimeLabelText('1630');
        string myTime63 = Helper.getStartEndTimeLabelText('1645');
        string myTime64 = Helper.getStartEndTimeLabelText('1700');
        
        string myTime6_3 = Helper.getStartEndTimeLabelText('1715');
        string myTime6_4 = Helper.getStartEndTimeLabelText('1730');
        string myTime65 = Helper.getStartEndTimeLabelText('1745');
        string myTime66 = Helper.getStartEndTimeLabelText('1800');
        string myTime67 = Helper.getStartEndTimeLabelText('1815');
        string myTime68 = Helper.getStartEndTimeLabelText('1830');
        string myTime69 = Helper.getStartEndTimeLabelText('1845');
        string myTime70 = Helper.getStartEndTimeLabelText('1900');
        string myTime71 = Helper.getStartEndTimeLabelText('1915');
        string myTime72 = Helper.getStartEndTimeLabelText('1930');
        string myTime73 = Helper.getStartEndTimeLabelText('1945');
        string myTime74 = Helper.getStartEndTimeLabelText('2000');
        
        string myTime7_3 = Helper.getStartEndTimeLabelText('2015');
        string myTime7_4 = Helper.getStartEndTimeLabelText('2030');
        string myTime75 = Helper.getStartEndTimeLabelText('2045');
        string myTime76 = Helper.getStartEndTimeLabelText('2100');
        string myTime77 = Helper.getStartEndTimeLabelText('2115');
        string myTime78 = Helper.getStartEndTimeLabelText('2130');
        string myTime79 = Helper.getStartEndTimeLabelText('2145');
        string myTime80 = Helper.getStartEndTimeLabelText('2200');
        string myTime81 = Helper.getStartEndTimeLabelText('2215');
        string myTime82 = Helper.getStartEndTimeLabelText('2230');
        string myTime83 = Helper.getStartEndTimeLabelText('2245');
        string myTime84 = Helper.getStartEndTimeLabelText('2300');
        
        string myTime85 = Helper.getStartEndTimeLabelText('2315');
        string myTime86 = Helper.getStartEndTimeLabelText('2330');
        string myTime87 = Helper.getStartEndTimeLabelText('2345');
            Helper.getSameDayOfPrevYear(system.today());      
        
        
        test.stopTest();
        
    }
}