//----------------------------------------------------------------------
//
// ECMAScript 5 Polyfills
//
//----------------------------------------------------------------------

//----------------------------------------------------------------------
// ES5 15.2 Object Objects
//----------------------------------------------------------------------

//
// ES5 15.2.3 Properties of the Object Constructor
//

// ES5 15.2.3.2 Object.getPrototypeOf ( O )
// From http://ejohn.org/blog/objectgetprototypeof/
// NOTE: won't work for typical function T() {}; T.prototype = {}; new T; case
// since the constructor property is destroyed.
if (!Object.getPrototypeOf) {
  Object.getPrototypeOf = function (o) {
    if (o !== Object(o)) { throw TypeError("Object.getPrototypeOf called on non-object"); }
    return o.__proto__ || o.constructor.prototype || Object.prototype;
  };
}

//    // ES5 15.2.3.3 Object.getOwnPropertyDescriptor ( O, P )
//    if (typeof Object.getOwnPropertyDescriptor !== "function") {
//        Object.getOwnPropertyDescriptor = function (o, name) {
//            if (o !== Object(o)) { throw TypeError(); }
//            if (o.hasOwnProperty(name)) {
//                return {
//                    value: o[name],
//                    enumerable: true,
//                    writable: true,
//                    configurable: true
//                };
//            }
//        };
//    }

// ES5 15.2.3.4 Object.getOwnPropertyNames ( O )
if (typeof Object.getOwnPropertyNames !== "function") {
  Object.getOwnPropertyNames = function (o) {
    if (o !== Object(o)) { throw TypeError("Object.getOwnPropertyNames called on non-object"); }
    var props = [], p;
    for (p in o) {
      if (Object.prototype.hasOwnProperty.call(o, p)) {
        props.push(p);
      }
    }
    return props;
  };
}

// ES5 15.2.3.5 Object.create ( O [, Properties] )
if (typeof Object.create !== "function") {
  Object.create = function (prototype, properties) {
    if (typeof prototype !== "object") { throw TypeError(); }
    function Ctor() {}
    Ctor.prototype = prototype;
    var o = new Ctor();
    if (prototype) { o.constructor = Ctor; }
    if (properties !== undefined) {
      if (properties !== Object(properties)) { throw TypeError(); }
      Object.defineProperties(o, properties);
    }
    return o;
  };
}

// ES 15.2.3.6 Object.defineProperty ( O, P, Attributes )
// Partial support for most common case - getters, setters, and values
(function() {
  if (!Object.defineProperty ||
      !(function () { try { Object.defineProperty({}, 'x', {}); return true; } catch (e) { return false; } } ())) {
    var orig = Object.defineProperty;
    Object.defineProperty = function (o, prop, desc) {
      // In IE8 try built-in implementation for defining properties on DOM prototypes.
      if (orig) { try { return orig(o, prop, desc); } catch (e) {} }

      if (o !== Object(o)) { throw TypeError("Object.defineProperty called on non-object"); }
      if (Object.prototype.__defineGetter__ && ('get' in desc)) {
        Object.prototype.__defineGetter__.call(o, prop, desc.get);
      }
      if (Object.prototype.__defineSetter__ && ('set' in desc)) {
        Object.prototype.__defineSetter__.call(o, prop, desc.set);
      }
      if ('value' in desc) {
        o[prop] = desc.value;
      }
      return o;
    };
  }
}());

// ES 15.2.3.7 Object.defineProperties ( O, Properties )
if (typeof Object.defineProperties !== "function") {
  Object.defineProperties = function (o, properties) {
    if (o !== Object(o)) { throw TypeError("Object.defineProperties called on non-object"); }
    var name;
    for (name in properties) {
      if (Object.prototype.hasOwnProperty.call(properties, name)) {
        Object.defineProperty(o, name, properties[name]);
      }
    }
    return o;
  };
}


// ES5 15.2.3.14 Object.keys ( O )
// https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object/keys
if (!Object.keys) {
  Object.keys = function (o) {
    if (o !== Object(o)) { throw TypeError('Object.keys called on non-object'); }
    var ret = [], p;
    for (p in o) {
      if (Object.prototype.hasOwnProperty.call(o, p)) {
        ret.push(p);
      }
    }
    return ret;
  };
}

