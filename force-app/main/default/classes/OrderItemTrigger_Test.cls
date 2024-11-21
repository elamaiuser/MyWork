/*
 * This Test class is covering the following Classes and a trigger
 * OrderItemTriggerService
 * OrderItemTriggerHandler
 * OrderItemTrigger
 * */

@isTest(SeeAllData = false)
public class OrderItemTrigger_Test
{
    public static String rolename = 'West_BDM';
    public static String mobileAccRecType = 'Mobile Account';
	public static String mobileOppRecType = 'Mobile Opp';
	public static String mobileSiteRecType = 'Mobile Site'; 
    public static Map<String,Id> recordTypeMap  = new Map<String,Id>();
    
    @testSetup static void prepareDataset()
    {
        // Create User
        User AdminUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'adminuser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        
        //UserRole urole  = [select id from userrole where developername =: rolename ];
        
        User DRDAMUser = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'DRD Profile'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
        );
                
        System.runAs( AdminUser )
        {
            insert DRDAMUser;
        }		
        
        // create mobile account
        recordTypeMap = recordTypeMap( 'Account' );
        Id recTypeId = recordTypeMap.get(mobileAccRecType);        
        Account accobj = new Account();
        accobj.RecordTypeId = recTypeId;
        accobj.Name = 'Exavalu';
        accObj.Internal_Name__c = 'EXAVALU';
        accobj.BillingPostalCode = '30146';        
		insert accobj;
        
        BSF_Constants.isTeamMemberCreatedFromBackend = true;
        
		// insert Account Team and add DRDAMUser
		List<AccountTeammember> atmList = new List<AccountTeammember>();
		AccountTeammember atm = new AccountTeammember();
        atm.AccountAccessLevel = 'Edit';
        atm.CaseAccessLevel = 'Edit';
        atm.OpportunityAccessLevel = 'Edit';
        atm.userId = DRDAMUser.Id ;
        atm.AccountId = accobj.Id ;
        atm.TeamMemberRole = 'Account Manager';
        atm.Start_Date__c = system.today();
        atm.End_Date__c = system.today()+10;
        atmList.add(atm);
        insert atmList;
        
        // Create Collection operation
        Biomed_Collection_Op_Center__c colOpp = new Biomed_Collection_Op_Center__c();
        colOpp.Name = 'Test collection Opetration';
        colOpp.sked_Lunch_Break_Duration_Fixed_Site__c = '30';
       	colOpp.sked_Lunch_Break_Duration_Mobile__c = '30';
        insert colOpp;
        
        // create mobile site
        List<sked__Location__c> skedlocationlist = new List<sked__Location__c>();
		recordTypeMap = recordTypeMap( 'sked__Location__c' );
		Id siteRecTypeId = recordTypeMap.get(mobileSiteRecType);		
		sked__Location__c siteObj = new sked__Location__c();
		siteObj.RecordTypeId = siteRecTypeId;
		siteObj.Name = 'Test Site';
		siteObj.sked__Address__c = 'Test Site Address';
		siteObj.sked_Site_Building_Name__c = 'Test Site Building';
		siteObj.sked_Floor_Description__c = 'Test Site Floor Description';
        siteObj.sked_Collection_Operation__c = colOpp.Id;
		siteObj.sked_Room_Name__c = 'Room 15';
		siteObj.sked_National_Name__c = 'AMERICA';
		siteObj.sked_Physical_Location_Type__c = 'Outside';
		siteObj.sked_Site_Inspection_Completed_By__c = DRDAMUser.Id;
		siteObj.sked_Date_Site_Inspection_Completed__c = System.today().addDays(2);
		siteObj.sked_Automation_Suitability__c = 'Suitable';
		siteObj.sked_Outside_stairs__c = 1;
		siteObj.sked_Inside_stairs__c = 2;
		siteObj.sked_Base_Description__c = 'test base description';
		siteObj.sked_Travel_Time_to_Staging_Location__c = 45;
		siteObj.sked_ARC_Vehicle_Parking_Directions__c = 'Test Direction';
		siteObj.sked_Staff_Personal_Parking_Directions__c = 'Test Direction';
		siteObj.sked_Site_Main_Phone__c = '758-771-0091';
		siteObj.sked_Directions_From_CollectionOperation__c = 'Test Direction';
		siteObj.sked_Pay_for_Parking__c = 'Other';
		siteObj.sked_Pay_for_Parking_Details__c = 'Test Pay';        
        siteObj.sked_Address_1__c = 'Test Site Address 1';  
        siteObj.sked_County__c = 'USA';
        siteObj.sked_City__c = 'Aubum';
        siteObj.sked_State__c = 'Alabama';
        siteObj.sked_Zip_Code__c = '36801';
        siteObj.sked_Wireless_Policy__c = 'Accepted';
        siteObj.Source__c = 'Custom New Form';        
		skedlocationlist.add(siteObj);
		insert skedlocationlist;
        
