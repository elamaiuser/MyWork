@isTest
private class skedErrorUtils_Test {
    @isTest 
    static void testGetPartialUpdateErrorString() {
        Account testAccount = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c = 'Test Internal Name',
            APT_Required__c = FALSE,
            Type = skedConstants.ACCOUNT_TYPE_EDUCATION,
            Industry_Code__c = skedConstants.ACCOUNT_INDUSTRY_CODE_HIGH_SCHOOL
        );
        insert testAccount;
        List<sObject> affectedRecords = new List<sObject>{testAccount};
        List<Database.SaveResult> saveResults = Database.update(affectedRecords, false);
        String errorString = skedErrorUtils.getPartialUpdateErrorString(saveResults, affectedRecords, 'Account');
        System.assertEquals(null, errorString);

        testAccount.Name = null;
        saveResults = Database.update(affectedRecords, false);
        errorString = skedErrorUtils.getPartialUpdateErrorString(saveResults, affectedRecords, 'Account');
        System.assertEquals('The following errors have occured:\n-- Object Account with record ID ' + testAccount.Id + ' --\nFields: Name\nMessage: Required fields are missing: [Name]\nStatus Code: REQUIRED_FIELD_MISSING', errorString);

        delete testAccount;

        saveResults = Database.update(affectedRecords, false);
        errorString = skedErrorUtils.getPartialUpdateErrorString(saveResults, affectedRecords, 'Account');
        System.assertEquals('The following errors have occured:\n-- Object Account with record IDs ' + testAccount.Id + ' failed by following errors --\nFields: \nMessage: entity is deleted\nStatus Code: ENTITY_IS_DELETED', errorString);
    }

    @isTest
    static void testGetErrorString() {
        Account testAccount = new Account(
            Name = 'Test Account',
            District_Manager__c = UserInfo.getUserId(),
            Internal_Name__c = 'Test Internal Name',
            APT_Required__c = FALSE,
            Type = skedConstants.ACCOUNT_TYPE_EDUCATION,
            Industry_Code__c = skedConstants.ACCOUNT_INDUSTRY_CODE_HIGH_SCHOOL
        );
        insert testAccount;
        testAccount.Name = null;
        List<sObject> affectedRecords = new List<sObject>{testAccount};
        List<Database.SaveResult> saveResults = Database.update(affectedRecords, false);
        String errorString = skedErrorUtils.getErrorString(saveResults[0].getErrors().get(0));
        System.assertEquals('Fields: Name\nMessage: Required fields are missing: [Name]\nStatus Code: REQUIRED_FIELD_MISSING', errorString);
    }
}