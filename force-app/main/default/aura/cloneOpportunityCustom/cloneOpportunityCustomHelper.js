({
    
    handleErrors: function(errors, cmp, type, onclose){
        let variant = 'error';
        let message = 'Unknown error';

        if(type){
            variant = type;
        }

        if (errors && Array.isArray(errors) && errors.length > 0) {
            message = errors[0].message;
        }

        let msgParams = {
            "variant": "error",
            "header": "Information",
            "message": message
        };

        if(onclose){
           msgParams.closeCallback = function(){ onclose(cmp) };
        }

        cmp.find('notifLib').showNotice(msgParams);

        console.error(message);
    }
})