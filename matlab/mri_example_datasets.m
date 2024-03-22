function [ret] = mri_example_datasets(maindir,example_number)
%% [RET] = MRI_EXAMPLE_DATASETS() returns an exemplary MRI navigator 
%   dataset of a phantom measurement. Expects the dicom files in a
%   subfolder "phantom_1" of the current directory.
%  [...] = MRI_EXAMPLE_DATASETS(MAINDIR) allows to specify the location of
%   the data folder.
%  [...] = MRI_EXAMPLE_DATASETS(...,EXAMPLE_NUMBER) additionally allows to 
%   specify the selected example [1..4], default: 1.
% 
% Shipped examples:
%   (1) 2 navigator slices (sagittal+coronal) of a heart-shaped phantom in a
%       motion phantom, as presented in: 
%       (under review) [Koerner et al, Front. Phys., 2024 "A modular torso 
%       phantom featuring a pneumatic stepper and flow for MR sequence development"].
%   (2) 2 oblique (!) navigator slices of a container translated transversally.
%   (3) 2 navigator slices (sagittal+coronal) of a container translated transversally.
%   (4) 2 navigator slices (sagittal+coronal) of the heart-shaped phantom in
%       a different motion phantom.


%% check inputs
    if nargin<1 || isempty(maindir)
        maindir = pwd();
    end
    if nargin<2 || isempty(example_number)
        example_number = 1; %{1,2,3,4}
    end


%% example struct
    xmpl_data = struct([]);

    % example 1
        xmpl_data(1).dicom_dir = fullfile(maindir,'phantom_1');    % path to dicoms
        xmpl_data(1).dicom_num = 157;                 % dicom series number
        xmpl_data(1).refIdx    = 1;                   % reference index for motion calculation (MATLAB indexing starting from 1)
        xmpl_data(1).initBbox  = [ [51 37 26 31];...
                                   [46 29 28 31] ];   % initial bounding box for the two slices

    % example 2
        xmpl_data(2).dicom_dir = fullfile(maindir,'phantom_2');    % path to dicoms
        xmpl_data(2).dicom_num = 31;                  % dicom series number
        xmpl_data(2).refIdx    = 1;                   % reference index for motion calculation (MATLAB indexing starting from 1)
        xmpl_data(2).initBbox  = [ [25 22 69 75];...
                                   [44 29 66 74] ];   % initial bounding box for the two slices

    % example 3
        xmpl_data(3).dicom_dir = fullfile(maindir,'phantom_3');    % path to dicoms
        xmpl_data(3).dicom_num = 39;                  % dicom series number
        xmpl_data(3).refIdx    = 1;                   % reference index for motion calculation (MATLAB indexing starting from 1)
        xmpl_data(3).initBbox  = [ [30 58 47 24];...
                                   [51 34 45 26] ];   % initial bounding box for the two slices

    % example 4
        xmpl_data(4).dicom_dir = fullfile(maindir,'phantom_4');    % path to dicoms
        xmpl_data(4).dicom_num = 71;                  % dicom series number
        xmpl_data(4).refIdx    = 1;                   % reference index for motion calculation (MATLAB indexing starting from 1)
        xmpl_data(4).initBbox  = [ [49 62 28 35];...
                                   [22 55 37 47] ];   % initial bounding box for the two slices


%% check outputs
    if example_number>numel(xmpl_data)
        warning('invalid example dataset selected, returning default (first) dataset')
        example_number = 1;
    end
    if ~exist(xmpl_data(example_number).dicom_dir,'dir')
        error('couldnt find any data in the provided directory, aborting...')
    end


%% results
    ret = xmpl_data(example_number);


end