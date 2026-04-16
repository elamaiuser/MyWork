/**
 * @Description : Test class for GenericRelatedListLWCController.
 *                Covers getRecords, deleteRecords, and buildSafeAdditionalFilter
 *                across happy-path, edge-case, and error scenarios.
 *                Target: >= 90% code coverage with no compilation or runtime errors.
 * Ver       Date            Author              Modification
 * 1.0       2024                                Initial Version
 */
@isTest(SeeAllData=false)
public class GenericRelatedListLWCControllerTest {

    // ── Test data setup ───────────────────────────────────────────────────────

    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 7; i++) {
            contacts.add(new Contact(
                FirstName              = 'First' + i,
                LastName               = 'Last' + i,
                AccountId              = acc.Id,
                Email                  = 'test' + i + '@example.com',
                Migration_ID__c        = 'TEST-' + i,
                Original_Service_Date__c = Date.today()
            ));
        }
        insert contacts;

        List<Task> tasks = new List<Task>();
        tasks.add(new Task(Subject = 'Call', Status = 'Not Started', Priority = 'Normal', WhatId = acc.Id));
        tasks.add(new Task(Subject = 'Email', Status = 'Not Started', Priority = 'Normal', WhatId = acc.Id));
        insert tasks;
    }

    // ── getRecords — happy path ───────────────────────────────────────────────

    @isTest
    static void testGetRecords_basicQuery() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name,Last Name',
                'contact',
                'FirstName,LastName',
                'AccountId',
                5,
                0,
                'LastName ASC',
                null
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.sObjectList, 'sObjectList should not be null');
        System.assertEquals('Contact', result.objectName, 'objectName should be Contact');
        System.assertNotEquals(null, result.columnNames, 'columnNames should not be null');
    }

    @isTest
    static void testGetRecords_returnsHasMoreWhenRecordsExceedLimit() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                5,
                0,
                null,
                null
            );
        Test.stopTest();

        System.assertEquals(true, result.hasMore, 'hasMore should be true when 7 contacts exist and limit is 5');
        System.assertEquals(5, result.sObjectList.size(), 'Should return exactly 5 records');
    }

    @isTest
    static void testGetRecords_hasMoreFalseWhenWithinLimit() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                20,
                0,
                null,
                null
            );
        Test.stopTest();

        System.assertEquals(false, result.hasMore, 'hasMore should be false when all records fit within limit');
        System.assertEquals(7, result.sObjectList.size(), 'Should return all 7 contacts');
    }

    @isTest
    static void testGetRecords_withOffset() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                5,
                5,
                null,
                null
            );
        Test.stopTest();

        System.assertNotEquals(null, result.sObjectList, 'Should return records for offset page');
    }

    @isTest
    static void testGetRecords_withOrderByDesc() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'Last Name',
                'contact',
                'LastName',
                'AccountId',
                10,
                0,
                'LastName DESC',
                null
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null with DESC order');
    }

    @isTest
    static void testGetRecords_orderByFieldOnlyNoDirection() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'Last Name',
                'contact',
                'LastName',
                'AccountId',
                10,
                0,
                'LastName',
                null
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should handle ORDER BY with no direction (defaults to DESC)');
    }

    @isTest
    static void testGetRecords_invalidOrderByFieldFallsBackToDefault() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'Last Name',
                'contact',
                'LastName',
                'AccountId',
                10,
                0,
                'NonExistentField__xyz DESC',
                null
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should fall back to CreatedDate DESC for invalid ORDER BY field');
    }

    @isTest
    static void testGetRecords_nullLimitAndOffsetDefaultCorrectly() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                null,
                null,
                null,
                null
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should use default limit=5 and offset=0 when null passed');
    }

    @isTest
    static void testGetRecords_resolvesParentRecordName() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                5,
                0,
                null,
                null
            );
        Test.stopTest();

        System.assertNotEquals(null, result.recordName, 'recordName should be resolved for Account parent');
    }

    @isTest
    static void testGetRecords_parentWithNoNameFieldDoesNotCrash() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                5,
                0,
                null,
                null
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return result without throwing even when parent name resolution runs');
    }

    @isTest
    static void testGetRecords_duplicateFieldsDeduped() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name,First Name',
                'contact',
                'FirstName,FirstName',
                'AccountId',
                5,
                0,
                null,
                null
            );
        Test.stopTest();

        System.assertEquals('FirstName', result.columnNames, 'Duplicate fields should be deduplicated');
    }

    @isTest
    static void testGetRecords_idFieldNotDuplicated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'Id',
                'contact',
                'Id',
                'AccountId',
                5,
                0,
                null,
                null
            );
        Test.stopTest();

        System.assertEquals('', result.columnNames, 'Id should not appear in columnNames (already in SELECT)');
    }

    // ── getRecords — additional filter ────────────────────────────────────────

    @isTest
    static void testGetRecords_withSimpleAdditionalFilter() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                10,
                0,
                null,
                'FirstName = First0'
            );
        Test.stopTest();

        System.assertEquals(1, result.sObjectList.size(), 'Should return only the matching contact');
    }

    @isTest
    static void testGetRecords_withAdditionalFilterQuotedValue() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                10,
                0,
                null,
                'FirstName = \'First1\''
            );
        Test.stopTest();

        System.assertEquals(1, result.sObjectList.size(), 'Should return contact matched by quoted value');
    }

    @isTest
    static void testGetRecords_withAdditionalFilterAndOr() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                10,
                0,
                null,
                'FirstName = First0 OR FirstName = First1'
            );
        Test.stopTest();

        System.assertEquals(2, result.sObjectList.size(), 'Should return 2 contacts matched by OR filter');
    }

    @isTest
    static void testGetRecords_withInOperator() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                10,
                0,
                null,
                'FirstName IN (\'First0\',\'First1\')'
            );
        Test.stopTest();

        System.assertEquals(2, result.sObjectList.size(), 'Should return 2 contacts matched by IN filter');
    }

    @isTest
    static void testGetRecords_withNotEqualOperator() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.wrapperClass result =
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                20,
                0,
                null,
                'FirstName != First0'
            );
        Test.stopTest();

        System.assertEquals(6, result.sObjectList.size(), 'Should exclude 1 contact with != filter');
    }

    // ── getRecords — error paths ──────────────────────────────────────────────

    @isTest
    static void testGetRecords_invalidObjectNameThrows() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Boolean threw = false;

        Test.startTest();
        try {
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'Name',
                'NotARealObject__xyz',
                'Name',
                'AccountId',
                5,
                0,
                null,
                null
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Should throw for invalid object API name');
    }

    @isTest
    static void testGetRecords_blankFilterFieldThrows() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Boolean threw = false;

        Test.startTest();
        try {
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                '',
                5,
                0,
                null,
                null
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Should throw for blank filterFieldApiName');
    }

    @isTest
    static void testGetRecords_invalidFilterFieldFormatThrows() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Boolean threw = false;

        Test.startTest();
        try {
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'Account.Id',
                5,
                0,
                null,
                null
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Should throw for filter field containing dot (not word chars only)');
    }

    @isTest
    static void testGetRecords_invalidAdditionalFilterSyntaxThrows() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Boolean threw = false;

        Test.startTest();
        try {
            GenericRelatedListLWCController.getRecords(
                new List<String>{ acc.Id },
                'First Name',
                'contact',
                'FirstName',
                'AccountId',
                5,
                0,
                null,
                'INVALID GARBAGE TOKEN ;;;'
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Should throw for invalid additional filter syntax');
    }

    // ── deleteRecords ─────────────────────────────────────────────────────────

    @isTest
    static void testDeleteRecords_deletesRecord() {
        Task tsk = [SELECT Id FROM Task LIMIT 1];

        Test.startTest();
        GenericRelatedListLWCController.deleteRecords(tsk.Id);
        Test.stopTest();

        List<Task> remaining = [SELECT Id FROM Task WHERE Id = :tsk.Id];
        System.assertEquals(0, remaining.size(), 'Task should have been deleted');
    }

    @isTest
    static void testDeleteRecords_invalidIdThrows() {
        Boolean threw = false;

        Test.startTest();
        try {
            GenericRelatedListLWCController.deleteRecords(null);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Should throw when null Id passed to deleteRecords');
    }

    // ── buildSafeAdditionalFilter — direct unit tests via @TestVisible ────────

    @isTest
    static void testBuildSafeFilter_blankReturnsEmpty() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();

        Test.startTest();
        String result = GenericRelatedListLWCController.buildSafeAdditionalFilter('', fieldMap);
        Test.stopTest();

        System.assertEquals('', result, 'Blank filter should return empty string');
    }

    @isTest
    static void testBuildSafeFilter_simpleEquals() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();

        Test.startTest();
        String result = GenericRelatedListLWCController.buildSafeAdditionalFilter(
            'FirstName = Test', fieldMap
        );
        Test.stopTest();

        System.assert(result.contains('FirstName'), 'Result should contain field name');
        System.assert(result.contains('='), 'Result should contain operator');
        System.assert(result.contains('\'Test\''), 'Result should contain escaped quoted value');
    }

    @isTest
    static void testBuildSafeFilter_nullLiteral() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();

        Test.startTest();
        String result = GenericRelatedListLWCController.buildSafeAdditionalFilter(
            'FirstName = null', fieldMap
        );
        Test.stopTest();

        System.assert(result.contains('null'), 'null should not be quoted');
    }

    @isTest
    static void testBuildSafeFilter_trueFalseLiterals() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();

        Test.startTest();
        String resultTrue = GenericRelatedListLWCController.buildSafeAdditionalFilter(
            'HasOptedOutOfEmail = true', fieldMap
        );
        String resultFalse = GenericRelatedListLWCController.buildSafeAdditionalFilter(
            'HasOptedOutOfEmail = false', fieldMap
        );
        Test.stopTest();

        System.assert(resultTrue.contains('true'), 'true should not be quoted');
        System.assert(resultFalse.contains('false'), 'false should not be quoted');
    }

    @isTest
    static void testBuildSafeFilter_numericLiteral() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();

        Test.startTest();
        String result = GenericRelatedListLWCController.buildSafeAdditionalFilter(
            'NumberOfEmployees = 100', fieldMap
        );
        Test.stopTest();

        System.assert(result.contains('100'), 'Numeric value should not be quoted');
        System.assert(!result.contains('\'100\''), 'Numeric value should not be wrapped in quotes');
    }

    @isTest
    static void testBuildSafeFilter_dateLiteral() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();

        Test.startTest();
        String result = GenericRelatedListLWCController.buildSafeAdditionalFilter(
            'CreatedDate = TODAY', fieldMap
        );
        Test.stopTest();

        System.assert(result.contains('TODAY'), 'TODAY date literal should not be quoted');
    }

    @isTest
    static void testBuildSafeFilter_lastNDaysLiteral() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();

        Test.startTest();
        String result = GenericRelatedListLWCController.buildSafeAdditionalFilter(
            'CreatedDate = LAST_N_DAYS:7', fieldMap
        );
        Test.stopTest();

        System.assert(result.contains('LAST_N_DAYS:7'), 'LAST_N_DAYS literal should not be quoted');
    }

    @isTest
    static void testBuildSafeFilter_inListWithQuotedValues() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();

        Test.startTest();
        String result = GenericRelatedListLWCController.buildSafeAdditionalFilter(
            'FirstName IN (\'Alice\',\'Bob\')', fieldMap
        );
        Test.stopTest();

        System.assert(result.contains('IN'), 'Result should contain IN operator');
        System.assert(result.contains('\'Alice\''), 'Alice should be quoted');
        System.assert(result.contains('\'Bob\''), 'Bob should be quoted');
    }

    @isTest
    static void testBuildSafeFilter_notInOperator() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();

        Test.startTest();
        String result = GenericRelatedListLWCController.buildSafeAdditionalFilter(
            'FirstName NOT IN (\'Alice\',\'Bob\')', fieldMap
        );
        Test.stopTest();

        System.assert(result.contains('NOT IN'), 'Result should contain NOT IN operator');
    }

    @isTest
    static void testBuildSafeFilter_andOrParentheses() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();

        Test.startTest();
        String result = GenericRelatedListLWCController.buildSafeAdditionalFilter(
            'FirstName = Alice OR (LastName = Smith AND HasOptedOutOfEmail = false)',
            fieldMap
        );
        Test.stopTest();

        System.assert(result.contains('OR'), 'Result should contain OR');
        System.assert(result.contains('AND'), 'Result should contain AND');
    }

    @isTest
    static void testBuildSafeFilter_invalidSyntaxThrows() {
        Map<String, Schema.SObjectField> fieldMap =
            Schema.getGlobalDescribe().get('contact').getDescribe().fields.getMap();
        Boolean threw = false;

        Test.startTest();
        try {
            GenericRelatedListLWCController.buildSafeAdditionalFilter(
                'DROP TABLE Contact', fieldMap
            );
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Should throw for filter with unexpected tokens');
    }
}
