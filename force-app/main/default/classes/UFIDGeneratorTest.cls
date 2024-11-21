@isTest
private class UFIDGeneratorTest {
    static testmethod void testUFIDGeneration() {
         // test UFID generation on account object

         // create a single account record
         Account testAccount = new Account (Name = 'Test Account');

         try {
             insert testAccount;
         } catch (DMLException ex) {
             System.assert(false, ex.getDMLMessage(0));
         }

         List<UFIDGenerator.UFIDInfo> ufidInfos = new List<UFIDGenerator.UFIDInfo>();
         UFIDGenerator.UFIDInfo ufidInfo = new UFIDGenerator.UFIDInfo();

         ufidInfo.prefix = 'A';
         ufidInfo.maxLength = 6;
         ufidInfo.value = UFIDGenerator.MASK.length() - 5;
         ufidInfo.recordId = testAccount.id;
         ufidInfo.fieldName = 'UFID__c';
         list<String> ufids;

         ufidInfos.add (ufidInfo);

         Test.startTest();
             ufids = UFIDGenerator.genUFID(ufidInfos);
         Test.stopTest();

         system.assertEquals(1, ufids.size());

         testAccount = [ select UFID__c from Account where id = :testAccount.id];

         String val = 'A0000' + UFIDGenerator.MASK.subString(UFIDGenerator.MASK.length() - 5, UFIDGenerator.MASK.length() - 4);
         System.assertEquals(val, testAccount.UFID__c);
         System.assertEquals(val, ufids[0]);
    }
}