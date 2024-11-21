global class skedUntypedService extends skedDataService {

    public skedUntypedService() {
        super();
    }

    public skedUntypedService(string sObjectApiName) {
        super();
        this.sObjectApiName = sObjectApiName;
        string className = sObjectApiName.removeEnd(skedConstants.CUSTOM_FIELDS_EXTENSION);
        className = className.startsWith('sked_') ? className.remove('sked_') : className;
        className = className.remove('_');
        if (sObjectApiName.toLowerCase() == 'case') {
            this.objectType = 'caseModel';
        }
        else {
            this.objectType = className;
        }
        this.domainType = Type.forName('skedModels.' + this.objectType);
    }

    protected override void initialize() {}

}