//----------------------------------------------------------------------
// ES5 15.3 Function Objects
//----------------------------------------------------------------------

//
// ES5 15.3.4 Properties of the Function Prototype Object
//

// ES5 15.3.4.5 Function.prototype.bind ( thisArg [, arg1 [, arg2, ... ]] )
// https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function/bind
if (!Function.prototype.bind) {
  Function.prototype.bind = function (o) {
    if (typeof this !== 'function') { throw TypeError("Bind must be called on a function"); }
    var slice = [].slice,
        args = slice.call(arguments, 1),
        self = this,
        bound = function () {
          return self.apply(this instanceof nop ? this : o,
                            args.concat(slice.call(arguments)));
        };

    function nop() {}
    nop.prototype = self.prototype;
    bound.prototype = new nop();
    return bound;
  };
}


//----------------------------------------------------------------------
// ES5 15.4 Array Objects
//----------------------------------------------------------------------

//
// ES5 15.4.3 Properties of the Array Constructor
//


// ES5 15.4.3.2 Array.isArray ( arg )
// https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/isArray
Array.isArray = Array.isArray || function (o) { return Boolean(o && Object.prototype.toString.call(Object(o)) === '[object Array]'); };


//
// ES5 15.4.4 Properties of the Array Prototype Object
//

// ES5 15.4.4.14 Array.prototype.indexOf ( searchElement [ , fromIndex ] )
// From https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/indexOf
if (!Array.prototype.indexOf) {
  Array.prototype.indexOf = function (searchElement /*, fromIndex */) {
    if (this === void 0 || this === null) { throw TypeError(); }

    var t = Object(this);
    var len = t.length >>> 0;
    if (len === 0) { return -1; }

    var n = 0;
    if (arguments.length > 0) {
      n = Number(arguments[1]);
      if (isNaN(n)) {
        n = 0;
      } else if (n !== 0 && n !== (1 / 0) && n !== -(1 / 0)) {
        n = (n > 0 || -1) * Math.floor(Math.abs(n));
      }
    }

    if (n >= len) { return -1; }

    var k = n >= 0 ? n : Math.max(len - Math.abs(n), 0);

    for (; k < len; k++) {
      if (k in t && t[k] === searchElement) {
        return k;
      }
    }
    return -1;
  };
}

// ES5 15.4.4.15 Array.prototype.lastIndexOf ( searchElement [ , fromIndex ] )
// From https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/lastIndexOf
if (!Array.prototype.lastIndexOf) {
  Array.prototype.lastIndexOf = function (searchElement /*, fromIndex*/) {
    if (this === void 0 || this === null) { throw TypeError(); }

    var t = Object(this);
    var len = t.length >>> 0;
    if (len === 0) { return -1; }

    var n = len;
    if (arguments.length > 1) {
      n = Number(arguments[1]);
      if (n !== n) {
        n = 0;
      } else if (n !== 0 && n !== (1 / 0) && n !== -(1 / 0)) {
        n = (n > 0 || -1) * Math.floor(Math.abs(n));
      }
    }

    var k = n >= 0 ? Math.min(n, len - 1) : len - Math.abs(n);

    for (; k >= 0; k--) {
      if (k in t && t[k] === searchElement) {
        return k;
      }
    }
    return -1;
  };
}

// ES5 15.4.4.16 Array.prototype.every ( callbackfn [ , thisArg ] )
// From https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/every
if (!Array.prototype.every) {
  Array.prototype.every = function (fun /*, thisp */) {
    if (this === void 0 || this === null) { throw TypeError(); }

    var t = Object(this);
    var len = t.length >>> 0;
    if (typeof fun !== "function") { throw TypeError(); }

    var thisp = arguments[1], i;
    for (i = 0; i < len; i++) {
      if (i in t && !fun.call(thisp, t[i], i, t)) {
        return false;
      }
    }

    return true;
  };
}

// ES5 15.4.4.17 Array.prototype.some ( callbackfn [ , thisArg ] )
// From https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/some
if (!Array.prototype.some) {
  Array.prototype.some = function (fun /*, thisp */) {
    if (this === void 0 || this === null) { throw TypeError(); }

    var t = Object(this);
    var len = t.length >>> 0;
    if (typeof fun !== "function") { throw TypeError(); }

    var thisp = arguments[1], i;
    for (i = 0; i < len; i++) {
      if (i in t && fun.call(thisp, t[i], i, t)) {
        return true;
      }
    }

    return false;
  };
}

