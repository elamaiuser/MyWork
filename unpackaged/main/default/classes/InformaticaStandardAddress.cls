public with sharing class InformaticaStandardAddress {
    /*
    <n:cln_cnst_line1_addr>1923 Lake Forest Rd</n:cln_cnst_line1_addr>
    <n:cln_cnst_line2_addr>24C</n:cln_cnst_line1_addr>
    <n:cln_cnst_city_nm>Grapevine</n:cln_cnst_city_nm>
    <n:cln_cnst_state_cd>TX</n:cln_cnst_state_cd>
    <n:cln_cnst_zip_5>76051</n:cln_cnst_zip_5>
    <n:USSpecificDeliveryPointValidationConfirmation>Y</n:USSpecificDeliveryPointValidationConfirmation>
    <n:USSpecificDeliveryPointValidationFootnote1>AA</n:USSpecificDeliveryPointValidationFootnote1>
    <n:USSpecificDeliveryPointValidationFootnote2>BB</n:USSpecificDeliveryPointValidationFootnote2>
    <n:USSpecificHighRiseDefault>N</n:USSpecificHighRiseDefault>
    <n:GeoCodingLatitude>32.974153</n:GeoCodingLatitude>
    <n:GeoCodingLongitude>-97.097379</n:GeoCodingLongitude>
    <n:GeoCodingGeocodingStatus>EGC9</n:GeoCodingGeocodingStatus>
     */

    public String Line1 {get;set;}
    public String Line2 {get;set;}
    public String City {get;set;}
    public String State {get;set;}
    public String Zip {get;set;}
    public String DeliveryPointConfirmation {get;set;}
    public String DeliveryPointFootnote1 {get;set;}
    public String DeliveryPointFootnote2 {get;set;}
    public String HighRise {get;set;}
    public String Latitude {get;set;}
    public String Longitude {get;set;}
    public String GeoCodingStatus {get;set;}
    public String FullAddress {
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