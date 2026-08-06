function ind = cv_station2ind(station,station_str)
    % STATION2IND Identify indices of string station names
    % (helper function under utils/)
    %   
    % INPUT:
    %   station     = 1D cell-array (1xN) with all N string station names
    %   station_str = 1D cell-array (1xM) with M string station names to find
    % OUTPUT:
    %   ind         = 1D array (1xM) with indices of M stations of interest
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-08-06


    ind = NaN(size(station_str));
    for j=1:length(ind)
        ind_sel = find(strcmp(station,station_str{j}));
        if isempty(ind_sel)
            disp(strcat("Station #",station_str{j}," was not found!"))
        end
        ind(j) = ind_sel;
    end
end