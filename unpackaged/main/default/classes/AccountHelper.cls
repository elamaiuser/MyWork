public with sharing class AccountHelper {
    public static Boolean firstRun = true;
    
    /**
* AS-012769-SYSTEM: Mapping Converted Lead Fields to the Account
* *//*
    public static void updateAccountType(List<Account> oldAccounts, List<Account> newAccounts,
                                         Map<Id,Account> oldAccountsMap,Map<Id,Account> newAccountsMap){
                                             
                                             System.debug('Entered method updateAccountType');
                                             
                                             for(Account newAccount:newAccounts){
                                                 System.debug('Processing newAccount with account_type_from_lead__c and Id values as ->'+newAccount.account_type_from_lead__c+','+newAccount.id);
                                                 if(String.isBlank(newAccount.account_type_from_lead__c) ==true)
                                                     continue;
                                                 if(newAccount.id == null){//coming in for first time
                                                     newAccount.type=newAccount.account_type_from_lead__c;
                                                     continue;               
                                                 }
                                                 if(newAccount.id != null && oldAccountsMap!=null 
                                                    && oldAccountsMap.get(newAccount.id)!=null){ //update scenario
                                                        System.debug('Processing oldAccount with account_type_from_lead__c and Id values as ->'+oldAccountsMap.get(newAccount.id).account_type_from_lead__c+','+newAccount.id);
                                                        
                                                        if(newAccount.account_type_from_lead__c != oldAccountsMap.get(newAccount.id).account_type_from_lead__c){
                                                            newAccount.type=newAccount.account_type_from_lead__c;
                                                        }
                                                        if(String.isBlank(newAccount.Type) ==true){
                                                            newAccount.type=newAccount.account_type_from_lead__c;
                                                        }   
                                                    }
                                             }//end of for loop 
                                             
                                         }*/
    
    //Create Notes on Account Starategy Change
    /*public static void createNotesOnAccountStrategyupdate(List<Account> oldAccounts, List<Account> newAccounts,
                                                          Map<Id,Account> oldAccountsMap,Map<Id,Account> newAccountsMap)
    {
        List<ContentVersion> NotesList = new List<ContentVersion>();
        for (Account newAccount:newAccounts)  {
            //|| (newAccount.Account_Strategy__c != oldAccountsMap.get(newAccount.Id).Account_Strategy_Notes__c)
            if(newAccount.Account_Strategy_Notes__c != null && ((newAccount.Account_Strategy_Notes__c != oldAccountsMap.get(newAccount.Id).Account_Strategy_Notes__c) 
                                                               )){
                                                                   ContentVersion objCntNote = new ContentVersion();
                                                                   objCntNote.Title = newAccount.Account_Strategy__c;
                                                                   objCntNote.PathOnClient = objCntNote.Title + '.snote';
                                                                   objCntNote.VersionData = Blob.valueOf(newAccount.Account_Strategy_Notes__c);
                                                                   objCntNote.FirstPublishLocationId = newAccount.id;  // ParentId
                                                                   NotesList.add(objCntNote);
                                                                   //insert objCntNote;
                                                               }
        }
        if(NotesList.size()>0) insert NotesList;                
    }*/
    
    /*
* JIRA Ticket: HRP - 1678, 
* Description: Populate Market field on Account based on Billing Zip code - Market Mapping
*/  /*
    public static void populateMarketOnAccount( List<Account> oldAccounts, List<Account> newAccounts,
                                               Map<Id,Account> oldAccountsMap,Map<Id,Account> newAccountsMap){
                                                   
                                                   List<Account> beforeInsertAccList = new List<Account>();
                                                   List<Account> beforeUpdateAccList = new List<Account>();
                                                   
                                                   Set<Decimal> zipcodeset = new Set<Decimal>();
                                                   
                                                   for(Account newAccount:newAccounts){
                                                       if( newAccount.Id == null ){ // before insert scenario
                                                           beforeInsertAccList.add( newAccount );
                                                       }else if( newAccount.Id != null ){ // before update scenario
                                                           beforeUpdateAccList.add( newAccount );
                                                       }
                                                   }
                                                   
                                                   if( !beforeInsertAccList.isEmpty() ){
                                                       
                                                       for( Account newAccount:beforeInsertAccList  ){
                                                           
                                                           if( newAccount.BillingPostalCode != null){
                                                               zipcodeset.add( Integer.valueOf( newAccount.BillingPostalCode ) );
                                                           }
                                                       }
                                                   }else if( !beforeUpdateAccList.isEmpty() ){
                                                       for( Account newAccount:beforeUpdateAccList  ){
                                                           if( newAccount.BillingPostalCode != null){
                                                               zipcodeset.add( Decimal.valueOf( newAccount.BillingPostalCode ) );
                                                           }
                                                           
                                                       }
                                                   }
                                                   
                                                   if( !zipcodeset.isEmpty() ){
                                                       Set<String> zipCodeStringSet = new Set<String>();
                                                       for(Decimal zip:zipCodeSet){
                                                        zipCodeStringSet.add(String.valueOf(zip));
                                                       }
                                                       Map<String, String> zipcodeAndMarketMap = new Map<String, String>();
                                                       
                                                       List< ARC_Market_Mapping__c > ARCMarketingMappObject = [ 	SELECT ID,
                                                                                                               Zip_Code__c,
                                                                                                               Market__c
                                                                                                               FROM ARC_Market_Mapping__c
                                                                                                               WHERE Zip_Code__c IN:zipCodeStringSet ];
                                                       
                                                       if( !ARCMarketingMappObject.isEmpty() ){
                                                           for( ARC_Market_Mapping__c marketvar : ARCMarketingMappObject ){
                                                               zipcodeAndMarketMap.put( marketvar.Zip_Code__c, marketvar.Market__c );
                                                           }
                                                       }
                                                       
                                                       for( Account newAccount: newAccounts ){
                                                           if(newAccount.BillingPostalCode  !=  null){
                                                               newAccount.Market__c = zipcodeAndMarketMap.get(newAccount.BillingPostalCode) ;
                                                           }
                                                           
                                                       }
                                                       
                                                   }
                                                   for(Account newAccount: newAccounts){
                                                       System.debug('==MARKET=='+newAccount.Market__c);
                                                   }
                                               }
    */
    //AS-013046-Account Billing Address standardization, will be called from before insert and before update
    /*
    public static void standardizeBillingAddress(List<Account> newAccounts, Map<Id, Account> oldMap,
                                                 Map<Id, Account> newMap, String op)
    {
        
        System.debug('Entered method standardizeBillingAddress with oldMap and newMap' + oldMap + ' : ' + newMap);
        if (System.isFuture())
        {//extremely important,only run for first time otherwise will get exception future cannot be called from future
            return;
        }
        //collects all leads which need to be evaluated for clean address                               
        List<Id> evaluateAddressAccountList = new List<Id>(); 
        for (Account newAccount:newAccounts)
        {
            
            boolean isEmptyAddress = AddressUtility.isEmptyAddress(newAccount, AddressUtility.AccountBillingAddressFieldsMap);
            if (isEmptyAddress == null)
            {
                System.debug('Address is null for incoming Account');
                continue;
            }
            InformaticaStandardAddress stdAddr = null;
            if (op.equals('INSERT'))
            {
                System.debug('Coming in for first time insert without empty address for lead object:' + newAccount);
                evaluateAddressAccountList.add(newAccount.id);//this is called from after insert, so id will be there always
            }
            else if (op.equals('UPDATE'))
            {
                System.debug('Coming in as update');
                Account oldAccount = oldMap.get(newAccount.id);
                boolean isAddressChanged = AddressUtility.isAddresssChanged(oldAccount, newAccount, AddressUtility.AccountBillingAddressFieldsMap);
                System.debug('isAddressChanged:' + isAddressChanged);
                if (isAddressChanged == true)
                {
                    evaluateAddressAccountList.add(newAccount.id);//this is called from after insert/after update, so id will be there always
                }
            }
            //Call Informatica API and clean addresses
            AddressUtility.cleanAccountBillingAddress(evaluateAddressAccountList);
        }
    }*/
    
    //AS-013046-Account Shipping Address standardization, will be called from before insert and before update
    /*
    public static void standardizeShippingAddress(List<Account> newAccounts, Map<Id, Account> oldMap,
                                                  Map<Id, Account> newMap, String op)
    {
        
        System.debug('Entered method standardizeShippingAddress with oldMap and newMap' + oldMap + ' : ' + newMap);
        if (System.isFuture())
        {//extremely important,only run for first time otherwise will get exception future cannot be called from future
            return;
        }
        //collects all leads which need to be evaluated for clean address                               
        List<Id> evaluateAddressAccountList = new List<Id>(); 
        for (Account newAccount:newAccounts)
        {
            
            boolean isEmptyAddress = AddressUtility.isEmptyAddress(newAccount, AddressUtility.AccountShippingFieldsMap);
            if (isEmptyAddress == null)
            {
                System.debug('Address is null for incoming Account');
                continue;
            }
            InformaticaStandardAddress stdAddr = null;
            if (op.equals('INSERT'))
            {
                System.debug('Coming in for first time insert without empty address for lead object:' + newAccount);
                evaluateAddressAccountList.add(newAccount.id);//this is called from after insert, so id will be there always
            }
            else if (op.equals('UPDATE'))
            {
                System.debug('Coming in as update');
                Account oldAccount = oldMap.get(newAccount.id);
                boolean isAddressChanged = AddressUtility.isAddresssChanged(oldAccount, newAccount, AddressUtility.AccountShippingFieldsMap);
                System.debug('isAddressChanged:' + isAddressChanged);
                if (isAddressChanged == true)
                {
                    evaluateAddressAccountList.add(newAccount.id);//this is called from after insert/after update, so id will be there always
                }
            }
            //Call Informatica API and clean addresses
            AddressUtility.cleanAccountShippingAddress(evaluateAddressAccountList);
        }
    }*/
    
    
}