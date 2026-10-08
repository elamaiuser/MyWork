public with sharing class TMSSiteService {
    
    // ====================================================================================
    // 1. TMS_Site__c TRIGGER LOGIC
    // ====================================================================================
    
    public static void handleTMSSiteBeforeSave(List<TMS_Site__c> newSites, Map<Id, TMS_Site__c> oldMap) {
        List<TMS_Site__c> sitesToValidate = new List<TMS_Site__c>();
        
        for (TMS_Site__c site : newSites) {
            if (site.Effective_Date__c == null) {
                site.Effective_Date__c = System.today();
            }
            if (site.End_Date__c == null) {
                site.End_Date__c = Date.newInstance(4000, 12, 31);
            }
            
            if (oldMap == null || 
                site.Name != oldMap.get(site.Id).Name || 
                site.Effective_Date__c != oldMap.get(site.Id).Effective_Date__c || 
                site.End_Date__c != oldMap.get(site.Id).End_Date__c) {
                
                sitesToValidate.add(site);
            }
        }
        
        if (!sitesToValidate.isEmpty()) {
            validateTMSSiteDateRanges(sitesToValidate, newSites);
        }
    }

    private static void validateTMSSiteDateRanges(List<TMS_Site__c> sitesToValidate, List<TMS_Site__c> allNewSites) {
        Set<String> siteNames = new Set<String>();
        for (TMS_Site__c site : sitesToValidate) {
            siteNames.add(site.Name);
        }
        
        List<TMS_Site__c> existingSites = [
            SELECT Id, Name, Effective_Date__c, End_Date__c 
            FROM TMS_Site__c 
            WHERE Name IN :siteNames AND Id NOT IN :allNewSites
        ];
        
        Map<String, List<TMS_Site__c>> existingSiteMap = new Map<String, List<TMS_Site__c>>();
        for (TMS_Site__c exSite : existingSites) {
            if (!existingSiteMap.containsKey(exSite.Name)) {
                existingSiteMap.put(exSite.Name, new List<TMS_Site__c>());
            }
            existingSiteMap.get(exSite.Name).add(exSite);
        }
        
        for (Integer i = 0; i < sitesToValidate.size(); i++) {
            TMS_Site__c currentSite = sitesToValidate[i];
            
            for (Integer j = i + 1; j < sitesToValidate.size(); j++) {
                TMS_Site__c otherSite = sitesToValidate[j];
                if (currentSite.Name == otherSite.Name && isOverlapping(currentSite, otherSite)) {
                    String dateRange = formatDate(otherSite.Effective_Date__c) + ' - ' + formatDate(otherSite.End_Date__c);
                    currentSite.addError('Date range overlaps with another site in this batch: ' + otherSite.Name + ' (' + dateRange + ')');
                }
            }
            
            if (existingSiteMap.containsKey(currentSite.Name)) {
                for (TMS_Site__c exSite : existingSiteMap.get(currentSite.Name)) {
                    if (isOverlapping(currentSite, exSite)) {
                        String dateRange = formatDate(exSite.Effective_Date__c) + ' - ' + formatDate(exSite.End_Date__c);
                        currentSite.addError('Date range overlaps with an existing TMS Site: ' + exSite.Name + ' (' + dateRange + ')');
                    }
                }
            }
        }
    }
    
    private static Boolean isOverlapping(TMS_Site__c siteA, TMS_Site__c siteB) {
        return (siteA.Effective_Date__c <= siteB.End_Date__c) && (siteA.End_Date__c >= siteB.Effective_Date__c);
    }

    private static String formatDate(Date d) {
        if (d == null) return '';
        
        Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());
        return dt.format('MM/dd/yyyy');
    }
    
    // ====================================================================================
    // 2. TMS_Site_User_Assignment__c TRIGGER LOGIC
    // ====================================================================================

    public static void handleAssignmentBeforeSave(List<TMS_Site_User_Assignment__c> newAssignments, Map<Id, TMS_Site_User_Assignment__c> oldMap) {
        Set<Id> usersToValidate = new Set<Id>();
        
        for (TMS_Site_User_Assignment__c assignment : newAssignments) {
            Boolean isInsertDefault = (oldMap == null && assignment.Is_Default__c);
            Boolean isUpdateDefault = (oldMap != null && assignment.Is_Default__c && !oldMap.get(assignment.Id).Is_Default__c);
            
            if (isInsertDefault || isUpdateDefault) {
                if (usersToValidate.contains(assignment.User__c)) {
                    assignment.addError('Only one default TMS Site can be selected for a User.');
                } else {
                    usersToValidate.add(assignment.User__c);
                }
            }
        }
        
        if (!usersToValidate.isEmpty()) {
            Set<Id> usersWithExistingDefault = new Set<Id>();
            for (TMS_Site_User_Assignment__c existing : [
                SELECT User__c 
                FROM TMS_Site_User_Assignment__c 
                WHERE Is_Default__c = TRUE 
                AND User__c IN :usersToValidate 
                AND Id NOT IN :newAssignments
            ]) {
                usersWithExistingDefault.add(existing.User__c);
            }
            
            for (TMS_Site_User_Assignment__c assignment : newAssignments) {
                if (assignment.Is_Default__c && usersWithExistingDefault.contains(assignment.User__c)) {
                    assignment.addError('This User already has an active default TMS Site assigned.');
                }
            }
        }
    }
    
    // ====================================================================================
    // 3. sked__Location__c TRIGGER LOGIC
    // ====================================================================================

    public static void validateTMSSiteBeforeSave(List<sked__Location__c> newLocations, Map<Id, sked__Location__c> oldMap) {
        Set<Id> tmsSiteIds = new Set<Id>();
        List<sked__Location__c> locationsToValidate = new List<sked__Location__c>();
        
        for (sked__Location__c loc : newLocations) {
            Boolean isTmsSiteChanged = (oldMap == null || loc.TMS_Site__c != oldMap.get(loc.Id).TMS_Site__c);
            Boolean isActiveChangedToTrue = (oldMap != null && loc.sked_Active__c && !oldMap.get(loc.Id).sked_Active__c);
            
            if (loc.TMS_Site__c != null && loc.sked_Active__c && (isTmsSiteChanged || isActiveChangedToTrue)) {
                
                if (tmsSiteIds.contains(loc.TMS_Site__c)) {
                    loc.addError('Another active BSF Site in this batch is already attempting to map to this TMS Site.');
                } else {
                    tmsSiteIds.add(loc.TMS_Site__c);
                    locationsToValidate.add(loc);
                }
            }
        }
        
        if (!tmsSiteIds.isEmpty()) {
            Set<Id> existingMappedTmsSites = new Set<Id>();
            
            for (sked__Location__c existingLoc : [
                SELECT TMS_Site__c 
                FROM sked__Location__c 
                WHERE TMS_Site__c IN :tmsSiteIds 
                AND sked_Active__c = TRUE 
                AND Id NOT IN :newLocations
            ]) {
                existingMappedTmsSites.add(existingLoc.TMS_Site__c);
            }
            
            for (sked__Location__c loc : locationsToValidate) {
                if (existingMappedTmsSites.contains(loc.TMS_Site__c)) {
                    loc.addError('An active BSF Site is already mapped to this TMS Site.');
                }
            }
        }
    }
}