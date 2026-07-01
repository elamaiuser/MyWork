@IsTest
public class SFC360_Lead360ViewController_Test {

    /**
     * Bypasses JSON deserialization completely by instantiating ConnectApi.CdpQueryOutput 
     * directly and assigning its mutable global properties in-memory.
     */
    private static ConnectApi.CdpQueryOutput createMockResponse(List<Map<String, Object>> rows) {
        ConnectApi.CdpQueryOutput mockOut = new ConnectApi.CdpQueryOutput();
        mockOut.data = (List<Object>) rows;
        mockOut.rowCount = rows.size();
        mockOut.done = true;
        return mockOut;
    }

    @IsTest
    static void testQueryDataCloudWithAccountSource() {
        // Step 1: Mock SQL_GET_UNIFIED_ID_BASE
        SFC360_Lead360ViewController.mockQueryMap.put(
            'UnifiedssotAccountUa1__dlm.ssot__Id__c AS unified_account_id__c',
            createMockResponse(new List<Map<String, Object>>{
                new Map<String, Object>{ 'unified_account_id__c' => 'UNIF-ACC-111' }
            })
        );

        // Step 2: Mock SQL_ACCOUNT_MANAGERS
        SFC360_Lead360ViewController.mockQueryMap.put(
            'account_manager_name__c, account_manager_email__c, org_identifier__c',
            createMockResponse(new List<Map<String, Object>>{
                new Map<String, Object>{
                    'org_identifier__c' => 'BioMedSF',
                    'account_manager_name__c' => 'Alice Bio',
                    'account_manager_email__c' => 'alice@biomed.org'
                },
                new Map<String, Object>{
                    'org_identifier__c' => 'HospitalSales',
                    'account_manager_name__c' => 'Bob Sales',
                    'account_manager_email__c' => 'bob@sales.org'
                },
                new Map<String, Object>{
                    'org_identifier__c' => 'FundRaising',
                    'account_manager_name__c' => 'Charlie Fund',
                    'account_manager_email__c' => 'charlie@giving.org'
                },
                new Map<String, Object>{
                    'org_identifier__c' => 'TrainingServices',
                    'account_manager_name__c' => 'Diana Train',
                    'account_manager_email__c' => 'diana@training.org'
                }
            })
        );

        // Step 3: Mock SQL_ACCOUNT_MANAGERS_CGTS
        SFC360_Lead360ViewController.mockQueryMap.put(
            'SFC_Lead360_CGTS_Account_Managers__cio',
            createMockResponse(new List<Map<String, Object>>{
                new Map<String, Object>{
                    'org_identifier__c' => 'HospitalSales',
                    'account_manager_name__c' => 'Evan CGTS',
                    'account_manager_email__c' => 'evan@cgts.org'
                }
            })
        );

        // Step 4: Mock SQL_ACTIVITY_SUMMARY
        SFC360_Lead360ViewController.mockQueryMap.put(
            'SFC360_Account_Activity_Summary__cio',
            createMockResponse(new List<Map<String, Object>>{
                new Map<String, Object>{
                    'source_system__c' => 'FundRaising',
                    'is_closed__c' => 'false',
                    'activity_count__c' => 4,
                    'account_id__c' => 'FR-ACC-REC'
                },
                new Map<String, Object>{
                    'source_system__c' => 'HospitalSales',
                    'is_closed__c' => 'true',
                    'activity_count__c' => 10,
                    'account_id__c' => 'HS-ACC-REC'
                },
                new Map<String, Object>{
                    'source_system__c' => 'TrainingServices',
                    'is_closed__c' => 'false',
                    'activity_count__c' => 2,
                    'account_id__c' => 'TS-ACC-REC'
                }
            })
        );

        // Step 5: Mock SQL_RELATED_ACC
        SFC360_Lead360ViewController.mockQueryMap.put(
            'COUNT(account_name__c)',
            createMockResponse(new List<Map<String, Object>>{
                new Map<String, Object>{ 'account_count' => 8 }
            })
        );

        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'dataSourceObjectId' => 'Account',
            'sourceRecId' => '001100000000001AAA'
        };
        SFC360_Lead360ViewController.ConstituentDataWrapper result = SFC360_Lead360ViewController.queryDataCloud(params);
        Test.stopTest();

