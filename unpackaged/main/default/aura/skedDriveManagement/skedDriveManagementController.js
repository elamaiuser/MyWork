({
    handleDiscardUnsavedChanges: function(component) {
        const unsavedDialogComponent = component.find('unsavedChangesDialog');
        unsavedDialogComponent.setUnsavedChanges(false);
    },
    handleDriveDirtyStateChanged: function(component, event) {
        const unsavedDialogComponent = component.find('unsavedChangesDialog');
        unsavedDialogComponent.setUnsavedChanges(event.getParam('isDirty'));
    }
})