global class skedPostPatternMigrationBatch implements Database.Batchable<sked__Availability_Pattern__c>, Database.AllowsCallouts {
    global skedPostPatternMigrationBatch() {}

    global List<sked__Availability_Pattern__c> start(Database.BatchableContext BC) {
        return [
            SELECT Id, Name, sked__Description__c, sked__Pattern__c, sked_Validate_2CDO_Rule__c, sked_MigrationID__c
            FROM sked__Availability_Pattern__c
            WHERE sked_MigrationID__c != NULL
            AND sked_Post_Migration_Processed__c = FALSE
        ];
    }

    global void execute(Database.BatchableContext BC, List<sked__Availability_Pattern__c> records) {
        skedModels.availabilityPattern availabilityPattern = new skedModels.availabilityPattern();
        availabilityPattern.id = records[0].Id;
        availabilityPattern.name = records[0].Name;
        availabilityPattern.description = records[0].sked__Description__c;
        availabilityPattern.pattern = records[0].sked__Pattern__c;
        availabilityPattern.validate2CDORule = records[0].sked_Validate_2CDO_Rule__c;
        availabilityPattern.patternData = (skedAvailabilityPatternData) JSON.deserialize(availabilityPattern.pattern, skedAvailabilityPatternData.class);
        availabilityPattern.availabilityPatternResources = new List<skedModels.availabilityPatternResource>();

        skedRacController.savePatternRequestModel patternRequestModel = new skedRacController.savePatternRequestModel();
        patternRequestModel.availabilityPattern = availabilityPattern;
        try {
            skedAvailabilityPatternService service = (skedAvailabilityPatternService) skedServiceFactory.instance.resolve('sked__Availability_Pattern__c');
            skedDataService.saveResult saveResult = service.saveAvailabilityPattern(patternRequestModel.availabilityPattern);

            if (saveResult.success) {
                update new sked__Availability_Pattern__c(
                    Id = availabilityPattern.Id,
                    sked_Post_Migration_Processed__c = true
                );
            }

        } catch (Exception exc) {
            System.debug('Caught Exception trying to update Availability Pattern: ' + exc.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
}