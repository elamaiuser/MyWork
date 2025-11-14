/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class ApiInput {
    global ApiInput() {

    }
global class AutoComplete {
    global String country;
    global String input;
    global String sessionId;
    global AutoComplete(String address, String countryCode, String sessionId) {

    }
}
global class DistanceMatrix {
    global List<sked.ApiInput.Geometry> destinations;
    global List<sked.ApiInput.Geometry> origins;
    global DistanceMatrix(List<System.Location> origins, List<System.Location> destinations) {

    }
    global List<sked.ApiInput.Geometry> toGeometryList(List<System.Location> locList) {
        return null;
    }
}
global class Generic {
    global String httpMethod;
    global String jsonBody;
    global Map<String,String> params;
    global String path;
    global Generic(String httpMethod, String path, Map<String,String> params, String jsonBody) {

    }
}
global class Geocode {
    global List<String> addresses;
    global Geocode(List<String> addresses) {

    }
}
global class Geometry {
    global Decimal lat;
    global Decimal lng;
    global Geometry(System.Location loc) {

    }
}
global class JobCancelledNotification {
    global String jobId;
    global JobCancelledNotification(String jobId) {

    }
}
global class Notification {
    global Id jobId;
    global Id resourceId;
    global Notification(Id jobId, Id resourceId) {

    }
}
global class OneOff {
    global String message;
    global String protocol;
    global String resourceId;
    global OneOff(String resourceId, String message, String protocol) {

    }
}
global class Place {
    global String placeId;
    global String sessionId;
    global Place(String placeId, String sessionId) {

    }
}
global class Sms {
    global String countryCode;
    global String jobId;
    global String message;
    global String phoneNumber;
    global Sms(String phoneNumber, String countryCode, String message) {

    }
    global Sms(String phoneNumber, String countryCode, String message, String jobId) {

    }
}
}