        // create mobile opportunity
		recordTypeMap = recordTypeMap( 'Opportunity' );
		Id optyRecTypeId = recordTypeMap.get(mobileOppRecType);		
		Opportunity optyObj = new Opportunity();
		optyObj.RecordTypeId = optyRecTypeId;
		optyObj.AccountId = accobj.Id;
		optyObj.Drive_Site__c = skedlocationlist[0].Id;
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
		insert optyObj;
        
        // create products
		List<Product2> productList = new List<Product2>();         
		Product2 prod1 = new Product2(Name = 'Laptop X200',
									 Start_Date__c = System.today().addDays(1),
									 End_Date__c = System.today().addDays(4),
                                     Family = 'Hardware');
        productList.add(prod1);
        Product2 prod2 = new Product2(Name = 'Theme Seasonal',
									 Start_Date__c = System.today().addDays(1),
									 End_Date__c = System.today().addDays(4),
                                     Product_Id__c = 'Theme001',
                                     Family = 'Theme');
        productList.add(prod2);
        Product2 prod3 = new Product2(Name = 'Size-ePoster',
									 Start_Date__c = System.today().addDays(1),
									 End_Date__c = System.today().addDays(4),
                                     Product_Id__c = 'Size004.e',
                                     Family = 'Theme;Education;Diversity;General');
        productList.add(prod3); 
        Product2 prod4 = new Product2(Name = 'Theme Test',
									 Start_Date__c = System.today().addDays(1),
									 End_Date__c = System.today().addDays(4),
                                     Product_Id__c = 'Theme002',
                                     Family = 'Theme');
        productList.add(prod4); 
		insert productList;       
        
