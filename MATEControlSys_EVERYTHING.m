if exist('bb','var') == 0
    bb = beaglebone('192.168.7.2');
    enableSerialPort(bb,1)
    mcs = serialdev(bb,'/dev/ttyO1',9600);
    mcs2 = serialdev(bb,'/dev/ttyO2',9600);
    mcs3 = serialdev(bb,'/dev/ttyO4',9600);
end



joy = vrjoystick(1);
[axes,butts,povs] = read(joy);
a = 100;
b = 64;
c = 64;

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
    axes = round(axes,2);
    vect = [axes(1) axes(2)];
    Rvect = rotateVector(vect);
    Rvect = Rvect*127;
    % tpower(3) is rotation axis
    tpower = [Rvect(1) Rvect(2) axes(3) axes(4)];
    % tpower(4) controls up/down power
    tpower(4) = abs(tpower(4)-1)*(127/2);
    % Exponential curve should be implemented on power, hopefully
    power = round(127.*abs((tpower/127).^3));
%     power = round(abs(tpower));
    if power(1) > 127
        power(1) = 127;
    end
    if power(2) > 127;
        power(2) = 127;
    end

% Rotation
% max: half power
    Raxes = [0 0 0 0]; % Initialize variable
    while abs(axes(3)) > 0.6 || abs(Raxes(3)) > 0.6
        maxPower = 120;
        axes(3) = 0;
        [Raxes,Rbutts,Rpovs] = read(joy);
        if Raxes(3) > 0
            %rotate right
            rotatePower = round(maxPower*((Raxes(3)-0.5)/0.5));
            write(mcs,[128 0 rotatePower bitand(128+0+rotatePower,127)])%A reverse
            write(mcs,[128 5 rotatePower bitand(128+5+rotatePower,127)])%C reverse
            write(mcs,[129 1 rotatePower bitand(129+1+rotatePower,127)])%B forward
            write(mcs,[129 4 rotatePower bitand(129+4+rotatePower,127)])%D forward
        elseif Raxes(3) < 0
            Raxes(3)=-Raxes(3);
            %rotate left
            rotatePower = round(maxPower*((Raxes(3)-0.5)/0.5));
            write(mcs,[128 1 rotatePower bitand(128+1+rotatePower,127)])
            write(mcs,[128 4 rotatePower bitand(128+4+rotatePower,127)])
            write(mcs,[129 0 rotatePower bitand(129+0+rotatePower,127)])
            write(mcs,[129 5 rotatePower bitand(129+5+rotatePower,127)])
        end
        pause(0.05)
    end

% AC MC uses addr 128
    % Stop
    if Rvect(1) == 0
        write(mcs,[128 0 0 bitand(128+0,127)])
        write(mcs,[128 4 0 bitand(128+4,127)])
    % Forward
    elseif Rvect(1) > 0
        write(mcs,[128 1 power(1) bitand(128+1+power(1),127)])
        write(mcs,[128 5 power(1) bitand(128+5+power(1),127)])
    % Backward
    else
        write(mcs,[128 0 power(1) bitand(128+0+power(1),127)])
        write(mcs,[128 4 power(1) bitand(128+4+power(1),127)])
    end
    
% BD MC uses addr 129
    % Stop
    if Rvect(2) == 0 
        write(mcs,[129 0 0 bitand(129+0,127)])
        write(mcs,[129 4 0 bitand(129+4,127)])
    % Forward
    elseif Rvect(2) > 0
        write(mcs,[129 0 power(2) bitand(129+0+power(2),127)])
        write(mcs,[129 4 power(2) bitand(129+4+power(2),127)])
    % Backward
    else
        write(mcs,[129 1 power(2) bitand(129+1+power(2),127)])
        write(mcs,[129 5 power(2) bitand(129+5+power(2),127)])
    end


% % Up/Down MC Pololu
    % Buttons 3 (Down) and 5 (Up)
    
    if butts(5) == 1 && butts(3) == 0
        write(mcs2,[170 13 9 power(4)])
        write(mcs2,[170 14 9 power(4)])
    elseif butts(3) == 1 && butts(5) == 0
        write(mcs2,[170 13 10 power(4)])
        write(mcs2,[170 14 10 power(4)])
    else
        write(mcs2,[170 13 9 0])
        write(mcs2,[170 14 9 0])
    end
    
    % 
% %     Read temperature
%     if butts(7) == 1
% %       TODO: Implement timer function
%         tempTimer = timer();
%         
%         strtemp = system(bb, 'cat /MATE/temp.txt');
%         numtemp = str2double(strtemp(70:74));
%         temp = ((numtemp/1000)*1.8) + 32
%     end
    
    pause(0.01)
end