function plot_distance_markers(xL,yL,d10)
    % PLOT_DISTANCE_MARKERS Insert markers to 2D area plot to visualize 
    %                       what scales are represented
    % (helper function under utils/)
    %
    % DESCRIPTION:
    %   Insert markers of length 'd10' in the lower-left corner (10% away
    %   from corner) of 2D area plot to represent both longitudinal and
    %   latitudinal scale presented in figure
    %   
    % INPUT:
    %   xL = xlim (i.e., longitude edges) of plot [degE]
    %   yL = ylim (i.e., latitude edges)  of plot [degN]
    % OPTIONAL INPUT:
    %   d10 = length of distance marker [km] (default: 10km)
    %   
    % SEE ALSO:
    %   ...
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-07-28

    RE  = 6371.000785; % earth radius [km]
    if nargin<3
        d10 = 10; % distance [km]
    end
    d10_str = strcat(" ",num2str(d10),"km");
    d10     = d10/(pi*RE/180); % distance [rad]
    dx      = xL(2)-xL(1);
    dy      = yL(2)-yL(1);
    lat_mean= yL(1)+0.1*dy;

    plot((xL(1)+0.1*dx)*[1 1],(yL(1)+0.1*dy)+[0 d10],'Linewidth',4,'Color','k')
    plot((xL(1)+0.1*dx)+[0 d10/cosd(lat_mean)],(yL(1)+0.1*dy)*[1 1],'Linewidth',4,'Color','k')
    text(xL(1)+0.1*dx,yL(1)+0.1*dy+d10,d10_str,'FontSize',16,'Color','k')
    text(xL(1)+0.1*dx+d10/cosd(lat_mean),yL(1)+0.1*dy,d10_str,'FontSize',16,'Color','k')
end