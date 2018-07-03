	/**
	 * utilities for Purchase, Sales, Work, Item pages that are responsible 
	 * for AddManage Line functionality 
	 
	 NB: your page must have , from KSE.cls
	  <script>var NS = '{!NamespaceUU}';</script>
	 */
	
	function findNS( ele, classname ) { 
		return ele.find( '.'+NS+classname );
	}
	
	// inside a table
	function readOnlyInput ( tr, classname ) { 
		return findNS ( tr, classname ).removeClass('false').find('input:visible').attr('readonly','true');
	}
	
	
	function cleanNS ( result ) { 	// remove the namespace from json object, recursive
		for ( var r in result ) {  
			if ( typeof(r) !== 'string' ) continue; 
			var cleanr = r.replace(NS,'');
			result[cleanr] = result[r];
			if ( typeof(result[cleanr]) === 'string' ) result[cleanr] = result[cleanr].replace(NS,'');
			if ( cleanr !== r ) delete result[r];			
			if ( typeof( result[cleanr] ) === 'object' ) cleanNS( result[cleanr] );
		}	
		return result != null; 
	}
	
	
	function fill( tr , result, fieldpath , fieldname ) {   // find the input fields, fill them in
		var value = valueAt( result, fieldpath );
		//if ( value == null ) return; 
		if ( value!=null && typeof(value) ==='string') { 
			//Decode the encoded String
			//var decoded = $('<div/>').html(value).text(); //BAD!  Injects unsafe code into the DOM!
			//value = decoded;
		}
		
		var td = tr.find('.'+NS+fieldname);
		
		if (td.hasClass('picklist')){
			$(td.find('select').val(result[fieldpath]).change()); 
		}
			
		if ( value !=null && td.hasClass('double') ) { 
			value = value.toFixed(6);
		}
		if ( td.is('input:visible, textarea') ) td.val( value ); 
		else td.find('input:visible, textarea').val( value ); 
	}
	
	function valueAt( result, field ) {  					// get properties of related json objects using sobject style path 
		if ( result === undefined ) {return null; } 	// allow this , exampe no price , alert ( 'undefined result ' + field ); 
		if ( result[field] !== undefined ) return result[field];
		var fieldin = field;
		var wh = field.indexOf('\.');
		var field = field.substring( 0, wh );
		return valueAt( result[field], fieldin.substring( wh+1 ));  
	}
	
	function checkErrors ( event ) { 
        if (event.status) {            
            // ok, clear error
            $("#noItemsFound").hide();
            $("#responseErrors").text('');
        } else if (event.type === 'exception') {
            $("#responseErrors").text( event.message + ' : ' + event.type);
            $("#noItemsFound").show();
        } else {
            $("#responseErrors").text( event.message );
        }
    }
	
	function isAnyRecordSelected() {  
		return $('td.removeCol input:checkbox:checked').size() > 0; 
	}
	
	function removeCheckBoxClicked(elemId){
	    enableDisableFuntion('RemoveButtonId');
	    enableDisableFuntion('CloneButtonId');
	}
	
	function enableDisableFuntion(buttonId){            
	    if(!isAnyRecordSelected()){
	        $("input[id*='"+buttonId+"']").removeClass('btn').addClass('btnDisabled'); 
	    }else{
	        $("input[id*='"+buttonId+"']").removeClass('btnDisabled').addClass('btn');
	    }           
	}
	
	function cloneAlert(){                  
	      if( isAnyRecordSelected() ) {
	           if ( window.confirm('Are you sure you would like to clone the selected records?') == true ) {
	                var selected_indexes = '';
	                $('td.removeCol  input:checkbox').each( function( i ) { 
	                    if ( $(this).is(':checked') ) 
	                        selected_indexes += i+',';
	                });
	                executeClone(selected_indexes);  
	           }
	       } else {
	           alert('Please select one or more records to clone');
	       }
	       return false;
	}
	
	function cloneNoAlert(){                  
	      if( isAnyRecordSelected() ) {
	           
                var selected_indexes = '';
                $('td.removeCol  input:checkbox').each( function( i ) { 
                    if ( $(this).is(':checked') ) 
                        selected_indexes += i+',';
                });
                executeClone(selected_indexes);  

	       } else {
	           alert('Please select one or more records to clone');
	       }
	       return false;
	}
	
	function cancelSrcDocNoAlert(){                 
	      if( isAnyRecordSelected() ) {
	           
                var selected_indexes = '';
                $('td.removeCol  input:checkbox').each( function( i ) { 
                    if ( $(this).is(':checked') ) 
                        selected_indexes += i+',';
                });
                cancelPOLines(selected_indexes); 
	       } else {
	           alert('Please select one or more records to cancel');
	       }
	       return false;
	}
	function ReopenNoAlert(){                   
	      if( isAnyRecordSelected() ) {
	
                var selected_indexes = '';
                $('td.removeCol  input:checkbox').each( function( i ) { 
                    if ( $(this).is(':checked') ) 
                        selected_indexes += i+',';
                });
                Reopen(selected_indexes);  
	       } else {
	           alert('Please select one or more records to Reopen');
	       }
	       return false;
	} 
	function deleteAlert(){                  
	       if( isAnyRecordSelected() ) {
	           if ( window.confirm('Are you sure you would like to delete these records?') == true ) {
	                var selected_indexes = '';
	                $('td.removeCol  input:checkbox').each( function( i ) { 
	                    if ( $(this).is(':checked') ) 
	                        selected_indexes += i+',';
	                });
	                remove(selected_indexes);  
	           }
	       } else {
	           alert('Please select one or more records to remove');
	       }
	       return false;
	}
	
	function cancelLineAlert(){                  
	       if( isAnyRecordSelected() ) {
	           if ( window.confirm('Are you sure you would like to cancel these lines?') == true ) {
	                var selected_indexes = '';
	                $('td.removeCol  input:checkbox').each( function( i ) { 
	                    if ( $(this).is(':checked') ) 
	                        selected_indexes += i+',';
	                });
	                cancelLines(selected_indexes);  
	           }
	       } else {
	           alert('Please select one or more records to cancel');
	       }
	       return false;
	}
	
	/* assume we have just added a new row, set the focus on the first text input,
	 *  not the default after a re-render */
	function focusTheNewRow( tableID ) { 
		$("table[id$='"+tableID+"'] tr:last").find("input[type='text']:first").focus();    	
	}
	