// A script to control DarwinDumper's UI and respond to user input.
// Copyright (C) 2013-2017 Blackosx
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
// ====================================================================
//
// This file controls the communication between the
// DarwinDumper shell script and the user interface.
//
// Built on the macgap2 project by Tim Debo
// https://github.com/MacGapProject/MacGap2
//
// Blackosx - Feb 2013 -> October 2017
//
//

var gTmpDir = "/tmp/DarwinDumper";
var gLogBashToJs = "bashToJs";
var gSymlinkStatus="";
var tempDir="/tmp";
var appName="DarwinDumper";
var commsFileName="jsToBash";
var workDir=tempDir+"/"+appName;
var gLogJsToBash=workDir+"/"+commsFileName;
var gDebug=0;
var colourRed="#FF0000";
var colourGreen="#608c4e";

//-------------------------------------------------------------------------------------
// On initial load
$(document).ready(function()
{
    DisableRunButton();

    readBashToJsMessageFile();

    $( "#infoWindow" ).hide();

    setUpDialogBoxes();
});

//-------------------------------------------------------------------------------------
function SetFocus()
{
    MacGap.activate();
}

//-------------------------------------------------------------------------------------
// Check for incoming messages from bash script
function readBashToJsMessageFile()
{

    incoming = MacGap.File.read( gLogBashToJs, "string" );
    if (typeof incoming !== 'undefined' && incoming != 0) {

        // Split settings by newline
        var incoming = incoming.split('\n');

        // Take first line
        var firstLine = (incoming[0]);

        // Attempt to overcome issue of a possible incomplete message
        // Only process line if it contains 3 instances of @ character
        var atCheck = (firstLine.match(/@/g) || []).length;
        if (atCheck == 3 ) {

            // Split firstLine by @
            var firstLineSplit = (firstLine).split('@');
            var firstLineCommand = (firstLineSplit[1]);

            // Debug - Capture what JS recieves (after UI is setup)
            if (gDebug == 1) {
                SendMessageToBash("DBG_JSreceived:"+firstLineCommand+"|"+firstLineSplit[2]);
            }
        
            // match command against known ones.
            switch(firstLineCommand) {

                case "Debug":
                    MacGap.removeMessage(firstLine);
                    gDebug=firstLineSplit[2];
                    break;
                case "Version":                                             // Bash sends: "Version@${VERS}@"
                    MacGap.removeMessage(firstLine);
                    printVersion(firstLineSplit[2]);
                    break;
                case "UserLastOptions":                                     // Bash sends: "UserLastOptions@${prevOptions}@"
                    MacGap.removeMessage(firstLine);
                    readLastSettings(firstLineSplit[2]);
                    break;
                case "csrBitsAndKexts":                                     // Bash sends: "csrBitsAndKexts@
                                                                            //              ${gCSR_ALLOW_UNAPPROVED_KEXTS},
                                                                            //              ${gCSR_ALLOW_ANY_RECOVERY_OS},
                                                                            //              ${gCSR_ALLOW_DEVICE_CONFIGURATION},
                                                                            //              ${gCSR_ALLOW_UNRESTRICTED_NVRAM},
                                                                            //              ${gCSR_ALLOW_UNRESTRICTED_DTRACE},
                                                                            //              ${gCSR_ALLOW_APPLE_INTERNAL},
                                                                            //              ${gCSR_ALLOW_KERNEL_DEBUGGER},
                                                                            //              ${gCSR_ALLOW_TASK_FOR_PID},
                                                                            //              ${gCSR_ALLOW_UNRESTRICTED_FS},
                                                                            //              ${gCSR_ALLOW_UNTRUSTED_KEXTS}:${gDrvLoadedD},${gDrvLoadedP},${gDrvLoadedR},${gDrvLoadedV},${gDrvLoadedA}@"
                    MacGap.removeMessage(firstLine);
                    CheckCsrAndLoadedKexts(firstLineSplit[2]);
                    break;
                case "Symlink":                                            // Bash sends three possibles: "Symlink@Update@", "Symlink@Okay@" or "Symlink@Create@"
                    MacGap.removeMessage(firstLine);
                    SetSymlinkMenuTick(firstLineSplit[2]);
                    // Update Symlink info window just incase it's open
                    setSymlinkStatus(gSymlinkStatus);
                    break;
                case "AppPath":                                            // Bash sends "AppPath@${appRootPath}@"
                    MacGap.removeMessage(firstLine);
                    // Save path in to hidden field in index.html
                    $("input[name='globAppPath']").val(firstLineSplit[2]);
                    break;
                case "SaveDirectoryPath":                                  // Bash sends "SaveDirectoryPath@${SAVE_DIR}@"
                    MacGap.removeMessage(firstLine);
                    CheckPathIsWriteable(firstLineSplit[2]);
                    HideOverlay();
                    break;
                case "DF":  // DarwinDumper Feedback                       // Bash sends Example "DF@S:Report@"
                    MacGap.removeMessage(firstLine);
                    FeedbackUI(firstLineSplit[2]);
                    break;
                case "Done":
                    MacGap.removeMessage(firstLine);
                    MacGap.terminate();
                    break;
                case "ClearAuth":
                    MacGap.removeMessage(firstLine);
                    ClearDialogAuth();
                    break;
                default:
                    alert("Found else:" + firstLine + " | This is a problem and the app may not function correctly. Please report this error");
                    if(firstLine == "") {
                        MacGap.removeMessage("");
                    } else {
                        MacGap.removeMessage(firstLine);
                    }
                    break;
            }

        }

        // recursively call function as long as file exists every 1/20th second.
        timerReadMessageFile = setTimeout(readBashToJsMessageFile, 50);

    } else {

        // recursively call function as long as file exists but at 1/10th second intervals
        timerReadMessageFile = setTimeout(readBashToJsMessageFile, 100);
    }
}

