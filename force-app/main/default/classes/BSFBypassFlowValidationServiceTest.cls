@isTest
public class BSFBypassFlowValidationServiceTest {
    @isTest
    public static void TestSetProfileCheckBypass(){
        BSFBypassFlowValidationService.SetBypassRequest request = new BSFBypassFlowValidationService.SetBypassRequest();
        request.setBypassFlow = true;
        BSFBypassFlowValidationService.setProfileCheckBypass(new List<BSFBypassFlowValidationService.SetBypassRequest>{request});        
    }
}