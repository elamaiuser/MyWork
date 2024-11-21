public class skedServiceFactory {

    public static final string CUSTOM_FIELDS_EXTENSION = '__c';
    protected Map<string, skedDataService> mapDataService;
    /************************************************ Singleton stuff ***********************************************/
    private static skedServiceFactory mInstance;

    public static skedServiceFactory instance {
        get {
            if (mInstance == null) {
                mInstance = new skedServiceFactory();
            }
            return mInstance;
        }
    }

    private skedServiceFactory() {
        this.mapDataService = new Map<string, skedDataService>();
    }
    /************************************************ Service Factory ***********************************************/
    public skedDataService resolve(string serviceKey) {
        skedDataService service;
        if (mapDataService.containsKey(serviceKey)) {
            service = mapDataService.get(serviceKey);
        }
        else {
            string className;
            if (serviceKey == 'skedHC__Exception__c') {
                className = 'skedExceptionLogService';
            }
            else {
                className = serviceKey.removeEnd(CUSTOM_FIELDS_EXTENSION);
                className = className.startsWith('skedHC_') ? className.remove('skedHC_') : className;
                className = className.startsWith('sked_') ? className.remove('sked_') : className;
                className = className.remove('_');
                className = 'sked' + className + 'Service';
            }
            Type dataServiceType = Type.forName(className);
            if (dataServiceType != NULL) {
                service = (skedDataService)dataServiceType.newInstance();
            }
            else {
                service = new skedUntypedService(serviceKey);
            }
        }
        this.mapDataService.put(serviceKey, service);
        return service;
    }

}