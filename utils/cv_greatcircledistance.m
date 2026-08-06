function gcd = cv_greatcircledistance(lat,lon)
    % GREATCIRCLEDISTANCE between neighboring transect points
    % (helper function under utils/)
    %   
    % INPUT:
    %   lat = latitude  of station transect [degN] - 1D array (1xM) with M>=2
    %   lon = longitude of station transect [degE] - 1D array (1xM) with M>=2
    % OUTPUT:
    %   gcd = great-circle distance between neighboring transect points [m] - 1D array (1x(M-1)) 
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-08-06

    RE  = 6371000.785; % earth radius [m]
    gcd = RE * acos(sind(lat(1:end-1)).*sind(lat(2:end))+...
                    cosd(lat(1:end-1)).*cosd(lat(2:end)).*cosd(lon(2:end)-lon(1:end-1)));
end