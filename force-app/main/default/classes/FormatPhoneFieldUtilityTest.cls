@IsTest
private class FormatPhoneFieldUtilityTest {


    @IsTest
    private static void testFormatPhoneFields(){
        Account account = new Account(Name='Test',Phone='777-777-7777');
        Test.startTest();
        insert account;
        Test.stopTest();
        Account account2 = [select Phone from Account where Name = 'Test'];
        System.assert(account2.Phone == '7777777777');

    }
}