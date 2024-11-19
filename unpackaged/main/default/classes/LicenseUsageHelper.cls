/**
 * Class: LicenseUsageHelper
 * Copyright (C) 2024 American Red Cross
 * Purpose: Helper class for license usage calculation
 * 
 * Change History:
 * 
 * Developer                Date                Ticket              Description
 * ----------------------------------------------------------------------------------------------------
 * Chris Ferraro            1/15/2024                               Initial creation
 * Chris Ferraro            6/20/2024                               Added WITH USER MODE to queries
 * 
 */
 public with sharing class LicenseUsageHelper {
    
    public static void dispatcher() {
        processSalesforceLicenses();
        processManagedPackages();
    }
    
    public static void processSalesforceLicenses() {
        RecordType SalesforceLicenseRecordType = getSalesforceLicenseRecordType();
        UserLicense[] licenses = getUserLicenses();
        License_Usage__c[] usages = new License_Usage__c[]{};
        
        for (UserLicense ul : licenses) {
            License_Usage__c usage = new License_Usage__c();
            usage.recordTypeId = SalesforceLicenseRecordType.Id;
            usage.License_Snapshot_Date_Time__c = DateTime.now();
            usage.Name__c = ul.MasterLabel;
            usage.License_Definition_Key__c = ul.LicenseDefinitionKey;
            usage.Total_Licenses__c = ul.TotalLicenses;
            usage.Used_Licenses__c = ul.UsedLicenses;
            usage.Status__c = ul.Status;
            usages.add(usage);
        }
        
        insert usages;
    }
    
    public static void processManagedPackages() {
        RecordType managedPackageRecordType = getManagedPackageRecordType();
        PackageLicense[] packageLicenses = getPackageLicenses();
        Map<String, String> packageNameMap = getPackageNameMap();
        
        License_Usage__c[] usages = new License_Usage__c[]{};
        
        for (PackageLicense lic : packageLicenses) {
            License_Usage__c usage = new License_Usage__c();
            usage.recordTypeId = managedPackageRecordType.Id;
            usage.License_Snapshot_Date_Time__c = DateTime.now();
            usage.Name__c = packageNameMap.get(lic.NamespacePrefix);
            usage.Namespace_Prefix__c = lic.NamespacePrefix;
            usage.Total_Licenses__c = lic.AllowedLicenses;
            usage.Used_Licenses__c = lic.UsedLicenses;
            usage.Status__c = lic.Status;
            usage.Package_Id__c = lic.Id;
            usages.add(usage);
        }
        insert usages;
    }
    
    public static Map<String, String> getPackageNameMap() {
        
        Package_Name__mdt[] packageNames = [SELECT Package_Name__c, Package_Namespace__c FROM Package_Name__mdt WHERE Package_Name__c != ''];
        Map<String, String> packageNameMap = new Map<String, String>();
        
        for (Package_Name__mdt packageName : packageNames) {
            packageNameMap.put(packageName.Package_Namespace__c, packageName.Package_Name__c);
        }
        
        return packageNameMap;
    }

    public static RecordType getManagedPackageRecordType() {
        recordType[] rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Managed_Package' WITH USER_MODE LIMIT 1];
        return rt[0];
    }
    
    public static RecordType getSalesforceLicenseRecordType() {
        recordType[] rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Salesforce_License' WITH USER_MODE LIMIT 1];
        return rt[0];
    }


    public static UserLicense[] getUserLicenses() { 
        return [SELECT CreatedDate,Id,LastModifiedDate,LicenseDefinitionKey,MasterLabel,Name,Status,SystemModstamp,TotalLicenses,UsedLicenses,UsedLicensesLastUpdated FROM UserLicense WHERE Status = 'Active' WITH USER_MODE];
    }


    public static PackageLicense[] getPackageLicenses() {
        return [SELECT AllowedLicenses,CreatedDate,ExpirationDate,Id,IsAvailableForIntegrations,IsProvisioned,LastModifiedDate,NamespacePrefix,Status,SystemModstamp,UsedLicenses FROM PackageLicense WHERE Status != 'Free' WITH USER_MODE];
    }
    
}