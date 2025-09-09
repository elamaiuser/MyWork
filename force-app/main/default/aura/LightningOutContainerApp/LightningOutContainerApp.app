<aura:application access="GLOBAL" extends="ltng:outApp" >
	<aura:dependency resource="c:flowHostCMP"/>
    <aura:dependency resource="c:slwcMassListenDriveChange"/> 
    <!-- <aura:dependency resource="markup://force:*" type="EVENT"/>  -->
    <aura:dependency resource="markup://force:navigateToSObject" type="EVENT"/>
    <aura:dependency resource="markup://force:navigateToObjectHome" type="EVENT"/>
</aura:application>