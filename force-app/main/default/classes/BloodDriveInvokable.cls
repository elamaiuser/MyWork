/**
 * @description: This apex class is executed from Send Bell Notification For Drive processbuilder to send custom notification.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 09/05/2023			    Barnojit Sharma			Centralized apex class to send Notifications from Process Builder (HRP-10482)
 * *****************************************************************************************************************************************************************************************
 **/
public with sharing class BloodDriveInvokable {
    
    @InvocableMethod
    public static void sendNotificationToDMForBloodDrive(List<Id> optyId)
    {
        if(optyId!=null){
            List<Opportunity> optyList = [SELECT Id,Name,Drive_date__c,DriveStatus__c,AccountId,Account.Name,Account.District_Manager__c,Account.Account_Manager__c,
                                          Account.Is_Account_Managed__c,LastModifiedby.UserName FROM Opportunity 
                                          WHERE Id IN:optyId and Drive_date__c >=:system.today() and Account.Account_Manager__c=Null and Account.District_Manager__c != null and LastModifiedby.UserName !='service account'];
            
            
            List<CUstomNotificationType> CUstomNotificationTypeList = [SELECT Id FROM CUstomNotificationType WHERE DeveloperName = 'Account_Custom_Notification'];
            List<Messaging.CustomNotification> notificationList = new List<Messaging.CustomNotification>();
            List<String> userId = new List<String>(); 
            BSF_CustomNotification notification; //HRP-10482 changes
            Id typeId;
            
            if(!CUstomNotificationTypeList.isEmpty()){
                typeId=CUstomNotificationTypeList[0].Id;
            }
            
            Map<String,String> mapOfIntegrationUser=new Map<String,String>();//
            String customLabelIntUser=Label.Integration_User;
            if(customLabelIntUser!=null && customLabelIntUser.contains(',')){
                String[] splitStrings = customLabelIntUser.split(',');
                for(String s1:splitStrings){
                    mapOfIntegrationUser.put(s1,s1);  
                }   
            }
            system.debug('entered1');
            for(Opportunity opty:optyList){
                if(opty.DriveStatus__c != null && (opty.DriveStatus__c == 'Tentative' || opty.DriveStatus__c == 'Confirmed')) {
                    system.debug('entered2');
                    if(!mapOfIntegrationUser.containsKey(Userinfo.getUserId())){ // Skipping for Integration Users(as a part of data migration)
                        system.debug('entered3');
                        //HRP-10482 changes starts here     
                        notification = new BSF_CustomNotification()
                                            .body('Blood Drive name: '+opty.Name+
                                             ',which has the Drive Date as '+opty.Drive_Date__c+
                                             ' is still having its Account '+opty.Account.Name+
                                             ' in Unassigned Status!')
                                            .title('Hi! '+'One of your coming Blood Drive ' + opty.Name + 'is still has an Unassigned Account!: '+opty.Account.Name)
                                            .sender(Userinfo.getUserId())           			
                                            .typeId(typeId )
                                            .target(opty.Id) // target object id
                                            .category('UnmanagedAccount');
                        //HRP-10482 changes ends here
                        userId = new List<String>();
                        System.debug('==notification=='+notification);                        
                        userId.add(opty.Account.District_Manager__c);
                        notification.send(userId);
                    }
                }
            }
        }
    }    
}