//AS-013042-Address standardization
public with sharing class AddressUtility {
    
    public static Map<String,String> LeadAddressFieldsMap = new Map<String,String>();
	public static Map<String, Map<Id,String>> accountDeliveryconfirmation = new Map<String, Map<Id,String>>();
    public static Map<Id,String> contactIdAccountIdMap = new Map<Id,String>();
    public static Map<String,String> ContactMailingAddressFieldsMap = new Map<String,String>();
	public static Map<String,String> ContactSecondaryAddressFieldsMap = new Map<String,String>();
    public static Map<String,String> AccountBillingAddressFieldsMap = new Map<String,String>();
    public static Map<String,String> AccountShippingFieldsMap = new Map<String,String>();
    public static final String STREET = 'STREET';
    public static final String CITY = 'CITY';
    public static final String ZIP = 'ZIP';
    public static final String STATE_CODE = 'STATE_CODE';

    


    static{
        LeadAddressFieldsMap.put(STREET,'Street');        LeadAddressFieldsMap.put(CITY,'City');
        LeadAddressFieldsMap.put(ZIP,'PostalCode');        LeadAddressFieldsMap.put(STATE_CODE,'StateCode');
        
        ContactMailingAddressFieldsMap.put(STREET,'MailingStreet');        ContactMailingAddressFieldsMap.put(CITY,'MailingCity');
        ContactMailingAddressFieldsMap.put(ZIP,'MailingPostalCode');        ContactMailingAddressFieldsMap.put(STATE_CODE,'MailingStateCode');
        
        ContactSecondaryAddressFieldsMap.put(STREET,'OtherStreet');        ContactSecondaryAddressFieldsMap.put(CITY,'OtherCity');
        ContactSecondaryAddressFieldsMap.put(ZIP,'OtherPostalCode');        ContactSecondaryAddressFieldsMap.put(STATE_CODE,'OtherStateCode');
      
        AccountBillingAddressFieldsMap.put(STREET,'BillingStreet');        AccountBillingAddressFieldsMap.put(CITY,'BillingCity');
        AccountBillingAddressFieldsMap.put(ZIP,'BillingPostalCode');        AccountBillingAddressFieldsMap.put(STATE_CODE,'BillingStateCode');
        
        AccountShippingFieldsMap.put(STREET,'ShippingStreet');        AccountShippingFieldsMap.put(CITY,'ShippingCity');
        AccountShippingFieldsMap.put(ZIP,'ShippingPostalCode');        AccountShippingFieldsMap.put(STATE_CODE,'ShippingStateCode');
    }

	@future(callout =true)
    /**
     * Validates Account object address in case if it is not empty and changed from last time/first time insert
     * */
    public static void cleanAccountBillingAddress(List<Id> accountIdList){
		accountDeliveryconfirmation = new Map<String, Map<Id,String>>();
		
       List<Account> accountList =  [select id,BillingStreet,BillingCity,BillingStateCode,BillingPostalCode,Account_Manager__c from Account where id in :accountIdList];
       //System.debug('accountList size fetched from DB:'+accountList.size()); 
       List<Account> updateList = new List<Account>();
       for(Account account:accountList){
          //System.debug('account fetched from DB:'+account); 
          InputAddress inputAddress = convertFromSFAddress(account,AccountBillingAddressFieldsMap); 
          system.debug('inputAddress##'+inputAddress);
		  InformaticaStandardAddress stdAddress = cleanAddress(inputAddress);
           system.debug('stdAddress ###'+stdAddress);
          populateAddress(account, stdAddress,AccountBillingAddressFieldsMap);
          String billingStreet = account.BillingStreet;
          String streetLineSeperator ='';
          if(String.isBlank(billingStreet)){
            updateList.add(new Account(Id=account.Id));  
          	continue;
          }
          if(billingStreet.contains(',')) //contains comma if address is standardized by USPS otherwise will be new line character,
			  streetLineSeperator = ',';
          else if(billingStreet.contains('\r\n'))
              streetLineSeperator = '\r\n';
          if(String.isBlank(streetLineSeperator)){
              account.BillingStreet_1__c = billingStreet;
          }else{
              account.BillingStreet_1__c = billingStreet.substringBefore(streetLineSeperator);
              account.BillingStreet_2__c = billingStreet.substringAfter(streetLineSeperator);
          }

          updateList.add(account);   
       } 
        system.debug('accountList in informitica' +accountList);
        update updateList;
	   	system.debug('accountList in informitica2' +accountList);
		if( accountDeliveryconfirmation.keySet().size() > 0 ){
			System.debug( 'accountDeliveryconfirmation_is==>' + accountDeliveryconfirmation  );
            AccountService.addressUpdationunsucessnotifyByTask(accountDeliveryconfirmation, contactIdAccountIdMap);
		}
    }
    
    /**
     * Validates Contact object address in case if it is not empty and changed from last time/first time insert
     * */
    	@future(callout =true)
    public static void cleanAccountShippingAddress(List<Id> accountIdList){
		accountDeliveryconfirmation = new Map<String, Map<Id,String>>();
		
       List<Account> accountList =  [select id,ShippingStreet,ShippingCity,ShippingStateCode,ShippingPostalCode,Account_Manager__c from Account where id in :accountIdList];
       System.debug('accountList size fetched from DB:'+accountList.size()); 
       for(Account account:accountList){
          System.debug('account fetched from DB:'+account); 
          InputAddress inputAddress = convertFromSFAddress(account,AccountShippingFieldsMap); 
		  InformaticaStandardAddress stdAddress = cleanAddress(inputAddress);
          populateAddress(account, stdAddress,AccountShippingFieldsMap);
          String shippingStreet = account.ShippingStreet;
          String streetLineSeperator ='';
          if(String.isBlank(shippingStreet))
               return;
          if(shippingStreet.contains(',')) //contains comma if address is standardized by USPS otherwise will be new line character,
			  streetLineSeperator = ',';
          else if(shippingStreet.contains('\r\n'))
              streetLineSeperator = '\r\n';
          if(String.isBlank(streetLineSeperator)){
              account.ShippingStreet_1__c = shippingStreet;
          }else{
              account.ShippingStreet_1__c = shippingStreet.substringBefore(streetLineSeperator);
              account.ShippingStreet_2__c = shippingStreet.substringAfter(streetLineSeperator);
          } 
       } 
       update accountList;
		if( accountDeliveryconfirmation.keySet().size() > 0 ){
			System.debug( 'accountDeliveryconfirmation_is==>' + accountDeliveryconfirmation  );
            AccountService.addressUpdationunsucessnotifyByTask(accountDeliveryconfirmation, contactIdAccountIdMap);
		}
        
    }
    
    
     @future(callout =true)
    /**
     * Validates Contact object address in case if it is not empty and changed from last time/first time insert
     * */
    public static void cleanContactSecondaryAddress(List<Id> contactIdList){
		accountDeliveryconfirmation = new Map<String, Map<Id,String>>();
       List<Contact> contactList =  [select id,OtherStreet,OtherCity,OtherStateCode,OtherPostalCode,Account.Account_Manager__c,AccountId from Contact where id in :contactIdList];
       System.debug('contactList size fetched from DB:'+contactList.size()); 
       for(Contact contact:contactList){
          System.debug('contact fetched from DB:'+contact); 
          InputAddress inputAddress = convertFromSFAddress(contact,ContactSecondaryAddressFieldsMap); 
		  InformaticaStandardAddress stdAddress = cleanAddress(inputAddress);
          populateAddress(contact, stdAddress,ContactSecondaryAddressFieldsMap);
          String otherStreet = contact.OtherStreet;
          String streetLineSeperator ='';
          if(String.isBlank(otherStreet))
               return;
          if(otherStreet.contains(',')) //contains comma if address is standardized by USPS otherwise will be new line character,
			  streetLineSeperator = ',';
          else if(otherStreet.contains('\r\n'))
              streetLineSeperator = '\r\n';
          if(String.isBlank(streetLineSeperator)){
              contact.OtherStreet_1__c = otherStreet;
          }else{
              contact.OtherStreet_1__c = otherStreet.substringBefore(streetLineSeperator);
              contact.OtherStreet_2__c = otherStreet.substringAfter(streetLineSeperator);
          }
       }
       //if (Schema.sObjectType.Contact.fields.OtherStreet_1__c.isUpdateable()) {}
        update contactList;
    
		if( accountDeliveryconfirmation.keySet().size() > 0 ){
			System.debug( 'accountDeliveryconfirmation_is==>' + accountDeliveryconfirmation  );
            AccountService.addressUpdationunsucessnotifyByTask(accountDeliveryconfirmation, contactIdAccountIdMap);
		}
        
    }
    
	@future(callout =true)
    /**
     * Validates Contact object address in case if it is not empty and changed from last time/first time insert
     * */
    public static void cleanContactMailingAddress(List<Id> contactIdList){
		accountDeliveryconfirmation = new Map<String, Map<Id,String>>();
		
       List<Contact> contactList =  [select id,MailingStreet,MailingCity,MailingStateCode,MailingPostalCode, Account.Account_Manager__c, AccountId  from Contact where id in :contactIdList];
       System.debug('contactList size fetched from DB:'+contactList.size()); 
       for(Contact contact:contactList){
          System.debug('contact fetched from DB:'+contact); 
          InputAddress inputAddress = convertFromSFAddress(contact,ContactMailingAddressFieldsMap); 
		  InformaticaStandardAddress stdAddress = cleanAddress(inputAddress);
          populateAddress(contact, stdAddress,ContactMailingAddressFieldsMap);
          String mailingStreet = contact.MailingStreet;
          String streetLineSeperator ='';
          if(String.isBlank(mailingStreet))
               return;
          if(mailingStreet.contains(',')) //contains comma if address is standardized by USPS otherwise will be new line character,
			  streetLineSeperator = ',';
          else if(mailingStreet.contains('\r\n'))
              streetLineSeperator = '\r\n';
          if(String.isBlank(streetLineSeperator)){
              contact.MailingStreet_1__c = mailingStreet;
          }else{
              contact.MailingStreet_1__c = mailingStreet.substringBefore(streetLineSeperator);
              contact.MailingStreet_2__c = mailingStreet.substringAfter(streetLineSeperator);
          }
       } 
       update contactList;
		if( accountDeliveryconfirmation.keySet().size() > 0 ){
			System.debug( 'accountDeliveryconfirmation_is==>' + accountDeliveryconfirmation  );
            AccountService.addressUpdationunsucessnotifyByTask(accountDeliveryconfirmation, contactIdAccountIdMap);
		}
        
    }    
    
    
    @future(callout =true)
    /**
     * Validates Lead object address in case if it is not empty and changed from last time/first time insert
     * */
    public static void cleanLeadAddress(List<Id> leadIdList){
       List<Lead> leadList =  [select id,Street,City,StateCode,PostalCode from Lead where id in :leadIdList];
       System.debug('leadList size fetched from DB:'+leadList.size()); 
       for(Lead lead:leadList){
          System.debug('lead fetched from DB:'+lead); 
          InputAddress inputAddress = convertFromSFAddress(lead,LeadAddressFieldsMap); 
		  InformaticaStandardAddress stdAddress = cleanAddress(inputAddress);
          populateAddress(lead, stdAddress,LeadAddressFieldsMap);
       } 
       //if (Schema.sObjectType.Lead.isUpdateable()) {}
        update leadList;
    
        
    }
    
    
    public static InputAddress convertFromSFAddress(SObject sObj,Map<String,String> addressFieldsMap){
        if(sObj == null || isEmptyAddress(sObj,addressFieldsMap))
            return null;
        InputAddress inputAddress = new InputAddress();
        inputAddress.addressLine1 = (String)sObj.get(addressFieldsMap.get(STREET));
        inputAddress.city = (String)sObj.get(addressFieldsMap.get(CITY));
        inputAddress.state = (String)sObj.get(addressFieldsMap.get(STATE_CODE));
        inputAddress.zip5 = (String)sObj.get(addressFieldsMap.get(ZIP));
		return InputAddress;        
        
    }
    
    public static Boolean isEmptyAddress(SObject sObj,Map<String,String> addressFieldsMap){
         if(sObj == null)
            return true;
        System.debug('Incoming object street,city:'+ (String)sObj.get(addressFieldsMap.get(STREET))+','+(String)sObj.get(addressFieldsMap.get(CITY)));
        System.debug('Incoming object state,postalCode:'+(String)sObj.get(addressFieldsMap.get(STATE_CODE))+','+(String)sObj.get(addressFieldsMap.get(ZIP)));
		if(String.isNotEmpty((String)sObj.get(addressFieldsMap.get(STREET)))
            || String.isNotEmpty((String)sObj.get(addressFieldsMap.get(CITY)))
            ||String.isNotEmpty((String)sObj.get(addressFieldsMap.get(STATE_CODE)))
            ||String.isNotEmpty((String)sObj.get(addressFieldsMap.get(ZIP)))
          ){
            return false;
          }
        return true;
        
    }
    
    
  
    
    public static void populateAddress(sObject sObj, InformaticaStandardAddress stdAddr,Map<String,String> addressFieldsMap){
        System.debug('Entered populateAddress method');
        if(stdAddr == null || stdAddr.DeliveryPointConfirmation!= 'Y'){
            Boolean isAccount = sObj instanceof Account;
            Boolean isContact = sObj instanceof Contact;
            system.debug( 'Account instance=>' + isAccount + ' Contact instance=>' +  isContact );
			if( isAccount ){	
                accountDeliveryconfirmation.put( 'Account', new Map<Id, String>());
                accountDeliveryconfirmation.get('Account').put( String.valueOf(sObj.get( 'Id' )), userInfo.getUserId() );
				
            }else if( isContact ){
                Contact cont = (Contact) sobj; 
                accountDeliveryconfirmation.put( 'Contact', new Map<Id, String>());
                accountDeliveryconfirmation.get('Contact').put( cont.Id, userInfo.getUserId());
                contactIdAccountIdMap.put(cont.Id, cont.AccountId );
                             
            }
            return;
		}
         sObj.put(addressFieldsMap.get(STREET),stdAddr.Line1 + (String.isEmpty(stdAddr.Line2)?'':','+stdAddr.Line2));
         sObj.put(addressFieldsMap.get(CITY),stdAddr.City);
         sObj.put(addressFieldsMap.get(STATE_CODE), stdAddr.State);
         sObj.put(addressFieldsMap.get(ZIP),stdAddr.Zip);
        
    }
    
    
    public static InformaticaStandardAddress cleanAddress(InputAddress inputAddress){
        System.debug('Entered method cleanAddress with inputAddress:'+inputAddress);
        if(inputAddress == null)
            return null;
        InformaticaStandardAddress standardAddr = InformaticaAddressStandardization.getStandardAddress(inputAddress);
        System.debug('USPS cleanAddress response:'+standardAddr);
        return standardAddr;
    }
    
    public static boolean isAddresssChanged(sObject oldSObj, sObject newSObj,Map<String,String> addressFieldsMap){
        System.debug('Entered method isAddresssChanged with sobjects old,new :'+oldSObj+','+newSObj);
        if(newSObj ==null || isEmptyAddress(newSObj,addressFieldsMap))
            return false;
        if(oldSObj == null && newSObj!=null)
            return true;//address coming in for first time 
		
        System.debug('two2##'+((String)oldSObj.get(addressFieldsMap.get(STREET)) != (String)newSObj.get(addressFieldsMap.get(STREET))));
        if((oldSObj.get(addressFieldsMap.get(STREET)) == null || !String.valueOf(oldSObj.get(addressFieldsMap.get(STREET))).equals(String.valueOf(newSObj.get(addressFieldsMap.get(STREET)))))
           || (String)oldSObj.get(addressFieldsMap.get(CITY))!=(String)newSObj.get(addressFieldsMap.get(CITY))
           || (String)oldSObj.get(addressFieldsMap.get(STATE_CODE))!=(String)newSObj.get(addressFieldsMap.get(STATE_CODE))
           || (String)oldSObj.get(addressFieldsMap.get(ZIP))!=(String)newSObj.get(addressFieldsMap.get(ZIP))
          ){
            return true; 
          }        
        return false;
    }

    public static boolean isZipcodeChanged(sObject oldSObj, sObject newSObj,Map<String,String> addressFieldsMap){
        System.debug('Entered method isAddresssChanged with sobjects old,new :'+oldSObj+','+newSObj);
        if(newSObj ==null || isEmptyAddress(newSObj,addressFieldsMap))
            return false;
        if(oldSObj == null && newSObj!=null)
            return true;//address coming in for first time

        if((String)oldSObj.get(addressFieldsMap.get(ZIP))!=(String)newSObj.get(addressFieldsMap.get(ZIP))
          ){
            return true; 
          }        
        return false;
    }
    
    @InvocableMethod
    public static void splitUserStreet(List<User> userList){
         List<User> toUpdateList = new List<User>();

        for(User userObj:userList){
            
          User tempUser = userObj.clone(true,true,true,true);
          String userStreet = userObj.Street;
          String streetLineSeperator ='';
          if(String.isBlank(userStreet))
               return;
            
           if(userStreet.contains('\r\n')){
              System.debug('Street contains new line character'); 
               tempUser.PrimaryStreet_1__c =userStreet.substringBefore('\r\n');
               tempUser.PrimaryStreet_2__c = userStreet.substringAfter('\r\n');

           }
          else{
              System.debug('Street Not contains new line character'); 
              tempUser.PrimaryStreet_1__c = userStreet;
              tempUser.PrimaryStreet_2__c = '';
          }
           toUpdateList.add(tempUser); 
       }
       
    //if (Schema.sObjectType.User.fields.PrimaryStreet_1__c.isUpdateable()) {}
    update  toUpdateList;
     
    }
    
    
    
    

}