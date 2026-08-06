function [ax,c] = cv_plot_map(trans,str_title,bathy)
    % PLOT_MAP Plots a lat/lon-map of transect with bathymetry
    % (plotting function)
    %
    % INPUT:
    %   trans       = Matlab structure of transect
    %                 (output from 'design_transect.m')
    %   str_title   = Title for map as string
    %   bathy       = Matlab structure containing bathymetry data with fields:
    %                       bathy.LON   = 2D Longitude array [degE]
    %                       bathy.LAT   = 2D Latitude array [degE]
    %                       bathy.depth = 2D ocean depth array [m]
    %
    % OUTPUT:
    %   ax = MATLAB axes of map
    %   c  = colorbar structure of map
    %
    % SEE ALSO:
    %   plot_transect.m
    %   design_transect.m
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-08-06

    colorscheme = {[0 0.4470 0.7410],[0.8500 0.3250 0.0980],[0.9290 0.6940 0.1250],[0.4940 0.1840 0.5560],[0.4660 0.6740 0.1880],[0.3010 0.7450 0.9330],[0.6350 0.0780 0.1840]};
    % color:            blue                 red                     yellow                purple                  green               light blue               dark red

    c = colorbar; 
    posc = get(c,'Position');   % position/dimensions of colorbar
    posf = get(gcf,'Position'); % position/dimensions of figure
    poss = get(gca,'Position'); % position/dimensions of axes
    pos  = posf .* poss;        % actual size of axes (not just ratio of posf)
    %posc= get(c,'Position');

    lat = trans.ctd.lat;
    lon = trans.ctd.lon;
    station_str = trans.ctd.station;

    lat_full = trans.lat;
    lon_full = trans.lon;

    % Zoom into area covered by transect
    dd = 0.25; % Additional space outside of transect
    lat_edge = [min(lat) max(lat)]; dlat = lat_edge(2)-lat_edge(1);
    lon_edge = [min(lon) max(lon)]; dlon = lon_edge(2)-lon_edge(1);
    xL = lon_edge + [-1 1]*dd*dlon; dx = xL(2)-xL(1);
    yL = lat_edge + [-1 1]*dd*dlat; dy = yL(2)-yL(1);

    % Control lat/lon ratio in map and adjust map dimensions
    lat_mean = mean(lat);
    ratio    = (dx*cosd(lat_mean))/dy / (pos(3)/pos(4));

    if ratio > 1
        dy = dx * cosd(lat_mean) / (pos(3)/pos(4));
        yL = lat_edge + [-1 1]*(dy-dlat)/2;
        %pos(4)  = ((xL(2)-xL(1))/(yL(2)-yL(1))*cosd(lat_mean)) / pos(3);
        %posc(4) = pos(4);
    elseif ratio < 1
        dx = (pos(3)/pos(4)) * dy / cosd(lat_mean);
        xL = lon_edge + [-1 1]*(dx-dlon)/2;
        %pos(3) = ...;
    end

    % Identify subset of bathy-grid needed for plot
    nx = [1 1 2 2]; ny = [1 2 1 2]; [Lx,Ly] = size(bathy.depth);
    for j=1:4
        [nx(j),ny(j)] = cv_nearestneighbor2D(bathy,yL(ny(j)),xL(nx(j)));
    end
    nx(nx==1) = 2; nx(nx==Lx) = Lx-1; % move away from bathy-boundaries
    ny(ny==1) = 2; ny(ny==Ly) = Ly-1;

    ind_x = (min(nx)-1):(max(nx)+1); 
    ind_y = (min(ny)-1):(max(ny)+1);
    %ind_lat = find(bathy.LAT()<yL(1),1,'last'):find(bathy.LAT(:,1)>yL(2),1,'first');
    %ind_lon = find(bathy.LON(1,:)<yL(1),1,'last'):find(bathy.LON(1,:)>yL(2),1,'first');

    hold on;
    fill([xL(1) xL(2) xL(2) xL(1)],[yL(1) yL(1) yL(2) yL(2)],.7*[1 1 1],'LineStyle','none') % Land in grey
    pcolor(bathy.LON(ind_x,ind_y),bathy.LAT(ind_x,ind_y),bathy.depth(ind_x,ind_y),'EdgeColor','none'); % Bathymetry
    plot(lon_full,lat_full,'Linewidth',2,'Color',colorscheme{3}); % plot transect path
    scatter(lon,lat,25,'o','filled','MarkerFaceColor',colorscheme{2},'MarkerEdgeColor','k') % CTD stations
    text(lon,lat,strcat(" ",strip(station_str,'left','0')),'FontSize',12,'Color',colorscheme{2},'Clipping','on')
    
    %cv_plot_distance_markers(xL,yL);

    cmocean('deep',15); %cL = clim; cL(1)=0; clim(cL); 
    xlim(xL); ylim(yL);
    title(str_title)
    ax = gca; ax.FontSize = 12;

    post = get(ax,'Position');
    set(c,'Position',posc+[0 0 0 poss(1)-post(1)])
    set(ax,'Position',poss);
end