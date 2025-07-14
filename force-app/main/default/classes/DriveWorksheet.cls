public with sharing class DriveWorksheet {
    public static string accId {get;set;}
      @AuraEnabled(Cacheable = true)
      public static List<sked_Drive__c> getDriveList(string drID){
          List<sked_Drive__c> lst = new List<sked_Drive__c>() ;
          lst =  [SELECT id,name,sked_Drive_Site__r.name,sked_Start_Time__c, sked_End_Time__c, sked_Drive_Date__c, 
                   sked_Vehicle_Types__c,sked_Purple_Top_Drive__c,
                   sked_Account__c, sked_Account__r.name ,sked_Linked_Drive_Id__c,sked_Day_of_Week__c ,
                   sked_Account__r.Phone,  sked_Account__r.TYpe,sked_Account__r.Last_Closed_Drive_New__c, 
                   sked_Account__r.Account_Manager_Phone__c,sked_Account__r.Account_Manager__r.Name,
                   sked_Drive_Site__r.sked_Wireless_Policy__c,sked_Drive_Site__r.sked_Max_Auto_Machines__c, sked_Drive_Site__r.sked_Directions_From_CollectionOperation__c,
                   sked_Opportunity__r.Open_to_Public__c, sked_Opportunity__r.Drive_Status__c,
                   sked_Opportunity__r.WholeBloodProjectedUnits__c, sked_Opportunity__r.WB_Projected_Procedures__c, 
                   sked_Opportunity__r.X2RBC_Projected_Procedures__c, sked_Opportunity__r.Double_Red_Projected_Units__c,
                   sked_Opportunity__r.Apheresis_Projected_Units__c, sked_Opportunity__r.Platelet_Projected_Procedures__c, 
                   sked_Opportunity__r.Total_Projected_Procedures__c, sked_Opportunity__r.Total_Products_Projected__c,
                   sked_Collection_Operation__r.id
                   FROM sked_Drive__c where id =: drID ]; 
                     accId = lst[0].sked_Account__c;
                  return lst;
                         
      }
  
      @AuraEnabled(cacheable=true)
      public static List<Account> getAccountList() {
          return [SELECT Id, Name,fax,phone, 
                    Account_Manager__r.Name, Account_Manager__r.Phone
                    FROM Account where Id=:accId];
      }
      
  }