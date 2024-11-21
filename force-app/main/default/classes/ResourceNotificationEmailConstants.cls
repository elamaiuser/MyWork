/*
* Date					Developer Name			Comments
 * ***************************************************************************************************************************************************************************
 * 05/16/2023			Barnojit Sharma				Constant class for ResourceNotificationEmailUtil apex class (HRP-1566)
 *****************************************************************************************************************************************************************************
*/
public class ResourceNotificationEmailConstants {
    public static final String COMA = ',';
    public static final String BLANK = '';
    public static final String INSERT_STR = 'INSERT';
    public static final String UPDATE_STR = 'UPDATE';
    public static final String STAFF = 'Staff';
    public static final String DATE_FORMAT = 'EEE, MM/dd/yyyy \'at\' hh:mm aaa';
    public static final String SPACE = ' ';
    public static final String ID_STR = 'Id';
    public static final String NANE_STR = 'Name';
    public static final String QUERY_PART1 = 'SELECT Id, Name FROM ';
    public static final String QUERY_PART2 = ' WHERE Id IN:idList';
    public static final String EMAIL_BODY_CREATE_PART1 = 'There is a new resource for <b>';
    public static final String EMAIL_BODY_CREATE_PART2 = '</b>, the details of the resource can be found below.';
    public static final String EMAIL_BODY_CREATE_PART3 = '<br>Date of Creation :';
    public static final String EMAIL_BODY_BR = '<br><br>';
    public static final String EMAIL_BODY_UPDATE_PART1 = 'A recent update has been made to the <b>';
    public static final String EMAIL_BODY_UPDATE_PART2 = '</b> Resource, updated field details are provided below.';
    public static final String EMAIL_BODY_UPDATE_PART3 = '<br>Employee Number :';
    public static final String EMAIL_BODY_UPDATE_PART4 = '<br>Date of Change :';
    public static final String EMAIL_SUBJECT = 'Notification: Resource Record Updated/Created';
    public static final String FILTER = 'FILTER';
    public static final String HI = 'Hi ';
    public static final String BR = '<br>';
    public static final String TABLE_PART1 = '<table border="1" cellpadding="4" cellspacing="0">';
    public static final String TABLE_PART2 = '<thead><tr><th>Field Name</th><th>Value</th></tr></thead><tbody><tr><td>Employee Number</td><td>';
    public static final String TABLE_PART3 = '</td></tr>';
    public static final String TABLE_PART4 = '<thead><tr><th>Field Name</th><th>Old Value</th><th>New Value</th></tr></thead><tbody>';
    public static final String TD_START = '<td>';
    public static final String TD_CLOSE = '</td>';
    public static final String TR_START = '<tr>';
    public static final String TR_CLOSE = '</tr>';
    public static final String TABLE_CLOSE = '</tbody></table>';
}