//-------------------------------------------------------------------------------------
// Print DarwinDumper version to the window.
function printVersion(version)
{
    if ( version != "" ) {
        $("#leftSideVersionBox").append("v"+version);
    }
}

//-------------------------------------------------------------------------------------
function HideOverlay()
{
    $(".overlay").hide();
}

//-------------------------------------------------------------------------------------
function ShowOverlay()
{
    $(".overlay").show();
}

//-------------------------------------------------------------------------------------
function HideOverlayPreventUserInteraction()
{
    $(".overlayPreventUserInteraction").hide();
}

//-------------------------------------------------------------------------------------
function ShowOverlayPreventUserInteraction()
{
    $(".overlayPreventUserInteraction").show();
}

//-------------------------------------------------------------------------------------
function FeedbackUI(message)
{
    if (message != 0) {

        if (message.substring(0, 2) == "S:") {
            $("#info_"+message.substring(2)).closest(".OptionLineWaiting").attr('class', 'OptionLineRunning');
            $("#status_"+message.substring(2)).text('Running');
        }
                    
        if (message.substring(0, 2) == "F:") {
            $("#info_"+message.substring(2)).closest(".OptionLineRunning").attr('class', 'OptionLineCompleted');
            $("#status_"+message.substring(2)).text('Completed');
        }

    }
}

//-------------------------------------------------------------------------------------
function readLastSettings(prevSettings)
{
    if (prevSettings != 0) {

        prevSettings = prevSettings.split(',');

        // if array is not blank
        if (prevSettings != "") {

            // step through each element
            for (var i = 0; i < prevSettings.length; i++) {

                if (prevSettings[i] != "ArchiveZip" && prevSettings[i] != "ArchiveLzma" && prevSettings[i] != "ArchiveNone" && prevSettings[i] != "ReportNone" && prevSettings[i] != "Report") {

                    // Set each checkbox
                    $("#"+prevSettings[i]).prop('checked', true);

                } else {

                    if (prevSettings[i] == "ArchiveZip" || prevSettings[i] == "ArchiveLzma" || prevSettings[i] == "ArchiveNone") {
                        // Set the archive drop down menu.
                        $('[name=archiveOptions]').val(prevSettings[i]);
                        setColourArchive();
                    }

                    // html report - separate the 'none' option
                    if (prevSettings[i] == "ReportNone") {
                        // Set the htmlReport drop down menu.
                        $("#Report").prop('checked',false);
                    }

                    // html report - process the other options.
                    if (prevSettings[i] == "Report") {
                        // Set checkbox to set
                        $("#Report").prop('checked',true);
                    }
                }
            }

            CheckboxRunButtonCheck();

        }

    } else {

        // There is no prefs file.

        // Check all the dump checkboxes.
        EnableAllCheckboxes();

        // Check each group select checkbox
        $("#topHeaderBox .groupSelectButtonTop").prop('checked', true);
        $("#middleHeaderBox .groupSelectButtonMiddle").prop('checked', true);

        // Check the HTML Report
        $("#Report").prop('checked', true);

        // Set the archive drop down menu to .zip
        $('[name=archiveOptions]').val("ArchiveZip");

        CheckboxRunButtonCheck();
    }
}