        // Standard Assertions
        System.assertNotEquals(null, result, 'The query result wrapper should populate.');
        System.assertEquals('UNIF-ACC-111', result.unifiedId, 'Unified ID mismatch.');
        System.assertEquals(8, result.numberOfAccounts, 'Related accounts count mismatch.');

        // Account Manager Assertions
        System.assertNotEquals(null, result.accAmDetails, 'Account Manager details map should populate.');
        System.assertEquals(1, result.accAmDetails.get('BioMedSF').size(), 'BioMed accounts size mismatch.');
        System.assertEquals('Alice Bio', result.accAmDetails.get('BioMedSF')[0].name);
        System.assertEquals(1, result.accAmDetails.get('Cell Gene Therapy').size());
        System.assertEquals('Bob Sales', result.accAmDetails.get('Cell Gene Therapy')[0].name);

        // Activity Summary Assertions
        System.assertEquals(4, result.openActivityFR);
        System.assertEquals(4, result.totalActivityFR);
        System.assertEquals(0, result.openActivityHS);
        System.assertEquals(10, result.totalActivityHS);
        System.assertEquals(2, result.openActivityTS);
        System.assertEquals(2, result.totalActivityTS);
    }

    @IsTest
    static void testQueryDataCloudWithLeadSource() {
        // Mock Lead specific lookup query pathway
        SFC360_Lead360ViewController.mockQueryMap.put(
            'JOIN ssot__Lead__dlm',
            createMockResponse(new List<Map<String, Object>>{
                new Map<String, Object>{ 'unified_account_id__c' => 'UNIF-LEAD-222' }
            })
        );

        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'dataSourceObjectId' => 'Lead',
            'sourceRecId' => '00Q100000000001BBB'
        };
        SFC360_Lead360ViewController.ConstituentDataWrapper result = SFC360_Lead360ViewController.queryDataCloud(params);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('UNIF-LEAD-222', result.unifiedId, 'Unified ID lookup for lead pathway failed.');
    }

    @IsTest
    static void testQueryActivityModalFilterAllAndDates() {
        String currentYearStr = String.valueOf(Date.today().year());
        String pastYearStr = String.valueOf(Date.today().year() - 1);

        // Simulated ISO formatted Datetime strings (JSON format)
        String mockDateCurYear = currentYearStr + '-06-15T12:00:00.000Z';
        String mockDatePastYear = pastYearStr + '-04-10T12:00:00.000Z';

        SFC360_Lead360ViewController.mockQueryMap.put(
            'SFC360_Account_Activity__cio',
            createMockResponse(new List<Map<String, Object>>{
                // Row 1: Valid Datetime JSON structure (Current Year)
                new Map<String, Object>{
                    'task_id__c' => 'TSK-901',
                    'is_closed__c' => 'true',
                    'task_sub_type__c' => 'Email',
                    'task_owner_name__c' => 'Owner 1',
                    'activity_date__c' => mockDateCurYear
                },
                // Row 2: Valid Datetime JSON structure (Past Year)
                new Map<String, Object>{
                    'task_id__c' => 'TSK-902',
                    'is_closed__c' => 'false',
                    'task_sub_type__c' => 'Call',
                    'task_owner_name__c' => 'Owner 2',
                    'activity_date__c' => mockDatePastYear
                },
                // Row 3: Throws parsing exception but falls back to Split logic (formatted as Date only)
                new Map<String, Object>{
                    'task_id__c' => 'TSK-903',
                    'is_closed__c' => 'false',
                    'task_sub_type__c' => 'Task',
                    'task_owner_name__c' => 'Owner 3',
                    'activity_date__c' => currentYearStr + '-08-20'
                },
                // Row 4: No date structure to trigger "Others" category
                new Map<String, Object>{
                    'task_id__c' => 'TSK-904',
                    'is_closed__c' => 'false',
                    'task_sub_type__c' => 'Task',
                    'task_owner_name__c' => 'Owner 4',
                    'activity_date__c' => null
                }
            })
        );

        Test.startTest();
        SFC360_Lead360ViewController.ActivityModalWrapper result = SFC360_Lead360ViewController.queryActivityModal('ACC-123', 'All');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.activityData.size() > 0, 'Activity Data groups should be returned.');

        Boolean verifiedCurYear = false;
        Boolean verifiedPastYear = false;
        Boolean verifiedOthers = false;

        for (SFC360_Lead360ViewController.ActivityGroup gp : result.activityData) {
            if (gp.groupLabel.equals('June - ' + currentYearStr)) {
                verifiedCurYear = true;
                System.assertEquals('TSK-901', gp.activities[0].taskId);
                System.assertEquals('06/15/' + currentYearStr, gp.activities[0].completeDate, 'Date formatting failed.');
            } else if (gp.groupLabel.equals(pastYearStr)) {
                verifiedPastYear = true;
                System.assertEquals('TSK-902', gp.activities[0].taskId);
                System.assertEquals('04/10/' + pastYearStr, gp.activities[0].completeDate);
            } else if (gp.groupLabel.equals('Others')) {
                verifiedOthers = true;
                System.assertEquals('TSK-904', gp.activities[0].taskId);
                System.assertEquals('', gp.activities[0].completeDate);
            }
        }
        System.assertEquals(true, verifiedCurYear);
        System.assertEquals(true, verifiedPastYear);
        System.assertEquals(true, verifiedOthers);
    }

    @IsTest
    static void testQueryActivityModalFilterOpen() {
        // Enforce the "Open" filter query coverage path
        SFC360_Lead360ViewController.mockQueryMap.put(
            'AND is_closed__c = \'false\'',
            createMockResponse(new List<Map<String, Object>>{
                new Map<String, Object>{
                    'task_id__c' => 'TSK-Open-01',
                    'is_closed__c' => 'false',
                    'task_sub_type__c' => 'Call',
                    'task_owner_name__c' => 'Open Task Owner',
                    'activity_date__c' => null
                }
            })
        );

        Test.startTest();
        SFC360_Lead360ViewController.ActivityModalWrapper result = SFC360_Lead360ViewController.queryActivityModal('ACC-123', 'Open');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.activityData.size());
        System.assertEquals('Others', result.activityData[0].groupLabel);
        System.assertEquals('TSK-Open-01', result.activityData[0].activities[0].taskId);
    }

    @IsTest
    static void testQueryRelatedAccountDetails() {
        SFC360_Lead360ViewController.mockQueryMap.put(
            'ssot__Account__dlm.KQ_Id__c',
            createMockResponse(new List<Map<String, Object>>{
                new Map<String, Object>{
                    'acc_name' => 'Test Account Corp',
                    'org_name' => 'Org-Identifier-Corp',
                    'account_rec_id__c' => '001999999999abc',
                    'account_manager_name__c' => 'Zack Manager',
                    'Address' => '100 Main Street',
                    'City' => 'New York',
                    'State' => 'NY',
                    'ZipCode' => '10001',
                    'Phone' => '+15550100'
                }
            })
        );

        Test.startTest();
        SFC360_Lead360ViewController.AccountDetailsModalWrapper result = SFC360_Lead360ViewController.queryRelatedAccountDetails('UNIF-ACC-333');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.accountData.size());
        SFC360_Lead360ViewController.AccountDetails row = result.accountData[0];
        System.assertEquals('Test Account Corp', row.accountName);
        System.assertEquals('Org-Identifier-Corp', row.orgName);
        System.assertEquals('100 Main Street', row.accAddress);
        System.assertEquals('+15550100', row.accPhone);
    }

    @IsTest
    static void testNullParamBoundariesAndSafeHelpers() {
        // Direct validation of parameter handling limit paths
        System.assertEquals(null, SFC360_Lead360ViewController.queryDataCloud(null).unifiedId);
        System.assertEquals(null, SFC360_Lead360ViewController.queryDataCloud(new Map<String, Object>()).unifiedId);

        System.assertEquals(null, SFC360_Lead360ViewController.queryActivityModal('', 'All').activityData);
        System.assertEquals(null, SFC360_Lead360ViewController.queryRelatedAccountDetails(null).accountData);

        System.assertEquals(null, SFC360_Lead360ViewController.safeGetString(null, 'key'));
        System.assertEquals(null, SFC360_Lead360ViewController.deserializeData(null));
    }
}