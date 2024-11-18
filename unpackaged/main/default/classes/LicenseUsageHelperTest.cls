/**
 * Class: LicenseUsageHelperTest
 * Copyright (C) 2024 American Red Cross
 * Purpose: Test class for license usage calculation
 * 
 * Change History:
 * 
 * Developer                Date                Ticket              Description
 * ----------------------------------------------------------------------------------------------------
 * Chris Ferraro            1/15/2024                               Initial creation
 * 
 */

@isTest
private class LicenseUsageHelperTest {
    private static testMethod void LicenseTest() {
        LicenseUsageHelper.dispatcher();
        UserLicense[] licenses = [SELECT CreatedDate,Id,LastModifiedDate,LicenseDefinitionKey,MasterLabel,Name,Status,SystemModstamp,TotalLicenses,UsedLicenses,UsedLicensesLastUpdated FROM UserLicense WHERE Status = 'Active'];
        RecordType SalesforceLicenseRecordType = LicenseUsageHelper.getSalesforceLicenseRecordType();

        License_Usage__c[] licenseUsages = [SELECT Id from License_Usage__c WHERE RecordTypeId = :SalesforceLicenseRecordType.Id];
        Assert.areEqual(licenseUsages.size(), licenses.size());
    }

    private static testMethod void testScheduler() {
        LicenseUsageSchedulable lus = new LicenseUsageSchedulable();
        lus.execute(null);

        UserLicense[] licenses = [SELECT CreatedDate,Id,LastModifiedDate,LicenseDefinitionKey,MasterLabel,Name,Status,SystemModstamp,TotalLicenses,UsedLicenses,UsedLicensesLastUpdated FROM UserLicense  WHERE Status = 'Active'];
        RecordType SalesforceLicenseRecordType = LicenseUsageHelper.getSalesforceLicenseRecordType();

        License_Usage__c[] licenseUsages = [SELECT Id from License_Usage__c WHERE RecordTypeId = :SalesforceLicenseRecordType.Id];
        Assert.areEqual(licenseUsages.size(), licenses.size());
    }
    
}