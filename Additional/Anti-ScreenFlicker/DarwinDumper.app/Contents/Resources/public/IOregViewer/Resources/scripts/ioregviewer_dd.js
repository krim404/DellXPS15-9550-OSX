/*
 * This file sets up the browser ready for reading and displaying HTML and JSON data files 
 * using the following libraries:
 * - jQuery - http://jquery.com
 * - jstree - http://www.jstree.com
 * - jstree-grid - https://github.com/deitch/jstree-grid
 * - jquery.hotkeys.js - https://github.com/jeresig/jquery.hotkeys
 * - jquery-ui-1.10.0.custom.min.js - http://jqueryui.com
 *
 * The licenses for the above remain as intended. 
 *
 * ioregviewer_dd.js is an adapted version or ioregviewer.js for DarwinDumper.
 *
 * Blackosx - January 2013
 *
 * v1.3dd
 */

// Set initial width for third column of right property tree.
// 700px from left of window to left edge of third column.
// 60px from right edge of window to right edge of right tree div.
// 20px extra to allow for scroll bar and spacing.
// -----
// 780px total.
var thirdColumnWidth=(window.innerWidth)-780;
var runOnce=0;

// --------------------------------------------------------------------------------------
function Initiate(direct){
	// argument comes from user clicking outer header with I/O Kit Registry title ib main DarwinDumper html report.

    if (runOnce == 0) {

	    // build the url for the desired left tree file.
        left_tree_url="IORegistry/IORegViewer/Resources/dataFiles/"+direct+"/"+direct+".html";
    
        // Initialise Left tree.
        createLeftTree();
 
        // Load property data for Root node in right tree. 
        loadInitialRightTreeFile(direct,'data1');
        
        runOnce=1;
    }
    
    // Read textfield when search button is pressed, then pass it to seach function.
    $(".user_search_button").click(function(){
        var my_search_string = $("#user_search_string").val();
        $("div#leftPaneTree").jstree("search",my_search_string);
    });
		
    $(".user_clear_button").click(function () {
        // clear search in tree
        $("div#leftPaneTree").jstree("clear_search");
        // clear text in search box
        $("#user_search_string").val("");
    }); 
}


// --------------------------------------------------------------------------------------
function loadInitialRightTreeFile(folderToRead,fileToLoad){
	// Called from the /IORegistry/IORegViewer/Resources/dataFiles//*/*.html
	// 1st argument is the name of the containing folder of the JSON property data.
	// 2nd argument is the name of the property data file.
	
	// build the url for the desired right tree file. 
    right_tree_url="IORegistry/IORegViewer/Resources/dataFiles//"+folderToRead+"/"+fileToLoad+".txt";
    
    // draw the tree.
    createRightTree();
}


// --------------------------------------------------------------------------------------
function RefreshLeftTree(dropdown){
	// argument comes from drop down menu.

	var myindex = dropdown.selectedIndex
	var selectedValue = dropdown.options[myindex].value

	// build the url for the desired left tree file.
    left_tree_url="IORegistry/IORegViewer/Resources/dataFiles//"+selectedValue+"/"+selectedValue+".html";
    
    // Refresh Left tree.
    $("div#leftPaneTree").jstree('refresh');
    
    // Load property data for Root node in right tree and refresh it. 
    right_tree_url="IORegistry/IORegViewer/Resources/dataFiles//"+selectedValue+"/data1.txt";
    $("div#rightPaneTree").jstree('refresh');
}


// --------------------------------------------------------------------------------------
function loadFile(folderToRead,fileToLoad){
	// Called from clicking a node in the left tree.
	// Each node date file: /IORegistry/IORegViewer/Resources/dataFiles//*/*.html
	// contains an onclick event calling this function. 
	// 1st argument is the name of the containing folder of the JSON property data.
	// 2nd argument is the name of the property data file.
	
	// build the url for the desired right tree file. 
    right_tree_url="IORegistry/IORegViewer/Resources/dataFiles//"+folderToRead+"/"+fileToLoad+".txt";

    // Refresh the right tree.
    $("div#rightPaneTree").jstree('refresh');
}


// --------------------------------------------------------------------------------------
var waitForFinalEvent = (function () {
// A solution to monitor when an event is completed.
// From http://bit.ly/fDW5rg
  var timers = {};
  return function (callback, ms, uniqueId) {
    if (!uniqueId) {
      uniqueId = "Don't call this twice without a uniqueId";
    }
    if (timers[uniqueId]) {
      clearTimeout (timers[uniqueId]);
    }
    timers[uniqueId] = setTimeout(callback, ms);
  };
})();


