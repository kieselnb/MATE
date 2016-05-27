function vR = rotateVector( v )
% ROTATEVECTOR A vector rotator
%     Rotates the given vector by 45 degrees

theta = -45;
R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];

vR = v*R*sqrt(2);