// ES5 15.4.4.18 Array.prototype.forEach ( callbackfn [ , thisArg ] )
// From https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/forEach
if (!Array.prototype.forEach) {
  Array.prototype.forEach = function (fun /*, thisp */) {
    if (this === void 0 || this === null) { throw TypeError(); }

    var t = Object(this);
    var len = t.length >>> 0;
    if (typeof fun !== "function") { throw TypeError(); }

    var thisp = arguments[1], i;
    for (i = 0; i < len; i++) {
      if (i in t) {
        fun.call(thisp, t[i], i, t);
      }
    }
  };
}


// ES5 15.4.4.19 Array.prototype.map ( callbackfn [ , thisArg ] )
// From https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/Map
if (!Array.prototype.map) {
  Array.prototype.map = function (fun /*, thisp */) {
    if (this === void 0 || this === null) { throw TypeError(); }

    var t = Object(this);
    var len = t.length >>> 0;
    if (typeof fun !== "function") { throw TypeError(); }

    var res = []; res.length = len;
    var thisp = arguments[1], i;
    for (i = 0; i < len; i++) {
      if (i in t) {
        res[i] = fun.call(thisp, t[i], i, t);
      }
    }

    return res;
  };
}

// ES5 15.4.4.20 Array.prototype.filter ( callbackfn [ , thisArg ] )
// From https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/Filter
if (!Array.prototype.filter) {
  Array.prototype.filter = function (fun /*, thisp */) {
    if (this === void 0 || this === null) { throw TypeError(); }

    var t = Object(this);
    var len = t.length >>> 0;
    if (typeof fun !== "function") { throw TypeError(); }

    var res = [];
    var thisp = arguments[1], i;
    for (i = 0; i < len; i++) {
      if (i in t) {
        var val = t[i]; // in case fun mutates this
        if (fun.call(thisp, val, i, t)) {
          res.push(val);
        }
      }
    }

    return res;
  };
}


// ES5 15.4.4.21 Array.prototype.reduce ( callbackfn [ , initialValue ] )
// From https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/Reduce
if (!Array.prototype.reduce) {
  Array.prototype.reduce = function (fun /*, initialValue */) {
    if (this === void 0 || this === null) { throw TypeError(); }

    var t = Object(this);
    var len = t.length >>> 0;
    if (typeof fun !== "function") { throw TypeError(); }

    // no value to return if no initial value and an empty array
    if (len === 0 && arguments.length === 1) { throw TypeError(); }

    var k = 0;
    var accumulator;
    if (arguments.length >= 2) {
      accumulator = arguments[1];
    } else {
      do {
        if (k in t) {
          accumulator = t[k++];
          break;
        }

        // if array contains no values, no initial value to return
        if (++k >= len) { throw TypeError(); }
      }
      while (true);
    }

    while (k < len) {
      if (k in t) {
        accumulator = fun.call(undefined, accumulator, t[k], k, t);
      }
      k++;
    }

    return accumulator;
  };
}


// ES5 15.4.4.22 Array.prototype.reduceRight ( callbackfn [, initialValue ] )
// From https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/ReduceRight
if (!Array.prototype.reduceRight) {
  Array.prototype.reduceRight = function (callbackfn /*, initialValue */) {
    if (this === void 0 || this === null) { throw TypeError(); }

    var t = Object(this);
    var len = t.length >>> 0;
    if (typeof callbackfn !== "function") { throw TypeError(); }

    // no value to return if no initial value, empty array
    if (len === 0 && arguments.length === 1) { throw TypeError(); }

    var k = len - 1;
    var accumulator;
    if (arguments.length >= 2) {
      accumulator = arguments[1];
    } else {
      do {
        if (k in this) {
          accumulator = this[k--];
          break;
        }

        // if array contains no values, no initial value to return
        if (--k < 0) { throw TypeError(); }
      }
      while (true);
    }

    while (k >= 0) {
      if (k in t) {
        accumulator = callbackfn.call(undefined, accumulator, t[k], k, t);
      }
      k--;
    }

    return accumulator;
  };
}


