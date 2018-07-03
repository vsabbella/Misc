//recursive function to iterate over all properties of an object
//and sanitize the values for XSS vulnerabilities, etc. 
//relies on SecureFilters static resource
//see here for more info: https://github.com/SalesforceEng/secure-filters

var safeTypes = ["undefined", "boolean", "number"]; //these types don't need to be escaped

function sanitize(obj, method) {
	//console.log('obj');
	//console.log(obj);
	
	//console.log('typeof obj');
	//console.log(typeof obj);	
	
	if (obj == null) {
		return obj;
	}
	
	//some types are impossible to inject XSS into, so we'll just return those as is
	if (safeTypes.indexOf(typeof obj) != -1) {
		return obj;
	} 	
		
	var defaultMethod = 'html';
	var validMethods = ['html', 'js', 'jsAttr', 'uri'];
	
	if (method == null) {
		method = defaultMethod;
	}
	
	if (validMethods.indexOf(method) == -1) {
		throw 'Invalid sanitize method';
	}
	
	//check to see if it is just a string we are passing in:
	if (typeof obj == 'string') {
		return sanitizePreProcess(obj, method);
	} 	

	for (var property in obj) {
		if (obj.hasOwnProperty(property)) {
			if (typeof obj[property] == "object") {
				sanitize(obj[property], method);
			} else {
				//console.log(property + "   " + obj[property]);
				obj[property] = sanitizePreProcess(obj[property], method);
			}
		}
	}   
	return obj;    
}

//quick check to see if there is a hyperlink in the string
//<a href="/apex/InventoryMaster?id=a2B15000003Fi3B">SKID-0000000013</a> 
function sanitizePreProcess(primVal, method) {
    if (primVal != null) {
        
		//some types are impossible to inject XSS into, so we'll just return those as is
		if (safeTypes.indexOf(typeof primVal) != -1) {
			return primVal;
		}         
        
        if (typeof primVal == "string") {
	        if (primVal.toLowerCase().indexOf('</a>') == -1) {
		        //no hyperlinks, just sanitize and return
	            return sanitizePrimitive(primVal, method); 
	        } else {
	            //potentially 1 or more hyperlinks in the string.  Need to sanitize in pieces.
				return deconstruct(primVal, method);
	        }        
        }
        
    }
	
	return primVal;    
}


//this function tokenizes up a string into an array of string values and anchor tags
//and hands them off to be santized in the appropriate manner
//could be extended if needed to to include other tags beside anchor tags
function deconstruct(sVal, method) {
    var decon = [];
    var remaining = sVal;  
	var keepChecking = true;
    
    while (keepChecking) {
        var lcaseRemaining = remaining.toLowerCase();
        
		var tagStart = lcaseRemaining.indexOf('<a ');
		var tagEnd = lcaseRemaining.indexOf('</a>');        
        
        if ((tagStart == -1) || (tagEnd == -1) || (tagEnd < tagStart)) {
        	//missing a start/end tag, or end is before start - just push the remaining into a string
            decon.push({type:'string', value:remaining});
            keepChecking = false;
            break;
        } else {
            //store anything before the anchor tag
            if (tagStart > 0) {
                var sBefore = remaining.substring(0, tagStart);
                decon.push({type:'string', value:sBefore});                
            }
            
            //get the complete anchor tag
            var anchorTag = remaining.substring(tagStart, tagEnd+4);
            decon.push({type:'anchor', value:anchorTag});   

            //store the remaining pieces of the string
            remaining = remaining.substring(tagEnd+4);
        }
    }

    //loop through our deconstructed pieces and sanitize them
    var recon = '';
    var failureCount = 0;
    for (var i=0; i<decon.length; i++) {
        if (decon[i].type == 'anchor') {
            var anchorObj = sanitizeAnchorTag(decon[i].value, method);
			var anchor = '';
            
            if (anchorObj.success) {
                var target = '';
                if (anchorObj.target != null) {
	                target = ' target="' + anchorObj.target + '"'; 
                }
            	recon += '<a href="'+anchorObj.href+'"'+target+'>'+anchorObj.text+'</a>';    
            } else {
                failureCount++;
            }
        } else if (decon[i].type == 'string') {
            recon += sanitizePrimitive(decon[i].value, method);
        }
    }
    
    if (failureCount > 0) {
        //if any of the anchor tags failed sanitization,
        //revert to just sanitizing the entire original string
    	recon = sanitizePrimitive(sVal, method);
    }
	
	return recon;
}


