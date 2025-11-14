/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class ApiResult {
    global static String AUTOCOMPLETE_MOCK_DATA;
    global static String DISTANCE_MATRIX_MOCK_DATA;
    global static String GEOCODE_MOCK_DATA;
    global static String NOTIFY_MOCK_DATA;
    global static String ONEOFF_MOCK_DATA;
    global static String PLACE_MOCK_DATA;
    global static String SMS_MOCK_DATA;
    global ApiResult() {

    }
global class Address {
    global String area1;
    global String area2;
    global String country;
    global String locality;
    global String postalCode;
    global String route;
    global String streetNumber;
    global String subLocality;
    global Address() {

    }
}
global class AddressPrediction {
    global String description;
    global String placeId;
    global AddressPrediction() {

    }
}
global class AutoComplete extends sked.ApiResult.Generic {
    global sked.ApiResult.AutoCompleteResult result;
    global String sessionId;
    global AutoComplete() {

    }
    global Map<String,String> getResultMap() {
        return null;
    }
    global String getSessionId() {
        return null;
    }
    global override void toResultObject(String jsonResult) {

    }
}
global class AutoCompleteResult {
    global List<sked.ApiResult.AddressPrediction> predictions;
    global AutoCompleteResult() {

    }
}
global class BaseError {
    global String errorType;
    global String message;
    global BaseError() {

    }
}
global class Distance {
    global Integer distanceInMeters;
    global Distance() {

    }
}
global class DistanceMatrix extends sked.ApiResult.Generic {
    global sked.ApiResult.Matrix result;
    global DistanceMatrix() {

    }
    global String createKey(System.Location origin, System.Location destination) {
        return null;
    }
    global Map<String,sked.ApiResult.Element> getResultMap(List<System.Location> originList, List<System.Location> destinationList) {
        return null;
    }
    global override void toResultObject(String jsonResult) {

    }
}
global class Duration {
    global Integer durationInSeconds;
    global Duration() {

    }
}
global class Element {
    global sked.ApiResult.Distance distance;
    global sked.ApiResult.Duration duration;
    global String status;
    global Element() {

    }
    global String getError() {
        return null;
    }
    global Boolean isSuccess() {
        return null;
    }
}
global virtual class Generic {
    global String message;
    global String response;
    global String status;
    global Integer statusCode;
    global Boolean success;
    global Generic() {

    }
    global String getError() {
        return null;
    }
    global void init(sked.ApiResult.Generic result) {

    }
    global Boolean isSuccess() {
        return null;
    }
    global virtual void setMockResponse() {

    }
    global virtual void toResultObject(String jsonResult) {

    }
}
global class Geocode extends sked.ApiResult.Generic {
    global List<sked.ApiResult.GeocodeItem> result;
    global Geocode() {

    }
    global override void toResultObject(String jsonResult) {

    }
}
global class GeocodeFailure {
    global String address;
    global sked.ApiResult.GeocodeFailureReason reason;
    global GeocodeFailure() {

    }
}
global class GeocodeFailureReason {
    global String msg;
    global GeocodeFailureReason() {

    }
}
global class GeocodeItem {
    global sked.ApiResult.GeocodeFailure geocodeFailure;
    global sked.ApiResult.GeocodeSuccess geocodeSuccess;
    global GeocodeItem() {

    }
    global String getError() {
        return null;
    }
    global System.Location getLocation() {
        return null;
    }
    global Boolean isSuccess() {
        return null;
    }
}
global class GeocodeSuccess {
    global String address;
    global sked.ApiResult.Latlng latlng;
    global GeocodeSuccess() {

    }
}
global class JobNotification {
    global String jobId;
    global List<sked.ApiResult.ResourceNotification> results;
    global JobNotification() {

    }
}
global class Latlng {
    global Decimal lat;
    global Decimal lng;
    global Latlng() {

    }
}
global class Matrix {
    global List<List<sked.ApiResult.Element>> matrix;
    global Matrix() {

    }
}
global class MessageResult {
    global String protocol;
    global MessageResult() {

    }
}
global class Notification {
    global Id jobId;
    global String message;
    global List<sked.ApiResult.ResourceNotification> results;
    global Boolean success;
    global Notification() {

    }
}
global class NotificationResult extends sked.ApiResult.Generic {
    global sked.ApiResult.JobNotification result;
    global NotificationResult() {

    }
    global String getError(String resourceId) {
        return null;
    }
    global override void toResultObject(String jsonResult) {

    }
}
global class OneOff extends sked.ApiResult.Generic {
    global sked.ApiResult.MessageResult result;
    global OneOff() {

    }
    global override void toResultObject(String jsonResult) {

    }
}
global class Place extends sked.ApiResult.Generic {
    global sked.ApiResult.PlaceResult result;
    global Place() {

    }
    global String getAddress() {
        return null;
    }
    global System.Location getLocation() {
        return null;
    }
    global override void toResultObject(String jsonResult) {

    }
}
global class PlaceResult {
    global sked.ApiResult.Address addressComponents;
    global String formattedAddress;
    global sked.ApiResult.Latlng geometry;
    global PlaceResult() {

    }
}
global class ResourceNotification {
    global sked.ApiResult.BaseError error;
    global String protocol;
    global Id resourceId;
    global ResourceNotification() {

    }
}
global class Sms extends sked.ApiResult.Generic {
    global Sms() {

    }
}
}
