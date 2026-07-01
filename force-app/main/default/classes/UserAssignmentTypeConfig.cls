public class UserAssignmentTypeConfig {
    public String typeName;
    public String targetObj;
    public String targetLookupField;
    public String junctionObj;
    public String junctionUserField;
    public String junctionTargetField;
    public String targetFilter;
    public String junctionFilter;

    public UserAssignmentTypeConfig(String typeName, String targetObj, String targetLookupField, 
                                    String junctionObj, String junctionUserField, 
                                    String junctionTargetField, String targetFilter, 
                                    String junctionFilter) {
        
        this.typeName            = typeName;
        this.targetObj           = targetObj;
        this.targetLookupField   = targetLookupField;
        this.junctionObj         = junctionObj;
        this.junctionUserField   = junctionUserField;
        this.junctionTargetField = junctionTargetField;
        this.targetFilter        = String.isNotBlank(targetFilter) ? ' AND ' + targetFilter : '';
        this.junctionFilter      = String.isNotBlank(junctionFilter) ? ' AND ' + junctionFilter : '';
    }
}