global class slwcAvailabilityService {
    @AuraEnabled
    public static skedWorkdayGetPlanBalanceResponse getUnavailabilityStatistic(String resourceId, String selectedDate, Boolean isCallOut) {
        System.debug(selectedDate);
        Date reqDate = skedDateTimeUtils.getDateFromIsoString(selectedDate);
        skedAvailabilityService service = (skedAvailabilityService)skedServiceFactory.instance.resolve('sked__Availability__c');
        return service.getUnavailabilityStatistics(resourceId, reqDate, isCallOut);
    }
}