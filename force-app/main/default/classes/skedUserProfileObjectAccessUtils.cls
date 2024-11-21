public class skedUserProfileObjectAccessUtils {
    public static boolean hasPermission(String scenario, skedHubBase.triggerContext context) {
        Boolean hasPermission = false;
        
        User user = skedTriggerHub_Cache.loginUser;
        for (sked_User_Profile_Object_Access__mdt item : sked_User_Profile_Object_Access__mdt.getAll().values()) {
            if (item.sked_Scenario__c == scenario) {
                if (item.sked_Target_Type__c == skedConstants.TARGET_TYPE_PROFILE && user.Profile.Name == item.sked_Target__c
                || item.sked_Target_Type__c == skedConstants.TARGET_TYPE_USER && user.Alias == item.sked_Target__c) {
                    hasPermission = (context.isInsert && item.sked_Can_Insert__c) || (context.isUpdate && item.sked_Can_Update__c) || (context.isDelete && item.sked_Can_Delete__c);
                }
            }
        }
        return hasPermission;
    }
}