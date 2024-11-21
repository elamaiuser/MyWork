public without sharing class GeneratePendingDCRController {

    @AuraEnabled
    public static driveDateWrapper getData(List<Id> travelTimeSiteToCo, List<Id> travelTimeCoToSite) {
        driveDateWrapper driveData = new driveDateWrapper();
        List<sked_Drive__c> driveList = [SELECT Id, Name, sked_Drive_Date__c, sked_Status__c, sked_Start_Time__c, sked_End_Time__c, sked_Opportunity__r.Flow_Start_Time_Label_Text__c, sked_Opportunity__r.Flow_End_Time_Label_Text__c FROM sked_Drive__c where (sked_Travel_Time_CO_To_Site__c in: travelTimeCoToSite OR sked_Travel_Time_Site_To_CO__c in: travelTimeSiteToCo) AND sked_Drive_Date__c >= today AND sked_Status__c Not in ('Complete','Cancel') limit 1000];
        driveData.drives = driveList;
        String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId() LIMIT 1].Name;
        if(System.label.TravelTimeEditableProfiles.split(',').contains(profileName)){
            driveData.isButtonVisible = true;
        } else {
            driveData.isButtonVisible = false;
        }
        return driveData;
    }

    @AuraEnabled
    public static String createRequestForDCR(List<Id> impactedDrivesId) {
        System.debug('impactedDrivesId :: '+impactedDrivesId);
        String impactedDrivesIdString = String.join(impactedDrivesId, ',');
        System.debug(impactedDrivesIdString);
        List<DCRGenerationEvent__e> createPendingDCRList = new List<DCRGenerationEvent__e>(); 
        DCRGenerationEvent__e event = new DCRGenerationEvent__e(
                impactedDrivesId__c = impactedDrivesIdString
                );
        createPendingDCRList.add(event);
        //Publish Event
        if(!createPendingDCRList.isEmpty()) {
            List<Database.SaveResult> eventPubResultList = EventBus.publish(createPendingDCRList);
            
            for(Database.SaveResult eventPubResult : eventPubResultList) {
                if(eventPubResult.isSuccess()) {
                    System.debug('\nEvents published successfully  => ' + eventPubResult);
                }
                else {
                    for(Database.Error pubError : eventPubResult.getErrors()) {
                        System.debug('\nEvent publishing failed => ' + pubError.getStatusCode() + ' => ' + pubError.getMessage());
                    }
                }
            }
        }
            return 'DCR created successfully';
    }

    public class driveDateWrapper {
       @AuraEnabled public List<sked_Drive__c> drives;
       @AuraEnabled public Boolean isButtonVisible;
    }
    
}