        // create Pricebook entry
        Id pricebookId = Test.getStandardPricebookId();	    
		List<PricebookEntry> pentrylist = new List<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productlist[0].Id,UnitPrice = 0.01, IsActive = true);															
		pentrylist.add(standardPrice);		
		insert pentrylist;
        
        // Create Orders
        // 1. MR = Split
        List<Order> orderList = new List<Order>();
		Order o = new Order();
		o.name='Test Order1';
		o.AccountId= accobj.Id ;
		o.OpportunityId = optyObj.Id ;
		o.Material_Recipient_Type__c = 'Split';
		o.Material_Recipient__c = 'Account Manager;Account Contact';
        o.Material_Recipient_Default__c = 'Account Contact';
		o.EffectiveDate=system.today();
		o.status='draft' ;
		o.Pricebook2Id =  pricebookId ;
        
		orderList.add(o);
		
         // 2. MR = Same
		o = new Order();
		o.name='Test Order2';
		o.AccountId= accobj.Id ;
		o.OpportunityId = optyObj.Id ;
		o.Material_Recipient_Type__c = 'Same';
		o.Material_Recipient__c = 'Account Manager';
        o.Material_Recipient_Default__c = 'Account Manager';
		o.EffectiveDate=system.today();
		o.status='draft' ;
		o.Pricebook2Id =  pricebookId ;
        o.BudgetCurrency__c = 1.892;
		orderList.add(o);
        
         // 3. MR = NULL
        o = new Order();
		o.name='Test Order3';
		o.AccountId= accobj.Id ;
		o.OpportunityId = optyObj.Id ;
		o.EffectiveDate=system.today();
		o.status='draft' ;
		o.Pricebook2Id =  pricebookId ;
		orderList.add(o);	
        insert orderList;       
                
    }
	
    static testMethod void validateProductMaterialRecipientSc1_Test()
    {
        Test.startTest();
        List<Order> orderWithBlankMRTypeList = [select Id, Name from Order];
        PricebookEntry standardPrice = [select Id from PricebookEntry limit 1];
        List<product2> productList = [select Id, Name from Product2];
        
        OrderItem oItem = new OrderItem();
        oItem.OrderId= orderWithBlankMRTypeList[2].Id ;
		oItem.PricebookEntryId= standardPrice.Id ;
		oItem.Quantity = 1 ;
		oItem.UnitPrice = 0.01 ; 
		oItem.Product2id  = productList[1].Id;
        oItem.Material_Recipient__c  = 'Account Manager';       
        
        try{
            insert oItem;
        }Catch(Exception ex)
        {
            system.assert(ex.getMessage().contains('Please deselect Material Recipient'));
        }
        Test.stopTest();
        
    }
    
    static testMethod void validateProductMaterialRecipientSc3_Test()
    {
        Test.startTest();
        Order orderWithMismatchMRType = [select Id, Name from Order where Material_Recipient_Type__c = 'Same' limit 1];
        PricebookEntry standardPrice = [select Id from PricebookEntry limit 1];
        List<product2> productList = [select Id, Name from Product2];
        OrderItem oItem = new OrderItem();
        oItem.OrderId= orderWithMismatchMRType.Id ;
		oItem.PricebookEntryId= standardPrice.Id ;
		oItem.Quantity = 1 ;
		oItem.UnitPrice = 0.01 ; 
		oItem.Product2id  = productList[1].Id;
        oItem.Material_Recipient__c  = 'Account Contact';
               
        try{
            insert oItem;
        }Catch(Exception ex)
        {
            system.assert(ex.getMessage().contains('Selected Material Recipient not matched as in Order'));
        }
        Test.stopTest();
        
    }
    static testMethod void validateProductMaterialRecipientSc4_Test()
    {
        Test.startTest();
        Order orderWithMismatchMRType = [select Id, Name from Order where Material_Recipient_Type__c = 'Split' limit 1];
        PricebookEntry standardPrice = [select Id from PricebookEntry limit 1];
        List<product2> productList = [select Id, Name from Product2];
        OrderItem oItem = new OrderItem();
        oItem.OrderId= orderWithMismatchMRType.Id ;
		oItem.PricebookEntryId= standardPrice.Id ;
		oItem.Quantity = 1 ;
		oItem.UnitPrice = 0.01 ; 
		oItem.Product2id  = productList[1].Id;
        oItem.Material_Recipient__c  = 'Staging Office';
        
        try{
            insert oItem;
        }Catch(Exception ex)
        {
            system.assert(ex.getMessage().contains('Selected Material Recipient not matched as in Order'));
        }
        Test.stopTest();
        
    }
    static testMethod void validateProductMaterialRecipientOtherSc_Test()
    {
        Test.startTest();
        
        List<Order> orderObjList = [select Id, Name,Material_Recipient_Default__c from Order];
        PricebookEntry standardPrice = [select Id from PricebookEntry limit 1];
        List<product2> productList = [select Id, Name from Product2];
        
        // Same item only - 1 orderItem with NULL MR
        OrderItem oItem = new OrderItem();
        oItem.OrderId= orderObjList[1].Id ;
		oItem.PricebookEntryId= standardPrice.Id ;
		oItem.Quantity = 1 ;
		oItem.UnitPrice = 0.01 ; 
		oItem.Product2id  = productList[1].Id;
              
        insert oItem;
        List<OrderItem> oitems = [ select Id, OrderId,Material_Recipient__c from OrderItem];
        system.assertEquals(orderObjList[1].Material_Recipient_Default__c, oItems[0].Material_Recipient__c);
        
         // Split items only - 2 orderItems with NULL MR
         List<OrderItem> orderItemList3 = new List<OrderItem>();
        OrderItem oItem3;
        oItem3 = new OrderItem();
        oItem3.OrderId= orderObjList[0].Id ;
		oItem3.PricebookEntryId= standardPrice.Id ;
		oItem3.Quantity = 1 ;
		oItem3.UnitPrice = 0.01 ; 
		oItem3.Product2id  = productList[0].Id;
        orderItemList3.add(oItem3);
        
        oItem3 = new OrderItem();
        oItem3.OrderId= orderObjList[0].Id ;
		oItem3.PricebookEntryId= standardPrice.Id ;
		oItem3.Quantity = 1 ;
		oItem3.UnitPrice = 0.01 ; 
		oItem3.Product2id  = productList[1].Id;
        orderItemList3.add(oItem3);
              
        insert orderItemList3;
        List<OrderItem> oitemsAfterInsert3 = [ select Id, OrderId,Material_Recipient__c from OrderItem where orderId =:orderObjList[0].Id];
        system.assertEquals(orderObjList[0].Material_Recipient_Default__c, oitemsAfterInsert3[0].Material_Recipient__c);
        
        // split items only -  2 orderItems with one OI having NULL MR
        List<OrderItem> orderItemList = new List<OrderItem>();
        OrderItem oItem2;
        oItem2 = new OrderItem();
        oItem2.OrderId= orderObjList[0].Id ;
		oItem2.PricebookEntryId= standardPrice.Id ;
		oItem2.Quantity = 1 ;
		oItem2.UnitPrice = 0.01 ; 
		oItem2.Product2id  = productList[1].Id;
        oItem2.Material_Recipient__c = 'Account Manager';
        orderItemList.add(oItem2);
        
        oItem2 = new OrderItem();
        oItem2.OrderId= orderObjList[0].Id ;
		oItem2.PricebookEntryId= standardPrice.Id ;
		oItem2.Quantity = 1 ;
		oItem2.UnitPrice = 0.01 ; 
		oItem2.Product2id  = productList[1].Id;
        orderItemList.add(oItem2);
        
        insert orderItemList;
        List<OrderItem> oitemsAfterInsert2 = [ select Id, OrderId,Material_Recipient__c from OrderItem where orderId =:orderObjList[0].Id];
        oitemsAfterInsert2.remove(0);
        oitemsAfterInsert2.remove(1);
        system.assertEquals('Account Manager', oitemsAfterInsert2[1].Material_Recipient__c);
        
        // split items only -  1 orderItems with NULL MR        
        OrderItem oItem4 = new OrderItem();
        oItem4.OrderId= orderObjList[0].Id ;
		oItem4.PricebookEntryId= standardPrice.Id ;
		oItem4.Quantity = 2 ;
		oItem4.UnitPrice = 0.01 ; 
		oItem4.Product2id  = productList[2].Id;        
        insert oItem4;
        
        List<OrderItem> oitemListAfterInsert5 = [select Id, OrderId,Material_Recipient__c from OrderItem where quantity =2];
        system.assertEquals(orderObjList[0].Material_Recipient_Default__c, oitemListAfterInsert5[0].Material_Recipient__c);
        
        Test.stopTest();
        
    }
    static testMethod void checkZipCodeOnOppToAddProduct_Test()
    {
        Test.startTest();
        
        Order orderWithMismatchMRType = [select Id, Name from Order where Material_Recipient_Type__c = 'Split' limit 1];
        PricebookEntry standardPrice = [select Id from PricebookEntry limit 1];
        List<product2> productList = [select Id, Name from Product2];
        Biomed_Collection_Op_Center__c colOpp = [select Id from Biomed_Collection_Op_Center__c limit 1];
        
        //create product collection operation
        List<Product_Collection_Operation__c> productColOppList = new List<Product_Collection_Operation__c>();        
        Product_Collection_Operation__c proColOpp = new Product_Collection_Operation__c();
        proColOpp.Product__c = productlist[0].Id;
        proColOpp.Collection_Operation__c = colOpp.Id;
        productColOppList.add(proColOpp);
        insert productColOppList;
        
        OrderItem oItem = new OrderItem();
        oItem.OrderId= orderWithMismatchMRType.Id ;
		oItem.PricebookEntryId= standardPrice.Id ;
		oItem.Quantity = 1 ;
		oItem.UnitPrice = 0.01 ; 
		oItem.Product2id  = productList[0].Id;
        oItem.Material_Recipient__c  = 'Staging Office';        
        
        try{
            insert oItem;
        }Catch(Exception ex)
        {
            system.assert(ex.getMessage().contains('Can not add product as collection Operation is not available'));
        }
        Test.stopTest();
        
    }
    static testMethod void validateOneThemePerOrder_Test()
    {
        Test.startTest();
               
        Order orderWithSameMRType = [select Id, Name from Order where Material_Recipient_Type__c = 'Same' limit 1];
        List<product2> productList = [select Id, Name from Product2];
        
        Id pricebookId = Test.getStandardPricebookId();	    
		List<PricebookEntry> pentrylist = new List<PricebookEntry>();
        
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productlist[1].Id,UnitPrice = 0.01, IsActive = true);															
		pentrylist.add(standardPrice1);
        
        PricebookEntry standardPrice3 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productlist[3].Id,UnitPrice = 0.01, IsActive = true);															
		pentrylist.add(standardPrice3);
        
		insert pentrylist;
          
        OrderItem oItemWithOneTheme = new OrderItem();
        oItemWithOneTheme.OrderId= orderWithSameMRType.Id ;
		oItemWithOneTheme.PricebookEntryId= standardPrice1.Id ;
		oItemWithOneTheme.Quantity = 1 ;
		oItemWithOneTheme.UnitPrice = 0.01 ; 
		oItemWithOneTheme.Product2id  = productList[1].Id;
        oItemWithOneTheme.Material_Recipient__c  = 'Account Manager';
        insert oItemWithOneTheme;
        
        OrderItem oItemWithMoreTheme = new OrderItem();
        oItemWithMoreTheme.OrderId= orderWithSameMRType.Id ;
		oItemWithMoreTheme.PricebookEntryId= standardPrice3.Id;
		oItemWithMoreTheme.Quantity = 1 ;
		oItemWithMoreTheme.UnitPrice = 0.01 ; 
		oItemWithMoreTheme.Product2id  = productList[3].Id;
        oItemWithMoreTheme.Material_Recipient__c  = 'Account Manager';
                       
        try{
            insert oItemWithMoreTheme;
        }Catch(Exception ex)
        {
            system.assert(ex.getMessage().contains('A theme product already exists'));
        }
        
        List<OrderItem> createdItem = [select id from OrderItem];
        delete createdItem;
        
        List<OrderItem> moreThanOneThemeList = new List<OrderItem>();
        OrderItem oItemWithOneThemeV2; 
        oItemWithOneThemeV2 = new OrderItem();
        oItemWithOneThemeV2.OrderId= orderWithSameMRType.Id ;
		oItemWithOneThemeV2.PricebookEntryId= standardPrice1.Id ;
		oItemWithOneThemeV2.Quantity = 1 ;
		oItemWithOneThemeV2.UnitPrice = 0.01 ; 
		oItemWithOneThemeV2.Product2id  = productList[1].Id;
        oItemWithOneThemeV2.Material_Recipient__c  = 'Account Manager';
        moreThanOneThemeList.add(oItemWithOneThemeV2);
        
        oItemWithOneThemeV2 = new OrderItem();
        oItemWithOneThemeV2.OrderId= orderWithSameMRType.Id ;
		oItemWithOneThemeV2.PricebookEntryId= standardPrice3.Id;
		oItemWithOneThemeV2.Quantity = 1 ;
		oItemWithOneThemeV2.UnitPrice = 0.01 ; 
		oItemWithOneThemeV2.Product2id  = productList[3].Id;
        oItemWithOneThemeV2.Material_Recipient__c  = 'Account Manager';
        moreThanOneThemeList.add(oItemWithOneThemeV2);
        
        try{
            insert moreThanOneThemeList;
        }catch(exception ex)
        {
            
            system.assert(ex.getMessage().contains('Please select only one theme per order'));
        }
        
        Test.stopTest();
        
    }
    static testMethod void calculateBudgetforProductsProjected_Test()
    {
        Test.startTest();
        
        Order orderObj = [select Id, Name from Order where Material_Recipient_Type__c = 'Same' limit 1];
        PricebookEntry standardPrice = [select Id from PricebookEntry limit 1];
        List<product2> productList = [select Id, Name from Product2];
        
        OrderItem oItemWithExdBudget = new OrderItem();
        oItemWithExdBudget.OrderId= orderObj.Id ;
		oItemWithExdBudget.PricebookEntryId= standardPrice.Id ;
		oItemWithExdBudget.Quantity = 10 ;
		oItemWithExdBudget.UnitPrice = 0.19 ; 
		oItemWithExdBudget.Product2id  = productList[0].Id;
        oItemWithExdBudget.Material_Recipient__c  = 'Account Manager';
               	
        try{
            insert oItemWithExdBudget;
        }Catch(Exception ex)
        {
            system.assert(ex.getMessage().contains('Total Budget is exceeding'));
        }
        Test.stopTest();
        
    }
    static testMethod void validateProductMaterialRecipientBeforeUpdate_Test()
    {
        Test.startTest();
        
        Order orderObjWithNullMR = [select Id, Name from Order where Material_Recipient_Type__c = null limit 1];
        PricebookEntry standardPrice = [select Id from PricebookEntry limit 1];
        List<product2> productList = [select Id, Name from Product2];
        
        OrderItem oItemWithWithNullMR = new OrderItem();
        oItemWithWithNullMR.OrderId= orderObjWithNullMR.Id ;
		oItemWithWithNullMR.PricebookEntryId= standardPrice.Id ;
		oItemWithWithNullMR.Quantity = 1 ;
		oItemWithWithNullMR.UnitPrice = 0.01 ; 
		oItemWithWithNullMR.Product2id  = productList[0].Id;
               	
        insert oItemWithWithNullMR;
        List<OrderItem> createdOItem = [select Id,Material_Recipient__c from OrderItem limit 1];
        createdOItem[0].Material_Recipient__c = 'Account Manager';
        
        try{
            update createdOItem[0];
        }catch(Exception ex)
        {
            system.assert(ex.getMessage().contains('Please deselect Material Recipient'));
        }
        Test.stopTest();
        
    }
	//Method to get the map of recordType Name as key and recordTypeId as value 
    public static Map<String,Id> recordTypeMap(string obj)
    {
        Map<String,Id> recTypeNameWithIdMap = new Map<String,Id>();
        if(obj!= null)
        {
            for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByName().values())
            {
                recTypeNameWithIdMap.put(recInfo.getName(),recInfo.getRecordTypeId());
            }
        }
        return recTypeNameWithIdMap;
    }
	
}