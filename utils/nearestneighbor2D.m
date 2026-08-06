function [nx,ny] = nearestneighbor2D(A,lat,lon,dist_max)
    % NEARESTNEIGHBOR2D Indices of nearest neighbor of non-equidistant 2D Lat/Lon-field
    % (helper function under utils/)
    %   
    % INPUT:
    %   A   = matlab structure of 2D latitude/longitude fields
    %             A.LON = 2D Longitude [degE]
    %             A.LAT = 2D Latitude  [degN] 
    %   lat = latitude  of station transect [degN] - 1D array (1xM) 
    %   lon = longitude of station transect [degE] - 1D array (1xM) 
    % OPTIONAL INPUT:
    %   dist_max = maximum distance allowed for successful execution [m]
    %              (typically: point out of array range and indices not meaningful)
    % OUTPUT:
    %   [nx,ny] = index locations within 2D array
    %
    % SEE ALSO:
    %   ...
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-07-28

    dist_squared = (A.LAT-lat).^2 + (A.LON-lon).^2 * cosd(lat)^2;
    [dmin,~]     = min(dist_squared,[],'all');
    if nargin>3 && dmin > (dist_max/111000)^2
        return; % return if dmin too big
    end
    [nx,ny]      = find(dist_squared==dmin);
    nx = nx(1); ny = ny(1);
end