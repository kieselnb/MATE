clc
display 'Starting Control'
clear variables;
barometricPressure=993.9; % Zero Depth pressure reference
if exist('bb','var') == 0
    bb = beaglebone('192.168.7.2');
    display 'BeagleBone Connected'
    mcs1 = serialdev(bb,'/dev/ttyO1',9600);
    mcs2 = serialdev(bb,'/dev/ttyO2',9600);
    mcs3 = serialdev(bb,'/dev/ttyO4',9600);
end



% % Everytime control begin, reset the microSerial servo controller
pinSerialReset = 'P8_8';
configureDigitalPin(bb,pinSerialReset,'output');
writeDigitalPin(bb,pinSerialReset,0);
pause(.25)
writeDigitalPin(bb,pinSerialReset,1);



joy = vrjoystick(1);
[axes,butts,povs] = read(joy);
a = 100;
b = 64;
c = 64;

p1 = 'P8_13';  % Trigger1 (Open/close)
p2 = 'P8_14';  % Trigger 2
p3 = 'P8_15'; % Button behind trigger (Extend)
p4 = 'P8_16'; % Button behind trigger2
p5 = 'P8_17'; % Button 8 
p6 = 'P8_18'; % Button 8, 2
p1_var = 0;
p2_var = 0;
p3_var = 0;

configureDigitalPin(bb,p1,'output');
configureDigitalPin(bb,p2,'output');
configureDigitalPin(bb,p3,'output');
configureDigitalPin(bb,p4,'output');
configureDigitalPin(bb,p5,'output');
configureDigitalPin(bb,p6,'output');
writeDigitalPin(bb,p1,0);
writeDigitalPin(bb,p2,1);
writeDigitalPin(bb,p3,0);
writeDigitalPin(bb,p4,1);
writeDigitalPin(bb,p5,0);
writeDigitalPin(bb,p6,1);

trim = 0;


display 'Control Ready'
% DO NOT USE CONTROL-C TO CLOSE PROGRAM
% BUTTON 9 EXITS THE PROGRAM
while (butts(9) == 0)
    
    [axes,butts,povs] = read(joy);

    % % Servo Control    
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
    write(mcs3,[128 1 2 0 a]);
    write(mcs3,[128 1 2 2 b]); %BUGFIX: Changed to mcs3 to allow pan opticon control
    write(mcs3,[128 1 2 1 c]); %RS 4/25/2016
    
    % BEGIN DRIVE CONTROL
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
    power(3) = power(3)/2;
%     power = round(abs(tpower));
    if power(1) > 127
        power(1) = 127;
    end
    if power(2) > 127;
        power(2) = 127;
    end