//this function takes in a full anchor tag like this:
//<a href="/apex/InventoryMaster?id=a2B15000003Fi3B">SKID-0000000013</a>
//and sanitizes the href, target, and text inside the tag
//the href URL is handed off to another function to sanitize it.
function sanitizeAnchorTag(link, method) {
    var anchorObj = {success:false, href:null, target:null, text:null};    
    try {
		//we are going to parse
		//<a href="/page" target="_blank">text</a>
		//at the string level, since it is to risky to do XML parsing for XSS vulnerability reasons

        //===================== parse out the text value
		var closeBracketIndex = link.indexOf('>');
    	var text = link.substring(closeBracketIndex+1);
        var textLcase = text.toLowerCase();
        var closeBracketIndex = textLcase.indexOf('</a>');
        text = text.substring(0, closeBracketIndex);
		//=====================
        
        
        
        //===================== parse out the href value
		var linkLcase = link.toLowerCase();
        var hrefIndex = linkLcase.indexOf(' href') + 5;
		var hrefSubstr = link.substring(hrefIndex);  //  ="/page" target="_blank">text</a> 
		
        //turn it into a character array
        var arrChar = hrefSubstr.split('');
        var firstQuoteIndex;
        var lastQuoteIndex;
        var quoteType;
        
        //find the first matching set of quotes that enclose the href
        for (var i=0; i<arrChar.length; i++) {
            if ((arrChar[i] == '"') || (arrChar[i] == "'")) {
                if (quoteType == null) {
	                quoteType = arrChar[i]; 
                    firstQuoteIndex = i;  
                } else {
                    if (quoteType == arrChar[i]) {
                    	lastQuoteIndex = i;    
                    } 
                }  
                if ((firstQuoteIndex != null) && (lastQuoteIndex != null)) {
                	break;
                }
            }
        }
        var href = hrefSubstr.substring(firstQuoteIndex+1, lastQuoteIndex).trim(); //  /page
		//=====================		

        
        

        //===================== parse out the target value        
        var target;
		//remove all whitespace.  want to make sure this is target=, not the word target somewhere else
        var compressed = link.replace(/\s+/g, '');
    
        var compressedLcase = compressed.toLowerCase();
        var targetIndex = compressedLcase.indexOf('target="');
        if (targetIndex == -1) {
        	targetIndex = compressedLcase.indexOf("target='");    
        }
        
	    if (targetIndex != -1) {
        	targetIndex += 7;
        }
    
    
        if (targetIndex != -1) {
	        var targetSubStr = compressed.substring(targetIndex);
            //turn it into a character array
            arrChar = targetSubStr.split('');
            
            quoteType = null;
            firstQuoteIndex = null;
            lastQuoteIndex = null;
            
            //find the first matching set of quotes that enclose the target
            for (var i=0; i<arrChar.length; i++) {
                if ((arrChar[i] == '"') || (arrChar[i] == "'")) {
                    if (quoteType == null) {
                        quoteType = arrChar[i]; 
                        firstQuoteIndex = i;  
                    } else {
                        if (quoteType == arrChar[i]) {
                            lastQuoteIndex = i;    
                        } 
                    }  
                    if ((firstQuoteIndex != null) && (lastQuoteIndex != null)) {
                        break;
                    }
                }
            }
           	target = targetSubStr.substring(firstQuoteIndex+1, lastQuoteIndex).trim(); //  _blank            
        }    
		//=====================		     

        //make sure there is no "javascript" string anywhere in the hyperlink
        if (href != null) {
            var hrefLcase = href.toLowerCase();
            if (hrefLcase.indexOf('javascript') != -1) {
                anchorObj.success = false;
                return anchorObj;
            }
        }

        var validTargets = ['_blank', '_self', '_parent', '_top'];
        
        if ((href != null) && (text != null)) {
            if (validTargets.indexOf(target) != -1) {
            	anchorObj.target = target;    
            }
            anchorObj.text = sanitizePrimitive(text, 'html');
            anchorObj.href = sanitizeURL(href);
            anchorObj.success = true;                        
        }

    } catch(err) {
        //console.log('invalid hyperlink: ' + err);
    }
    return anchorObj;
}

//this function uses the URI.js library (https://github.com/medialize/URI.js)
//to break a URL up into its pieces, and sanitize the pieces we allow, one by one
//to return a URL which has any special characters escaped in the pieces - without escaping ones we want!
function sanitizeURL(URL) {
	var sURL = '';
    try {
        var result = URI.parse(URL);
        
        if (result != null) {
            //add protocol if exists and valid
            if ('protocol' in result) {
                if ((result.protocol == 'http') || (result.protocol == 'https')) {
                    sURL += result.protocol + '://';   
                } else {
                    //unsupported protocol, reject it
                    return sanitizePrimitive(URL);
                }
            }
            
            //TODO: add support for user / pass
            
            //add / sanitize hostname if it exists
            if ('hostname' in result) {
				sURL += sanitizePrimitive(result.hostname);
            }            

            //TODO: add support for ports             
            
            //add / sanitize path if it exists
            if ('path' in result) {
                //path may include slashes, so we have to split on those
                //so they don't get encoded
                var pathParts = result.path.split('/');
                var arrPath = [];
                for (var i=0; i<pathParts.length; i++) {
		            arrPath.push(sanitizePrimitive(pathParts[i]));
                }
                var sPath = arrPath.join('/'); 
				sURL += sPath;
            }       
            
            //add / sanitize querystring if it exists
            if ('query' in result) {
                var arrQS = [];
				var params = result.query.split('&');
                for (var i=0; i<params.length; i++) {
                	var keyValue = params[i].split('=');
                    if (keyValue.length == 2) {
                    	arrQS.push(sanitizePrimitive(keyValue[0]) + '=' + sanitizePrimitive(keyValue[1]));   
                    }
                }
                if (arrQS.length > 0) {
                	var querystring = arrQS.join('&');   
                    sURL += '?' + querystring;
                }
            }             
            
            //add / sanitize fragment if it exists
            if ('fragment' in result) {
				sURL += '#' + sanitizePrimitive(result.fragment);
            }                
        }
    } catch(err) {
        //console.log('ERROR: '+err);
        return sanitizePrimitive(URL);
    }
    
    return sURL;
}


function sanitizePrimitive(primVal, method) {
	if (primVal != null) {
		//only need to sanitize strings
		if (typeof primVal == 'string') { 
			switch (method) {
				case 'html':
					primVal = secureFilters.html(primVal);
					break;
				case 'js':
					primVal = secureFilters.js(primVal);
					break;
				case 'jsAttr':
					primVal = secureFilters.jsAttr(primVal);
					break;
				case 'uri':
					primVal = secureFilters.uri(primVal);
					break;		                    
				default:
					primVal = secureFilters.html(primVal); //use html as the default
			}
		}
	}
	return primVal;
}


