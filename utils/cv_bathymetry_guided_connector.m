function [lat,lon] = cv_bathymetry_guided_connector(lat,lon,bathy,param)
    % BATHYMETRY_GUIDED_CONNECTOR Bathymetry-dependent connector between two
    %                             neighboring transect points
    % (helper function under utils/)
    %
    % DESCRIPTION:
    %   Creates a (curved) connector between two sample points by striving
    %   a balance between following local bathymetry (via gradient descent) and 
    %   keeping the connector appropriately short, with the balance dictated by
    %   user-determined parameters
    %   (intended for usage in domains with complicated bathymetry such as
    %    fjords, particularly if stations are not close to one another)
    %    NOTE: For most use-cases, varying only 'alpha' should be sufficient!
    %   
    % INPUT:
    %   lat    = Latitude  vector of 2 neighboring points along a transect
    %   lon    = Longitude vector of 2 neighboring points along a transect
    %   bathy  = Matlab structure containing bathymetry data with fields:
    %               bathy.LON   = 2D Longitude array [degE]
    %               bathy.LAT   = 2D Latitude array [degE]
    %               bathy.depth = 2D ocean depth array [m]
    %        
    % OPTIONAL INPUT:
    %   param  = Matlab structure of optimization parameters:
    %               param.alpha  = weight of how far depth-following connector is 
    %                              allowed to deviate from great-circle connector 
    %                              (default: 1)
    %               param.nb_sub = sub-divide connector between two stations in 
    %                              (nb_sub-1) segments (default: 10)
    %               param.Nmax   = max. iterations gradient descent (default: 100)
    %               param.Nmin   = stop gradient descent if change of connector 
    %                              between cycles dist_min for Nmin cycles (default: 25)
    %               param.dist_min = see 'Nmin' (default: 10 km)
    %               param.dist_max = ratio of how much longer depth-following 
    %                                connector is allowed to be compared to
    %                                direct great-circle connector  (default: 0.25)
    %
    % OUTPUT:
    %   [lat,lon] = Latitude/Longitude vectors of connector between two
    %               neighboring transect points
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-08-06

    RE  = 6371000.785;

    % Replace parameters with user-input if provided
    if nargin<4
        alpha = 1;      
        nb_sub = 10;    
        Nmax = 100;     
        Nmin = 25;      
        dist_min = 10;  
        dist_max = .25; 
    else
        if isfield(param,'alpha');  alpha = param.alpha;    else; alpha = 1;    end
        if isfield(param,'nb_sub'); nb_sub = param.nb_sub;  else; nb_sub = 10;  end
        if isfield(param,'Nmax');   nb_sub = param.Nmax;    else; Nmax = 100;   end
        if isfield(param,'Nmin');   nb_sub = param.Nmin;    else; Nmin = 25;    end
        if isfield(param,'dist_min'); nb_sub = param.dist_min; else; dist_min = 10;  end
        if isfield(param,'dist_max'); nb_sub = param.dist_max; else; dist_max = .25; end
    end

    % Divide Euclidean connector into (nb_sub-1) segments
    dist_start = sum(cv_greatcircledistance(lat,lon));
    lat = linspace(lat(1),lat(end),nb_sub); lat_start = lat;
    lon = linspace(lon(1),lon(end),nb_sub); lon_start = lon;
    
    % Identify unit vector that is orthogonal to Euclidean connector between start/end point
    vec_ortho = [-(lat(end)-lat(1)); lon(end)-lon(1)];
    vec_ortho = vec_ortho/(sqrt(sum(vec_ortho.^2)));

    % Create optimization field for gradient descent:
    % i) Ocean depth, capped at linearly-varying average depth (with
    %    distance) from start/end station locations
    %    Goal: Follow bathymetry at sample points or shoaler depths (e.g., when
    %          crossing sills) while avoiding gradient descent into deeper areas
    depth_sel = bathy.depth;
    dist1     = (bathy.LAT-lat(1)).^2 + (bathy.LON-lon(1)).^2 * cosd(lat(1))^2;
    dist2     = (bathy.LAT-lat(end)).^2 + (bathy.LON-lon(end)).^2 * cosd(lat(end))^2;
    [nx,ny]   = cv_nearestneighbor2D(bathy,lat(1),lon(1),1000);     depth1 = bathy.depth(nx,ny);
    [nx,ny]   = cv_nearestneighbor2D(bathy,lat(end),lon(end),1000); depth2 = bathy.depth(nx,ny);
    depth_max = (depth1./dist1 + depth2./dist2)./(1./dist1+1./dist2); % linearly-varying average
                                                                      % depth between start/end stations
    depth_sel = min(depth_sel,depth_max); % choose whatever is shallower
    depth_sel = depth_sel/max(depth_sel(:)); % Normalize ocean depth to vary between 0 and 1

    % ii) Ellipse with start/end station locations as focal points
    %     Goal: Overlay bathymetry field with ellipse favoring Euclidean
    %           connector to suppress overly large deflections 
    dist_ellipse = (RE * acos(sind(bathy.LAT).*sind(lat(1))+...
                             cosd(bathy.LAT).*cosd(lat(1)).*cosd(lon(1)-bathy.LON)) + ...
                    RE * acos(sind(bathy.LAT).*sind(lat(end))+...
                             cosd(bathy.LAT).*cosd(lat(end)).*cosd(lon(end)-bathy.LON)) - ...
                    RE * acos(sind(lat(end)).*sind(lat(1))+...
                             cosd(lat(end)).*cosd(lat(1)).*cosd(lon(1)-lon(end))) ).^2;

    % Final gradient descent field
    % (Note: 'alpha' parameter determines blend between fields i and ii)
    depth_sel = depth_sel - dist_ellipse/(1e5 * alpha);
    
    % Gradient descent
    dist_tot = NaN(1,Nmax); % Vector of connector distance as it grows during gradient descent
    for n=1:Nmax
        lat_new = [lat(1) NaN(1,length(lat)-2) lat(end)];
        lon_new = [lon(1) NaN(1,length(lon)-2) lon(end)]; 
        % For each i-th sub-segment, move down local gradient projected onto
        % the vector orthogonal to Euclidean connector between start/end point
        for k=2:length(lat)-1 
            % Identify local gradient surrounding i-th segment point
            [nx,ny] = cv_nearestneighbor2D(bathy,lat(k),lon(k),1000);
            [dhi,dhj] = gradient(depth_sel(nx-1:nx+1,ny-1:ny+1));   dhi = mean(dhi,'all'); dhj = mean(dhj,'all');
            [dloni,dlonj] = gradient(bathy.LON(nx-1:nx+1,ny-1:ny+1)); dloni = mean(dloni,'all'); dlonj = mean(dlonj,'all');
            [dlati,dlatj] = gradient(bathy.LAT(nx-1:nx+1,ny-1:ny+1)); dlati = mean(dlati,'all'); dlatj = mean(dlatj,'all');
            % Transformation with Jacobian matrix and its inverse
            %                     J = [dloni dlonj; dlati dlatj] (Jacobian matrix)
            detJ  = dloni .* dlatj - dlonj .* dlati;       % determinant
            Jinv  = 1/detJ * [dlatj -dlati; -dlonj dloni]; % Jacobian inverse
            gradh = Jinv * [dhi; dhj]; % vector pointing toward greatest descent (toward greater depths)

            % Project 'gradh' onto orthogonal vector
            projh = sum(vec_ortho .* gradh); projh = projh*1e-3;
            if abs(projh)>1/1000 % If gradient descent step too large, make it smaller
                projh = projh/abs(projh)/1000;
            end
            % Update lat/lon values of curved segment
            lon_new(k) = lon(k) + vec_ortho(1)*projh;
            lat_new(k) = lat(k) + vec_ortho(2)*projh;
        end
        lat = lat_new;
        lon = lon_new;

        dist_tot(n) = sum(cv_greatcircledistance(lat,lon)); % Length of new connector
        if n>Nmin
            ddist = diff(dist_tot(n-Nmin:n));
            if all(abs(ddist)<dist_min) % check if connector length still varies
                break;
            end
        end
    end

    % Check if changed connector length hasn't increased too much,
    % otherwise, go with Euclidean connector instead
    dist_new = sum(cv_greatcircledistance(lat,lon));
    if dist_new/dist_start > 1+dist_max
        lat = lat_start;
        lon = lon_start;
    end
end 