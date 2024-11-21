public with sharing class SessionPermSetActivationController {
    
    @InvocableMethod(label='Deactivate Session Permission')
    public static void deactivatesession() {
                /*String 	sessionId;	
        String sessionPermSetId = '0PS2g0000005DDXGA2';
        Map<String, String> sessionManagement = Auth.SessionManagement.getCurrentSession();
        sessionId = sessionManagement.get( 'SessionId' );
        system.debug( 'session id is ' + sessionId );
        system.debug( 'session list without session id is ' +  [SELECT Id FROM SessionPermSetActivation WHERE PermissionSetId=:sessionPermSetId LIMIT 1 ] );
        List<SessionPermSetActivation> sessionlist = new List<SessionPermSetActivation>();
        sessionlist = [SELECT Id
        FROM SessionPermSetActivation
        //WHERE AuthSessionId=:sessionId
        WHERE PermissionSetId=:sessionPermSetId LIMIT 1]	;
        System.debug( 'sessionlist is ' + sessionlist );
        delete sessionlist ; */
        //List<Profile> pfs = new List<Profile>();
        List<Profile> pfs = [ select Id, Name from Profile where id=: Userinfo.getProfileId() ];
        Map<String, Object_Specific_Setting__mdt> triggerSettingMap = Object_Specific_Setting__mdt.getAll();
        String triggerObject = 'SessionBasedPermission';
        String methodsToBypass = '';
        for(String triggerSettingKey : triggerSettingMap.keySet()){
            Object_Specific_Setting__mdt triggerSetting = triggerSettingMap.get(triggerSettingKey);
            if(   triggerObject.equalsIgnoreCase(triggerSetting.Object_Name__c.toLowerCase() ) 
                    && triggerSetting.Bypass_Apex_Action__c 
                    && triggerSetting.Allowed_Profiles__c.toLowerCase().contains( pfs[0].Name.toLowerCase() )  
                    && triggerSetting.DeveloperName == 'DeactivateOppSplit_Setting' ){

                    methodsToBypass = triggerSetting.Bypass_Apex_Action_method_1__c;
            }
        }


        if( methodsToBypass.indexOf('deactivatesessionFuture') == -1 ){
            deactivatesessionFuture();
        }/*else{
            //System.debug( 'deactivatesessionFuture -Bypassed' );
        }*/
        
    }
    
    @future
    public static void deactivatesessionFuture()
    {   
        // Perform some operations
        
        List<permissionset> permissionList = new List<permissionset>();
        String sessionPermSetId ;
        permissionList = [ select id from permissionset where name = 'AccessToBloodDriveSplit' ];
        if( !permissionList.isempty() ){
            sessionPermSetId = permissionList[0].Id ;
        }
        List<SessionPermSetActivation> sessionlist = new List<SessionPermSetActivation>();
        sessionlist = [SELECT Id
                       FROM SessionPermSetActivation
                       //WHERE AuthSessionId=:sessionId
                       WHERE PermissionSetId=:sessionPermSetId ]	;
        //System.debug( 'sessionlist is ' + sessionlist );
       
            delete sessionlist ;
        
        
    }
    
    
}