//----------------------------------------------------------------------
// ES5 15.5 String Objects
//----------------------------------------------------------------------

//
// ES5 15.5.4 Properties of the String Prototype Object
//


// ES5 15.5.4.20 String.prototype.trim()
if (!String.prototype.trim) {
  String.prototype.trim = function () {
    return String(this).replace(/^\s+/, '').replace(/\s+$/, '');
  };
}



//----------------------------------------------------------------------
// ES5 15.9 Date Objects
//----------------------------------------------------------------------


//
// ES 15.9.4 Properties of the Date Constructor
//

// ES5 15.9.4.4 Date.now ( )
// From https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Global_Objects/Date/now
if (!Date.now) {
  Date.now = function now() {
    return Number(new Date());
  };
}


//
// ES5 15.9.5 Properties of the Date Prototype Object
//

// ES5 15.9.4.43 Date.prototype.toISOString ( )
// Inspired by http://www.json.org/json2.js
if (!Date.prototype.toISOString) {
  Date.prototype.toISOString = function () {
    function pad2(n) { return ('00' + n).slice(-2); }
    function pad3(n) { return ('000' + n).slice(-3); }

    return this.getUTCFullYear() + '-' +
      pad2(this.getUTCMonth() + 1) + '-' +
      pad2(this.getUTCDate()) + 'T' +
      pad2(this.getUTCHours()) + ':' +
      pad2(this.getUTCMinutes()) + ':' +
      pad2(this.getUTCSeconds()) + '.' +
      pad3(this.getUTCMilliseconds()) + 'Z';
  };
}
;
/*! (C) WebReflection Mit Style License */

