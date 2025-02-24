import { isArray, isString, isEmpty } from 'c/lodash';

const LWC_ERROR_TYPE = {
  UNKNOWN: 'UNKNOWN',
  TEXT: 'TEXT',
  APEX_CUSTOM: 'APEX_CUSTOM',
  CUSTOM_FIELD: 'CUSTOM_FIELD',
  TRIGGER_AND_VALIDATION_RULE: 'TRIGGER_AND_VALIDATION_RULE'
};

class AppError {
  rawError;
  message;
  stackTrace;

  constructor(rawError, message) {
    this.rawError = rawError;
    this.message = message;
    this.stackTrace = '';
  }
}

class LWCError extends AppError {
  constructor(rawError, message) {
    super(rawError, message);
  }

  parseUnknown = () => {
    return this.rawError;
  }

  parseText = () => {
    if(!this.rawError) return null;

    let message = this.rawError;
    let messageKey = '"message":"';
    let messageIndex = message.indexOf(messageKey);
    if(messageIndex > -1) {
      message = message.substring(messageIndex + messageKey.length);
      let nextQuoteIndex = message.indexOf('"');
      message = message.substring(0, nextQuoteIndex);  
    }

    return message;
  }

  parseApexCustomError = () => {
    // check if message is a json string to get shortError value only
    let message = this.rawError.message;
    try {
      const customError = JSON.parse(message);
      message = customError.shortError || message;
    } catch(e) {}

    return message;
  }

  parseCustomFieldError = () => {
    if(!this.rawError.fieldErrors || isEmpty(this.rawError.fieldErrors)) return null;
    let errorMessages = Object.values(this.rawError.fieldErrors)[0] || [];
    return errorMessages.length > 0 ? errorMessages[0].message : null;
  }

  parseTriggerAndValidationRuleError = () => {
    if(!this.rawError.pageErrors || !this.rawError.pageErrors.length) return null;
    return this.rawError.pageErrors[0].message;
  }

  getType = () => {
    const rawError = this.rawError;
    if(isString(rawError)) {
      return LWC_ERROR_TYPE.TEXT;
    }

    if(rawError.exceptionType) {
      return LWC_ERROR_TYPE.APEX_CUSTOM;
    }

    if((rawError.pageErrors && rawError.pageErrors.length)) {
      return LWC_ERROR_TYPE.TRIGGER_AND_VALIDATION_RULE;
    }

    if(!isEmpty(rawError.fieldErrors)) {
      return LWC_ERROR_TYPE.CUSTOM_FIELD;
    }

    return LWC_ERROR_TYPE.UNKNOWN;
  }

  parse(rawError) {
    if(!rawError) return;

    const typeMap = {
      [LWC_ERROR_TYPE.UNKNOWN]: this.parseUnknown,
      [LWC_ERROR_TYPE.TEXT]: this.parseText,
      [LWC_ERROR_TYPE.APEX_CUSTOM]: this.parseApexCustomError,
      [LWC_ERROR_TYPE.CUSTOM_FIELD]: this.parseCustomFieldError,
      [LWC_ERROR_TYPE.TRIGGER_AND_VALIDATION_RULE]: this.parseTriggerAndValidationRuleError
    }

    this.rawError = rawError;
    const type = this.getType();
    const parseFn = typeMap[type];

    if(parseFn) {
      this.message = parseFn()
    }
  }
}

class ErrorHandler {
  static DEFAULT_LWC_ERROR = new LWCError('DEFAULT_LWC_ERROR', 'Something went wrong.');
  static fromLWC = (errorResponse) => {
    if(!errorResponse || !errorResponse.body) return [];
    
    let errors = errorResponse.body; 
    if(!isArray(errors)) {
      errors = [errors];
    }

    return errors.map(error => {
      let lwcError = new LWCError();
      lwcError.parse(error);
      lwcError.stackTrace = errorResponse.body.stackTrace;

      return lwcError;
    })
  } 
}

export {
  AppError,
  ErrorHandler
}