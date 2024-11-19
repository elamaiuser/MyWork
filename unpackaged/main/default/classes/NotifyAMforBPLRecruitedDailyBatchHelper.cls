/**
 * @description: This apex class send custom notifications to Opportunities that are linked to the accounts provided as input and where Receive_Call_List__c is false.
 **  Modification Log  ****
 *  Date					Developer Name			Comments
 * *****************************************************************************************************************************************************************************************
 * 09/05/2023			    Barnojit Sharma			Centralized apex class to send Notifications from Process Builder (HRP-10482)
 * *****************************************************************************************************************************************************************************************
 **/

public with sharing class NotifyAMforBPLRecruitedDailyBatchHelper {
    public static  void findDriveWithNoCallRecipientContact(List<Account> accBplRecruitedList){
        
        list<Opportunity> oppList = new List<Opportunity>();
        map<Id, Id> accIdAmId = new  map<Id, Id>();
        
        Integer noOfWeek = Integer.valueOf(system.Label.NotifyAmWeekConfigForBplRecruited);
        Integer noOfDays =  noOfWeek * 7;
        
        if(accBplRecruitedList.size() > 0){
            for(Account acc: accBplRecruitedList){
                accIdAmId.put(acc.Id, acc.Account_Manager__c);
            }
        }
        if(accIdAmId.size() > 0){
            CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Account_Custom_Notification'];
            
            oppList = [SELECT Id, accountId, drive_date__c, CreatedDate ,(SELECT Id,OpportunityId, role FROM OpportunityContactRoles 
                                                                          WHERE Receive_Call_List__c = false) 
                       from Opportunity WHERE drive_date__c >: system.today() 
                       AND accountId IN : accIdAmId.keyset()];
            System.debug('Check List 123 : '+oppList);
            for(Opportunity opp: oppList){  
                Date getNotificationDate;
                if(opp.OpportunityContactRoles.size() >= 0 ){ 
                    System.debug('Check List 124 : '+opp.drive_date__c); 
                    if(opp.drive_date__c != null){
                        getNotificationDate = calculateBusinessDays(opp.drive_date__c, noOfDays);                      
                    }
                    System.debug('Check List 125 : '+getNotificationDate); 
                    System.debug('Check List 126 : '+accIdAmId.get(opp.accountId)); 
                    if(getNotificationDate != null){
                        if(getNotificationDate == system.today() && accIdAmId.get(opp.accountId) != null){ 
                            sendNotification(opp.Id, accIdAmId.get(opp.accountId), notificationType.Id);
                        }
                        else if(getNotificationDate <= system.today() && opp.CreatedDate == system.today() - 1 && accIdAmId.get(opp.accountId) != null){
                            sendNotification(opp.Id, accIdAmId.get(opp.accountId), notificationType.Id);
                        }
                    }    
                }
            }            
        }       
    }    
    
    static void sendNotification(Id oppId, Id amId, Id notificationTypeId){
        System.debug('Check List 127 : '+oppId); 
        System.debug('Check List 128 : '+amId); 
        System.debug('Check List 129 : '+notificationTypeId); 
        //HRP-10482 changes starts here 
        BSF_CustomNotification notification = new BSF_CustomNotification()
                        .title('Drive Contact Call List Recipient is Blank!')
                        .body('Your drive does not have a Call List Recipient selected, does this drive need a call list?')
                        .typeId(notificationTypeId)
                        .target(oppId)
            			.category('MissingCallListRecepient');
        //HRP-10482 changes ends here
        try {
            
                notification.send(new List<String> { amId }); 
                System.debug('Check List 130 '); 
            
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
    
    public static Date calculateBusinessDays(Date startDate, Integer businessDaysToMinus )
    {
        Date finalDate = startDate;
        Integer direction = businessDaysToMinus < 0 ? -1 : 1;
        while(businessDaysToMinus != 0)
        {
            finalDate = finalDate.addDays(-direction);
            if (!IsWeekend(finalDate))
            {
                businessDaysToMinus -= direction;
            }
        }
        return finalDate;
    }
    static Boolean IsWeekend(Date myDate)
    {
        String myDateString = Datetime.newInstance(myDate.year(), myDate.month(),myDate.day()).format('EEE');
        return 'Sat'.equals(myDateString) || 'Sun'.equals(myDateString);
    }  
    
}