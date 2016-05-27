clc
if exist('bb','var') == 0
    bb = beaglebone('192.168.7.2');
    enableSerialPort(bb,4)
    mcs = serialdev(bb,'/dev/ttyO4',9600);
end
%128 = start
%1 = Device ID
%2 = Set position command
%0 = servo #
%100 = position

joy = vrjoystick(1);
[axes,butts,povs] = read(joy);
a = 100;
b = 64;
c = 64;

% camlist = webcamlist;
cam = webcam(1);
cam2 = webcam(2);
cam2.Resolution = '1280x720';
cam.Resolution = '1280x720';

vp = vision.DeployableVideoPlayer;
vp2 = vision.DeployableVideoPlayer;
vpo = vision.DeployableVideoPlayer;
vpo2 = vision.DeployableVideoPlayer;
x = 1;
% fstk = snapshot(cam);
while (butts(2) == 0)
    [axes,butts,povs] = read(joy);
    if (povs == 0 || povs == 45 || povs == 315) && (a > 0)
        a = a - 2;
    elseif (povs == 180 || povs == 135 || povs == 225) && (a < 127)
        a = a + 2;
    end
    if (povs == 90 || povs == 45 || povs == 135) && (b > 0)
        b = b - 2;
    elseif (povs == 270 || povs == 225 || povs == 315) && (b < 127)
        b = b + 2;
    end
    if (butts(11) == 1) && (c > 50)
        c = c - 2;
    elseif (butts(12) == 1) && (c < 77)
        c = c + 2;
    end
    % fprintf('%d %d %d\n',a,b,c)
    write(mcs,[128 1 2 0 a]);
    write(mcs,[128 1 2 2 b]);
    write(mcs,[128 1 2 1 c]);
    
    vs = snapshot(cam);
    vs2 = snapshot(cam2);
    vsr = imrotate(vs,-90);
    vsr2 = imrotate(vs2,-90);
    step(vpo,vsr)
    step(vpo2,vsr2)
    
    pause(0.01)
end
release(vp)
release(vp2)
clear vp
clear cam
