/**
 * @description: This apex class is executed from Send Bell Notification To District Manager processbuilder to send custom notification.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 09/05/2023			    Barnojit Sharma			Centralized apex class to send Notifications from Process Builder (HRP-10482)
 * *****************************************************************************************************************************************************************************************
 **/
public with sharing class AccountInvokable {
    /*
set custom notification
*/
    @InvocableMethod
    public static void sendNotificationToDM(List<Id> accountId)
    {
        
        List<Account> accList = [SELECT Id,Name,District_Manager__c,(SELECT Id,Name,StageName,Drive_Date__c,DriveStatus__c FROM Opportunities) FROM Account WHERE Id IN :accountId ];
        List<CUstomNotificationType> CUstomNotificationTypeList = [SELECT Id FROM CUstomNotificationType WHERE DeveloperName = 'Account_Custom_Notification' ];
        List<String> userId = new List<String>(); 
        BSF_CustomNotification notification; //HRP-10482 changes
        Id typeId;
        
        if(!CUstomNotificationTypeList.isEmpty()){
            typeId=CUstomNotificationTypeList[0].Id;
        }
        
        for(Account acc:accList){ 
            if(typeId!=null){      
                for(Opportunity opty:acc.Opportunities){
                    if((opty.DriveStatus__c != null && (opty.DriveStatus__c == 'Tentative' || opty.DriveStatus__c == 'Confirmed')) 
                       && (opty.Drive_Date__c != null) 
                       && (opty.Drive_Date__c > date.today() || opty.Drive_Date__c == date.today())){ 
                            //HRP-10482 changes starts here                   	                       
                           notification = new BSF_CustomNotification()
                                                .body('Blood Drive name: '+opty.Name+
                                                ',which has the Drive Date as '+opty.Drive_Date__c+
                                                ' is still having its Account '+acc.Name+
                                                ' in Unassigned Status!')
                                                .title('Hi! '+'One of your coming Blood Drive is still has an Unassigned Account!: '+acc.Name)
                                                .sender(Userinfo.getUserId())            			
                                                .typeId(typeId )
                                                .target(acc.Id) // target object id
                           						.category('UnmanagedAccount');
                            //HRP-10482 changes ends here
                           userId = new List<String>();
                           System.debug('==notification=='+notification);                        
                           userId.add(acc.District_Manager__c);
                           try{
                                notification.send(userId);  
                           }
                           catch(Exception e) {
                               System.debug('The following exception has occurred: ' + e.getMessage());
                               System.debug('Line number: '+e.getLineNumber());
                           }
                           
                       }                    
                }
                
            }
            
        }
        
    }
    
}