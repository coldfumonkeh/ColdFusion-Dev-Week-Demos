/*
// Name: script.as
// Author: Matt Gifford AKA coldfumonkeh
// Date: 24th October 2009
// Purpose: script file for CFPDF demonstration application
*/

// import the ColdFusion service events

import coldfusion.service.Util;

import flash.events.DataEvent;
import flash.events.IOErrorEvent;
import flash.events.NativeDragEvent;
import flash.net.FileReference;
import flash.net.URLRequest;
import flash.net.URLVariables;

// Import classes to handle drag / drop and clipboard utilities
import flash.desktop.ClipboardFormats;
import flash.desktop.NativeDragManager;

import mx.collections.ArrayCollection;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;

// create variables
public 	var uploadUrl	: URLRequest = new URLRequest();
public 	var fileArray	: Array;
private var file		: FileReference;

// variables required here for ColdFusion settings
[Bindable] public 	var cfServer		: String = '127.0.0.1'; // 127.0.0.1
[Bindable] public 	var cfPort			: Number = 8500;		// 8500
[Bindable] public 	var cfUser			: String = 'cfaas';		// authorised username
[Bindable] public 	var cfPassword		: String = 'cfaas';		// authorised password

// random settings to make the thing work ;)
[Bindable] public 	var uploadedFileURL	: String;

[Bindable] public 	var strPDFTitle		: String = '';
[Bindable] public 	var strPdfAction	: String = '';
[Bindable] public 	var strPdfURL		: String = '';

[Bindable] public 	var strAuthor		: String = '';
[Bindable] public 	var strPageLayout	: String = '';
[Bindable] public 	var strTotalPages	: String = '';

[Bindable] public 	var arrThumb		: ArrayCollection = new ArrayCollection();

private function init():void {
	// set the event listeners for the drag/drop
	dropPanel.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnter);
	dropPanel.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);
	fileArray = new Array('pdf');
	
	// build the uploadUrl
	var variables:URLVariables 	= new URLVariables();
	variables.serviceusername	= cfUser;
	variables.servicepassword	= cfPassword;
	
	uploadUrl.url 			= 'http://' + cfServer + ':' + cfPort + '' + Util.UPLOAD_URL;
	uploadUrl.method		= 'POST';
	uploadUrl.contentType	= 'multipart/form-data';
	uploadUrl.data			= variables;
	
}

private function onDragEnter(e:NativeDragEvent):void {
	var fa:Object = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
	// Check if file is accepted by the application
	for(var i:uint=0; i<fileArray.length; i++) {
		if(fa[0].extension == fileArray[i]) {
			NativeDragManager.acceptDragDrop(dropPanel);
		}
	}
}

private function onDragDrop(e:NativeDragEvent):void {
	var fa:Object = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
	// Store the name of the document to be uploaded. We'll use this to display the doc name in the application.
	strPDFTitle = fa[0].name;
	// run the file upload function
	uploadFile(fa[0]);
}

// upload the file to the server
private function uploadFile(fo:Object):void {
	file = FileReference(fo);
	file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, onUploadComplete);
	file.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
	file.upload(uploadUrl);
}

// run after the initial drag/drop to obtain the file and run the ColdFusion pdf service
private function onUploadComplete(event:DataEvent):void {
	// clear the thumbnail array
	arrThumb.removeAll();
	// Grab the remote URL of the uploaded file on the ColdFusion server
	uploadedFileURL = Util.extractURLFromUploadResponse(event.data.toString());
	// Assign to a string for display in the application
	strPdfURL = uploadedFileURL;
	trace('upload complete', uploadedFileURL);
	
	// run the CF service
	strPdfAction = 'getInfo';
	pdf.execute();
}

// file io error handling
private function onIOError(event:IOErrorEvent):void {
	trace(event);
}

// ColdFusion services handlers
private function onResult(event:ResultEvent):void {
	switch (strPdfAction) {
		case 'getInfo':
			strAuthor 		= event.result.author;
			strPageLayout	= event.result.pageLayout;
			strTotalPages	= event.result.totalPages;
			// enable the thumbnail button
			genThumbs_btn.enabled = true;
			break;
		case 'thumbnail':
			for (var i:uint=0; i<event.result.length; i++) {
				var intstep:int = i+1;
				trace('thumbnail generated', event.result[i][i+1]);
				var obj:Object = new Object();
				obj.url = event.result[i][i+1];
				arrThumb.addItem(obj);
			}
			genThumbs_btn.enabled = false;
			break;
	}
	trace(event);
}

private function onFault(event:FaultEvent):void {
	trace(event);
}


private function getThumbs():void {
	// run code to get thumbnails
	strPdfAction = 'thumbnail';
	pdf.execute();
}