// --------------------------------------------------------------------------------------
function createLeftTree(){
    jQuery(document).ready(function(){
    
        // Does the data file exist / can we load it?
        $.get(left_tree_url, function(data){ 
        
            $("div#leftPaneTree").jstree({
               core : { "animation" : 100 }, // , "initially_open": "root" - not used as using class="jstree-open" in html file.
	            plugins : ["themes","html_data","ui","sort","hotkeys","search","types"],
	    		themes: { "theme": "apple", "dots": true, "icons": true },
	            ui: { "select_limit" : 1 , "initially_select": ["#Root"]},
	            html_data: {ajax:{url:function (node){return left_tree_url;}}}, //CURRENTLY WORKS
	    		search : { "case_insensitive":true, "show_only_matches":true, ajax:{url:function (node){return left_tree_url;}}},
		    	types: { "types":{ "large" :{ "icon" : { "image" : "Resources/assets/large.png" }}}}
             })
         
              // When a node is clicked, display the metadata for the node in <div> main </div>
             .on('select_node.jstree', function(e, data){
                 document.getElementById('class_placeholder').innerHTML= data.rslt.obj.attr("info");
             });
             
         }).error(function() {
            // If wanting to add browser detection, jQuery recommends http://modernizr.com
            // check http://api.jquery.com/jQuery.browser/#jQuery-browser-version2
            //alert('Error! Failed to load data file:'+left_tree_url+". The file path is either invalid, or if you're using Google Chrome, then note by default it does not allow local XMLHttpRequests. For a Chrome workaround check http://bit.ly/MFUGsn");
            alert('Error! Failed to load data file:'+left_tree_url+".\r\n\r\nIf file exists, then it's a local XMLHttpRequest error.\r\n\r\nSolution for Apple Safari:\r\nGo to Safari -> Preferences -> Advanced and enable the 'Show Develop menu in menu bar' checkbox.\r\nThen select Disable Local File Restrictions from the Develop Menu.\r\n\r\nSolution for Google Chrome:\r\nSee http://bit.ly/MFUGsn");
        });
    })
}


// --------------------------------------------------------------------------------------
function createRightTree(){
    jQuery(document).ready(function(){
    
        // Does the data file exist / can we load it?
        $.get(right_tree_url, function(data){ 
 
                $("div#rightPaneTree")
                .jstree({
	                core : { "animation" : 100 },
	                plugins: ["themes","json_data","grid","sort","ui","hotkeys"],          
	                themes: { "theme": "apple", "dots": false, "icons": false },
	                json_data: { "ajax":{"url":function (node){return right_tree_url;}},"progressive_render":true}, // ,"progressive_unload":true   -  removed as this causes duplicate tree entries when closing and reopening a node.
	                grid: {columns: [{"width":240},{"width":80,"value":"ColType"},{"width":357,"value":"ColValue"},]},
	                ui: { "select_limit" : 0, "initially_open": ["#data1"] }
                })
                //.on("loaded_grid.jstree", function (event, data) {alert("GRID IS LOADED");});
                //.on("select_node.jstree", function (event, data) {alert($(data.args[0]).text());}) 
                .on("select_cell.jstree-grid", function (event, value) {
                   showConversions(value);
                });

        }).error(function() {
            // If wanting to add browser detection, jQuery recommends http://modernizr.com
            // check http://api.jquery.com/jQuery.browser/#jQuery-browser-version2
            //alert('Error! Failed to load data file:'+left_tree_url+". The file path is either invalid, or if you're using Google Chrome, then note by default it does not allow local XMLHttpRequests. For a Chrome workaround check http://bit.ly/MFUGsn");
            alert('Error! Failed to load data file:'+left_tree_url+".\r\n\r\nIf file exists, then it's a local XMLHttpRequest error.\r\n\r\nSolution for Apple Safari:\r\nGo to Safari -> Preferences -> Advanced and enable the 'Show Develop menu in menu bar' checkbox.\r\nThen select Disable Local File Restrictions from the Develop Menu.\r\n\r\nSolution for Google Chrome:\r\nSee http://bit.ly/MFUGsn");
        });
    })
}

