package {
	/* JPEGCam v1.0.9 */
	/* Webcam library for capturing JPEG images and submitting to a server */
	/* Copyright (c) 2008 - 2009 Joseph Huckaby <jhuckaby@goldcartridge.com> */
	/* Licensed under the GNU Lesser Public License */
	/* http://www.gnu.org/licenses/lgpl.html */

    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.events.ActivityEvent;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.utils.*;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.external.ExternalInterface;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLRequestHeader;
    import flash.net.URLLoader;
    import flash.system.Security;
    import flash.system.SecurityPanel;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.geom.Matrix;

    import mx.core.Application;    
    import mx.events.FlexEvent;
    import mx.core.UIComponent;

    import com.adobe.images.JPGEncoder;
    import ru.inspirit.net.MultipartURLLoader;

    public class WebCam extends Application {
        public var videoCameraContainer:UIComponent;
        private var video:Video;
        private var encoder:JPGEncoder;
        private var snd:Sound;
        private var channel:SoundChannel = new SoundChannel();
        private var jpeg_quality:int;
        private var video_width:int;
        private var video_height:int;
        private var server_width:int;
        private var server_height:int;
        private var camera:Camera;
        private var bmp:Bitmap;
        private var bmpdata:BitmapData;
        private var endpoint:String;
        private var stealth:int;
        private var lastHttpStatus:int;
        
        public function WebCam() {
            addEventListener(FlexEvent.APPLICATION_COMPLETE,mainInit); 	
        }

        public function mainInit(event:FlexEvent):void {
            // class constructor
            flash.system.Security.allowDomain("*");

            ExternalInterface.addCallback('_ping', ping);

            var flashvars:Object = LoaderInfo(this.root.loaderInfo).parameters;
            video_width = Math.floor( flashvars.width );
            video_height = Math.floor( flashvars.height );
            server_width = Math.floor( flashvars.server_width );
            server_height = Math.floor( flashvars.server_height );
			
            stage.align = "TL";
            stage.scaleMode = "noScale";
			
            // Hack to auto-select iSight camera on Mac (JPEGCam Issue #5, submitted by manuel.gonzalez.noriega)
            // From: http://www.squidder.com/2009/03/09/trick-auto-select-mac-isight-in-flash/
            var cameraIdx:int = -1;
            for (var idx:int = 0, len:int = Camera.names.length; idx < len; idx++) {
                if (Camera.names[idx] == "USB Video Class Video") {
                    cameraIdx = idx;
                    idx = len;
                }
            }

            debug("camera == " + cameraIdx);

            if (cameraIdx > -1) {
                camera = Camera.getCamera( String(cameraIdx) );
            }
            else {
                camera = Camera.getCamera();
            }

            debug("camera == " + camera);
						            
            if (camera != null) {
                camera.addEventListener(ActivityEvent.ACTIVITY, activityHandler);
                video = new Video(370,278); // how to work these out from the container?
                video.attachCamera(camera);
                videoCameraContainer.addChild(video);
				
                camera.setMode(370, 278, 12, false);
                camera.setQuality(100, 100);
                camera.setKeyFrameInterval(10);

                // do not detect motion (may help reduce CPU usage)
                camera.setMotionLevel( 100 );

                ExternalInterface.addCallback('_snap', snap);
                ExternalInterface.addCallback('_configure', configure);
                ExternalInterface.addCallback('_upload', upload);
                ExternalInterface.addCallback('_reset', reset);

                if (flashvars.shutter_enabled == 1) {
                    snd = new Sound();
                    snd.load( new URLRequest( flashvars.shutter_url ) );
                }

                jpeg_quality = 100;

                debug("this camera is registered cheddar");
                ExternalInterface.call('webcam.flash_notify', 'flashLoadComplete', true);
            }
            else {
                debug("You need a camera.");
                ExternalInterface.call('webcam.flash_notify', "error", "No camera was detected.");
            }
        }

        public function ping ():void {
            debug("pong");
        }
		
        public function set_quality(new_quality:int):void {
            // set JPEG image quality
            if (new_quality < 0) new_quality = 0;
            if (new_quality > 100) new_quality = 100;
            jpeg_quality = new_quality;
        }
        
        public function configure(panel:String = SecurityPanel.CAMERA):void {
            // show configure dialog inside flash movie
            Security.showSettings(panel);
        }
		
        private function activityHandler(event:ActivityEvent):void {
            debug("activityHandler: " + event);
        }
		
        public function snap(endpoint:String, new_quality:Number, shutter:Boolean, extra_query:String, new_stealth:int = 0):void {
            debug("in snap(), drawing to bitmap " + endpoint + " " + new_quality);

            // take snapshot from camera, and upload if URL was provided
            if (new_quality) set_quality(new_quality);
            stealth = new_stealth;
			
            if (shutter) {
                channel = snd.play();
                setTimeout( snap2, 10, endpoint, extra_query );
            }
            else {
                debug("just doing snap");
                snap2(endpoint, extra_query);
            }
        }
		
        public function snap2(endpoint:String, extra_query:String):void {
            debug("snap2");
            // take snapshot, convert to jpeg, submit to server
            var w:int = 370;
            var h:int = 278;
            bmpdata = new BitmapData(w, h);
            bmpdata.draw( video );

            debug("drawn bmp");
			
            if (!stealth) {
                // draw snapshot on stage
                bmp = new Bitmap( bmpdata );
                videoCameraContainer.addChild( bmp );
			
                // stop capturing video
                video.attachCamera( null );
                videoCameraContainer.removeChild( video );
            }
			
            // if URL was provided, upload now
            if (endpoint) {
                upload(endpoint, w, h, extra_query);
            }
        }

        public function onHttp(evt:HTTPStatusEvent):void {
            debug("onHttp " + evt.status);
            lastHttpStatus = evt.status;
        }

        public function onLoaded(evt:Event):void {
            // image upload complete
            debug("onLoaded called " + evt.type);
            var msg:String = "unknown";
            var ldr:MultipartURLLoader;
            ldr = evt.target as MultipartURLLoader;
            var data:Object = ldr.getData();
            debug("onLoaded target " + evt.target);
            debug("onLoaded target data" + data);
            if (lastHttpStatus == 200) {
                debug("calling external");
                debug(data.toString());
                ExternalInterface.call('webcam.flash_notify', "success", data);
            }
        }
		
        public function upload(endpoint:String, width:int, height:int, extra_query:String):void {
            if (bmpdata) {
                var do_rescale:Boolean = false;
                if (do_rescale && ((video_width > server_width) && (video_height > server_height))) {
                    // resize image downward before submitting
                    var tmpdata:BitmapData = new BitmapData(server_width, server_height);
					
                    var matrix:Matrix = new Matrix();
                    matrix.scale( server_width / video_width, server_height / video_height );
					
                    tmpdata.draw(bmpdata, matrix, null, null, null, true); // smoothing
                    bmpdata = tmpdata;
                } // need resize
				
                debug("converting to jpeg - extra_query =" + extra_query);
			
                var photoBytes:ByteArray;
                encoder = new JPGEncoder(50);
                photoBytes = encoder.encode(bmpdata);
                debug("jpeg length: " + photoBytes.length);

                var request:MultipartURLLoader = new MultipartURLLoader();
                request.addEventListener(Event.COMPLETE, onLoaded);
                request.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttp);
                
                var extras:URLVariables = new URLVariables();
                if (extra_query != null && extra_query != "") {
                    extras.decode(extra_query);
                }
 
                debug("upload extras created from query");
                
                for ( var paramName:String in extras ) {
                    debug ("upload extra param: " + paramName + "=" + extras[paramName]);
                    request.addVariable(paramName, extras[paramName]);
                }
                // simple string data
                //  request.addVariable('test', 'test variable');
 
                // file data: ByteArray, File name, Name of the file field, content MIME type (default application/octet-stream)
                // use [] if you need identical file field name
                // specify MIME type for your file part
                request.addFile(photoBytes, 'upload.jpg', 'photo', 'image/jpeg');
                try {
                    debug("sending post to: " + endpoint);
                    request.load(endpoint);
                }
                catch (error:Error) {
                    debug("Unable to load requested document.");
                    ExternalInterface.call('webcam.flash_notify', "error", "Unable to post data: " + error);
                }
            }
            else {
                ExternalInterface.call('webcam.flash_notify', "error", "Nothing to upload, must capture an image first.");
            }
        }
		
        public function reset():void {
            // reset video after taking snapshot
            if (bmp) {
                removeChild( bmp );
                bmp = null;
                bmpdata = null;
			
                video.attachCamera(camera);
            	addChild(video);
            }
        }


        private function debug(msg:String):void 
        {
            ExternalInterface.call("webcam.log", "DEBUG: " + msg);
        }
    }
}