//-------------------------------------------------------------------------------------
// Change colour of the archive drop down menu text
// depending on the selected value.
// Note: these colours match the values used in .css
function setColourArchive()
{
    var temp=$("#archive").val();

    if ( temp=="ArchiveNone" ) {
        $("#archive").css("color","#666");
    } else {
        $("#archive").css("color","#FFF");
    }
}

//-------------------------------------------------------------------------------------
// Write to file
function SendMessageToBash(messageText)
{
  MacGap.File.write( gLogJsToBash, messageText, "string" );
}

//-------------------------------------------------------------------------------------
// React to the form submission.
// Find each item that was selected and build
// a string with each title. Then send the final
// string back to the Terminal.
function processSelections(userRunChoice)
{
    var tmp="";

    // begin string with user choice of root privileges.
    var string=("Root="+userRunChoice);

    // add to string user choice of archive
    string=(string+","+$("#archive").val())

    for(i=0; i<document.User_Options.elements.length; i++)
    {
        tmp=document.User_Options.elements[i];
        if(tmp.checked){

            // write a comma to separate the contents.
            string=(string+",")

            // build output string.
            string=(string+tmp.id);

            // update status bars to show process is waiting to process.
            // skip any non dump options
            if (tmp.id != tmp.id != "Public" && tmp.id != "ArchiveNone" && tmp.id != "ReportNone") {
                $("#info_"+tmp.id).closest(".OptionLine").attr('class', 'OptionLineWaiting');
                $("#status_"+tmp.id).text('Waiting');
            }
        }
    }

    if($("#archive").val()=="ArchiveZip" || $("#archive").val()=="ArchiveLzma") {
      $("#status_archive").closest(".OptionLine").attr('class', 'OptionLineWaiting');
      $("#status_archive").text('Waiting');
    }

    SendMessageToBash("DD_Run@"+string);

    ShowOverlayPreventUserInteraction();

    // Disable all dump option checkboxes
    $(".dump_option").prop("disabled", true);

    // Disable both top and middle section checkboxes
    $('*[class^="groupSelectButton"]').prop("disabled", true);

    // Disable private checkbox
    $("#privacy").prop("disabled", true);

    // Disable html report checkbox
    $("#Report").prop('disabled', true);

    // Disable all 'info' buttons
    $(".button_info").attr("disabled", "disabled");

    disableControlButtons();
    disableOptionButtons();

}

//-------------------------------------------------------------------------------------
function CheckPathIsWriteable(pathToCheck)
{
    updateSaveDirStatus(pathToCheck);

    var check = MacGap.IsDirWriteable(pathToCheck);

    if(check){

        $("input[type=text]").css("background",colourGreen);
        SendMessageToBash("DD_SaveDirectorySet@"+pathToCheck);

    } else {

        $("input[type=text]").css("background",colourRed);
        DisableRunButton();

        PresentPathError(pathToCheck,"The following path cannot be written to");

    }

}

//-------------------------------------------------------------------------------------
function updateSaveDirStatus(saveFilePath)
{
    $("#globSaveDirectory").val(saveFilePath);
}

//-------------------------------------------------------------------------------------
function GetSaveDir()
{
    userPath=$("#globSaveDirectory").val();
    return userPath;
}

//-------------------------------------------------------------------------------------
// This corresponds to the save path 'Choose' button being clicked.
function saveDirectoryPageBrowseButtonPressed()
{
    MacGap.Dialog.openSheetWithWriteCheck({files:false,multiple:false,directories:true,prompt: "Select",message:"Please select a save path",callback:function(files){

    if (files[0].substring(0, 6) == "Error:") {

        MacGap.notify({
                        type: 'sheet', // Optional. Defaults to user notifications.
                        title: 'Error',
                        content: 'Chosen path ' + files[0].substring(6) + ' is not writeable',
                        sound: true,
        });

        updateSaveDirStatus(files[0].substring(6));
        $("input[type=text]").css("background",colourRed);

    } else if (files == "!USERCANCELLED!") {

      // ??

    } else {

      updateSaveDirStatus(files[0]);
      $("input[type=text]").css("background",colourGreen);

      // Send path to bash to update user prefs
      var CurrentSavePath=GetSaveDir();
      SendMessageToBash("DD_SaveDirectorySet@"+CurrentSavePath);

    }

    CheckboxRunButtonCheck();

  }});

}

