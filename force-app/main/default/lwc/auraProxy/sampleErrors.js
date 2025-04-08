const type1 = { //unkown
    "status": 500,
    "body": {
        "message": "error parsing apex response: */{\n  \"message\":\"No apex action available for slwcDataService.testAuraError\"\n}/*ERROR*/"
    },
    "headers": {}
}

const aura = { //apex custom error
    "status": 500,
    "body": {
        "exceptionType": "skedException",
        "isUserDefinedException": true,
        "message": "custom error",
        "stackTrace": "Class.testErrorService.testAuraError: line 5, column 1"
    },
    "headers": {}
}

const aura2 = { //apex custom error
    "status": 500,
    "body": {
        "exceptionType": "System.StringException",
        "isUserDefinedException": false,
        "message": "Invalid id: abc",
        "stackTrace": "Class.testErrorService.testIdValue: line 31, column 1"
    },
    "headers": {}
}

const type2 = { //custom field error
    "status": 500,
    "body": {
        "fieldErrors": {
            "test_Picklist_Value__c": [
                {
                    "statusCode": "INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST",
                    "message": "Picklist Value: bad value for restricted picklist field: abc"
                }
            ]
        },
        "pageErrors": [],
        "index": null,
        "duplicateResults": []
    },
    "headers": {}
}

const trigger = { //trigger & validation rule
    "status": 500,
    "body": {
        "fieldErrors": {},
        "pageErrors": [
            {
                "statusCode": "FIELD_CUSTOM_VALIDATION_EXCEPTION",
                "message": "Error in trigger"
            }
        ],
        "index": null,
        "duplicateResults": []
    },
    "headers": {}
}