(function(e){function m(e,t,n,r){for(var i,s=n.slice(),o=b(t,e),u=0,a=s.length;u<a;u++){handler=s[u],typeof handler=="object"&&typeof handler.handleEvent=="function"?handler.handleEvent(o):handler.call(e,o);if(o.stoppedImmediatePropagation)break}return i=!o.stoppedPropagation,r&&i&&e.parentNode?e.parentNode.dispatchEvent(o):!o.defaultPrevented}function g(e,t){return{configurable:!0,get:e,set:t}}function y(e,t,n){var r=a(t||e,n);o(e,"textContent",g(function(){return r.get.call(this)},function(e){r.set.call(this,e)}))}function b(e,t){return e.currentTarget=t,e.eventPhase=e.target===e.currentTarget?2:3,e}function w(e,t){var n=e.length;while(n--&&e[n]!==t);return n}function E(){if(this.tagName==="BR")return"\n";var e=this.firstChild,t=[];while(e)e.nodeType!==8&&e.nodeType!==7&&t.push(e.textContent),e=e.nextSibling;return t.join("")}function S(e){return e.nodeType!==9&&document.documentElement.contains(e)}function x(e){var t=document.createEvent("Event");t.initEvent("input",!0,!0),(e.srcElement||e.fromElement||document).dispatchEvent(t)}function T(e){!n&&p.test(document.readyState)&&(n=!n,document.detachEvent(r,T),e=document.createEvent("Event"),e.initEvent(i,!0,!0),document.dispatchEvent(e))}function N(e){var t;while(t=this.lastChild)this.removeChild(t);e!=null&&this.appendChild(document.createTextNode(e))}function C(t,n){return n||(n=e.event),n.target||(n.target=n.srcElement||n.fromElement||document),n.timeStamp||(n.timeStamp=(new Date).getTime()),n}if(document.createEvent)return;var t=!0,n=!1,r="onreadystatechange",i="DOMContentLoaded",s="__IE8__"+Math.random(),o=Object.defineProperty||function(e,t,n){e[t]=n.value},u=Object.defineProperties||function(t,n){for(var r in n)if(f.call(n,r))try{o(t,r,n[r])}catch(i){e.console&&console.log(r+" failed on object:",t,i.message)}},a=Object.getOwnPropertyDescriptor,f=Object.prototype.hasOwnProperty,l=e.Element.prototype,c=e.Text.prototype,h=/^[a-z]+$/,p=/loaded|complete/,d={},v=document.createElement("div");y(e.HTMLCommentElement.prototype,l,"nodeValue"),y(e.HTMLScriptElement.prototype,null,"text"),y(c,null,"nodeValue"),y(e.HTMLTitleElement.prototype,null,"text"),o(e.HTMLStyleElement.prototype,"textContent",function(e){return g(function(){return e.get.call(this.styleSheet)},function(t){e.set.call(this.styleSheet,t)})}(a(e.CSSStyleSheet.prototype,"cssText"))),u(l,{textContent:{get:E,set:N},firstElementChild:{get:function(){for(var e=this.childNodes||[],t=0,n=e.length;t<n;t++)if(e[t].nodeType==1)return e[t]}},lastElementChild:{get:function(){for(var e=this.childNodes||[],t=e.length;t--;)if(e[t].nodeType==1)return e[t]}},oninput:{get:function(){return this._oninput||null},set:function(e){this._oninput&&(this.removeEventListener("input",this._oninput),this._oninput=e,e&&this.addEventListener("input",e))}},previousElementSibling:{get:function(){var e=this.previousSibling;while(e&&e.nodeType!=1)e=e.previousSibling;return e}},nextElementSibling:{get:function(){var e=this.nextSibling;while(e&&e.nodeType!=1)e=e.nextSibling;return e}},childElementCount:{get:function(){for(var e=0,t=this.childNodes||[],n=t.length;n--;e+=t[n].nodeType==1);return e}},addEventListener:{value:function(e,t,n){var r=this,i="on"+e,u=r[s]||o(r,s,{value:{}})[s],a=u[i]||(u[i]={}),l=a.h||(a.h=[]),c;if(!f.call(a,"w")){a.w=function(e){return e[s]||m(r,C(r,e),l,!1)};if(!f.call(d,i))if(h.test(e))try{c=document.createEventObject(),c[s]=!0,r.nodeType!=9&&r.parentNode==null&&v.appendChild(r),r.fireEvent(i,c),d[i]=!0}catch(c){d[i]=!1;while(v.hasChildNodes())v.removeChild(v.firstChild)}else d[i]=!1;(a.n=d[i])&&r.attachEvent(i,a.w)}w(l,t)<0&&l[n?"unshift":"push"](t),e==="input"&&r.attachEvent("onkeyup",x)}},dispatchEvent:{value:function(e){var t=this,n="on"+e.type,r=t[s],i=r&&r[n],o=!!i,u;return e.target||(e.target=t),o?i.n?t.fireEvent(n,e):m(t,e,i.h,!0):(u=t.parentNode)?u.dispatchEvent(e):!0,!e.defaultPrevented}},removeEventListener:{value:function(e,t,n){var r=this,i="on"+e,o=r[s],u=o&&o[i],a=u&&u.h,f=a?w(a,t):-1;-1<f&&a.splice(f,1)}}}),u(HTMLSelectElement,{value:{get:function(){return this.options[this.selectedIndex].value}}}),u(c,{addEventListener:{value:l.addEventListener},dispatchEvent:{value:l.dispatchEvent},removeEventListener:{value:l.removeEventListener}}),u(e.XMLHttpRequest.prototype,{addEventListener:{value:function(e,t,n){var r=this,i="on"+e,u=r[s]||o(r,s,{value:{}})[s],a=u[i]||(u[i]={}),f=a.h||(a.h=[]);w(f,t)<0&&(r[i]||(r[i]=function(){var t=document.createEvent("Event");t.initEvent(e,!0,!0),r.dispatchEvent(t)}),f[n?"unshift":"push"](t))}},dispatchEvent:{value:function(e){var t=this,n="on"+e.type,r=t[s],i=r&&r[n],o=!!i;return o&&(i.n?t.fireEvent(n,e):m(t,e,i.h,!0))}},removeEventListener:{value:l.removeEventListener}}),u(e.Event.prototype,{bubbles:{value:!0,writable:!0},cancelable:{value:!0,writable:!0},preventDefault:{value:function(){this.cancelable&&(this.defaultPrevented=!0,this.returnValue=!1)}},stopPropagation:{value:function(){this.stoppedPropagation=!0,this.cancelBubble=!0}},stopImmediatePropagation:{value:function(){this.stoppedImmediatePropagation=!0,this.stopPropagation()}},initEvent:{value:function(e,t,n){this.type=e,this.bubbles=!!t,this.cancelable=!!n,this.bubbles||this.stopPropagation()}}}),u(e.HTMLDocument.prototype,{defaultView:{get:function(){return this.parentWindow}},textContent:{get:function(){return this.nodeType===11?E.call(this):null},set:function(e){this.nodeType===11&&N.call(this,e)}},addEventListener:{value:function(n,s,o){var u=this;l.addEventListener.call(u,n,s,o),t&&n===i&&!p.test(u.readyState)&&(t=!1,u.attachEvent(r,T),e==top&&function a(e){try{u.documentElement.doScroll("left"),T()}catch(t){setTimeout(a,50)}}())}},dispatchEvent:{value:l.dispatchEvent},removeEventListener:{value:l.removeEventListener},createEvent:{value:function(e){var t;if(e!=="Event")throw new Error("unsupported "+e);return t=document.createEventObject(),t.timeStamp=(new Date).getTime(),t}}}),u(e.Window.prototype,{getComputedStyle:{value:function(){function i(e){this._=e}function s(){}var e=/^(?:[+-]?(?:\d*\.|)\d+(?:[eE][+-]?\d+|))(?!px)[a-z%]+$/,t=/^(top|right|bottom|left)$/,n=/\-([a-z])/g,r=function(e,t){return t.toUpperCase()};return i.prototype.getPropertyValue=function(i){var s=this._,o=s.style,u=s.currentStyle,a=s.runtimeStyle,f,l,c;return i=(i==="float"?"style-float":i).replace(n,r),f=u?u[i]:o[i],e.test(f)&&!t.test(i)&&(l=o.left,c=a&&a.left,c&&(a.left=u.left),o.left=i==="fontSize"?"1em":f,f=o.pixelLeft+"px",o.left=l,c&&(a.left=c)),f==null?f:f+""||"auto"},s.prototype.getPropertyValue=function(){return null},function(e,t){return t?new s(e):new i(e)}}()},addEventListener:{value:function(t,n,r){var i=e,o="on"+t,u;i[o]||(i[o]=function(e){return m(i,C(i,e),u,!1)}),u=i[o][s]||(i[o][s]=[]),w(u,n)<0&&u[r?"unshift":"push"](n)}},dispatchEvent:{value:function(t){var n=e["on"+t.type];return n?n.call(e,t)!==!1&&!t.defaultPrevented:!0}},removeEventListener:{value:function(t,n,r){var i="on"+t,o=(e[i]||Object)[s],u=o?w(o,n):-1;-1<u&&o.splice(u,1)}}}),function(e,t,n){for(n=0;n<t.length;n++)document.createElement(t[n]);e.length||document.createStyleSheet(""),e[0].addRule(t.join(","),"display:block;")}(document.styleSheets,["header","nav","section","article","aside","footer"])})(this);
/*! matchMedia() polyfill - Test a CSS media type/query in JS. Authors & copyright (c) 2012: Scott Jehl, Paul Irish, Nicholas Zakas. Dual MIT/BSD license */
/*! NOTE: If you're already including a window.matchMedia polyfill via Modernizr or otherwise, you don't need this part */

