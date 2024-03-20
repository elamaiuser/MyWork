// The following test class is covering the below mentioned apex class
// DriveGenerationErrorHandler

@isTest(SeeAllData = FALSE)
public class DriveGenerationErrorHandlerTest
{
    // Technical Issue
    static testMethod void testCreateBsfErrorLog1()
    {
        skedHubBase.BypassInsertTriggers = TRUE;
        skedHubBase.BypassUpdateTriggers = TRUE;
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
		Opportunity fixOpportunity = (Opportunity)mapTestData.get('fixedSiteOpportunity');        
        Test.startTest();
        try{
        	CreateSkedDrive.createDrives(new List<Opportunity>{fixOpportunity});
        }Catch(Exception ex)
        {
            system.assert(ex!= NULL);
            DriveGenerationErrorHandler.createBsfErrorLogs(ex, NULL, fixOpportunity.Id, Constants.TECHNICAL_ISSSUE, 'CreateSkedDrive' , 'createDrives');
        }        
        Test.stopTest();         
    }
    
    static testMethod void testErrorDescription()
    {
        Test.startTest();
        String result = DriveGenerationErrorHandler.errorDescriptionForMissingDataIssue('No Staffing Matrix Found\n');
        Test.stopTest();
        system.assert(result!= NULL);        
    }
    
    static testMethod void testGetFunctionalityFromOppSourceAndType()
    {
        skedHubBase.BypassInsertTriggers = TRUE;
        skedHubBase.BypassUpdateTriggers = TRUE;
        Map<string, sObject> mapTestData = GenerateDriveTestData.setupData();
		Opportunity fixOpportunity = (Opportunity)mapTestData.get('fixedSiteOpportunity');
        Test.startTest();
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([select Id, Type_of_Drive__c, source__c from Opportunity where Id =:fixOpportunity.Id]);
        String result = DriveGenerationErrorHandler.getFunctionalityFromOppSourceAndType(oppMap, fixOpportunity.Id);
        Test.stopTest();
        system.assert(result!= NULL);
        
    }

}