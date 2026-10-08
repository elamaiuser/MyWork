@IsTest
private class BSF_ActionControllerTest {

    private static void setMockMetadata(String targetType, String targetName, String allowedPermSets) {
        String jsonString = '{' +
            '"Target_Type__c": "' + targetType + '",' +
            '"Target_Name__c": "' + targetName + '",' +
            '"Allowed_Permission_Sets__c": "' + allowedPermSets + '"' +
        '}';
        
        Action_Override_Config__mdt mockRecord = (Action_Override_Config__mdt) JSON.deserialize(jsonString, Action_Override_Config__mdt.class);
        BSF_ActionController.mockMetadata = new List<Action_Override_Config__mdt>{ mockRecord };
    }

    @IsTest
    static void testBlankInputs() {
        Test.startTest();
        BSF_ActionController.ActionConfig config = BSF_ActionController.getTargetConfig('', null);
        Test.stopTest();

        System.assertEquals(true, config.notFound, 'Blank inputs should result in not found.');
        System.assertEquals(false, config.hasAccess, 'Blank inputs should not grant access.');
    }

    @IsTest
    static void testRoutingWithAllAccess() {
        // Setup mock: Allowed for 'All'
        setMockMetadata('LWC', 'driveMovementManager', 'All');

        Test.startTest();
        BSF_ActionController.ActionConfig config = BSF_ActionController.getTargetConfig('Account', 'New');
        Test.stopTest();

        System.assertEquals(false, config.notFound, 'Configuration should be found.');
        System.assertEquals(true, config.hasAccess, 'Access should be granted for All.');
        System.assertEquals(false, config.isFlow, 'Target should be an LWC.');
        System.assertEquals('driveMovementManager', config.targetName, 'Target name should match mock.');
    }

    @IsTest
    static void testRoutingWithSpecificPermissionSet() {
        // 1. Create a dummy Permission Set for testing
        PermissionSet ps = new PermissionSet(Name = 'BSF_Test_PermSet', Label = 'BSF Test PermSet');
        insert ps;
        
        // 2. Assign it to the current running user
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
        insert psa;
        
        // 3. Setup mock: Allowed only for this exact Permission Set API Name
        setMockMetadata('Flow', 'Create_New_Publicity_Order', 'BSF_Test_PermSet');

        Test.startTest();
        BSF_ActionController.ActionConfig config = BSF_ActionController.getTargetConfig('Contact', 'Edit');
        Test.stopTest();

        System.assertEquals(false, config.notFound, 'Configuration should be found.');
        System.assertEquals(true, config.hasAccess, 'Access should be granted due to Permission Set Assignment.');
        System.assertEquals(true, config.isFlow, 'Target should be marked as a Flow.');
        System.assertEquals('Create_New_Publicity_Order', config.targetName, 'Target name should match mock.');
    }

    @IsTest
    static void testAccessDeniedForMissingPermissionSet() {
        // Setup mock: Requires a Permission Set the user does NOT have
        setMockMetadata('LWC', 'driveMovementManager', 'Secret_Admin_Perm_Set');

        Test.startTest();
        BSF_ActionController.ActionConfig config = BSF_ActionController.getTargetConfig('Opportunity', 'View');
        Test.stopTest();

        System.assertEquals(false, config.notFound, 'Configuration should be found.');
        System.assertEquals(false, config.hasAccess, 'Access should be DENIED for missing Permission Set.');
        System.assertEquals(null, config.targetName, 'Target name should remain null when access denied.');
    }

    @IsTest
    static void testConfigurationNotFound() {
        // Clear mocks to simulate no configuration found
        BSF_ActionController.mockMetadata = new List<Action_Override_Config__mdt>();

        Test.startTest();
        BSF_ActionController.ActionConfig config = BSF_ActionController.getTargetConfig('Case', 'Delete');
        Test.stopTest();

        System.assertEquals(true, config.notFound, 'Should report not found when no CMDT exists.');
        System.assertEquals(false, config.hasAccess, 'Access should be false when not found.');
    }
}