(function(w) {
  "use strict";
  w.matchMedia = w.matchMedia || function(doc, undefined) {
    var bool, docElem = doc.documentElement, refNode = docElem.firstElementChild || docElem.firstChild, fakeBody = doc.createElement("body"), div = doc.createElement("div");
    div.id = "mq-test-1";
    div.style.cssText = "position:absolute;top:-100em";
    fakeBody.style.background = "none";
    fakeBody.appendChild(div);
    return function(q) {
      div.innerHTML = '&shy;<style media="' + q + '"> #mq-test-1 { width: 42px; }</style>';
      docElem.insertBefore(fakeBody, refNode);
      bool = div.offsetWidth === 42;
      docElem.removeChild(fakeBody);
      return {
        matches: bool,
        media: q
      };
    };
  }(w.document);
})(this);

/*! Respond.js v1.4.0: min/max-width media query polyfill. (c) Scott Jehl. MIT Lic. j.mp/respondjs  */
(function(w) {
  "use strict";
  var respond = {};
  w.respond = respond;
  respond.update = function() {};
  var requestQueue = [], xmlHttp = function() {
    var xmlhttpmethod = false;
    try {
      xmlhttpmethod = new w.XMLHttpRequest();
    } catch (e) {
      xmlhttpmethod = new w.ActiveXObject("Microsoft.XMLHTTP");
    }
    return function() {
      return xmlhttpmethod;
    };
  }(), ajax = function(url, callback) {
    var req = xmlHttp();
    if (!req) {
      return;
    }
    req.open("GET", url, true);
    req.onreadystatechange = function() {
      if (req.readyState !== 4 || req.status !== 200 && req.status !== 304) {
        return;
      }
      callback(req.responseText);
    };
    if (req.readyState === 4) {
      return;
    }
    req.send(null);
  };
  respond.ajax = ajax;
  respond.queue = requestQueue;
  respond.regex = {
    media: /@media[^\{]+\{([^\{\}]*\{[^\}\{]*\})+/gi,
    keyframes: /@(?:\-(?:o|moz|webkit)\-)?keyframes[^\{]+\{(?:[^\{\}]*\{[^\}\{]*\})+[^\}]*\}/gi,
    urls: /(url\()['"]?([^\/\)'"][^:\)'"]+)['"]?(\))/g,
    findStyles: /@media *([^\{]+)\{([\S\s]+?)$/,
    only: /(only\s+)?([a-zA-Z]+)\s?/,
    minw: /\([\s]*min\-width\s*:[\s]*([\s]*[0-9\.]+)(px|em)[\s]*\)/,
    maxw: /\([\s]*max\-width\s*:[\s]*([\s]*[0-9\.]+)(px|em)[\s]*\)/
  };
  respond.mediaQueriesSupported = w.matchMedia && w.matchMedia("only all") !== null && w.matchMedia("only all").matches;
  if (respond.mediaQueriesSupported) {
    return;
  }
  var doc = w.document, docElem = doc.documentElement, mediastyles = [], rules = [], appendedEls = [], parsedSheets = {}, resizeThrottle = 30, head = doc.getElementsByTagName("head")[0] || docElem, base = doc.getElementsByTagName("base")[0], links = head.getElementsByTagName("link"), lastCall, resizeDefer, eminpx, getEmValue = function() {
    var ret, div = doc.createElement("div"), body = doc.body, originalHTMLFontSize = docElem.style.fontSize, originalBodyFontSize = body && body.style.fontSize, fakeUsed = false;
    div.style.cssText = "position:absolute;font-size:1em;width:1em";
    if (!body) {
      body = fakeUsed = doc.createElement("body");
      body.style.background = "none";
    }
    docElem.style.fontSize = "100%";
    body.style.fontSize = "100%";
    body.appendChild(div);
    if (fakeUsed) {
      docElem.insertBefore(body, docElem.firstChild);
    }
    ret = div.offsetWidth;
    if (fakeUsed) {
      docElem.removeChild(body);
    } else {
      body.removeChild(div);
    }
    docElem.style.fontSize = originalHTMLFontSize;
    if (originalBodyFontSize) {
      body.style.fontSize = originalBodyFontSize;
    }
    ret = eminpx = parseFloat(ret);
    return ret;
  }, applyMedia = function(fromResize) {
    var name = "clientWidth", docElemProp = docElem[name], currWidth = doc.compatMode === "CSS1Compat" && docElemProp || doc.body[name] || docElemProp, styleBlocks = {}, lastLink = links[links.length - 1], now = new Date().getTime();
    if (fromResize && lastCall && now - lastCall < resizeThrottle) {
      w.clearTimeout(resizeDefer);
      resizeDefer = w.setTimeout(applyMedia, resizeThrottle);
      return;
    } else {
      lastCall = now;
    }
    for (var i in mediastyles) {
      if (mediastyles.hasOwnProperty(i)) {
        var thisstyle = mediastyles[i], min = thisstyle.minw, max = thisstyle.maxw, minnull = min === null, maxnull = max === null, em = "em";
        if (!!min) {
          min = parseFloat(min) * (min.indexOf(em) > -1 ? eminpx || getEmValue() : 1);
        }
        if (!!max) {
          max = parseFloat(max) * (max.indexOf(em) > -1 ? eminpx || getEmValue() : 1);
        }
        if (!thisstyle.hasquery || (!minnull || !maxnull) && (minnull || currWidth >= min) && (maxnull || currWidth <= max)) {
          if (!styleBlocks[thisstyle.media]) {
            styleBlocks[thisstyle.media] = [];
          }
          styleBlocks[thisstyle.media].push(rules[thisstyle.rules]);
        }
      }
    }
    for (var j in appendedEls) {
      if (appendedEls.hasOwnProperty(j)) {
        if (appendedEls[j] && appendedEls[j].parentNode === head) {
          head.removeChild(appendedEls[j]);
        }
      }
    }
    appendedEls.length = 0;
    for (var k in styleBlocks) {
      if (styleBlocks.hasOwnProperty(k)) {
        var ss = doc.createElement("style"), css = styleBlocks[k].join("\n");
        ss.type = "text/css";
        ss.media = k;
        head.insertBefore(ss, lastLink.nextSibling);
        if (ss.styleSheet) {
          ss.styleSheet.cssText = css;
        } else {
          ss.appendChild(doc.createTextNode(css));
        }
        appendedEls.push(ss);
      }
    }
  }, translate = function(styles, href, media) {
    var qs = styles.replace(respond.regex.keyframes, "").match(respond.regex.media), ql = qs && qs.length || 0;
    href = href.substring(0, href.lastIndexOf("/"));
    var repUrls = function(css) {
      return css.replace(respond.regex.urls, "$1" + href + "$2$3");
    }, useMedia = !ql && media;
    if (href.length) {
      href += "/";
    }
    if (useMedia) {
      ql = 1;
    }
    for (var i = 0; i < ql; i++) {
      var fullq, thisq, eachq, eql;
      if (useMedia) {
        fullq = media;
        rules.push(repUrls(styles));
      } else {
        fullq = qs[i].match(respond.regex.findStyles) && RegExp.$1;
        rules.push(RegExp.$2 && repUrls(RegExp.$2));
      }
      eachq = fullq.split(",");
      eql = eachq.length;
      for (var j = 0; j < eql; j++) {
        thisq = eachq[j];
        mediastyles.push({
          media: thisq.split("(")[0].match(respond.regex.only) && RegExp.$2 || "all",
          rules: rules.length - 1,
          hasquery: thisq.indexOf("(") > -1,
          minw: thisq.match(respond.regex.minw) && parseFloat(RegExp.$1) + (RegExp.$2 || ""),
          maxw: thisq.match(respond.regex.maxw) && parseFloat(RegExp.$1) + (RegExp.$2 || "")
        });
      }
    }
    applyMedia();
  }, makeRequests = function() {
    if (requestQueue.length) {
      var thisRequest = requestQueue.shift();
      ajax(thisRequest.href, function(styles) {
        translate(styles, thisRequest.href, thisRequest.media);
        parsedSheets[thisRequest.href] = true;
        w.setTimeout(function() {
          makeRequests();
        }, 0);
      });
    }
  }, ripCSS = function() {
    for (var i = 0; i < links.length; i++) {
      var sheet = links[i], href = sheet.href, media = sheet.media, isCSS = sheet.rel && sheet.rel.toLowerCase() === "stylesheet";
      if (!!href && isCSS && !parsedSheets[href]) {
        if (sheet.styleSheet && sheet.styleSheet.rawCssText) {
          translate(sheet.styleSheet.rawCssText, href, media);
          parsedSheets[href] = true;
        } else {
          if (!/^([a-zA-Z:]*\/\/)/.test(href) && !base || href.replace(RegExp.$1, "").split("/")[0] === w.location.host) {
            if (href.substring(0, 2) === "//") {
              href = w.location.protocol + href;
            }
            requestQueue.push({
              href: href,
              media: media
            });
          }
        }
      }
    }
    makeRequests();
  };
  ripCSS();
  respond.update = ripCSS;
  respond.getEmValue = getEmValue;
  function callMedia() {
    applyMedia(true);
  }
  if (w.addEventListener) {
    w.addEventListener("resize", callMedia, false);
  } else if (w.attachEvent) {
    w.attachEvent("onresize", callMedia);
  }
})(this);
(function() {


}).call(this);
