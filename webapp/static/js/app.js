if (window.console === undefined || window.console.log === undefined) {
    window.console = {'log': function(){} };
}

// namespace all js to securecam
var securecam = function() {
    // private funcs go here
    var cameraLoadComplete = null;
    var self = {
        // public funcs go here
        init: function() {
            $(document).trigger('woome_init', self);
            self.log("loading camera....");
            self.loadcamera();
        },
        loadcamera: function(){
            params = {
                "allowScriptAccess": "always",
                "wmode": "opaque",
                "bgcolor": "#ffffff"
            };
            swfobject.embedSWF("/static/flash/CameraPhoto.swf", "camera", "300px", "250px", "10.0.0", null, "", params);
            cameraLoadComplete = true;
            return cameraLoadComplete;
        },
        log: function(logmsg) {
            console.log(logmsg);
        },
        camera: function() {
            return swfobject.getObjectById("video");
        },
        flash_notify: function (status, args) {
            if (status == "success") {
                self.log("successfully uploaded photo");
            }
        },
        start_capture: function() {
            $('#capture_button')[0].innerHTML = 'Stop Recording ...';
            $('#capture_button')[0].onclick = function () { webcam.stop_capture (); };

            self.capture();
            self.running_id = setInterval(function() { self.capture(); }, 30000);
        },
        stop_capture: function() {
            $('#capture_button')[0].innerHTML = 'Start Recording ...';
            $('#capture_button')[0].onclick = function () { webcam.start_capture(); };
            clearInterval(self.running_id);
            self.log("stopped capturing pid: " + self.running_id);
        },
        capture: function(){
            var roomid = $('#roomid')[0].value;
            var username = $('#username')[0].value;
            var image_upload_url = '/room/' + roomid + '/image/';
            
            alert('taking a photo in room ... ' + roomid);
            if (cameraLoadComplete) {
                swfobject.getObjectById('camera')._snap(image_upload_url, 0.75, false, '', 1);
            } else {
                self.log("camera not loaded yet...");
            }
        }
    };
    self.init();
    return self;
};

$(document).ready(function () {
    webcam = securecam();
});



