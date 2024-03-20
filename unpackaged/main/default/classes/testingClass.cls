public class testingClass {
    
    public static void tester()
    {
        
        list<portfolio_assignment__c> expPortfolio =[select id,bsf_portfolio__c,Assignment_Type__c,Start_Date__c,End_Date__c,User__c from portfolio_assignment__c];
        system.debug('expPortfolio '+expPortfolio);
        set<string> portfolioCode = new set<string>();
        set<id> bsfId = new set<id>();
        map<string,portfolio_assignment__c> codewithPa = new map<string,portfolio_assignment__c>();
        for(portfolio_assignment__c pa :expPortfolio)
        {
            
            bsfId.add(pa.bsf_portfolio__c);
            
        }
        
        list<bsf_portfolio__c> portfoliowithoutassignments1 = [select id,Portfolio_Code__c,Portfolio_Type__c from bsf_portfolio__c where Id IN:bsfId];
        map<id,string> bsfidPortfolioCode = new map<id,string>();
        for(bsf_portfolio__c bsf :portfoliowithoutassignments1)
        {
            portfolioCode.add(bsf.Portfolio_Code__c);
            bsfidPortfolioCode.put(bsf.id,bsf.Portfolio_Code__c);
            
        }
        
        for(portfolio_assignment__c pa :expPortfolio)
        {
            
            codewithPa.put(bsfidPortfolioCode.get(pa.bsf_portfolio__c),pa);
        }
           list<bsf_portfolio__c> portfoliowithoutassignments = [select id,Portfolio_Code__c,Portfolio_Type__c from bsf_portfolio__c where Portfolio_Code__c IN:portfolioCode and Id Not IN(select bsf_portfolio__c from portfolio_Assignment__c)];
        system.debug('portfolioCode '+portfolioCode);
        map<string,List<bsf_portfolio__c>> idWithbsfportfolioc = new map<string,List<bsf_portfolio__c>>();
        map<id,portfolio_assignment__c> bsfIdPortfolioAssMap = new map<id,portfolio_assignment__c>();
        for(bsf_portfolio__c bsf :portfoliowithoutassignments)
        {
            /*if(bsf.PortfolioAssignments__r != null)
            {
                bsfIdPortfolioAssMap.put(bsf.id,bsf.PortfolioAssignments__r);
            }*/
            
            if(idWithbsfportfolioc.keyset().contains(bsf.Portfolio_Code__c))
            {
                idWithbsfportfolioc.get(bsf.Portfolio_Code__c).add(bsf);
            }
            else
            {
                idWithbsfportfolioc.put(bsf.Portfolio_Code__c,new List<bsf_portfolio__c>{bsf});
            }
        }
        
        system.debug('bsfIdPortfolioAssMap '+bsfIdPortfolioAssMap);
        list<portfolio_assignment__c> newPortfolioList = new list<portfolio_assignment__c>();
        for(string s :idWithbsfportfolioc.keyset())
        {
            for(bsf_portfolio__c bsf :idWithbsfportfolioc.get(s))
            {
                
                    portfolio_assignment__c expa = codewithPa.get(bsf.Portfolio_Code__c);
                    
                    system.debug('expa'+expa);
                    if(expa.Assignment_Type__c == bsf.Portfolio_Type__c)
                    {
                    portfolio_assignment__c pa = new portfolio_assignment__c();
                    pa.bsf_portfolio__c = bsf.id;
                    pa.Start_Date__c = expa.Start_Date__c;
                    pa.End_Date__c = expa.End_Date__c;
                    pa.Assignment_Type__c = expa.Assignment_Type__c;
                    pa.User__c = expa.User__c;
                    newPortfolioList.add(pa);
                    
                    }
            }
        }
        system.debug('newPortfolioList '+newPortfolioList);
        insert newPortfolioList;
            //}
        
    }
    
}