//-------------------------------------------------------------------------------------
// This corresponds to the save path 'Reset' button being clicked.
function saveDirectoryPageClearButtonPressed()
{
    // Set save path to same dir as app
    userPath=$("input[name='globAppPath']").val();

    CheckPathIsWriteable(userPath);

    EnableRunButtonBasedOnSavePathColour();
}

//-------------------------------------------------------------------------------------
// This corresponds to the save path 'Open' button being clicked.
function saveDirectoryPageOpenButtonPressed()
{
    // Send message back to 'init' script.
    SendMessageToBash("DD_SaveDirectoryOpen");
}

//-------------------------------------------------------------------------------------
//
function PresentPathError(saveFilePath,messageForUser)
{
    MacGap.Dialog.openSheetWithWriteCheck({files:false,multiple:false,directories:true,prompt: "Select",message:messageForUser+":\n"+saveFilePath+"\n\nPlease select a new save path.",callback:function(files){

    if (files[0].substring(0, 6) == "Error:") {

        MacGap.notify({
                        type: 'sheet', // Optional. Defaults to user notifications.
                        title: 'Error',
                        content: 'Chosen path ' + files[0].substring(6) + ' is not writeable',
                        sound: true,
        });

        updateSaveDirStatus(files[0].substring(6));
        $("input[type=text]").css("background",colourRed);

    } else if (files == "!USERCANCELLED!") {

        $("input[type=text]").css("background",colourRed);

    } else {

        updateSaveDirStatus(files[0]);
        $("input[type=text]").css("background",colourGreen);

        // Send path to bash to update user prefs
        var CurrentSavePath=GetSaveDir();
        SendMessageToBash("DD_SaveDirectorySet@"+CurrentSavePath);

    }

    CheckboxRunButtonCheck();

  }});

}

//-------------------------------------------------------------------------------------
function EnableRunButtonBasedOnSavePathColour()
{
    var savePathBgColour = $("input[type=text]").css("backgroundColor");
  
    if ( savePathBgColour == "rgb(96, 140, 78)" ) { // green // for ref Red =  ( bgColour == "rgb(255, 0, 0)" ) {
        enableButton("Run","button3");
    }

}

//-------------------------------------------------------------------------------------
function DisableRunButton()
{
  disableButton("button3","Run");
}

//-------------------------------------------------------------------------------------
function ResetStatusBars()
{
    $('*[id^="status"]').attr('class', 'statusBarIdle');
}

//-------------------------------------------------------------------------------------
function CheckboxRunButtonCheck()
{
    // Check if at least one dump option is selected, otherwise disable the Run button.
    if ($(codecid).prop('checked') || $(biosSystem).prop('checked') || $(biosVideo).prop('checked') || $(diskLoaderConfigs).prop('checked') || $(bootLoaderBootSectors).prop('checked') || $(diskPartitionInfo).prop('checked') || $(firmmemmap).prop('checked') || $(kexts).prop('checked') || $(lspci).prop('checked') || $(memory).prop('checked') || $(acpi).prop('checked') || $(cpuinfo).prop('checked') || $(devprop).prop('checked') || $(dmi).prop('checked') || $(edid).prop('checked') || $(bootlogF).prop('checked') || $(bootlogK).prop('checked') ||$(ioreg).prop('checked') || $(kernelinfo).prop('checked') || $(nvram).prop('checked') || $(opencl).prop('checked') || $(power).prop('checked') || $(rcscripts).prop('checked') || $(rtc).prop('checked') || $(sip).prop('checked') || $(smc).prop('checked') || $(sysprof).prop('checked')) {

        EnableRunButtonBasedOnSavePathColour();

    } else {

        DisableRunButton();

    }
}

//-------------------------------------------------------------------------------------
function updateSymlinkStatus(statusMessage,buttonText)
{
    // Set text of table cell contents to feedback status
    $("#table_symlink_status td").eq(1).html(statusMessage);

    // Set button text
    $("#table_symlink_status #symlink_page_button").val(buttonText);
}