% Rotation
% max: half power
    if abs(axes(3)) > 0.6
        maxPower = 127;
        %axes(3) = 0;
        %[Raxes,Rbutts,Rpovs] = read(joy);
        if axes(3) > 0
            %rotate right
            rotatePower = round(maxPower*((axes(3)-0.4)));
            write(mcs1,[128 0 rotatePower bitand(128+0+rotatePower,127)])%A reverse
            write(mcs1,[128 5 rotatePower bitand(128+5+rotatePower,127)])%C reverse
            write(mcs1,[129 1 rotatePower bitand(129+1+rotatePower,127)])%B forward
            write(mcs1,[129 4 rotatePower bitand(129+4+rotatePower,127)])%D forward
        elseif axes(3) < 0
            axes(3)=-axes(3);
            %rotate left
            rotatePower = round(maxPower*((axes(3)-0.4)));
            write(mcs1,[128 1 rotatePower bitand(128+1+rotatePower,127)])
            write(mcs1,[128 4 rotatePower bitand(128+4+rotatePower,127)])
            write(mcs1,[129 0 rotatePower bitand(129+0+rotatePower,127)])
            write(mcs1,[129 5 rotatePower bitand(129+5+rotatePower,127)])
        end

    else
    % AC M.C. uses addr 128
        % Stop
        if Rvect(1) == 0
            write(mcs1,[128 0 0 bitand(128+0,127)])
            write(mcs1,[128 4 0 bitand(128+4,127)])
        % Forward
        elseif Rvect(1) > 0
            write(mcs1,[128 1 power(1) bitand(128+1+power(1),127)])
            write(mcs1,[128 5 power(1) bitand(128+5+power(1),127)])
        % Backward
        else
            write(mcs1,[128 0 power(1) bitand(128+0+power(1),127)])
            write(mcs1,[128 4 power(1) bitand(128+4+power(1),127)])
        end
   
    % BD M.C. uses addr 129
        % Stop
        if Rvect(2) == 0 
            write(mcs1,[129 0 0 bitand(129+0,127)])
            write(mcs1,[129 4 0 bitand(129+4,127)])
        % Forward
        elseif Rvect(2) > 0
            write(mcs1,[129 0 power(2) bitand(129+0+power(2),127)])
            write(mcs1,[129 4 power(2) bitand(129+4+power(2),127)])
        % Backward
        else
            write(mcs1,[129 1 power(2) bitand(129+1+power(2),127)])
            write(mcs1,[129 5 power(2) bitand(129+5+power(2),127)])
        end
    end

    % % Up/Down M.C. Pololu
        % Buttons 3 (Down) and 5 (Up)
        
        % Up/Down trim value
            % Use buttons 4 and 6 to set the trim
    if butts(4) && trim > -127
        trim = trim - 1;
    elseif butts(6) && trim < 127
        trim = trim + 1;
    end

    if butts(5) == 1 && butts(3) == 0 
        write(mcs2,[170 13 9 power(4)])
        write(mcs2,[170 14 9 power(4)])
    elseif butts(3) == 1 && butts(5) == 0
        write(mcs2,[170 13 10 power(4)])
        write(mcs2,[170 14 10 power(4)])
    elseif trim >= 0
        write(mcs2,[170 13 9 trim])
        write(mcs2,[170 14 9 trim])
    elseif trim < 0
        write(mcs2,[170 13 10 abs(trim)])
        write(mcs2,[170 14 10 abs(trim)])
    end

    % % END DRIVE CONTROL

    % % Solenoid Control    
        if butts(8) == 1 % Button 8
            display 'Trigger 3'
            p1_var = xor(p1_var,1);
            writeDigitalPin(bb,p1,p1_var);
            writeDigitalPin(bb,p2,xor(p1_var,1));
            
            while(butts(8)==1)
                [axes,butts,povs] = read(joy);
                pause(0.001)
            end
        end
        if butts(2) == 1 % Button behind trigger
            display 'Trigger 2'
            p2_var = xor(p2_var,1);
            writeDigitalPin(bb,p3,p2_var);
            writeDigitalPin(bb,p4,xor(p2_var,1));
            while(butts(2)==1)
                [axes,butts,povs] = read(joy);
                pause(0.001)
            end
        end
        if butts(1) == 1 % Trigger 
            display 'Trigger 1'
            p3_var = xor(p3_var,1);
            writeDigitalPin(bb,p5,p3_var);
            writeDigitalPin(bb,p6,xor(p3_var,1));
            while(butts(1)==1)
                [axes,butts,povs] = read(joy);
                pause(0.001)
            end
        end
    
%     Read temperature
    if butts(7) == 1
%       TODO: Implement timer function
%         tempTimer = timer();
        strtemp = system(bb, 'cat /root/temp.txt')
        %numtemp = str2double(strcat((strtemp(18:19)), '.',strtemp(20:21)));
        %tempF = ((numtemp/1000)*1.8) + 32;
        %fprintf('Temperature: %.2f °C \n\n', numtemp); %Nicely format output
       
    end
    
    %Read Pressure
    if butts(10) ==1
        %TODO: Implement pressure Timer Function
           %pressTimer = timer();
        strpress = system(bb, 'cat /root/PressureData.txt');
        numpress = str2double(strpress(35:38))/10;
        fprintf('Pressure: %f mbar \n', numpress);
        numpress = (numpress - barometricPressure)/98;
        fprintf('Depth: %f meters \n\n', numpress); %Nicely format output
    end


    
    %pause(0.01)
end

% Release and clear variables
display 'Control Ended';
clear variables
