/* The following test class has covered the following classes and Triggers
	DriveMarketingProgramTriggerService , DriveMarketingProgramTriggerHandler , DriveMarketingProgramTrigger*/

@isTest
public class DriveMarketingProgramTriggerService_Test {
    
    @isTest static void testSetOrderBudget() {
        
        //create account
        List<Account> accList = new List<Account>();        
        Account accobj;
        accobj = new Account();
        accobj.Name = 'Exavalu';
        accobj.BillingPostalCode = '30622';
        accList.add(accobj);
        insert accList;
        
        //create opportunity
        List<Opportunity> opplist = new List<Opportunity>();
		Opportunity optyObj = new Opportunity();
		optyObj.AccountId = accList[0].Id;
		optyObj.Name = 'Test Drive';
		optyObj.StageName = 'Discovery';
		optyObj.Drive_Date__c = System.today();
		optyObj.Type_of_Drive__c = 'Mobile';
		optyObj.CloseDate = System.today();
		optyObj.Start_Time__c = System.now().Time();
		optyObj.End_Time__c = System.now().Time()+1;
		optyObj.Anticipated_Registered_Donors__c = 1;	
		optyObj.X2RBC_Projected_Procedures__c = 1;
		optyObj.WB_Projected_Procedures__c = 2;
		optyObj.Plasma_Pheresis_Projected_Procedures__c = 3;
		optyObj.Platelet_Projected_Procedures__c = 1;
		opplist.add(optyObj);		
		insert opplist;
           
        //create affiliations
        List<Marketing_Program__c> affList = new List<Marketing_Program__c>();
        Marketing_Program__c aff = new Marketing_Program__c();
        aff.Name = 'Pint Sized Hero';
        aff.External_Name__c = 'Pint Sized Hero';
        aff.Scope__c = 'Drive';
        affList.add(aff);
        insert affList;
        
        //create drive affiliations
        List<Drive_Marketing_Programs__c> dmList = new List<Drive_Marketing_Programs__c>();
        Drive_Marketing_Programs__c dm = new Drive_Marketing_Programs__c();
        dm.Marketing_Program__c = affList[0].id;
        dm.Blood_Drive_Opportunity__c = opplist[0].id;
        dmList.add(dm);
        insert dmList;
                
        // create order 
		List<Order> orderlist = new List<Order>();
		Order o = new Order();
		o.name='Test1 Order';
		o.AccountId= accList[0].Id ;
		o.OpportunityId = opplist[0].Id ;
		o.Material_Recipient_Type__c = 'Same';
		o.Material_Recipient__c = 'Account Manager';
		o.EffectiveDate=system.today();
		o.status='draft' ;
		orderlist.add(o);
        insert orderlist;
        
        test.startTest();
        List<Order> oList = [select Id from Order where Name = 'Test1 Order'];
        update oList;      
        test.stopTest();
			
        }        
        
    }