//-------------------------------------------------------------------------------------
// Set the symlink table cell and button text accordingly.
function setSymlinkStatus(status)
{
    if (status != 0) {

        if ( status == "Create") {

            updateSymlinkStatus("Not Installed","Create Symlink")

        } else if ( status == "Update") {

            updateSymlinkStatus("Exists but needs updating","Update Symlink")

        } else if ( status == "Okay") {

            updateSymlinkStatus("Correctly Installed","Delete Symlink")

        }

    }
}

//-------------------------------------------------------------------------------------
// Set checkmark against symlink menu item if valid symlink exists.
function SetSymlinkMenuTick(status)
{
    if (status != 0) {

        // Parse string

        if ( status == "Create") {
            // Set symlink menu text without check mark.
            $(".menu #info_symlink").val("Symlink");
            $(".menu #info_symlink").css('color', '#FF0033'); // red

        } else if ( status == "Update") {

            // Set symlink menu text without check mark.
            $(".menu #info_symlink").val("Symlink");
            $(".menu #info_symlink").css('color', '#FFCC33');  // orange

        } else if ( status == "Okay") {
            // Set symlink menu text with check mark.
            $(".menu #info_symlink").val("Symlink \u2713");
            $(".menu #info_symlink").css('color', '#33CC33'); // green

        }

        // Set global var to remember this
        gSymlinkStatus=status;
    }
}

//-------------------------------------------------------------------------------------
$(function()
{
    // On clicking the 'openPathButton' button.
    $("#openPathButton").on('click', function() {
        saveDirectoryPageOpenButtonPressed();
    });

    // On clicking the 'changePathButton' button.
    $("#changePathButton").on('click', function() {
        saveDirectoryPageBrowseButtonPressed();
    });

    // On clicking the 'resetPathButton' button.
    $("#resetPathButton").on('click', function() {
        saveDirectoryPageClearButtonPressed();
    });

    // Respond to the 'Deselect All' button press.
    $("#DeselectAll").click(function() {

        // UnCheck all dump option checkboxes.
        $("#MiddleOptions .dump_option").prop('checked', false);
        $("#topMiddleOptions .dump_option").prop('checked', false);
        $("#topHeaderBox .groupSelectButtonTop").prop('checked', false);
        $("#middleHeaderBox .groupSelectButtonMiddle").prop('checked', false);

        DisableRunButton();
    });
  
    // Respond to the 'Select All' button press.
    $("#SelectAll").click(function() {

        EnableAllCheckboxes();

        $("#topHeaderBox .groupSelectButtonTop").prop('checked', true);
        $("#middleHeaderBox .groupSelectButtonMiddle").prop('checked', true);

        EnableRunButtonBasedOnSavePathColour();

    });

    // On changing the 'archive' dropdown menu.
    $("#archive").change(function() {
        setColourArchive();
    });
  
    // On clicking the 'selectTopOptions' checkbox.
    $("#selectTopOptions").click(function() {

        if ($(selectTopOptions).prop('checked')) {

            $("#topMiddleOptions .dump_option").prop('checked', true);
            EnableRunButtonBasedOnSavePathColour();

        } else {

            $("#topMiddleOptions .dump_option").prop('checked', false);
            CheckboxRunButtonCheck();

        }

    });

    // On clicking the 'selectMiddleOptions' checkbox.
    $("#selectMiddleOptions").click(function() {

        if ($(selectMiddleOptions).prop('checked')) {
            $("#MiddleOptions .dump_option").prop('checked', true);
            EnableRunButtonBasedOnSavePathColour();

        } else {

            $("#MiddleOptions .dump_option").prop('checked', false);
            CheckboxRunButtonCheck();

        }

    });

    // Hide the div by id on click of button.
    $( "#infoWindowCloseButton" ).click(function() {

        $( "#infoWindow" ).hide( "slide", { direction: "up" }, 200);

        // enable the select, run and quit buttons
        EnableControlButtons();

        CheckboxRunButtonCheck();
        return false;
    });

    // On pressing return in the save path text field
    $("#globSaveDirectory").keydown(function (e){

        if(e.keyCode == 13){

            userPath=$("#globSaveDirectory").val();
            CheckPathIsWriteable(userPath);
            EnableRunButtonBasedOnSavePathColour();

        }
    });

    // On losing the focus of the save path text field.
    // i.e. user could have changed text but not pressed return
    $("#globSaveDirectory").focusout(function () {

        userPath=$("#globSaveDirectory").val();
        CheckPathIsWriteable(userPath);
        EnableRunButtonBasedOnSavePathColour();

    });

    // Respond to the main window info buttons when clicked.
    $(".button_info").click(function() {

        // disable the select, run and quit buttons
        disableControlButtons();

        // load respective page in to jquery window.
        loadInfoPageIntoDiv(this.id);
    });

    // Respond to the credits, info, symlink and custom path menu buttons when clicked.
    $(".button_showpage").click(function() {

        // disable the select, run and quit buttons
        disableControlButtons();
                              
        // load respective page in to jquery window.
        loadInfoPageIntoDiv(this.id);

        if(this.id=="info_symlink"){

            // Add 1/2 second delay to allow for symlink page to load in.
            setTimeout(function(){
                setSymlinkStatus(gSymlinkStatus)
            },250);
        }

    });

    // Respond to a .dump_option checkbox being clicked
    $(".dump_option").click(function() {
        CheckboxRunButtonCheck();
    });

    // Respond to a main window warning triangle being clicked.
    $("[id^=warn_]").click(function() {
        disableControlButtons();
        loadInfoPageIntoDiv(this.id);
    });
  
});


