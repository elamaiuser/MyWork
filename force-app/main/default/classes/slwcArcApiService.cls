global class slwcArcApiService {

    @AuraEnabled(cacheable=true)
    public static informaticaStandardAddressModel getStandardAddress(inputAddressModel inputAddress) {
        system.debug('addressL' + inputAddress);
        InputAddress address = new InputAddress();
        address.addressLine1 = inputAddress.addressLine1;
        address.addressLine2 = inputAddress.addressLine2;
        address.city = inputAddress.city;
        address.state = inputAddress.state;
        address.zip5 = inputAddress.zip5;
        
        informaticaStandardAddressModel result;
        if (Test.isRunningTest()){ 
            result = new informaticaStandardAddressModel();
            result.Line1 = '2204 Westcourt Ln';
            result.Line2 = 'Apt 218';
            result.City = 'Herndon';
            result.State = 'VA';
            result.Zip = '20170';
            result.Latitude = '37.7450046';
            result.Longitude = '-122.4816244';
            result.DeliveryPointConfirmation = 'y';
        }
        else {
            InformaticaStandardAddress standarAddress = InformaticaAddressStandardization.getStandardAddress(address);
            string jsonAddress = JSON.serialize(standarAddress);
            result = (informaticaStandardAddressModel)JSON.deserialize(jsonAddress, informaticaStandardAddressModel.class);
        }
        
        return result;
    }

    public class inputAddressModel {
        @AuraEnabled public String addressLine1 { get; set;}
        @AuraEnabled public String addressLine2 { get; set;}
        @AuraEnabled public  String city { get; set;}
        @AuraEnabled public  String state { get; set;}
        @AuraEnabled public  String zip5 { get; set;}
    }
    
    public class informaticaStandardAddressModel {
        @AuraEnabled public String Line1 {get;set;}
        @AuraEnabled public String Line2 {get;set;}
        @AuraEnabled public String City {get;set;}
        @AuraEnabled public String State {get;set;}
        @AuraEnabled public String Zip {get;set;}
        @AuraEnabled public String DeliveryPointConfirmation {get;set;}
        @AuraEnabled public String DeliveryPointFootnote1 {get;set;}
        @AuraEnabled public String DeliveryPointFootnote2 {get;set;}
        @AuraEnabled public String HighRise {get;set;}
        @AuraEnabled public String Latitude {get;set;}
        @AuraEnabled public String Longitude {get;set;}
        @AuraEnabled public String GeoCodingStatus {get;set;}
        @AuraEnabled public String FullAddress {
            get {
                String fullAddress = Line1;
                if(String.isNotBlank(Line2)) {
                    fullAddress = fullAddress + ' ' + Line2;
                }
                
                fullAddress = fullAddress + ', ' + City + ', ' + State + ' ' + Zip;
                
                return fullAddress;
            }
        }
    }
    
    
	
}