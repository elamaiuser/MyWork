global with sharing class BSFBypassFlowValidationService {
    public static Boolean bypassProfileValidation = false;
    @InvocableMethod(label='Bypass Profile Validation')
    public static void setProfileCheckBypass(List<SetBypassRequest> request) {
        bypassProfileValidation = request[0].setBypassFlow;
    }

    global class SetBypassRequest{
        @InvocableVariable(required=true)
        global Boolean setBypassFlow;
    }

}