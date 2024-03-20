import FORM_FACTOR from '@salesforce/client/formFactor';

const getMapWeekdayIndex = function(firstDayOfWeek = 'sun') {
    let mapWeekdayIndex = new Map();
    mapWeekdayIndex.set('sun', 0);
    mapWeekdayIndex.set('mon', 1);
    mapWeekdayIndex.set('tue', 2);
    mapWeekdayIndex.set('wed', 3);
    mapWeekdayIndex.set('thu', 4);
    mapWeekdayIndex.set('fri', 5);
    mapWeekdayIndex.set('sat', 6);

    const mapSize = mapWeekdayIndex.size;
    const currentFirstDayIndex = mapWeekdayIndex.get(firstDayOfWeek);
    const difference = mapSize - currentFirstDayIndex;
    Array.from(mapWeekdayIndex.keys()).forEach((weekday) => {
        let index = mapWeekdayIndex.get(weekday);
        index = (index + difference) % mapSize;
        mapWeekdayIndex.set(weekday, index);
    });

    return mapWeekdayIndex;
}

const getUserPreferences = function() {
    let userPreferences = {};
    if (localStorage.getItem('arcUserPreferences')) {
        userPreferences = JSON.parse(localStorage.getItem('arcUserPreferences'));
    }
    else {
        userPreferences = {
            mapLastQuery: new Map()
        };
        localStorage.setItem('arcUserPreferences', JSON.stringify(userPreferences));
    }
    return userPreferences;
}

const getLastQuery = function(cmpName) {
    let userPreferences = getUserPreferences();
    return userPreferences.mapLastQuery[cmpName];
}

const setLastQuery = function(cmpName, queryModel) {
    let userPreferences = getUserPreferences();
    if (!userPreferences.mapLastQuery) {
        userPreferences.mapLastQuery = new Map();
    }
    userPreferences.mapLastQuery[cmpName] = queryModel;
    localStorage.setItem('arcUserPreferences', JSON.stringify(userPreferences));
}
const isDesktop = function() {
    return FORM_FACTOR === 'Large';
}

const isMobile = function() {
    if(FORM_FACTOR === 'Small') return true;

    let check = false;
    (function(a){if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino|android|ipad|playbook|silk/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0,4))) check = true;})(navigator.userAgent||navigator.vendor||window.opera);
    return check;
}

const isTablet = function() {
    return FORM_FACTOR === 'Medium';
}

const getValueFromEvent = function(event){
    let result;
    if (event.target && event.target.type) {
        if (event.target.type === 'checkbox' || event.target.type === 'toggle') {
            return event.target.checked;
        }
        else if (event.target.type === 'number') {
            return !isNullOrEmpty(event.target.value) ? Number(event.target.value) : null;
        } 
        else {
            return event.target.value;
        }
    }
    if (event.detail) {
        if (event.detail.selectedValue) {
            result = event.detail.selectedValue;
        }
        else if (event.detail.value) {
            result = event.detail.value;
        }
        else if (event.detail.selectedValues) {
            result = [];
            event.detail.selectedValues.forEach((item) => {
                result.push(item.value);
            });
        }
    }
    return result;
};

const convertTimeToTimeStr = function(timeVal) {
    let ms = timeVal % 1000;
    timeVal = (timeVal - ms) / 1000;
    let secs = timeVal % 60;
    timeVal = (timeVal - secs) / 60;
    let mins = timeVal % 60;
    let hrs = (timeVal - mins) / 60;

    return padZeroLeft(hrs) + ':' + padZeroLeft(mins) + ':' + padZeroLeft(secs) + '.' + padZeroLeft(ms, 3);
}

const convertTimeStrToTime = function(timeStr) {
    let timeParts = timeStr.split(".");
    let ms = Number(timeParts[1]);
    let hourParts = timeParts[0].split(":");
    let hour = Number(hourParts[0]);
    let minute = Number(hourParts[1]);
    let second = Number(hourParts[2]);

    return hour * 3600000 + minute * 60000 + second * 1000 + ms;
}

const padZeroLeft = function(str, max) {
    max = max || 2;
    str = str.toString();
    return str.length < max ? padZeroLeft("0" + str, max) : str;
}

