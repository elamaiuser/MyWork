@isTest
public class NotifyAMforBPLRecruitedDailyBatchTest {
    @testSetup
    public static void DataSetup(){
        Test.startTest();   
        
        Account acc = new account();
        acc.name='testAccount';
        acc.Recruited_By__c = 'BPL Recruited';
        acc.Account_Manager__c = userInfo.getUserId();	
        insert acc; 
        
        Integer noOfWeek = Integer.valueOf(system.Label.NotifyAmWeekConfigForBplRecruited);
        Integer noOfDays =  noOfWeek * 7;
        Date calculateDays = AddBusinessDays(system.today(), noOfDays);                      
        
        list<opportunity> oppList = new list<opportunity>();
        
        opportunity opp1=new opportunity();
        opp1.AccountId=acc.Id;
        opp1.name='testOpp1';
        opp1.StageName= 'Draft';
        opp1.CloseDate= System.today(); 
        opp1.Drive_Date__c = calculateDays;
        opp1.Accept_56_Day_Rule_Violation__c = true;
		opp1.Start_Time__c = Time.newInstance(9, 0, 0, 0);
		opp1.End_Time__c = Time.newInstance(15, 0, 0, 0);
        opp1.Source__c = 'Adhoc';
        oppList.add(opp1);
        
        opportunity opp2=new opportunity();
        opp2.AccountId=acc.Id;
        opp2.name='testOpp2';
        opp2.StageName= 'Draft';
        opp2.CloseDate= System.today(); 
        opp2.Drive_Date__c = calculateDays;
        opp2.Accept_56_Day_Rule_Violation__c = true;
		opp2.Start_Time__c = Time.newInstance(9, 0, 0, 0);
		opp2.End_Time__c = Time.newInstance(15, 0, 0, 0);
        opp2.Source__c = 'Adhoc';
        oppList.add(opp2);
        
        insert oppList;
        
        NotifyAM4BPLRecruitedDailyBatchScheduler notifyAMBPLSch = new NotifyAM4BPLRecruitedDailyBatchScheduler(100);
		System.schedule('Notify AM BPL Recruited Batch1', '0 0 2 * * ?', notifyAMBPLSch);
        
        Test.stopTest();
    }
    
    @isTest
    public static void NotifyAMforBPLRecruitedDailyBatchHelperTest(){
        List<Account> accBplRecruitedList = [SELECT Id,Recruited_By__c,Account_Manager__c 
                                             FROM Account WHERE Recruited_By__c ='BPL Recruited'];
        Id batchJobId = Database.executeBatch(new NotifyAMforBPLRecruitedDailyBatch(), 200);
        System.assert( batchJobId != null );
    }
    
    static Date AddBusinessDays(Date startDate, Integer businessDaysToAdd)
    {
        Date finalDate = startDate;
        Integer direction = businessDaysToAdd < 0 ? -1 : 1;
        while(businessDaysToAdd != 0)
        {
            finalDate = finalDate.addDays(direction);
            if (!IsWeekend(finalDate))
            {
                businessDaysToAdd -= direction;
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