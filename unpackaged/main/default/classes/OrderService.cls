public with sharing class OrderService {
    
    /*
* JIRA Ticket: HRP - 735, 
* Description: 2.0 DRD AM: Selecting Publicity Order Item
*/
    public static void validateMaterialrecipent( List<Order> oldOrders, List<Order> newOrders,
                                                Map<Id,Order> oldOrdersMap,Map<Id,Order> newOrdersMap){
                                                    
                                                    
                                                    String materialrecipientisnull = 'Please select Material Recipient';
                                                    String morematerialrecipient = 'Please select only one value from Material Recipient';
                                                    String singlematerialrecipients = 'Please select more than one value from Material Recipient';
                                                    
                                                    Map<Id, Order> ordersWithRecipientType = new Map<Id, Order>();
                                                    for( Order od : newOrders ){
                                                        if( od.Material_Recipient_Type__c != null ){
                                                            if( !ordersWithRecipientType.containsKey( od.Id ) ){
                                                                ordersWithRecipientType.put( od.Id, od );
                                                            }
                                                        }
                                                    }
                                                    
                                                    for( Id orderid : ordersWithRecipientType.keySet() ){
                                                        if( ordersWithRecipientType.get( orderid ).Material_Recipient_Type__c == 'Same' ){
                                                            if( ordersWithRecipientType.get( orderid ).Material_Recipient__c == null ){
                                                                ordersWithRecipientType.get( orderid ).addError(materialrecipientisnull);
                                                            }else if( ordersWithRecipientType.get( orderid ).Material_Recipient__c !=null ){
                                                                String selectedval = ordersWithRecipientType.get( orderid ).Material_Recipient__c;
                                                                if( selectedval.contains(';') ){
                                                                    ordersWithRecipientType.get( orderid ).addError(morematerialrecipient);
                                                                }
                                                            }
                                                            
                                                        }else if( ordersWithRecipientType.get( orderid ).Material_Recipient_Type__c == 'Split' ){
                                                            if( ordersWithRecipientType.get( orderid ).Material_Recipient__c == null ){
                                                                ordersWithRecipientType.get( orderid ).addError(materialrecipientisnull);
                                                            }else if( ordersWithRecipientType.get( orderid ).Material_Recipient__c !=null ){
                                                                String selectedval = ordersWithRecipientType.get( orderid ).Material_Recipient__c;
                                                                if( !selectedval.contains(';') ){
                                                                    ordersWithRecipientType.get( orderid ).addError(singlematerialrecipients);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
    
    /*
* JIRA Ticket: HRP - 735, 
* Description: 2.0 DRD AM: Selecting Publicity Order Item
*/
    public static void setDefaultMaterialRecipient( List<Order> oldOrders, List<Order> newOrders,
                                                   Map<Id,Order> oldOrdersMap,Map<Id,Order> newOrdersMap){
                                                       
                                                       
                                                       for( Order od : newOrders ){
                                                           if( od.Material_Recipient__c != null ){
                                                               String selectedval = od.Material_Recipient__c;
                                                               if( selectedval.contains(';') ){
                                                                   String [] picklistvalues = selectedval.split(';');
                                                                   od.Material_Recipient_Default__c = picklistvalues[0];
                                                               }else{               
                                                                   od.Material_Recipient_Default__c = selectedval;
                                                               }            
                                                               
                                                           }
                                                       }                                                    
                                                       
                                                   }
    
    /*
* JIRA Ticket: HRP - 1776, 
* Description: Documenting Publicity Order Submitted to Vendor
*/
    public static void setPublicitySubmiter( List<Order> oldOrders, List<Order> newOrders,
                                            Map<Id,Order> oldOrdersMap,Map<Id,Order> newOrdersMap){
                                                
                                                
                                                for( Order od : newOrders ){
                                                    if( oldOrdersMap.get(od.Id).Publicity_Submitted__c != newOrdersMap.get(od.Id).Publicity_Submitted__c  ){
                                                        od.Publicity_Submitted_Date__c = System.today();
                                                        od.Publicity_Submitted_By__c = userInfo.getUserId();
                                                    }
                                                }                                                   
                                                
                                            }   
    /*
* JIRA Ticket: HRP - 1613, 
* Description: 1.1 User: Managing Publicity Order Budgets
*/
    public static void setOrderBudget( List<Order> oldOrders, List<Order> newOrders,
                                      Map<Id,Order> oldOrdersMap,Map<Id,Order> newOrdersMap){
                                          
                                          Set<Id> accountids    = new Set<Id>();                                                    
                                          Set<Id> opportunityids    = new Set<Id>();
                                          Set<Id> marketingProgramId = new Set<Id>();
                                          
                                          List<Account> accountList = new List<Account>();
                                          List<Marketing_Program__c> marketProgram = new List<Marketing_Program__c>();
                                          List<Drive_Marketing_Programs__c> driveMarket = new List<Drive_Marketing_Programs__c>();
                                          List<Budget_Matrix__mdt> budgetMatrix = new List<Budget_Matrix__mdt>();
                                          
                                          Map<Id, Account> accountIdAccount = new Map<Id, Account>();
                                          Map<Order, Id> orderAccountid = new Map<Order, Id>();
                                          Map<Order, Id> orderOpportunityid = new Map<Order, Id>();
                                          Map<Id, Id> driveMarketIdandMarketprogramId = new Map<Id, Id>();
                                          Map<Id, Marketing_Program__c> marketIdMarketProgram = new Map<Id, Marketing_Program__c>();
                                          Map<Id, List<Drive_Marketing_Programs__c>> opportunityIdDrivePrograms = new Map<Id, List<Drive_Marketing_Programs__c>>();
                                          Map<String, List<Budget_Matrix__mdt>> accountBudgetmatrix = new Map<String, List<Budget_Matrix__mdt>>();
                                          Map<Id, Opportunity> oppIdObject;
                                          
                                          for( Order od : newOrders ){
                                              accountids.add(od.accountId);
                                              opportunityids.add(od.OpportunityId);
                                              
                                              orderAccountid.put( od, od.accountId );
                                              orderOpportunityid.put( od, od.OpportunityId);
                                          }
                                          
                                          // Budget Matrix
                                          /*budgetMatrix = [ select Id, Type__c, Marketing_Program_Type__c, Account_Type__c, Industry_Code__c, Unit_Price__c from Budget_Matrix__mdt WITH SECURITY_ENFORCED];
                                          
                                          if( !budgetMatrix.isEmpty() ){
                                              for( Budget_Matrix__mdt bmx : budgetMatrix){              
                                                  if( !accountBudgetmatrix.containsKey( bmx.Type__c ) ){
                                                      accountBudgetmatrix.put(bmx.Type__c, new List<Budget_Matrix__mdt>());
                                                  }
                                                  accountBudgetmatrix.get(bmx.Type__c).add(bmx);                
                                              }
                                          } */
                                          // HRP-6470
											Map<String, Budget_Matrix__mdt> bm = Budget_Matrix__mdt.getAll();											
											for( String bmobj : bm.keySet()){   
												Budget_Matrix__mdt bmx = bm.get(bmobj);
												if( !accountBudgetmatrix.containsKey( bmx.Type__c ) ){
													accountBudgetmatrix.put(bmx.Type__c, new List<Budget_Matrix__mdt>());
												}
												accountBudgetmatrix.get(bmx.Type__c).add(bmx);                
											}
                                          // Opportunity / Blood Drive Opportunity
                                          oppIdObject = new Map<Id, Opportunity>([Select Id, Total_Products_Projected__c  From Opportunity where Id IN:opportunityids ]);
                                          
                                          // Drive Marketing Program
                                          driveMarket = [ select Id, Blood_Drive_Opportunity__c, Marketing_Program__c from Drive_Marketing_Programs__c where Blood_Drive_Opportunity__c IN:opportunityids  ];
                                          if( !driveMarket.isEmpty() ){
                                              for( Drive_Marketing_Programs__c dmp : driveMarket ){
                                                  driveMarketIdandMarketprogramId.put( dmp.Id, dmp.Marketing_Program__c);               
                                                  marketingProgramId.add(  dmp.Marketing_Program__c );
                                                  
                                                  if( !opportunityIdDrivePrograms.containsKey( dmp.Blood_Drive_Opportunity__c ) ){
                                                      opportunityIdDrivePrograms.put( dmp.Blood_Drive_Opportunity__c, new List<Drive_Marketing_Programs__c>() );
                                                  }
                                                  opportunityIdDrivePrograms.get( dmp.Blood_Drive_Opportunity__c ).add(dmp);
                                              }
                                          }
                                          
                                          // Marketing Program
                                          if( !marketingProgramId.isEmpty() ){
                                              marketProgram = [ select Id, Name from Marketing_Program__c where Id IN:marketingProgramId ];         
                                              if( !marketProgram.isEmpty() ){
                                                  for( Marketing_Program__c mp : marketProgram ){
                                                      if( !marketIdMarketProgram.containsKey( mp.Id ) ){
                                                          marketIdMarketProgram.put( mp.Id, mp );
                                                      }
                                                  }
                                              }
                                          }
                                          
                                          // Account
                                          accountList = [ select Id, Type, Industry_Code__c from Account where Id IN:accountids ];
                                          if( !accountList.isEmpty() ){
                                              for( Account acc : accountList ){
                                                  accountIdAccount.put( acc.Id, acc );
                                              }
                                          }
                                          
                                          // Order Budget Calculation
                                          for( Order od : newOrders ){
                                              Id oppid = orderOpportunityid.get(od);
                                              
                                              // Reset Budget to null, because if Order created using Salesforce Clone functionality
                                              od.BudgetCurrency__c = null;
                                              
                                              // Priority #1 : Marketing Program
                                              if( opportunityIdDrivePrograms.containsKey(oppid) ){
                                                  for( Drive_Marketing_Programs__c dmp : opportunityIdDrivePrograms.get(oppid) ){ // Iterate over the List of Drive Marketing Program
                                                      Id marketProgId= driveMarketIdandMarketprogramId.get(dmp.Id);
                                                      
                                                      Marketing_Program__c mprog = marketIdMarketProgram.get(marketProgId);
                                                      
                                                      if( accountBudgetmatrix.containsKey( 'Marketing Program' ) ){
                                                          for( Budget_Matrix__mdt bmx : accountBudgetmatrix.get('Marketing Program') ){
                                                              if( bmx.Marketing_Program_Type__c == mprog.Name){
                                                                  // Formulla to calculate Order Budget
                                                                  // System.debug( 'Order => Opportunity => OpportunityId: ' + od.OpportunityId );
                                                                  // System.debug( 'Order => Opportunity => Total_Products_Projected__c: ' + oppIdObject.get(od.OpportunityId).Total_Products_Projected__c );
                                                                  // System.debug( 'Budget_Matrix__mdt => Marketing_Program_Type__c => Unit_Price__c: ' + bmx.Unit_Price__c );
                                                                  Decimal productProjected = oppIdObject.get(od.OpportunityId).Total_Products_Projected__c;
                                                                  Decimal unitprice = bmx.Unit_Price__c;
                                                                  Decimal totalBudget = productProjected * unitprice;
                                                                  od.BudgetCurrency__c = totalBudget;
                                                              }
                                                          }                     
                                                      }                 
                                                  }
                                              }
                                              
                                              if( od.BudgetCurrency__c == null ){
                                                  // Priority #2 : Account Type, Industry Code
                                                  Account acc = accountIdAccount.get(od.AccountId);
                                                  if( accountBudgetmatrix.containsKey( 'Account' ) ){
                                                      for( Budget_Matrix__mdt bmx : accountBudgetmatrix.get('Account') ){
                                                          if( bmx.Account_Type__c == acc.Type && bmx.Industry_Code__c == acc.Industry_Code__c){
                                                              // Formulla to calculate Order Budget
                                                              // System.debug( 'Order => Opportunity => OpportunityId: ' + od.OpportunityId );
                                                              // System.debug( 'Order => Opportunity => Total_Products_Projected__c: ' + oppIdObject.get(od.OpportunityId).Total_Products_Projected__c );
                                                              // System.debug( 'Budget_Matrix__mdt => Marketing_Program_Type__c => Unit_Price__c: ' + bmx.Unit_Price__c );
                                                              Decimal productProjected = oppIdObject.get(od.OpportunityId).Total_Products_Projected__c;
                                                              Decimal unitprice = bmx.Unit_Price__c;
                                                              Decimal totalBudget = productProjected * unitprice;
                                                              od.BudgetCurrency__c = totalBudget;
                                                          }
                                                      }                     
                                                  }             
                                                  
                                              }
                                              
                                              if( od.BudgetCurrency__c == null ){
                                                  // Priority #3 : Other
                                                  if( accountBudgetmatrix.containsKey( 'Other' ) ){
                                                      for( Budget_Matrix__mdt bmx : accountBudgetmatrix.get('Other') ){
                                                          // Formulla to calculate Order Budget
                                                          Decimal productProjected = oppIdObject.get(od.OpportunityId).Total_Products_Projected__c;
                                                          Decimal unitprice = bmx.Unit_Price__c;
                                                          Decimal totalBudget = productProjected * unitprice;
                                                          od.BudgetCurrency__c = totalBudget;
                                                      }                     
                                                  }             
                                              }
                                          }                                                     
                                          
                                      }
    
    /*
* JIRA Ticket: HRP - 1613, 
* Description: 1.1 User: Managing Publicity Order Budgets
*/
    
    public static void checkOrderBudgetwithProduct( List<Order> oldOrders, List<Order> newOrders,
                                                   Map<Id,Order> oldOrdersMap,Map<Id,Order> newOrdersMap){
                                                       
                                                       Set<Id> orderids = new Set<Id>();    
                                                       List<OrderItem> oitemlist = new List<OrderItem>();
                                                       List<OrderItem> oitems = new List<OrderItem>();
                                                       
                                                       for( Order od : newOrders){
                                                           if( oldOrdersMap.get(od.Id).Publicity_Approved__c == false &&  newOrdersMap.get(od.Id).Publicity_Approved__c == true ){
                                                               orderids.add( od.Id );
                                                           } 
                                                           
                                                       }
                                                       if( !orderids.isEmpty() ){
                                                           oitemlist = [select Id, Quantity, UnitPrice from OrderItem where orderid in:orderids ];                                            
                                                           if( !oitemlist.isEmpty() ){
                                                               oitems.addAll(oitemlist);
                                                           } 
                                                           
                                                           Decimal totalProductBudget = 0.0;
                                                           for( OrderItem oit : oitems ){
                                                               Decimal eachProductBudget = oit.Quantity * oit.UnitPrice;
                                                               totalProductBudget = totalProductBudget + eachProductBudget;
                                                           }
                                                           
                                                           for( Order od : newOrders){
                                                               if( totalProductBudget > od.BudgetCurrency__c ){
                                                                   Decimal budgetdiff = totalProductBudget - od.BudgetCurrency__c ;
                                                                   od.addError('Total Budget is exceeding,exceeding amount is ' + budgetdiff );
                                                                   
                                                               }
                                                           }
                                                           
                                                       }                            
                                                   }
    
    /*
* JIRA Ticket: HRP - 743, 
* Description: 3.4 System: Auto population of Publicity Order Due Date
*/
    
    public static void calculateOrderDueDate(list<Order> orderList)    {
        Integer noOfWeek = Integer.valueOf(system.Label.Publicity_Order_Due_Date_Configuration);
        map<Id, Date> mapOfOppIdWithDriveDate = new map<Id, Date>();
        set<Id> oppId = new set<Id>();
        Integer noOfDays =  noOfWeek * 7;
        
        if(orderList.size() > 0 ){
            for(order od: orderList){
                if(od.OpportunityId != null)
                    oppId.add(od.OpportunityId);
            }
        }
        if(oppId.size() > 0 ){
            for(opportunity opp: [SELECT Id, Drive_Date__c FROM Opportunity where id in:oppId ]){                
                mapOfOppIdWithDriveDate.put(opp.Id, opp.Drive_Date__c);   
            } 
        }
        if(mapOfOppIdWithDriveDate.size() > 0){
            for(Id i: mapOfOppIdWithDriveDate.keySet()){                
                Date dueDate =  mapOfOppIdWithDriveDate.get(i) - noOfDays; 
                String myDateString = Datetime.newInstance(dueDate.year(),dueDate.month(),dueDate.day()).format('EEE');
                if('Sat'.equals(myDateString)){
                    dueDate = dueDate - 1;
                }
                if('Sun'.equals(myDateString)){
                    dueDate = dueDate - 2;
                }
                mapOfOppIdWithDriveDate.put(i,dueDate);
            }
        }
        if(orderList.size() > 0 ){
            for(order od: orderList){
                if(od.OpportunityId != null)
                    od.Order_Due_Date__c =  mapOfOppIdWithDriveDate.get(od.OpportunityId);
            }
        }
    } 
    public static void setPublicityApproved( List<Order> oldOrders, List<Order> newOrders,
                                            Map<Id,Order> oldOrdersMap,Map<Id,Order> newOrdersMap){
                                                
                                                
                                                for( Order od : newOrders ){
                                                    if( oldOrdersMap.get(od.Id).Publicity_Approved__c != newOrdersMap.get(od.Id).Publicity_Approved__c  ){
                                                        od.Publicity_Approved_Date__c = System.today();
                                                        od.Publicity_Approved_By__c = userInfo.getUserId();
                                                    }
                                                }                                                   
                                                
                                            }   
}