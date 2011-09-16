/*
Name: script.as
Author: Matt Gifford aka coldfumonkeh (http://www.mattgifford.co.uk)
Purpose: the main actionscript file for the CFaaS application
*/

// import the ColdFusion service events
import coldfusion.service.Util;
import coldfusion.service.events.*;

import flash.events.DataEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.NativeDragEvent;
import mx.controls.Alert;
import mx.events.SliderEvent;
import flash.events.MouseEvent;

import flash.net.URLRequest;
import flash.net.FileReference;

import flash.desktop.ClipboardFormats;
import flash.desktop.NativeDragManager;

// create the variables
public var uploadUrl		:	URLRequest = new URLRequest();
private var maximumSize		:	Number = 500;
private var ratio			:	Number;
private var file			:	FileReference;
private var imgArray		:	Array;

[Bindable] public var uploadedFileUrl	:	String;
[Bindable] public var imgWidth			:	Number;
[Bindable] public var imgHeight			:	Number;
[Bindable] public var imgPercent		:	Number = 100;
[Bindable] public var imgMargin			:	Number;
[Bindable] public var imgAngle			:	Number = 0;
[Bindable] public var originalHeight	:	Number;
[Bindable] public var originalWidth		:	Number;
[Bindable] public var arrImgOriginal	:	Array;
[Bindable] public var attachCollection	:	Array = new Array();

// variables required here to specify the email settings
[Bindable] public var mailServer		:	String = '';
[Bindable] public var mailUserName		:	String = '';
[Bindable] public var mailPassword		:	String = '';
// end of mail server settings

/* constructor method */
/* ****************** */
/* 	add event listeners to the panel for interaction, define the array of 'permitted' images,
and set up the ColdFusion web access for uploads
*/
private function init():void {
	this.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnter);
	this.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop);
	imgArray = new Array('gif','jpg','png');
	
	
	uploadUrl.url = "http://"+conf.cfServer+":"+conf.cfPort+Util.UPLOAD_URL+"&serviceusername="+conf.serviceUserName+"&servicepassword="+conf.servicePassword;
	uploadUrl.method = "POST";
	uploadUrl.contentType = "multipart/form-data";
	
	controlPanel.enabled	= false;
	trace(uploadUrl.url);
}

// Loop through the 'permitted' file extensions, and if matched, accept the drop
private function onDragEnter(e:NativeDragEvent):void {
	var fa:Object = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
	for(var i:uint=0; i<imgArray.length; i++) {
		if(fa[0].extension == imgArray[i]) {
			NativeDragManager.acceptDragDrop(imagePanel);
		}
	}
}
// on drop, set the image source, apply the image title to the panel, and upload the file for use
// with the ColdFusion services
private function onDragDrop(e:NativeDragEvent):void {
	var fa:Object 		= e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
	imagePanel.title 	= fa[0].name;
	file = FileReference(fa[0]);
	file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, onUploadComplete);
	file.upload(uploadUrl);
}


// run after initial drag/drop to obtain the file and run the ColdFusion image info service
private function onUploadComplete(event:DataEvent):void {
	uploadedFileUrl = Util.extractURLFromUploadResponse(event.data.toString());
	dragImage.source = uploadedFileUrl;
	filelabel.text = uploadedFileUrl;
	getImageInfo.execute();
}



// run after returned data from upload to obtain the original image details, including dimensions
private function imageInfoResult(event:ColdFusionServiceResultEvent):void {
	arrImgOriginal = new Array(event.result as Array);
	
	controlPanel.enabled 	= true;
	reset();
	
	// set values to hold the original image dimensions
	originalHeight 	= arrImgOriginal[0][1].value;
	originalWidth 	= arrImgOriginal[0][2].value;
	imgHeight 		= originalHeight;
	imgWidth		= originalWidth;
	
	// work out image ratio - image height / image width
	ratio = originalHeight/originalWidth;
	imgProportions(120);
	createThumb.execute();
}
// apply the source to the thumbnail image from the returned ColdFusion resize service
private function generateThumb(event:ColdFusionServiceResultEvent):void {
	originalThumb.source = event.result;
}

// works out the proportions of the image based upon a numeric value passed through as the maximum size
private function imgProportions(thumbMax:Number):void {
	originalThumb.height	= thumbMax;
	originalThumb.width		= Math.round(originalThumb.height/ratio);
}
// fault error handler
private function onFault(event:Event):void {
	trace(event.toString());
}
// obtain the angle for rotation and pass to the ColdFusion rotation service
private function onRotationChange(event:SliderEvent):void {
	imgAngle = event.value;
	rotateImage.execute();
}
// generic function to run on result from ColdFusion services. Will set the image source to the returned value
private function imageResult(event:ColdFusionServiceResultEvent):void {
	dragImage.source = event.result;
	filelabel.text = event.result.toString();
}
// run when the percentage slider has been changed
private function onPercChange(event:SliderEvent):void {
	imgPercent 	= event.value;
	percentAmends();
}
// change the dimensions of the main image
private function percentAmends():void {
	imgHeight 	= Math.round((originalHeight/100)*imgPercent);
	imgWidth	= Math.round((originalWidth/100)*imgPercent);
	resizeImage.execute();
}
// reset the image source to the original dimensions using the saved object
private function resetImage(event:MouseEvent):void {
	dragImage.source 	= arrImgOriginal[0][0].value;
	// set values to hold the original image dimensions
	originalHeight 		= arrImgOriginal[0][1].value;
	originalWidth 		= arrImgOriginal[0][2].value;
	
	reset();
	percentAmends();
}
// reset the values
private function reset():void {
	imgAngle = 0;
	imgPercent = 100;
}

////
private function sendEmail():void {
	attachCollection[0] = {"file": dragImage.source};
	sendMail.attachments = attachCollection;
	sendMail.execute();
}
// result handler for mail success
private function mailSuccess(event:ColdFusionServiceResultEvent):void {
	mx.controls.Alert.show('Your image has been successfully sent as an attachment','Email Success');
	trace(event);
}
// result handler for mail failure
private function mailFailure(event:ColdFusionServiceFaultEvent):void {
	mx.controls.Alert.show('Your email was not sent. Please ensure all details were filled out','Email Error');
	trace(event);
}


