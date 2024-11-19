public with sharing class skedUnavailabilityBalanceResultModel {
    public boolean hasEnoughHours;
    public decimal noOfAvailableHours;
    public decimal noOfRequestedHours;
    public List<skedModels.availability> unavailability;
}