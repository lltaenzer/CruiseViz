function [ax,c] = plot_TSplot(theta0,salt,vari,xL,yL,cL,col)
    % PLOT_TSPLOT Plots Potential Temperature-Absolute Salinity plot 
    %             for arrays of interest
    % (plotting function)
    %
    % INPUT:
    %   theta0 = Potential Temperature [degC] - array of variable size
    %   salt   = Absolute Salinity [g/kg] - array of same size as 'theta0'
    %   
    % OPTIONAL INPUT:
    %   vari   = Additional 3rd variable to be plotted in color
    %            (array of same size as 'theta0' and 'salt')
    %   xL     = x-axis (Salt) limits (sorted 2-entry vector)
    %            (default: [min(salt(:)) max(salt(:))])
    %   yL     = y-axis (Temp.) limits (sorted 2-entry vector)
    %            (default: [min(theta0(:)) max(theta0(:))])
    %   cL     = 3rd variable colormap/-bar limits (sorted 2-entry vector)
    %   col    = MATLAB structure containing any of the following color parameters:
    %               col. map     = String of which cmocean colormap should be used
    %                              (default: 'thermal')
    %               col.flag_bar = Boolean of whether colorbar should be added
    %                              (default: false)
    %               col.str_vari = String of colorbar label
    %               col.Ncol     = Number of discrete colormap steps
    %                              (default: 256)
    % 
    % OUTPUT:
    %   ax = MATLAB axes of TS-plot
    %   c  = MATLAB colorbar (if no colorbar, c = 0)
    %
    % SEE ALSO:
    %   plot_transect_collage.m
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-07-28
    
    if nargin<3 || isempty(vari) % should a third variable be plotted
        flag_vari = false; 
    else 
        flag_vari = true; 
    end

    if nargin<4 % axis limits
        xL = [min(salt(:)) max(salt(:))];
        yL = [min(theta0(:)) max(theta0(:))];
    end
    if flag_vari % colormap/colorbar parameters if 3rd variable available
        if nargin<6 || isempty(cL)
            cL = [min(vari(:)) max(vari(:))];
        end
        if ~isfield(col,'map')
            col.map = 'thermal';
        end
        if ~isfield(col,'flag_bar')
            col.flag_bar = false;
        end
        if ~isfield(col,'str_vari')
            col.str_vari = '';
        end
    end

    % Background density field
    s  = linspace(xL(1),xL(2),101); t = linspace(yL(1),yL(2),101); [T,S] = meshgrid(t,s);
    R  = gsw_rho_t_exact(S,T,0);
    [C,h] = contour(S,T,R-1000,'Color','k','ShowText','on','Color',.7*[1 1 1]);
    clabel(C,h,'FontSize',12,'Color',.7*[1 1 1]);

    % Plotting (incl. color-coding of potential 3rd variable)
    if ~flag_vari 
        scatter(salt(:),theta0(:),15,'o','filled','MarkerFaceColor',.7*[1 1 1],'MarkerEdgeColor','k')
    else
        [~,ind_sort] = sort(vari(:));
        scatter(salt(ind_sort),theta0(ind_sort),15,vari(ind_sort),'o','filled')
    
        if ~isfield(col,'Ncol') % Add color map with discrete steps (if Ncol provided)
            cmocean(col.map);
        else
            cmocean(col.map,col.Ncol)
        end

        if col.flag_bar % Add colorbar if desired
            c = colorbar; ylabel(c,col.str_vari,'FontSize',12./.9)
        else
            c = 0;
        end
        clim(cL);
    end

    xlabel('S [g kg^{-1}]'); ylabel('\Theta_0 [°C]')
    ax = gca; ax.FontSize = 12;
    xlim(xL); ylim(yL);
end