const classNames = function(){
  let classes = [];
  let hasOwn = {}.hasOwnProperty;

  for (let i = 0; i < arguments.length; i++) {
    let arg = arguments[i];
    if (!arg) continue;

    let argType = typeof arg;

    if (argType === 'string' || argType === 'number') {
      classes.push(arg);
    } else if (Array.isArray(arg)) {
      if (arg.length) {
        let inner = classNames.apply(null, arg);
        if (inner) {
          classes.push(inner);
        }
      }
    } else if (argType === 'object') {
      if (arg.toString !== Object.prototype.toString) {
        classes.push(arg.toString());
      } else {
        for (let key in arg) {
          if (hasOwn.call(arg, key) && arg[key]) {
            classes.push(key);
          }
        }
      }
    }
  }

  return classes.join(' ');
}

const addAlphaToColor = function(color, alpha){
  if(!color) return null;
  var r,g,b;
  var isHex = color.indexOf('#') === 0 && color.length === 7;
  var isRgb = color.indexOf('rgb(') === 0 || color.indexOf('rgba(') === 0;
  if(isHex) {
      color = color.replace('#', '');
      r = parseInt(color.substring(0,2), 16);
      g = parseInt(color.substring(2,4), 16);
      b = parseInt(color.substring(4,6), 16);
  } else if(isRgb) {
      color = color.replace('rgb(', '').replace(')', '').replace('rgba(', '');
      var colorParts = color.split(',');
      r = parseInt(colorParts[0].trim(), 16);
      g = parseInt(colorParts[1].trim(), 16);
      b = parseInt(colorParts[2].trim(), 16);
  } else {
      return color;
  }
 
  return 'rgba(' + r + ',' + g + ',' + b + ',' + (alpha || 0) / 100 + ')';
}

const isNullOrEmpty = (value) => {
    return value === undefined || value === null || value === '';
};

const generateUUID = () => {
    return Math.random().toString(36).substring(2, 15);
}

const refreshLightningPage = () => {
    eval("$A.get('e.force:refreshView').fire();");
}

const camelize = (str) => {
    return str.replace(/(?:^\w|[A-Z]|\b\w)/g, function (word, index) {
        return index === 0 ? word.toLowerCase() : word.toUpperCase();
    }).replace(/\s+/g, '');
}

const serial = (tasks) => {
    let prevPromise = Promise.resolve();
    tasks.forEach(function (task) {
        //First task
        if (!prevPromise) {
            prevPromise = task();
        } else {
            prevPromise = prevPromise.then(task);
        }
    });
    return prevPromise;
}
const buildTree = (data = []) => {
    let r = [], o = {};
    data.forEach(function (a) {
        o[a.id] = {
            id: a.id,
            children: (o[a.id] && o[a.id].children) || []
        };
        if (!a.parentId) {
            r.push(o[a.id]);
        } else {
            if(o[a.parentId]) {
                o[a.parentId].children = o[a.parentId].children || [];
                o[a.parentId].children.push(o[a.id]);
            } else {
                r.push(o[a.id]);
            }
        }
    });
    return r;
}

