public with sharing class DriveMarketingProgramTriggerService {

    /*
    * JIRA Ticket: HRP - 1614,
    * Description: 2.0 DRD AM: Selecting Publicity Order Item
    */

    public static void setOrderBudget(List<Drive_Marketing_Programs__c> oldDriveItems, List<Drive_Marketing_Programs__c> newDriveItems,
                                                        Map<Id,Drive_Marketing_Programs__c> oldDriveItemsMap,Map<Id,Drive_Marketing_Programs__c> newDriveItemsMap){

		List<Marketing_Program__c> mproglist = new List<Marketing_Program__c>();
		List<Order> orderupdatelist = new List<Order>();
	    Set<Id> marketingprogramid = new Set<Id>();
	    Set<Id> opportunityids = new Set<Id>();

		Map<Id, Marketing_Program__c> mpobjectmap = new Map<Id, Marketing_Program__c>();

		for( Drive_Marketing_Programs__c dm : newDriveItems ){
			marketingprogramid.add( dm.Marketing_Program__c);
		}

		mproglist = [select Id, Name from Marketing_Program__c where Id IN: marketingprogramid  ];
		for( Marketing_Program__c mp : mproglist ){
			mpobjectmap.put( mp.Id, mp );
		}


		for( Drive_Marketing_Programs__c dm : newDriveItems ){
			if( mpobjectmap.containsKey( dm.Marketing_Program__c )  && (mpobjectmap.get( dm.Marketing_Program__c ).Name == 'Pint Sized Hero' || mpobjectmap.get( dm.Marketing_Program__c ).Name == 'Future Blood Donor')  ){
				opportunityids.add( dm.Blood_Drive_Opportunity__c);
			}
		}

		if( !opportunityids.isEmpty() ){
			orderupdatelist = [ select Id from Order where OpportunityId IN:opportunityids  ];
		}

		if( !orderupdatelist.isEmpty() ){
			// Blank update, to recalculate Order budget
			//Schema.DescribeSObjectResult ds = Order.sObjectType.getDescribe();
            //if( ds.isUpdateable() ){}
				update orderupdatelist;
		}
    }

	public static void syncSpecialAffiliationsOnDrive(Map<Id, Drive_Marketing_Programs__c> driveAffiliationsMap, Map<Id, Drive_Marketing_Programs__c> oldDriveAffiliationsMap, String operation) {
		List<String> specialAffiliations = BSF_Utilities.getActivePicklistValues('Opportunity', 'Special_Affiliations__c');
		List<String> specialAffiliationsToSync;
		Map<Id, Opportunity> oppIdVsOppWithSpecialAffiliationsMap = new Map<Id, Opportunity>();
		Map<Id, Drive_Marketing_Programs__c> clonedDriveAffiliationsMap = driveAffiliationsMap.deepClone();

		if(operation.equalsIgnoreCase('Update') && oldDriveAffiliationsMap != null && !oldDriveAffiliationsMap.isEmpty()) {
			for(Drive_Marketing_Programs__c newDriveAffiliation : driveAffiliationsMap.values()) {
				if(newDriveAffiliation.Date_Removed__c != oldDriveAffiliationsMap.get(newDriveAffiliation.Id).Date_Removed__c) {
					if(newDriveAffiliation.Date_Removed__c == null) {
						operation = 'Insert'; //If date removed is made blank, sync the special affiliations field through insert operation
					} else if(newDriveAffiliation.Date_Removed__c > System.today()) {
						clonedDriveAffiliationsMap.remove(newDriveAffiliation.Id); //If date removed is greater than today, remove the affiliation so that it doesn't get processed further and eventually gets removed
					}
				}
			}
		}

		List<Drive_Marketing_Programs__c> driveAffiliations = [
			SELECT Id, Blood_Drive_Opportunity__c,
			Blood_Drive_Opportunity__r.Special_Affiliations__c,
			Marketing_Program__r.Name
			FROM Drive_Marketing_Programs__c
			WHERE Id IN :clonedDriveAffiliationsMap.keySet()
			AND Marketing_Program__r.Name IN :specialAffiliations
			AND Blood_Drive_Opportunity__r.Is_Template__c = false
			AND Blood_Drive_Opportunity__r.Type_of_Drive__c = :BSF_Constants.MOBILE_DRIVE
			AND Blood_Drive_Opportunity__r.StageName != :BSF_Constants.STAGE_CANCELLED
			ORDER BY Blood_Drive_Opportunity__c
			ALL ROWS
		];

		if(driveAffiliations != null && !driveAffiliations.isEmpty()) {
			for(Drive_Marketing_Programs__c driveAffiliation : driveAffiliations) {
				specialAffiliationsToSync = new List<String>();

				if(!oppIdVsOppWithSpecialAffiliationsMap.containsKey(driveAffiliation.Blood_Drive_Opportunity__c)) {
					oppIdVsOppWithSpecialAffiliationsMap.put(driveAffiliation.Blood_Drive_Opportunity__c, driveAffiliation.Blood_Drive_Opportunity__r);
				}

				String existingSpecialAffiliations = oppIdVsOppWithSpecialAffiliationsMap.get(driveAffiliation.Blood_Drive_Opportunity__c).Special_Affiliations__c;
				for(String existingSpecialAffiliation : existingSpecialAffiliations?.split(';') ?? new List<String>()) {
					if(!existingSpecialAffiliation.equalsIgnoreCase(driveAffiliation.Marketing_Program__r.Name)) {
						specialAffiliationsToSync.add(existingSpecialAffiliation);
					}
				}

				if(operation.equalsIgnoreCase('Insert') && !specialAffiliationsToSync.contains(driveAffiliation.Marketing_Program__r.Name)) {
					specialAffiliationsToSync.add(driveAffiliation.Marketing_Program__r.Name);
				}
				oppIdVsOppWithSpecialAffiliationsMap.get(driveAffiliation.Blood_Drive_Opportunity__c).Special_Affiliations__c = String.join(specialAffiliationsToSync, ';');
			}
		}

		if(!oppIdVsOppWithSpecialAffiliationsMap.isEmpty()) {
			TriggerHandler.bypass('OpportunityTriggerHandler');
			skedHubBase.BypassUpdateTriggers = true;

			Database.SaveResult[] updateResults = Database.Update(oppIdVsOppWithSpecialAffiliationsMap.values(), false);
			insert (BSF_Utilities.createErrorLogWithObjectId(
				updateResults,
				'Sync special affiliations',
				'DriveMarketingProgramTriggerService',
				'syncSpecialAffiliationsOnDrive',
				'Error',
				'Addition of special affiliations'
			));

			TriggerHandler.clearBypass('OpportunityTriggerHandler');
			skedHubBase.BypassUpdateTriggers = false;
		}
	}

}