//-------------------------------------------------------------------------------------
// The index.html form uses more than one button.
// Work out which one was pressed and respond accordingly.
function formButtonPressed(f,whichButton)
{
    if(whichButton=="run") {

        // check to see if an option requiring root privileges was ticked
        if ($(codecid).prop('checked') || $(cpuinfo).prop('checked') || $(biosSystem).prop('checked') || $(biosVideo).prop('checked') || $(diskLoaderConfigs).prop('checked') || $(bootLoaderBootSectors).prop('checked') || $(diskPartitionInfo).prop('checked') || $(firmmemmap).prop('checked') || $(lspci).prop('checked') || $(memory).prop('checked')) {

            processSelections(1);

        } else {

            processSelections(0);

        }

    }

}

//-------------------------------------------------------------------------------------
// Called from info_symlink.htm (the symlink slider info page).
function symlinkPageButtonPressed(text)
{
    SendMessageToBash("DD_Symlink@"+text);
    $( "#dialogWaitingAuth" ).dialog( "open" );
}

//-------------------------------------------------------------------------------------
function ClearDialogAuth()
{
    $( "#dialogWaitingAuth" ).dialog( "close" );
}

//-------------------------------------------------------------------------------------
function loadInfoPageIntoDiv(idToLoad)
{
    // load respective page in to jquery window.
    fileToLoad=("info_pages/"+idToLoad+'.htm');
    $('#infoFileContents').load(fileToLoad,function(responseTxt,statusTxt,xhr){

        if(statusTxt=="success") {
            $( "#infoWindow" ).show( "slide", { direction: "up" }, 200);
        }

        if(statusTxt=="error") {
            alert("Error: "+xhr.status+": "+xhr.statusText);
        }

    });
}

//-------------------------------------------------------------------------------------
// Disable user buttons.
function disableControlButtons()
{
    disableButton("button2","DeselectAll");
    disableButton("button4","SelectAll");
    disableButton("button3","Run");
    disableButton("button1","Quit");
}

//-------------------------------------------------------------------------------------
// Enable all dump option checkboxes.
function EnableAllCheckboxes()
{
    $("#MiddleOptions .dump_option").prop('checked', true);
    $("#topMiddleOptions .dump_option").prop('checked', true);
}

//-------------------------------------------------------------------------------------
// Enable user buttons.
function EnableControlButtons()
{
    enableButton("DeselectAll","button2");
    enableButton("SelectAll","button4");
    enableButton("Quit","button1");
}

//-------------------------------------------------------------------------------------
function disableOptionButtons()
{
    disableButton("button_showpage","info_credits");
    disableButton("button_showpage","info_help");
    disableButton("button_showpage","info_symlink");
}

//-------------------------------------------------------------------------------------
function EnableOptionButtons()
{
    enableButton("info_credits","button_showpage");
    enableButton("info_help","button_showpage");
    enableButton("info_symlink","button_showpage");
}

//-------------------------------------------------------------------------------------
function disableButton(buttonClass,buttonId)
{
    $("."+buttonClass).attr("disabled", "disabled");
    $("#"+buttonId).attr('class', 'ghosted');
}

//-------------------------------------------------------------------------------------
function enableButton(buttonId,buttonClass)
{
    $("#"+buttonId).attr('class',buttonClass);
    $("."+buttonClass).removeAttr("disabled");
}

