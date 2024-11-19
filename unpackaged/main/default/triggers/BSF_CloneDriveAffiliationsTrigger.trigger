trigger BSF_CloneDriveAffiliationsTrigger on Clone_Drive_Affiliations_Event__e (after insert) {
	DriveAffiliationHandler.getInstance((List<Clone_Drive_Affiliations_Event__e>)trigger.new).run();
}