const generateColors = (length = 0) => {
    const colors = [
        [
            "#64b5f6",
            "#42a5f5",
            "#2196f3",
            "#1e88e5",
            "#1976d2",
            "#1565c0",
            "#0d47a1",
            "#82b1ff",
            "#448aff",
            "#2979ff",
            "#2962ff"
        ],
        // [
        //     "#4dd0e1",
        //     "#26c6da",
        //     "#00bcd4",
        //     "#00acc1",
        //     "#0097a7",
        //     "#00838f",
        //     "#006064",
        //     "#84ffff",
        //     "#18ffff",
        //     "#00e5ff",
        //     "#00b8d4"
        // ],
        [
            "#4db6ac",
            "#26a69a",
            "#009688",
            "#00897b",
            "#00796b",
            "#00695c",
            "#004d40",
            "#a7ffeb",
            "#64ffda",
            "#1de9b6",
            "#00bfa5"
        ],
        [
            "#81c784",
            "#66bb6a",
            "#4caf50",
            "#43a047",
            "#388e3c",
            "#2e7d32",
            "#1b5e20",
            "#b9f6ca",
            "#69f0ae",
            "#00e676",
            "#00c853"
        ],
        [
            "#dce775",
            "#d4e157",
            "#cddc39",
            "#c0ca33",
            "#afb42b",
            "#9e9d24",
            "#827717",
            "#f4ff81",
            "#eeff41",
            "#c6ff00",
            "#aeea00"
        ],
        [
            "#fff176",
            "#ffee58",
            "#ffeb3b",
            "#fdd835",
            "#fbc02d",
            "#f9a825",
            "#f57f17",
            "#ffff8d",
            "#ffff00",
            "#ffea00",
            "#ffd600"
        ],
        [
            "#ffb74d",
            "#ffa726",
            "#ff9800",
            "#fb8c00",
            "#f57c00",
            "#ef6c00",
            "#e65100",
            "#ffd180",
            "#ffab40",
            "#ff9100",
            "#ff6d00"
        ],
        [
            "#ffab91",
            "#ff8a65",
            "#ff7043",
            "#ff5722",
            "#f4511e",
            "#e64a19",
            "#d84315",
            "#bf360c",
            "#ff9e80",
            "#ff6e40",
            "#ff3d00",
            "#dd2c00"
        ],
        [
            "#a1887f",
            "#8d6e63",
            "#795548",
            "#6d4c41",
            "#5d4037",
            "#4e342e",
            "#3e2723"
        ],
        [
            "#e57373",
            "#ef5350",
            "#f44336",
            "#e53935",
            "#d32f2f",
            "#c62828",
            "#b71c1c",
            "#ff8a80",
            "#ff5252",
            "#ff1744",
            "#d50000"
        ],
        [
            "#f06292",
            "#ec407a",
            "#e91e63",
            "#d81b60",
            "#c2185b",
            "#ad1457",
            "#880e4f",
            "#ff80ab",
            "#ff4081",
            "#f50057",
            "#c51162"
        ],
        [
            "#ba68c8",
            "#ab47bc",
            "#9c27b0",
            "#8e24aa",
            "#7b1fa2",
            "#6a1b9a",
            "#4a148c",
            "#ea80fc",
            "#e040fb",
            "#d500f9",
            "#aa00ff"
        ],
        [
            "#9575cd",
            "#7e57c2",
            "#673ab7",
            "#5e35b1",
            "#512da8",
            "#4527a0",
            "#311b92",
            "#b388ff",
            "#7c4dff",
            "#651fff",
            "#6200ea"
        ],
        [
            "#7986cb",
            "#5c6bc0",
            "#3f51b5",
            "#3949ab",
            "#303f9f",
            "#283593",
            "#1a237e",
            "#8c9eff",
            "#536dfe",
            "#3d5afe",
            "#304ffe"
        ]
    ];

    let generatedColors = [];
    let colorIndex = 0;
    for(let i = 0; i < length; i++) {
        let subColors = colors[colorIndex];
        generatedColors.push(subColors.shift());

        colorIndex++;
        if(colorIndex > colors.length) {
            colorIndex = 0;
        }
    }

    return generatedColors;
}

const parseJSON = (jsonString, fallbackResult = null) => {
    try {
        return JSON.parse(jsonString);
    } catch (e) {
        return fallbackResult;
    }
}

const jsonFriendlyErrorReplacer = (key, value) => {
    if (value instanceof Error) {
        return {
            // Pull all enumerable properties, supporting properties on custom Errors
            ...value,
            // Explicitly pull Error's non-enumerable properties
            name: value.name,
            message: value.message,
            stack: value.stack,
        }
    }
  
    return value
}

const getTravelTimeIndexKey = (fromLatitude, fromLongitude, toLatitude, toLongitude) => {
    return `${fromLatitude} ${fromLongitude}:${toLatitude} ${toLongitude}`;
}

const waitUntil = (func, intervalInMs = 5000, maxRunTimes = 0) => {
    let runTimes = 0;
    return new Promise((resolve, reject) => {
        const interval = setInterval(() => {
            if(maxRunTimes && runTimes >= maxRunTimes) {
                reject('error');
                clearInterval(interval);
                return;
            }

            return Promise.resolve()
            .then(() => {
                return func();
            })
            .then((result) => {
                if (result) {
                    resolve(result);
                    clearInterval(interval);
                }

                runTimes++;
            })
        }, intervalInMs);
    });
};

const isGeolocationValid = (placeDetails) => {
    return placeDetails && placeDetails.geometry && placeDetails.geometry.lat && placeDetails.geometry.lng;
}

export {
    isNullOrEmpty,
    generateUUID,
    convertTimeStrToTime,
    convertTimeToTimeStr,
    getLastQuery, setLastQuery,
    getMapWeekdayIndex,
    getValueFromEvent,
    padZeroLeft,
    classNames,
    addAlphaToColor,
    refreshLightningPage,
    camelize,
    serial,
    isDesktop,
    isMobile,
    isTablet,
    buildTree,
    generateColors,
    parseJSON,
    jsonFriendlyErrorReplacer,
    getTravelTimeIndexKey,
    waitUntil,
    isGeolocationValid
}