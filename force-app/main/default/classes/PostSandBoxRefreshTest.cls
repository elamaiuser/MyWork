@isTest
public class PostSandBoxRefreshTest {
    @isTest
    Public static void TestPostSandBoxRefresh(){
      
        Test.startTest();
        //String orgId='00D8I0000004cwu';
        //PostSandBoxRefresh.runApexClass(orgId);
        Test.testSandboxPostCopyScript(
            new PostSandBoxRefresh(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
        Test.stopTest();
    }

}