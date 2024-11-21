@isTest
private class slwcQueryBuilder_Test {

    static testmethod void mainTest() {
        Biomed_Collection_Op_Center__c testCollectionOperation1 = new Biomed_Collection_Op_Center__c(
            Name = 'Collection Operation 1',
            sked_Lunch_Break_Duration_Fixed_Site__c = '30',
            sked_Lunch_Break_Duration_Mobile__c = '30',
            sked_Hold_Threshold__c = 100,
            Staging_Location_Geolocation__Latitude__s = 37.7450046,
            Staging_Location_Geolocation__Longitude__s = -122.4816244,
            sked_Work_Week_First_Day__c = 'Sunday'
        );
        insert testCollectionOperation1;
        
        sked__Region__c testRegion1 = new sked__Region__c(
            Name = 'Region 1',
            sked__Timezone__c = UserInfo.getTimeZone().getID(),
            sked_Biomed_Collection_Op_Center__c = testCollectionOperation1.Id
        );
        insert testRegion1;
        
        Test.startTest();
        
        slwcQueryBuilder builder = new slwcQueryBuilder();
        builder.setFromClause('Biomed_Collection_Op_Center__c');
        builder.addField('Id');
        builder.addFields(new List<string> { 'Name' });
        builder.addFields(new Set<string> { 'sked_Work_Week_First_Day__c' });
        
        List<string> conditions = new List<string>();
        conditions.add(builder.generateCondition('Id = {0}', testCollectionOperation1.Id));
        conditions.add(builder.generateCondition('sked_Work_Week_First_Day__c = {0}', 'Sunday'));
        conditions.add(builder.generateCondition('CreatedDate >= {0}', system.now().addHours(-1)));
        conditions.add(builder.generateCondition('DAY_ONLY(CreatedDate) >= {0}', system.today().addDays(-1)));
        conditions.add(builder.generateCondition('Id = {0}', new Set<Id> { testCollectionOperation1.Id }));
        conditions.add(builder.generateCondition('Id = {0}', new List<string> { testCollectionOperation1.Id }));
        
        builder.addCondition(builder.generateCondition('Id = {0}', testCollectionOperation1.Id));
        builder.addConditions(conditions);
        builder.cleanConditions();
        
        builder.addCondition('Id = {0}', testCollectionOperation1.Id);
        builder.addCondition('sked_Work_Week_First_Day__c = {0}', 'Sunday');
        builder.addCondition('CreatedDate >= {0}', system.now().addHours(-1));
        builder.addCondition('DAY_ONLY(CreatedDate) >= {0}', system.today().addDays(-1));
        builder.addCondition('Id IN {0}', new Set<Id> { testCollectionOperation1.Id });
        builder.addCondition('Id IN {0}', new List<string> { testCollectionOperation1.Id });
        
        builder.orderClause = 'ORDER BY Name ASC';
        builder.limitRecords = 1;
        builder.offsetRecords = 0;
        
        string queryStr = builder.toString();
        Database.query(queryStr);
        
        Test.stopTest();
    }
    
}