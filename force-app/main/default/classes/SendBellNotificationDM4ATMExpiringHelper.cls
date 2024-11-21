/**
 * @description: This apex class is executed from SendBellNotificationDM4ATMExpiring Batch to send custom notifications to DM for atm expiring.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 09/05/2023			    Barnojit Sharma			Centralized apex class to send Notifications from Process Builder (HRP-10482)
 * *****************************************************************************************************************************************************************************************
 **/
public class SendBellNotificationDM4ATMExpiringHelper {
    
    Public Static void SendBellNotificationTODM(List<AccountTeamMember>newAtmList)
    {
        If(!newAtmList.isEmpty()){
        customNotificationType cn=[select id from CustomNotificationType where developername='Account_Custom_Notification'];
        List<String>sendId = new List<String>();
        for(AccountTeamMember atm:newAtmList)
        {
            Date D=System.today();
            if(D.addDays(3)==atm.End_Date__c){
                sendId.clear();
                sendId.add(atm.Account.District_Manager__c);
                //HRP-10482 changes starts here 
                new BSF_CustomNotification()
                        .typeId(cn.id)
                        .title('Account Team Member will expire in 3 days')
                        .body('HI ' + atm.Account.District_Manager__r.Name +
                            ' One of your account team member '+atm.User.Name + 
                            ' will expire in 3 days. Please take necessary actions as per your requirement. Thank you ')
                        .sender(atm.createdById)
                        .target(atm.Id)
                    	.category('AccountTeamMemberExpiry')
                        .send(sendId);
                        
                //HRP-10482 changes ends here
            }
        }
    }
    }

}