@isTest
public class AccountTeamInsert_Test 
{
    @isTest
    public static void testAccountTeamInsert(){
        
        Map <String,Schema.RecordTypeInfo> recordTypesAccount = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id mobileRecTypeId = recordTypesAccount.get('Mobile Account').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Account mobileAcc1 = new Account(
            name = 'Test Account 1',
        	RecordTypeId = MobileRecTypeId,
            BillingStreet = '2204 Westcrt ln, Apt 213', 
        	BillingCity = 'Herndon',
        	BillingStateCode = 'MI',
        	BillingPostalCode = '48420'
        );
        
        insert mobileAcc1;
        
   Bsf_portfolio__c bsf = new Bsf_Portfolio__c();
        bsf.Account_Based_Portfolio__c=true;
        bsf.Portfolio_Type__c='Account Manager';
        bsf.Taxonomy_Type__c='Bio Recruitment CD';
        bsf.Start_Date__c = system.today()-1;
        bsf.End_Date__c = system.today()+3;
        
        insert bsf;
  AccTeamFromPortfolioAssignmentService__e accTeamEve = new AccTeamFromPortfolioAssignmentService__e();
  List<AccTeamFromPortfolioAssignmentService__e> accTeamEveList = new List<AccTeamFromPortfolioAssignmentService__e>();

     						accTeamEve.UserId__c=userinfo.getUserId();
                            accTeamEve.AccountId__c=mobileAcc1.Id;
                            accTeamEve.BSF_Portfolio__c=bsf.id;
                            accTeamEve.Start_Date__c=system.today();
                            accTeamEve.End_Date__c=system.today()+3;
                            accTeamEve.AccountAccessLevel__c='Edit';
                            accTeamEve.CaseAccessLevel__c='Edit';
                            accTeamEve.OpportunityAccessLevel__c='Edit';
                            accTeamEve.TeamMemberRole__c='Account Manager';
                            accTeamEveList.add(accTeamEve);
        
        test.startTest();
        try{
        EventBus.publish(accTeamEveList);
        }
        catch(exception e)
        {
            system.debug('exception'+e);
        }
        test.stopTest();
    }
}