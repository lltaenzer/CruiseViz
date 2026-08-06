function station_str = station_string(station)
    % STATION_STR Create string array for naming stations by only listing 
    %             stations when station order is not a simple sequence,
    %             e.g., to avoid overlap when plotting transects
    % (helper function under utils/)
    %
    % INPUT:
    %   station = 1D cell array listing station string names of transect in order 
    %   
    % OUTPUT:
    %   station_str = 1D cell array listing station string names of
    %                 transect as they should appear in transect plots
    %
    % SEE ALSO:
    %   plot_transect.m
    % 
    % Author: Lukas Taenzer
    % Version: 1.0
    % Last updated: 2026-07-28

    % Set up arrays
    station_str        = station;
    %station_str_length = median(cellfun(@numel,station_str));
    station_nb         = NaN(size(station_str));
    
    % Transfer strings to numbers
    for j=1:length(station_str) 
        %station_nb(j) = str2double(station_str{j}(1:station_str_length));
        station_nb(j) = str2double(station_str{j});
    end

    % Identify locations with more complicated station names (not just numbers)
    % and their direct neighbors
    ind_nodouble = isnan(station_nb); 
    ind_nodouble(2:end-1) = ind_nodouble(2:end-1)+ind_nodouble(1:end-2)+ind_nodouble(3:end);
    ind_nodouble = (ind_nodouble~=0);

    % omit station name if part of simple sequence
    jump_station = abs(diff(station_nb));
    for j=1:length(jump_station)-1
        if (jump_station(j)==1 && jump_station(j+1)==1) || ~ind_nodouble(j+1)
            station_str{j+1} = ''; 
        end
    end

    station_str = strip(station_str,'left','0'); % remove leading zeros
end