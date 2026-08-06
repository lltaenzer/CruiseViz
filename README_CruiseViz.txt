CruiseViz

Version: 	1.0
Release date: 	2026-08-06
Author: 	Lukas Taenzer (Stockholm University)
License: 	MIT 
Written in:	MATLAB R2025b

DESCRIPTION
CruiseViz is a MATLAB toolbox for rapid visualization and first-order analysis
of CTD transects with special support for incorporating processed Seabird CTD 
files and for plotting transects in regions with complex bathymetry 
(e.g., fjords) through optional bathymetry-guided interpolation and extrapolation.

MAIN FUNCTIONS
1) READING
	- read_cnv2struct.m (Read collection of Seabird .cnv-files into CruiseViz format)
	- read_struct2struct.m (Convert existing MATLAB structures into CruiseViz format)
2) PROCESSING
	- design_transect.m (Generate interpolated transects)
3) PLOTTING
	- plot_transect.m (Plot individual transect sections)
	- plot_map.m (Plot station map and transect path)
	- plot_transect_collage.m (Create overview figure consisting of main transects, 
			           T-S plot, and station/transect map)

INSTALLATION
- Add the CruiseViz folder, including all subfolders, to the MATLAB path (Home -> Set Path)
- Run the tutorial from the folder in which it is saved.

INPUT DATA
- bathymetry data as Matlab structure (see 'data_example/bathymetry_johanpeterson_bedm6.mat')
- CTD profile data in variable formats:
	- Collection of processed Seabird .cnv-files 
	- Matlab structure of cell arrays for individual profiles
 	  (see 'data_example/ctd_struct_raw_isertupkangertiva2024.mat' as example)
	- Matlab structure in CruizeViz format
	  (see 'data_example/ctd_johanpeterson2025_ready2plot.mat' as example)

DEPENDENCIES
	- MATLAB
	- Selection of GSW TEOS-10 functions by McDougall & Barker (2011) - included
	- cmocean colormaps by Thyng et al. (2016) - included

DOCUMENTATION
See "Tutorial_CruiseViz" (either .mlx or .html) for first guidance of functions 
(reading and plotting) and possible user parameter choices. For a complete view
of functionality, see documentation of individual functions. 

CONTACT
Lukas Taenzer (Stockholm University)
Email: lukas.taenzer@geo.su.se
GitHub: https://github.com/lltaenzer/CruiseViz
