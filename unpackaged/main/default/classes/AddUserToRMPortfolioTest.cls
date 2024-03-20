@isTest
private class AddUserToRMPortfolioTest {
    @testSetup 
    static void setup() {
        List<BSF_Portfolio__c> portfoliosList = new List<BSF_Portfolio__c>();
        for(Integer i=0;i<5;i++) {
            portfoliosList.add(new BSF_Portfolio__c(Portfolio_Name__c = 'TestPF'+i));
        }
        insert portfoliosList;
        System.assertEquals('TestPF0', portfoliosList[0].Portfolio_Name__c,'Insert Failed');
    }
    @IsTest
    static  void getPortfolioNamesTest1(){
        List<BSF_Portfolio__c> portfolios = [SELECT Id, 
                                                    Portfolio_Name__c 
                                                FROM BSF_Portfolio__c];
        System.assertNotEquals(0, portfolios.size(),'No portfolios found.');
        List<String> inputs = new List<String>();
        for(BSF_Portfolio__c pf : portfolios){
            inputs.add(pf.Id);
        }
        Test.startTest();
        List<String> result = AddUserToRMPortfolio.getPortfolioNames(inputs);
        Test.stopTest();
        System.assertNotEquals(0, result.size(),'No portfolios found from test method.');
    }
    @IsTest
    static  void getPortfolioNamesTest2(){
        List<String> inputs = new List<String>();
        Test.startTest();
        List<String> result = AddUserToRMPortfolio.getPortfolioNames(inputs);
        Test.stopTest();
        System.assertEquals(0, result.size(),'Portfolios found from test method.');
    }
    @IsTest
    static  void createUserPortfolioMappingForRMTest1(){
        List<BSF_Portfolio__c> portfolios = [SELECT Id, 
                                                    Portfolio_Name__c 
                                                FROM BSF_Portfolio__c];
        System.assertNotEquals(0, portfolios.size(),'No portfolios found.');
        List<String> inputsIdList = new List<String>();
        for(BSF_Portfolio__c pf : portfolios){
            inputsIdList.add(pf.Id);
        }

        AddUserToRMPortfolio.AddUserToRMPortfolioWrapper pfWrapper = new AddUserToRMPortfolio.AddUserToRMPortfolioWrapper();
        pfWrapper.userId = UserInfo.getUserId();
        pfWrapper.endDate = DateTime.now().addYears(1).format('yyyy-MM-dd');
        pfWrapper.startDate = DateTime.now().format('yyyy-MM-dd');
        String inputString = JSON.serialize(pfWrapper);

        Test.startTest();
        AddUserToRMPortfolio.createUserPortfolioMappingForRM(inputString,inputsIdList);
        Test.stopTest();
    }
}