function ctd = cv_read_cnv2struct(path_load,variab)
    % READ_CNV2STRUCT Bring collection of processed CTD profiles from
    %                 Seabird CTD (.cnv-files) into shape required for 
    %                 CruizeViz processing & plotting 
    % (reading/writing function)
    %
    % INPUT:
    %   file_load    = path to folder with .cnv-files (processed Seabird 
    %                  CTD profiles), incl. potential file identifier to
    %                  distinguish between files from different cruises,
    %                  up-/down casts, etc. 
    %                  Example: 'data/dMSM130_'
    %   variab       = MATLAB structure containing information about variables 
    %                  to be read and their location within the .cnv-file:
    %                   - variab.filename= char/string of the file 
    %                                      name pattern with '*' marking the 
    %                                      location of the station name, e.g., 
    %                                      'dMSM130_*' (i.e., station name
    %                                      starts on 9th digit)
    %                   - variab.station = (optional) To give each station a unique
    %                                      string name, provide a 1D cell array of
    %                                      same length as there files (to be loaded), 
    %                                      each with a string
    %                   - variab.write   = 1D cell array with strings of profile
    %                                      variable as it should appear in the
    %                                      output file; the array should at least 
    %                                      contain the following variables:
    %                                       - 'temp'    = In-situ temperature 
    %                                       - 'sali'    = Practical salinity
    %                   - variab.loc     = 1D vector assigning each variable in 
    %                                      'write' to a data column in .cnv-file
    %                                      (starting at '0')
    %                   - variab.loc_pres= index-location of pressure
    %                                      column within .cnv data table
    %                                      (starting at '0')
    %   
    % OUTPUT:
    %   ctd = MATLAB structure to be loaded when using other CruiseViz
    %         functions. All profiles are organized on the same equidistant
    %         1db-pressure grid. The file contains the following variables 
    %         (with N = # CTD profiles, Z = # pressure levels):
    %               - nb (1xN)     = Station index (from 1 to N)
    %               - station {1xN}= Station names (1D cell array of strings)
    %               - time (1xN)   = Time
    %               - lon (1xN)    = Longitude [degE]
    %               - lat (1xN)    = Latitude [degN]
    %               - pres (Zx1)   = Pressure vector [db]
    %               - z (ZxN)      = Ocean depth level vector [m]
    %               - temp (ZxN)   = In-situ temperature [degC]
    %               - sali (ZxN)   = Practical salinity [PSU]
    %               - theta0 (ZxN) = Potential temperature [degC] 
    %               - salt (ZxN)   = Absolute salinity [g/kg] 
    %               - dens (ZxN)   = In-situ density [kg/m3]
    %               - sigmatheta (ZxN) = Reduced potential density [kg/m3] 
    %               - 'vari' (ZxN) = Additional variables as provided in
    %                                'variab.write'
    %               - pres_max (1xN)= Vector of max. profile pressure level [db]
    % 
    % SEE ALSO:
    %   read_cnv2struct
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-08-06

    if ~strcmp(path_load(end),'/')
        path_load = strcat(path_load,'/');
    end

    path_load = strcat(path_load,variab.filename);
    files     = dir(strcat(path_load,'.cnv')); % All files
    N         = length(files);

    % Setup final MATLAB structure 'ctd'
    ctd.nb      = (1:N);
    ctd.station = cell(1,N);
    ctd.time    = NaN(1,N);
    ctd.lon     = NaN(1,N);
    ctd.lat     = NaN(1,N);

    % First parsing through data files to identify parameters for later reading
    ind_pres = NaN(N,1);
    Nhead    = NaN(N,1);
    Ncol     = NaN(N,1);
    for a=1:N
        filenme_local = strcat(files(a).folder,'/',files(a).name);
	    fileID = fopen(filenme_local);
        data_raw = textscan(fileID,'%s','Delimiter', '\n', 'Whitespace', '');
        data_raw = data_raw{1,1};
        fclose(fileID); 

        % Identify table and meta-data locations
        ind_Ncol = zeros(1,N); ind_head = zeros(1,N);
        ind_lat  = zeros(1,N); ind_lon  = zeros(1,N); ind_time = zeros(1,N);
        for j=1:length(data_raw) % Identify line numbers
            ind_Ncol(j) = contains(data_raw{j},'# name');
            ind_head(j) = strcmp(data_raw{j},'*END*');
            ind_lat(j)  = contains(data_raw{j},'* NMEA Latitude =');
            ind_lon(j)  = contains(data_raw{j},'* NMEA Longitude =');
            ind_time(j) = contains(data_raw{j},'* NMEA UTC (Time) =');
        end
        Ncol(a)  = sum(ind_Ncol);  % number of table columns
        Nhead(a) = find(ind_head); % number of headerlines
        ind_lat  = find(ind_lat);  ind_lat = ind_lat(1); % line number of latitude info
        ind_lon  = find(ind_lon);  ind_lon = ind_lon(1); % line number of longitude info
        ind_time = find(ind_time); ind_time = ind_time(1); % line number of time info
        
        % Read data:
        % i) Identify CTD station name (from filename)
        if isfield(variab,'station')
            ctd.station{a} = variab.station{a};
        else
            idx = strfind(variab.filename,'*');
            ctd.station{a} = files(a).name(idx:end-4);
        end
 
        % ii) Identify meta-information from .cnv-header: Lat,Lon,Time
        lat_str = data_raw{ind_lat};
        lat = str2double(lat_str(19:20)) + str2double(lat_str(22:26))/60;
        if strcmp(lat_str(28),'S'); lat = - lat; end
        lon_str = data_raw{ind_lon};
        lon = str2double(lon_str(20:22)) + str2double(lon_str(24:28))/60;
        if strcmp(lon_str(30),'W'); lon = - lon; end
        ctd.lat(a) = lat; ctd.lon(a) = lon;
        
        time_str = data_raw{ind_time};
        mon = find(strcmp(time_str(21:23),{'Jan','Feb','Mar','Apr','May','Jun','Jul','Oct','Nov','Dec'}));
        ctd.time(a) = datenum(str2double(time_str(28:31)),mon,str2double(time_str(25:26)),...
                              str2double(time_str(33:34)),str2double(time_str(36:37)),str2double(time_str(39:40)));
    
        % iii) Identify max. pressure level across profiles 
        fileID   = fopen(filenme_local); 
        str_Ncol = reshape(repelem('%f ',Ncol(a)),Ncol(a),3)'; str_Ncol = str_Ncol(:)'; str_Ncol = str_Ncol(1:end-1);
        data_raw = textscan(fileID,str_Ncol,'HeaderLines',Nhead(a));
        fclose(fileID); 

        pres        = data_raw{1,variab.loc_pres+1};
        ind_pres(a) = max(pres);
    end

    % Add fields from data columns to MATLAB structure 'ctd'
    pres_max = max(ind_pres);
    ctd.pres    = (1:round(pres_max))'; D = length(ctd.pres); 
    for j=1:length(variab.write)
        ctd.(variab.write{j}) = NaN(D,N);
    end
    dz = median(diff(ctd.pres));
    
    % Read data from each .cnv-file
    for a=1:N
        % iii) Transfer fields from .cnv table to ctd-structure
        % - Read 2D data table (no header) 
        filenme_local = strcat(files(a).folder,'/',files(a).name);
	    fileID   = fopen(filenme_local);
        str_Ncol = reshape(repelem('%f ',Ncol(a)),Ncol(a),3)'; str_Ncol = str_Ncol(:)'; str_Ncol = str_Ncol(1:end-1);
        data_raw = textscan(fileID,str_Ncol,'HeaderLines',Nhead(a));
        fclose(fileID);

        for z=1:D
            pres_sel = data_raw{1,variab.loc_pres+1};
            ind_sel  = find(pres_sel>ctd.pres(z)-dz/2 & pres_sel<=ctd.pres(z)+dz/2);
            for j=1:length(variab.write)
                ctd.(variab.write{j})(z,a) = mean(data_raw{1,variab.loc(j)+1}(ind_sel),'omitnan');
            end
        end
    end
        
    % Derive additional variables of interest using GSW toolbox: 
    ctd.salt       = gsw_SA_from_SP(ctd.sali,ctd.pres,ctd.lon,ctd.lat);
    ctd.theta0     = gsw_pt_from_t(ctd.salt,ctd.temp,ctd.pres,0);
    ctd.dens       = gsw_rho_t_exact(ctd.salt,ctd.temp,ctd.pres);
    ctd.sigmatheta = gsw_pot_rho_t_exact(ctd.salt,ctd.temp,ctd.pres,0)-1000;
    ctd.depth      = -gsw_z_from_p(repmat(ctd.pres,1,length(ctd.lat)),ctd.lat); % depth [m] from pressure and latitude

    % Maximum pressure level of each CTD profile
    ctd.pres_max = NaN(size(ctd.time));
    for j=1:N
        ctd.pres_max(j) = ctd.pres(find(~isnan(ctd.dens(:,j)),1,'last'));
    end
end
