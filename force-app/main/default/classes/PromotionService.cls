/***
* HRP-5852->HRP-1615 - Salesforce COE - Oppy promotion record is not removed when the end date is changed
* When a promotion end date will change to the earlier date of its opportunity drive date then remove the 
* promotion from the opportunity and notify account manager via mail
* */
public with sharing class PromotionService {
    
    public static void validatePromotionEndDateWithDriveDate(list<Promotion__c> newPromotionList, map<Id,Promotion__c> oldPromotionMap){
        set<Id> setOfIdsPromoEndDateChanged = new set<Id>();    
        list<Id> listOfPromotionExpiredIds = new list<Id>();
        set<id> setOfOppIds = new set<id>();
        List<String> accountMangerEmailIds = new List<String> ();
        List<String> deletedOppPromoNames = new List<String> ();
        
        for(Promotion__c promo : newPromotionList){
            if(promo.End_Date__c !=  oldPromotionMap.get(promo.Id).End_Date__c){
                setOfIdsPromoEndDateChanged.add(promo.Id);
            }
        }
        // system.debug('@@ setOfIdsPromoEndDateChanged ' + setOfIdsPromoEndDateChanged);
        list<Opportunity_Promotion__c> oppPromotionList = [SELECT Id, Name, Promotion__c, Blood_Drive_Opportunity__c,
                                                           Blood_Drive_Opportunity__r.Drive_Date__c,
                                                           Promotion_End_Date__c FROM Opportunity_Promotion__c
                                                           WHERE Promotion__c  IN: setOfIdsPromoEndDateChanged
                                                            ];
        // system.debug('@@ oppPromotionList '+ oppPromotionList );
        for(Opportunity_Promotion__c oppPromo: oppPromotionList){
            if(oppPromo.Promotion_End_Date__c < oppPromo.Blood_Drive_Opportunity__r.Drive_Date__c){
                listOfPromotionExpiredIds.add(oppPromo.Id);
                setOfOppIds.add(oppPromo.Blood_Drive_Opportunity__c);
                deletedOppPromoNames.add(oppPromo.Name);
            }
        }
        //system.debug('@@ listOfPromotionExpiredIds ' + listOfPromotionExpiredIds);
        if(!listOfPromotionExpiredIds.isEmpty()){

          
                Database.delete(listOfPromotionExpiredIds);
            
            list<OpportunityTeamMember> oppAccountManagerList = [SELECT Id, User.Email, OpportunityId, Name, TeamMemberRole 
                                                                 FROM OpportunityTeamMember 
                                                                 where TeamMemberRole  = 'Account Manager' AND
                                                                 OpportunityId IN : setOfOppIds
                                                                  ];
            // system.debug('@@ oppAccountManagerList ' + oppAccountManagerList);
            for(OpportunityTeamMember oppAccManager : oppAccountManagerList){
                accountMangerEmailIds.add(oppAccManager.User.Email);
            }
            if(!accountMangerEmailIds.isEmpty())
            sendEmail(accountMangerEmailIds, deletedOppPromoNames);
        }
    }
    public static void sendEmail(List<String> emailIds,List<String> affectedOppPromoNames){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        //message.toAddresses =  emailIds;
        //  emailIds.add('anil.kallu@redcross.org');
        //   emailIds.add('lakshmi.natakarani@redcross.org');
        
        message.toAddresses =  emailIds;
        
        message.optOutPolicy = 'FILTER';
        message.subject = 'promotion/(s) has dissassociated from opportunity';
        String text = 'Hi, '+ 
            ' promotion end date has fallen under drive date of opportunity. So promotion has been removed'+
            ' from opportunity.';
        text = text+  '\n'+  '\n' ;//add two line breaks
        for(String val : affectedOppPromoNames)
        {
            text = text + val +  '\n' ;
        }
        
        message.plainTextBody = text;
        
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        BSF_EmailNotification.sendEmails(messages,'PromotionExpiry',null);//Changes for  HRP-11608
        
        // if (results[0].success) 
        // {
        //     System.debug('The email was sent successfully.');
        // }else 
        // {
        //     System.debug('The email failed to send: ' + results[0].errors[0].message);  
        // }
    }
}
/***
* HRP-1615->User: Managing Promotional Items Available to Drives
* 
* */
/*public class PromotionService {

/**
* When a promotion date is changed to earlier date, disassociate all associated opportunities and inform 
* via email to Account owners of the opportunities-needs only in before update context 
**/
/* public static void processPromotionEndDateChange(Map<Id,Promotion__c> oldMap,Map<Id,Promotion__c> newMap){
System.debug('Entered method processPromotionEndDateChange with old and new maps:'+oldMap+','+newMap);
Set<Id> newPromotionMapKeys = newMap.keyset();
Set<Id> promotionIdsAffected = new Set<Id>();
for(Id newPromotionId:newPromotionMapKeys){
Promotion__c newPromotion = newMap.get(newPromotionId);
Promotion__c oldPromotion = oldMap.get(newPromotionId);

System.debug('oldPromotion and newPromotion end dates:'+oldPromotion.End_Date__c+','+newPromotion.End_Date__c);  
if(oldPromotion.End_Date__c != null && newPromotion.End_Date__c != null
&& newPromotion.End_Date__c < oldPromotion.End_Date__c){//process only when new promotion end date is lower than old one
promotionIdsAffected.add(newPromotionId);
}
}
if(promotionIdsAffected.size()>0){
disconnectOpportunities(promotionIdsAffected);
}
}

@future
//disconnect opportunities associated with this promotion and email opportunity account owners
public static void disconnectOpportunities(Set<Id> promotionIds){
List<Opportunity_Promotion__c> opList = [select id,name,Blood_Drive_Opportunity__r.id,Blood_Drive_Opportunity__r.CloseDate, Blood_Drive_Opportunity__r.Account.ownerid,
Blood_Drive_Opportunity__r.Account.owner.email from Opportunity_Promotion__c where promotion__r.id in :promotionIds];

List<String> ownerEmailList =  new List<String>();
List<String> affectedOppPromoNames =  new List<String>();

for(Opportunity_Promotion__c op:opList){
System.debug('working on Opportunity promotion:'+op);
Opportunity opp= op.Blood_Drive_Opportunity__r;
String email = op.Blood_Drive_Opportunity__r.Account.owner.email;           
if(String.isBlank(email) == false){
ownerEmailList.add(email);
}
affectedOppPromoNames.add(op.name);
}
if(ownerEmailList.size()>0){
System.debug('sending email to list:'+ownerEmailList);
sendEmail(ownerEmailList,affectedOppPromoNames);
}
//delete opportunity promotion records to disconnect promotion from opportunity
delete opList;

}

public static void sendEmail(List<String> emailIds,List<String> affectedOppPromoNames){
Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
//message.toAddresses =  emailIds;
emailIds.add('anil.kallu@redcross.org');
emailIds.add('lakshmi.natakarani@redcross.org');

message.toAddresses =  emailIds;

message.optOutPolicy = 'FILTER';
message.subject = 'Promotion end date moved to earlier date';
String text = 'Promotion end date of below opportunity promotions is moved to earlier date, and you are identified as one of the Account owner of the opportunities affected.';
text = text+  '\n'+  '\n' ;//add two line breaks
for(String val : affectedOppPromoNames)
{
text = text + val +  '\n' ;
}

message.plainTextBody = text;

Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

if (results[0].success) 
{
System.debug('The email was sent successfully.');
}else 
{
System.debug('The email failed to send: ' + results[0].errors[0].message);  
}
} 
}*/