//-------------------------------------------------------------------------------------
function setUpDialogBoxes()
{
    $(function() {
        $( "#dialogWaitingAuth" ).dialog({
            modal: true, width: 370, height: 190, resizable: false, draggable: false, dialogClass: 'no-close', autoOpen: false,
            position: { my: "bottom", at: "center", of: window }
        });
    });
}

//-------------------------------------------------------------------------------------
// Process state of system with regard to SIP
function CheckCsrAndLoadedKexts(values)
{
    // values contains the csr settings and loaded kexts delimeted by a colon
    
    // Split firstLine by :
    var splitValues = (values).split(':');
    var csrSettings = (splitValues[0]);
    var loadedKexts = (splitValues[1]);

    if (csrSettings != 0 && loadedKexts != 0) {
        
        // Remove new line at the end of the strings.
        csrSettings = csrSettings.split(',');
        loadedKexts = loadedKexts.split(',');
        
        // Check csr settings
        // File will contain something like: 0,0,0,0,0,1,0,0,1,1
        // These values refer to each CSR_ALLOW_UNAPPROVED_KEXTS,CSR_ALLOW_ANY_RECOVERY_OS,CSR_ALLOW_DEVICE_CONFIGURATION,CSR_ALLOW_UNRESTRICTED_NVRAM,CSR_ALLOW_UNRESTRICTED_DTRACE,CSR_ALLOW_APPLE_INTERNAL,CSR_ALLOW_KERNEL_DEBUGGER,CSR_ALLOW_TASK_FOR_PID,CSR_ALLOW_UNRESTRICTED_FS,CSR_ALLOW_UNTRUSTED_KEXTS
        // 0 means item is disabled. 1 means enabled.
        CSR_ALLOW_UNTRUSTED_KEXTS=csrSettings[9];
        CSR_ALLOW_UNRESTRICTED_FS=csrSettings[8];
        CSR_ALLOW_TASK_FOR_PID=csrSettings[7];
        CSR_ALLOW_KERNEL_DEBUGGER=csrSettings[6];
        CSR_ALLOW_APPLE_INTERNAL=csrSettings[5];
        CSR_ALLOW_UNRESTRICTED_DTRACE=csrSettings[4];
        CSR_ALLOW_UNRESTRICTED_NVRAM=csrSettings[3];
        CSR_ALLOW_DEVICE_CONFIGURATION=csrSettings[2];
        CSR_ALLOW_ANY_RECOVERY_OS=csrSettings[1];
        CSR_ALLOW_UNAPPROVED_KEXTS=csrSettings[0];
        
        
        // Check Kext loaded settings
        // File will contain something like: 1,1,1,1
        // These values refer to each DirectHW.kext,pmem.kext,RadeonPCI.kext,VoodooHDA.kext
        // 0 means kext is not loaded in current system
        loadedKextD=loadedKexts[0];
        loadedKextP=loadedKexts[1];
        loadedKextR=loadedKexts[2];
        loadedKextV=loadedKexts[3];
        loadedKextA=loadedKexts[4];
        
        // Show relevant warning triangles
        if (CSR_ALLOW_UNTRUSTED_KEXTS == 0 && loadedKextD == 0) {

            $("#warn_biosSystem").attr('class', 'warning_triangle_info');
            $("#warn_lspci").attr('class', 'warning_triangle_info');

        } else {

            $("#warn_biosSystem").prop("disabled",true);
            $("#warn_lspci").prop("disabled",true);

        }

        if (CSR_ALLOW_UNTRUSTED_KEXTS == 0 && loadedKextR == 0) {

            $("#warn_biosVideo").attr('class', 'warning_triangle_info');

        } else {

            $("#warn_biosVideo").prop("disabled",true);

        }
        
        if (CSR_ALLOW_UNTRUSTED_KEXTS == 0 && loadedKextV == 0) {

            $("#warn_codecid").attr('class', 'warning_triangle_info');

        } else {

            $("#warn_codecid").prop("disabled",true);

        }

        if (CSR_ALLOW_UNTRUSTED_KEXTS == 0 && loadedKextA == 0) {

            $("#warn_cpuinfo").attr('class', 'warning_triangle_info');

        } else {

            $("#warn_cpuinfo").prop("disabled",true);

        }

        if (CSR_ALLOW_UNRESTRICTED_DTRACE == 0) {

            $("#warn_firmmemmap").attr('class', 'warning_triangle_info');

        } else {

            $("#warn_firmmemmap").prop("disabled",true);

        }
    }
}
