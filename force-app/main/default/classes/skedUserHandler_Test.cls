@isTest
private class skedUserHandler_Test {
    @isTest
    static void assignUsersToQueues_Test() {
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'APS Planner'];
        User u = new User(alias = 'test123', email='test123@noemail.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileId = p.Id, country='United States', IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@skedtest.com');

        String opCentersStr = '';
        for (Biomed_Collection_Op_Center__c opCenter : [SELECT Id, Name FROM Biomed_Collection_Op_Center__c]) {
            opCentersStr += opCenter.Name + ';';
        }
        opCentersStr = opCentersStr.Substring(0,opCentersStr.length()-1); 
        u.sked_Collection_Operations__c = opCentersStr;
        insert u;

        Test.startTest();
            skedUserHandler.assignUsersToQueues(new List<User>{u});
        Test.stopTest();

        List<GroupMember> userGroupMembers = [SELECT Id, Group.Name FROM GroupMember WHERE UserOrGroupId = :u.Id];
        System.assert(!userGroupMembers.isEmpty());
    }

    @isTest
    static void maintainUserQueues_Test() {
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'APS Planner'];
        User u = new User(alias = 'test123', email='test123@noemail.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileId = p.Id, country='United States', IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@skedtest.com');

        String opCentersStr = '';
        for (Biomed_Collection_Op_Center__c opCenter : [SELECT Id, Name FROM Biomed_Collection_Op_Center__c]) {
            opCentersStr += opCenter.Name + ';';
        }
        opCentersStr = opCentersStr.Substring(0,opCentersStr.length()-1); 
        u.sked_Collection_Operations__c = opCentersStr;
        insert u;

        Map<Id, User> oldMap = new Map<Id, User>();
        oldMap.put(u.Id, u);

        User u2 = u.clone(true, false, false, false);
        u2.sked_Collection_Operations__c = '';
        Map<Id, User> newMap = new Map<Id, User>();
        newMap.put(u2.Id, u2);

        Test.startTest();
            skedUserHandler.maintainUserQueues(newMap, oldMap);
        Test.stopTest();
    }

    @isTest
    static void removeUsersFromQueues_Test() {
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'APS Planner'];
        User u = new User(alias = 'test123', email='test123@noemail.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileId = p.Id, country='United States', IsActive =true,
        timezonesidkey='America/Los_Angeles', username='tester@skedtest.com');

        String opCentersStr = '';
        for (Biomed_Collection_Op_Center__c opCenter : [SELECT Id, Name FROM Biomed_Collection_Op_Center__c]) {
            opCentersStr += opCenter.Name + ';';
        }
        opCentersStr = opCentersStr.Substring(0,opCentersStr.length()-1); 
        u.sked_Collection_Operations__c = opCentersStr;
        insert u;
        
        Test.startTest();
            skedUserHandler.assignUsersToQueues(new List<User>{u});

            Map<Id, List<String>> collectionOpsToRemoveByUser = new Map<Id, List<String>>();
            collectionOpsToRemoveByUser.put(u.Id, opCentersStr.split(';'));
            skedUserHandler.removeUsersFromQueues(JSON.serialize(collectionOpsToRemoveByUser));
        Test.stopTest();

        List<GroupMember> userGroupMembers = [SELECT Id, Group.Name FROM GroupMember WHERE UserOrGroupId = :u.Id];
        System.assert(!userGroupMembers.isEmpty());

    }

    @TestSetup
    static void makeData() {
        List<Biomed_Collection_Op_Center__c> opCenters = new List<Biomed_Collection_Op_Center__c>();
        Set<String> collectionOpNames = new Set<String>{'Adrian MI', 'Alameda CA', 'Albany NY', 'Altoona PA'};
        for (String collectionOpName : collectionOpNames) {
            opCenters.add(new Biomed_Collection_Op_Center__c(
                Name = collectionOpName,
                sked_Lunch_Break_Duration_Fixed_Site__c = '30',
                sked_Lunch_Break_Duration_Mobile__c = '30',
                sked_Hold_Threshold__c = 100,
                Staging_Location_Geolocation__Latitude__s = 37.7450046,
                Staging_Location_Geolocation__Longitude__s = -122.4816244,
                sked_Work_Week_First_Day__c = 'Sunday'
            ));
        }
        insert opCenters;

        Test.startTest();
            skedFutureCallEventHandler.publishFutureCallEvent('skedBiomedCollectionOpHandler', 'createQueues', collectionOpNames);
        Test.stopTest();
    }
}