// --------------------------------------------------------------------------------------
function showConversions(hexValue) {

    // Display data in different formats in a jQuery UI dialog box
    var check=(getDataType(hexValue));
    var string="";
    switch (check)
    {
        case 'Number': string=(string+"<p class=\"bodyBold\">Original: <span class=\"bodyNormal\">"+hexValue+"</span></p>");
                       string=(string+"<p class=\"bodyBold\">Decimal: <span class=\"bodyNormal\">"+hex2dec(hexValue)+"</span></p>");
                       string=(string+"<p class=\"bodyBold\">Binary: <span class=\"bodyNormal\">"+Hex2Bin(hexValue)+"</span></p>");
                       break;
        case 'Data':   string=(string+"<p class=\"bodyBold\">Original: <span class=\"bodyNormal\">"+hexValue+"</span></p>");
                       var isPrintableData=hex2ascii(hexValue);
                       if (isPrintableData) {
                           string=(string+"<p class=\"bodyBold\">ASCII: <span class=\"bodyNormal\">"+isPrintableData+"</span></p>");
                       }
                       string=(string+"<p class=\"bodyBold\">Binary: <span class=\"bodyNormal\">"+Hex2Bin(hexValue)+"</span></p>");
                       
                       //string=(string+"<p class=\"bodyBold\">Decode: <span class=\"bodyNormal\">"+base642Str(hexValue)+"</span></p>");
                       break;
                               
        //default: string=(string+"<p class=\"bodyBold\">ASCII: <span class=\"bodyNormal\">"+hex2ascii(hexValue)+"</span></p>");
                       //break;
    }              
    
    // If not an array OR dictionary AND var string is not empty.
    if (check != "Container" && string != "") {
        document.getElementById('dialog').innerHTML = (string);
        $( "#dialog" ).dialog();
    }
}

// --------------------------------------------------------------------------------------
function removeEntities(hex){

    // If the string begins with < then assume it also ends in >
    // Then remove the opening and closing <> and return what's remaining.
    // Otherwise, return the original string.
    var a=hex.substring(0,4);
    if (a == "&lt;"){
        var newHex = hex.substring(4,hex.length-4);
        return newHex;
    }
    else
    {
        return hex;
    }
}

// --------------------------------------------------------------------------------------
function hex2ascii(hex) {
    
    // Remove opening < and closing > if they exist.
    hex=removeEntities(hex);
    
    // Check if the data begins with a printable ascii character
    // in the range from 0x20 thru 0x7E or (Space thru ~)
    var a=hex.substring(0,2)
    if (a >= "20" && a<="7E" ){
        var str = '';
        for (var i = 0; i < hex.length; i += 2)
            str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
        return str;
    }
    else
    {
        return "";
    }
}

// --------------------------------------------------------------------------------------
function hex2dec(hex) {
    return parseInt(hex,16);
}

// --------------------------------------------------------------------------------------
function checkHex(hex){
    return/^[0-9A-Fa-f]{1,64}$/.test(hex)
// http://stackoverflow.com/a/12987042
}

// --------------------------------------------------------------------------------------
function Hex2Bin(hex){
    
    // Remove opening < and closing > if they exist.
    hex=removeEntities(hex);

    // remove opening 0x
    hex=(hex.substring(2));
    
    if(!checkHex(hex))
        return 0;
    return parseInt(hex,16).toString(2)
// http://stackoverflow.com/a/12987042
}

// --------------------------------------------------------------------------------------
function base642Str(hex){
    
    // remove opening &lt; and closing &gt;
    var newHex = hex.substring(4,hex.length-4);
    alert(newHex);    
    var binstring=Hex2Bin(newHex);
    alert(binstring);
    var decodedData = window.atob(binstring);
    alert(decodedData);
    
// NOtes: https://developer.mozilla.org/en-US/docs/DOM/window.btoa
// Notes: check UTF - https://developer.mozilla.org/en-US/docs/DOM/window.btoa#Unicode_Strings
   // if(!decodedData){

   //     return 0;
   //}
   //  return decodedData;
}

// --------------------------------------------------------------------------------------
function getDataType(dt) {

    // Check for Number
    var a=dt.substring(0,2)
    if (a == "0x"){
        return "Number";
    }

    // Check for Conatiner    
    a=dt.indexOf("_values");
    if (a == 1){
      return "Container";
    }
    
    // Check for Data
    a=dt.substring(0,4)
    if (a == "&lt;"){
        return "Data";
    }   
}
