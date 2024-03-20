({
    afterScriptsLoaded : function(component, event, helper) {
        component.set("v.ready", true);
        helper.createChart(component);
    }
})