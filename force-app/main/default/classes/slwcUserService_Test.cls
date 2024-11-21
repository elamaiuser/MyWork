@isTest
private class slwcUserService_Test {

    static testmethod void testGetLoginUser() {
        Test.startTest();
        
        slwcUserService.getLoginUser();
        
        Test.stopTest();
    }
    
}