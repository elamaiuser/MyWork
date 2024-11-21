@isTest
public class UpdateNationalNameStatusControllerTest {
	@testSetup 
    public static void testSetup(){
        
        // create account
        Account accobj = new Account();
        accobj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Mobile Account').getRecordTypeId();
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30622';
        accobj.Initial_Reviewer__c = UserInfo.getUserId();
        accobj.National_Name_Status__c = 'Initial Review Pending';
        insert accobj;
        
        //create sked location
        sked__Location__c siteObj = new sked__Location__c();
        siteObj.RecordTypeId = Schema.SObjectType.sked__Location__c.getRecordTypeInfosByName().get('Mobile Site').getRecordTypeId();
        siteObj.Name = 'Test Site';
		siteObj.sked__Address__c = 'Test Site Address';
		siteObj.sked_Site_Building_Name__c = 'Test Site Building';
		siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
		siteObj.sked_Room_Name__c = 'Room 15';
		siteObj.sked_National_Name__c = 'AMERICA';
		siteObj.sked_Physical_Location_Type__c = 'Outside';
		siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
		siteObj.sked_Automation_Suitability__c = 'Suitable';
		siteObj.sked_Outside_stairs__c = 1;
		siteObj.sked_Inside_stairs__c = 2;
		siteObj.sked_Base_Description__c = 'test base description';
		siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
		siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
		siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
		siteObj.sked_Site_Main_Phone__c = '758-771-0091';
		siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
		siteObj.sked_Pay_for_Parking__c = 'Other';
		siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';   
        siteObj.sked_Address_1__c = 'Test Site Address 1';  
        siteObj.sked_County__c = 'USA';
        siteObj.sked_City__c = 'Aubum';
        siteObj.sked_State__c = 'Alabama';
        siteObj.sked_Zip_Code__c = '36801';
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.Source__c = 'Custom New Form';
        siteObj.Initial_Reviewer__c = UserInfo.getUserId();
        siteObj.National_Name_Status__c = 'Initial Review Pending';
        insert siteObj;
        
    }
    @isTest static void testMethodOne() {
        Account account = [Select id from account limit 1];
    	UpdateNationalNameStatusController.updateNationNameStatus(account.id);
    }
    @isTest static void testMethodtwo() {
        Account account = [Select id,National_Name_Status__c from account limit 1];
        account.National_Name_Status__c = 'Second Review Pending';
        update account;
    	UpdateNationalNameStatusController.updateNationNameStatus(account.id);
    }
    @isTest static void testMethodthree() {
        Account account = [Select id,National_Name_Status__c,Initial_Reviewer__c from account limit 1];
        account.National_Name_Status__c = 'Second Review Pending';
        account.Initial_Reviewer__c = null;
        update account;
    	UpdateNationalNameStatusController.updateNationNameStatus(account.id);
    }
    @isTest static void testMethodfour() {
        Account account = [Select id,National_Name_Status__c,Initial_Reviewer__c from account limit 1];
        account.National_Name_Status__c = 'Initial Review Pending';
        account.Initial_Reviewer__c = null;
        update account;
    	UpdateNationalNameStatusController.updateNationNameStatus(account.id);
    }
    
    @isTest static void testMethodFive() {
        sked__Location__c sites = [Select id from sked__Location__c limit 1];
    	UpdateNationalNameStatusController.updateNationNameStatus(sites.id);
    }
    @isTest static void testMethodSix() {
        sked__Location__c sites = [Select id ,National_Name_Status__c  from sked__Location__c limit 1];
        sites.National_Name_Status__c = 'Second Review Pending';
        update sites;
    	UpdateNationalNameStatusController.updateNationNameStatus(sites.id);
    }
    @isTest static void testMethodSeven() {
        sked__Location__c sites = [Select id ,National_Name_Status__c, Initial_Reviewer__c from sked__Location__c limit 1];
        sites.National_Name_Status__c = 'Second Review Pending';
        sites.Initial_Reviewer__c = null;
        update sites;
    	UpdateNationalNameStatusController.updateNationNameStatus(sites.id);
    }
    @isTest static void testMethodEight() {
        sked__Location__c sites = [Select id ,National_Name_Status__c, Initial_Reviewer__c from sked__Location__c limit 1];
        sites.National_Name_Status__c = 'Initial Review Pending';
        sites.Initial_Reviewer__c = null;
        update sites;
    	UpdateNationalNameStatusController.updateNationNameStatus(sites.id);
    }
    
}