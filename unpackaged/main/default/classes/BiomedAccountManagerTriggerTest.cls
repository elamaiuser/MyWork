@IsTest
private class BiomedAccountManagerTriggerTest {
	
    @isTest
    static void initialize_test() {
        DRD_Team__c team = new DRD_Team__c();
        team.DRD_Team_Lead__c = UserInfo.getUserId();
        insert team;
        
        Biomed_Account_Manager__c bam = new Biomed_Account_Manager__c();
        bam.Manager__c = UserInfo.getUserId();
        bam.DRD_Team__c = team.Id;
        bam.Mobile_Phone__c = '999-999-9999';
        bam.Work_Phone__c = '999-999-9999';
        insert bam;
    }
    
}