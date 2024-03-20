//Batchhelper for Batch:DMBellNotificationForATMExpiryBatch(notify DM for ATM expiry before 3 days)
public with sharing class DMBellNotificationATMExpiryBatchHelper {
    
    Public Static void SendBellNotificationToDM(List<AccountTeamMember>atmList)
    {
        If(!atmList.isEmpty())
        {
            customNotificationType cn=[select id from CustomNotificationType where developername='Account_Custom_Notification'];
            Set<String>sendId=new set <String>();
            
            for(AccountTeamMember atm:atmList)
            {
                sendId.clear();
                sendId.add(atm.Account.District_Manager__c);
                Messaging.CustomNotification SendBellNotificationtoDM=new Messaging.CustomNotification();
                SendBellNotificationtoDM.setNotificationTypeId(cn.id);
                SendBellNotificationtoDM.setTitle('Account Team Member will expire in 3 days');
                SendBellNotificationtoDM.setBody('HI ' + atm.Account.District_Manager__r.Name +' One of your account team member '+atm.User.Name + 
                                                 ' will expire in 3 days. Please take necessary actions as per your requirement. Thank you ');
                SendBellNotificationtoDM.setSenderId(atm.createdById);
                SendBellNotificationtoDM.setTargetId(atm.Id);
                SendBellNotificationtoDM.send(sendId);
                
            }
        }
    }
}