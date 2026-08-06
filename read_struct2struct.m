function ctd = read_struct2struct(data_input,variab_read,variab_write,variab_pres)
    % READ_STRUCT2STRUCT Bring collection of CTD profiles from a cruise
    %                    into shape required for CruizeViz processing & plotting 
    %                    if data is currently provided as a MATLAB
    %                    structure with CTD profiles saved within
    %                    individual structure array cells. 
    % (reading/writing function)
    %
    % INPUT:
    %   data_input   = MATLAB structure of CTD pfofiles in following format:
    %                   - 1D variables as 
    %                   - 2D variables as cell array with every profile saved
    %                     as an inividual cell entry, i.e., the n-th profile 
    %                     vector of variable 'vari' can be asscessed via 
    %                     data_input.(vari){n}
    %   variab_read  = 1D cell array with strings of variable names to be
    %                  read from data_input; the following variables are
    %                  mandatory: 
    %                       - Station name (string array)
    %                       - Time (double)
    %                       - Longitude [degE]
    %                       - Latitude [degN]
    %                       - Pressure vector for each profile [db]
    %                       - In-situ temperature [degC]
    %                       - Practical salinity [PSU]
    %   variab_write = 1D cell array with string of variable names as they
    %                  should appear in the output MATLAB structure (listed in 
    %                  the same order than for 'variab_read'); the following 
    %                  variable names should be used to be correctly
    %                  identified by CruiseViz functions: 
    %                       - 'station' = Station name 
    %                       - 'time'    = Time 
    %                       - 'lon'     = Longitude 
    %                       - 'lat'     = Latitude 
    %                       - 'pres'    = Pressure vector
    %                       - 'temp'    = In-situ temperature 
    %                       - 'sali'    = Practical salinity
    %   variab_pres  = variable name (string) used to depict pressure
    %                  vector in 'data_input'
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
    %                                'variab_read'
    %               - pres_max (1xN)= Vector of max. profile pressure level [db]
    %   
    % SEE ALSO:
    %   read_cnv2struct
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-07-28

    % Setup Matlab structure 'data_input'
    data_ini  = data_input;
    clear data;
    data_name = fieldnames(data_ini);
    if length(data_name)>1
        data = data_ini;
    else
        variab_name = fieldnames(data_ini.(data_name{1}));
        for j=1:length(variab_name)
            data.(variab_name{j}) = data_ini.(data_name{1}).(variab_name{j});
        end
    end
    N = length(data.(variab_name{1}));
    clear data_ini data_name variab_name data_input;
    
    
    % Find pressure of deepest profile
    ind_pres = NaN(N,1);
    if iscell(variab_pres)
        variab_pres = variab_pres{1};
    end
    for n=1:N
        ind_pres(n) = max(data.(variab_pres){n});
    end
    pres_max = max(ind_pres);
    
    % Transfer data
    clear ctd;
    ctd.nb = 1:N;

    % i) Check which fields are vectors or cell arrays with individual profiles
    variab_dim = ones(1,length(variab_read));
    for j=1:length(variab_read)
        if iscell(data.(variab_read{j})) && isa(data.(variab_read{j}){1},'double')
            variab_dim(j) = 2;
        end
    end

    % ii) Transfer 1D vectors
    for j=1:length(variab_read)
        if variab_dim(j)==2; continue; end
        ctd.(variab_write{j}) = data.(variab_read{j});
    end

    % iii) Transfer 2D vectors
    ctd.pres  = (1:round(pres_max))'; D = length(ctd.pres); dz = median(diff(ctd.pres));
    ctd.z     = -gsw_z_from_p(repmat(ctd.pres,1,length(ctd.lat)),ctd.lat); % depth [m] from pressure and latitude
    for j=1:length(variab_read)
        if variab_dim(j)==1; continue; end
        ctd.(variab_write{j}) = NaN(D,N);
        for n=1:N
            for z=1:D
                pres_sel = data.(variab_pres){n};
                ind_sel  = find(pres_sel>ctd.pres(z)-dz/2 & pres_sel<=ctd.pres(z)+dz/2);
                ctd.(variab_write{j})(z,n) = mean(data.(variab_read{j}){n}(ind_sel),'omitnan');
            end
        end
    end

    % Make field 'time' 1D if it's not already
    if ~any(size(ctd.time)==1)
        ctd.time = median(ctd.time,'omitnan');
    end

    % Derive additional variables of interest using GSW toolbox: 
    ctd.salt       = gsw_SA_from_SP(ctd.sali,ctd.pres,ctd.lon,ctd.lat);
    ctd.theta0     = gsw_pt_from_t(ctd.salt,ctd.temp,ctd.pres,0);
    ctd.dens       = gsw_rho_t_exact(ctd.salt,ctd.temp,ctd.pres);
    ctd.sigmatheta = gsw_pot_rho_t_exact(ctd.salt,ctd.temp,ctd.pres,0)-1000;
    
    % Maximum pressure level of each CTD profile
    ctd.pres_max = NaN(size(ctd.time));
    for j=1:N
        ctd.pres_max(j) = ctd.pres(find(~isnan(ctd.dens(:,j)),1,'last'));
    end
     
end