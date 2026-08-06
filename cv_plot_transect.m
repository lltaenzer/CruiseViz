function [ax,c] = cv_plot_transect(dist,pres,VARI,SIGMATHETA,depth,pres_max,dist_ctd,station_str,title_str,xlabel_str,col)
    % PLOT_TRANSECT Plots CTD transect for first-order analysis aboard the ship
    % (plotting function)
    %
    % INPUT:
    %   dist = 1D (1xM) distance vector of transect
    %   pres = 1D (Zx1) pressure level vector [db]
    %   VARI = 2D (ZxM) array with variable to be plotted 
    % 
    % OPTIONAL INPUT:
    %   SIGMATHETA  = Reduced potential density field to plot contours
    %                 (same array size as VARI)
    %   depth       = Ocean depth along distance vector [m]
    %   pres_max    = max. pressure level of transect [db]
    %   dist_ctd    = 1D double array with CTD locations along distance vector
    %   station_str = 1D cell array with station names to be plotted atop transect
    %   title_str   = Plot title as string
    %   xlabel_str  = Label for x-axis as string
    %   col         = MATLAB structure containing any of the following color parameters:
    %                   col. map     = String of which cmocean colormap should be used
    %                                  (default: 'thermal')
    %                   col.flag_bar = Boolean of whether colorbar should be added
    %                                  (default: false)
    %                   col.str_vari = String of colorbar label
    %                   col.Ncol     = Number of discrete colormap steps
    %                                  (default: 256)
    % 
    % OUTPUT:
    %   ax = MATLAB axes of TS-plot
    %   c  = MATLAB colorbar (if no colorbar, c = 0)
    %
    % SEE ALSO:
    %   design_transect.m
    %   plot_transect_collage.m
    %   plot_map.m
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-08-06

    colorscheme = {[0 0.4470 0.7410],[0.8500 0.3250 0.0980],[0.9290 0.6940 0.1250],[0.4940 0.1840 0.5560],[0.4660 0.6740 0.1880],[0.3010 0.7450 0.9330],[0.6350 0.0780 0.1840]};
    % color:            blue                 red                     yellow                purple                  green               light blue               dark red

    if nargin<6 || isempty(pres_max)
        pres_max = pres(find(any(~isnan(VARI),2),1,'last'));
    end

    % colormap/colorbar parameters if 3rd variable available
    if nargin<11
        col.map = 'thermal'; col.flag_bar = 0; col.str_vari = ''; col.cL = [min(VARI(:)), max(VARI(:))]; col.Ncol = 256;
    else
        if ~isfield(col,'map')
            col.map = 'thermal';
        end
        if ~isfield(col,'flag_bar')
            col.flag_bar = false;
        end
        if ~isfield(col,'str_vari')
            col.str_vari = '';
        end
        if ~isfield(col,'cL')
            col.cL = [min(VARI(:)), max(VARI(:))];
        end
        if ~isfield(col,'Ncol')
            col.Ncol = 256;
        end
    end

    hold on

    % Plot transect
    [DIST,PRES] = meshgrid(dist,pres);
    if any(size(DIST)~=size(VARI))
        [PRES,DIST] = meshgrid(pres,dist);
    end 
    pcolor(DIST,PRES,VARI,'LineStyle','none'); 
    
    % Add density isolines
    if nargin >= 4 && ~isempty(SIGMATHETA)
        contour(DIST,PRES,SIGMATHETA,0:1:23,'Color',.7*[1 1 1],'ShowText','off');
        [C,h] = contour(DIST,PRES,SIGMATHETA,24:1:30,'Color',.7*[1 1 1],'ShowText','on');
        clabel(C,h,'FontSize',12,'Color',.7*[1 1 1]);
    end

    % Add CTD station locations
    if nargin >= 7
        if ~isempty(dist_ctd) 
            scatter(dist_ctd,0*ones(size(dist_ctd)),50,'v','MarkerEdgeColor','k','MarkerFaceColor',colorscheme{2},'MarkerFaceAlpha',.5)
        end
        if  ~isempty(station_str)
            station_str = cv_station_string(station_str);
            text(dist_ctd,-pres_max/10*ones(size(dist_ctd)),station_str,'HorizontalAlignment','center','FontSize',12,'Color',colorscheme{2})
        end
    end
    
    % Plot Bathymetry
    if nargin>=5 && ~isempty(depth)
        x_bathy = [dist(1) dist dist(end)];
        y_bathy = [1.1*pres_max min(depth,1.1*pres_max) 1.1*pres_max];
        fill(x_bathy,y_bathy,.7*[1 1 1],'LineStyle','none')
        plot(dist,depth,'k','Linewidth',2)
    end

    % Colorbar
    c = colorbar; ylabel(c,col.str_vari,'FontSize',12./.9); 
    clim(col.cL); 

    % Colormap: Check if data on both sides of pivot value can be found
    if strcmp(col.map,'balance')
        if min(VARI(:)) * max(VARI(:)) < 0 
            cmocean('balance',col.Ncol,'pivot',0);  
        else
            ccol = cmocean('balance');
            if min(VARI(:)) > 0
                colormap(ccol(128+1:end,:))
            else
                colormap(ccol(1:128,:))
            end
        end
    else
        cmocean(col.map,col.Ncol);
    end

    if nargin>=9 && ~isempty(title_str)
        title(title_str)
    end

    ylabel('P [db]')
    if nargin >=10 && ~isempty(xlabel_str)
        xlabel(xlabel_str)
    end
    xlim([0 dist(end)]); ylim([0 pres_max]); set(gca,'ydir','reverse')
    ax = gca; ax.FontSize = 12;
end