public class TestUtil {
	

	public static User getCurrentUser(){
		return [select Id, Name from User where Id = :UserInfo.getUserId()];
	}

	public static User createUser(String userName,Id profileId,Boolean isInsert, Id managerId, String lastName, String firstName){
        User user = new User(
            Username = userName,
            Email = firstName + '.' + lastName + '@redcross.testing.org',
            LastName = lastName,
            FirstName = firstName,
            Alias = 'sv',
            ProfileID = profileId,
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey='UTF-8',
            ManagerId = managerId
        );
        if(isInsert)
            insert user;
        return user;
    }


}