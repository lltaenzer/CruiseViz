function cv_plot_transect_collage(trans,str_title,str_vari,bathy)
    % PLOT_TRANSECT_COLLAGE Plots collection of transects for first-order analysis 
    %                       aboard the ship
    % (plotting function)
    %
    % DESCRIPTION: 
    %   Plots the following panels of a chosen transect (with M stations, 
    %   containing K interpolated points) within a single canvas:
    %       i)   Potential Temperature transect
    %       ii)  Salinity Transect
    %       iii) Transect of additional variable of interest
    %       iv)  Plot T/S-diagram with variable of interest shown in color
    %       v)   Overview map of transect location (see function 'plot_map.m')
    %
    % INPUT:
    %   trans = Matlab structure of transect 
    %           (output from 'design_transect.m')
    %           At least the following fields are required:
    %             - trans.dist     = Distance vector [m] (1xK)
    %             - trans.lat      = Latitude vector [degN] (1xK)
    %             - trans.lon      = Longitude vector [degE] (1xK)
    %             - trans.depth    = Ocean depth along transect [m] (1xK)
    %             - trans.pres     = Pressure vector [db] (Zx1)
    %             - trans.theta0   = Potential temperature [degC] (ZxK)
    %             - trans.salt     = Absolute salinity [g/kg] (ZxK)
    %             - trans.sigmatheta = Reduced potential density [kg/m3] (ZxK)
    %             - trans.VARI     = Additional Variable of interest (ZxK)
    %             - trans.ctd.dist = Distance vector of CTD stations [m] (1xM)
    %             - trans.ctd.lat  = Latitude vector of CTD stations [degN] (1xM)
    %             - trans.ctd.lon  = Longitude vector of CTD stations [degE] (1xM)
    %             - trans.ctd.theta0
    %             - trans.ctd.salt
    %             - trans.ctd.VARI
    %   station_str = List of string station names to be plotted
    %   str_title   = Title for map as string
    %   str_vari    = Matlab structure containing information about
    %                 additional variable of interest
    %                   str_vari.short = String of variable name in 'trans'
    %                   str_vari.long  = String as to be shown on colorbar label
    %   bathy       = Matlab structure containing bathymetry data with fields:
    %                       bathy.LON   = 2D Longitude array [degE]
    %                       bathy.LAT   = 2D Latitude array [degE]
    %                       bathy.depth = 2D ocean depth array [m]
    %
    % SEE ALSO:
    %   design_transect.m
    %   plot_transect.m
    %   plot_map.m
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-08-06

    % Ensure that fields follow naming convention
    variab_str = fieldnames(trans);
    ind = find(contains(variab_str,'theta0'));     trans.theta0     = trans.(variab_str{ind(1)});
    ind = find(contains(variab_str,'salt'));       trans.salt       = trans.(variab_str{ind(1)});
    ind = find(contains(variab_str,'sigmatheta')); trans.sigmatheta = trans.(variab_str{ind(1)});
    variab_str = fieldnames(trans.ctd);
    ind = find(contains(variab_str,'theta0'));     trans.ctd.theta0 = trans.ctd.(variab_str{ind(1)});
    ind = find(contains(variab_str,'salt'));       trans.ctd.salt   = trans.ctd.(variab_str{ind(1)});

    % colorbar ranges for different variables
    if ~isfield(trans,'theta0_cbar')
        trans.theta0_cbar = [prctile(trans.theta0(:),[1 99]) 10];
    end
    if ~isfield(trans,'salt_cbar')
        trans.salt_cbar = [prctile(trans.salt(:),[1 99]) 10];
    end
    if ~isfield(trans,'vari_cbar')
        trans.vari_cbar = [prctile(trans.(str_vari.short)(:),[1 99]) 10];
    end
    if ~isfield(trans,'TS_edges')
        trans.TS_edges = [prctile(trans.theta0(:),[1 99]);...
                          prctile(trans.salt(:),[1 99])];
    end
    if ~isfield(trans,'pres_max')
        trans.pres_max = trans.pres(find(any(~isnan(trans.sigmatheta),2),1,'last'))+1;
    end

    % Is variable 'vari' an anomaly transect? Then, change colormap
    if contains(str_vari.long,'\Delta')
        flag_anom = true;
        str_anom = '\Delta';
    else
        flag_anom = false;
        str_anom = '';
    end

    % Plot Panels: 
    % i) Potential Temperature transect
    subplot(3,2,1); hold on;
    clear col; col.map = 'thermal';
    col.str_vari = strcat(str_anom,'\Theta_0 [°C]');
    col.cL       = trans.theta0_cbar(1:2);
    col.Ncol     = trans.theta0_cbar(3);
    [ax,~] = cv_plot_transect(trans.dist,trans.pres,trans.theta0,trans.sigmatheta,...
                              trans.depth,trans.pres_max,trans.ctd.dist,trans.ctd.station,[],[],col);
    set(ax,'Position',get(ax,'Position')+[-0.03 0 0.05 0])
    ax.FontSize = 12;

    % ii) Salinity Transect
    subplot(3,2,3); hold on;
    clear col; col.map = 'haline';
    col.str_vari = strcat(str_anom,'S [g kg^{-1}]');
    col.cL       = trans.salt_cbar(1:2);
    col.Ncol     = trans.salt_cbar(3);
    [ax,~] = cv_plot_transect(trans.dist,trans.pres,trans.salt,trans.sigmatheta,...
                              trans.depth,trans.pres_max,trans.ctd.dist,trans.ctd.station,[],[],col);
    set(ax,'Position',get(ax,'Position')+[-0.03 0 0.05 0])
    ax.FontSize = 12;

    % iii) Transect of additional variable of interest
    subplot(3,2,5); hold on;
    clear col; if flag_anom; col.map = 'balance'; else; col.map = 'rain'; end
    col.str_vari = strcat(str_anom,str_vari.long);
    col.cL       = trans.vari_cbar(1:2);
    col.Ncol     = trans.vari_cbar(3);
    [ax,~] = cv_plot_transect(trans.dist,trans.pres,trans.(str_vari.short),trans.sigmatheta,...
                              trans.depth,trans.pres_max,trans.ctd.dist,trans.ctd.station,[],'Distance [km]',col);
    set(ax,'Position',get(ax,'Position')+[-0.03 0 0.05 0])
    ax.FontSize = 12;

    % iv) Plot T/S-diagram with variable of interest shown in color
    subplot(3,2,[4 6]); hold on;
    xL = trans.TS_edges(2,:); yL = trans.TS_edges(1,:);
    % Set colorbar parameters for T/S plot
    clear col; if flag_anom; col.map = 'balance'; else; col.map = 'rain'; end
    col.flag_bar = false; % Don't add colorbar
    [ax,~] = cv_plot_TSplot(trans.ctd.theta0,trans.ctd.salt,trans.ctd.(str_vari.short),xL,yL,trans.vari_cbar(1:2),col);
    set(ax,'Position',get(ax,'Position')+[0.05 0 0 0])
    ax.FontSize = 12;

    % v) Overview map of transect location (see function 'plot_map.m')
    subplot(3,2,2); hold on;
    [ax,c] = cv_plot_map(trans,str_title,bathy);
    set(c,'Position',get(c,'Position')+[0.05 0 0 0])
    set(ax,'Position',get(ax,'Position')+[0.05 0 0 0])
    ax.FontSize = 12;
end