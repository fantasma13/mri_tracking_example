%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PREPARATION:
% This example uses C++ code from within Matlab. Some preparation steps
%   need to be carried out in advance:
        % 0.a) clone the OXSA toolbox into './matlab/OXSA' or add manually add the 'OXSA' folder to the matlab path
            % e.g. from the shell:
            %{
                cd ./matlab
                git clone https://github.com/OXSAtoolbox/OXSA
            %}
        % 0.b) build libraries for matlab (they are prebuilt, but in case you need to re-build them):
            % from Matlab:
            %{
                mexgen_tracking
                mexgen_calcshiftvector
            %}
        % 1) after building the libraries, close Matlab.
        % 2) temporarily add absolute path to environment LD_LIBRARY_PATH
            % run from shell that you start Matlab from:
            % e.g. in Linux (replace '~/github_example_tracking/' by the
            % absolute path to the example:
            %{
                export LD_LIBRARY_PATH="~/github_example_tracking/tracking4matlablib:$LD_LIBRARY_PATH"
                export LD_LIBRARY_PATH="~/github_example_tracking/calcshiftvectorlib:$LD_LIBRARY_PATH"
            %}
        % 3) start Matlab from this shell
        % 5) test function
            %{
                trackerNum = 2;
                initBbox = [51 37 26 31];
                refIdx = 1;
                clib.tracking4matlablib.videoTracking('results/videos/157_flash_nav_set-210526_2slc_SETTER_START_slc-1.avi',trackerNum,refIdx-1,initBbox,true,true)
            %}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
%% get path to current file
    mfilePath = mfilename('fullpath');
    if contains(mfilePath,'LiveEditorEvaluationHelper') || isempty(mfilePath)
        mfilePath = matlab.desktop.editor.getActiveFilename;
    end
    maindir = fileparts(fileparts(mfilePath));

cd(maindir);
addpath(genpath(fullfile(maindir,'matlab')))
addpath(fullfile(maindir,'matlab/libtracking4matlab'))
addpath(fullfile(maindir,'matlab/calcshiftvectorlib'))
%{
    setenv('PATH',           [char(fullfile(maindir,'matlab','tracking4matlablib')) ':' getenv('PATH')]);
    setenv('LD_LIBRARY_PATH',[char(fullfile(maindir,'matlab','tracking4matlablib')) ':' getenv('LD_LIBRARY_PATH')])
    setenv('PATH',           [char(fullfile(maindir,'matlab','calcshiftvectorlib')) ':' getenv('PATH')]);
    setenv('LD_LIBRARY_PATH',[char(fullfile(maindir,'matlab','calcshiftvectorlib')) ':' getenv('LD_LIBRARY_PATH')])
%}

%import clib.calcshiftvectorlib.*
%import clib.tracking4matlablib.*


%% shipped examples:
    xmpl_data = struct([]);

    % example 1
        xmpl_data(1).dicom_dir = fullfile(maindir,'data/phantom_1');    % path to dicoms
        xmpl_data(1).dicom_num = 157;                 % dicom series number
        xmpl_data(1).refIdx    = 1;                   % reference index for motion calculation (MATLAB indexing starting from 1)
        xmpl_data(1).initBbox  = [ [51 37 26 31];...
                                   [46 29 28 31] ];   % initial bounding box for the two slices

    % example 2
        xmpl_data(2).dicom_dir = fullfile(maindir,'data/phantom_2');    % path to dicoms
        xmpl_data(2).dicom_num = 31;                  % dicom series number
        xmpl_data(2).refIdx    = 1;                   % reference index for motion calculation (MATLAB indexing starting from 1)
        xmpl_data(2).initBbox  = [ [25 22 69 75];...
                                   [44 29 66 74] ];   % initial bounding box for the two slices

    % example 3
        xmpl_data(3).dicom_dir = fullfile(maindir,'data/phantom_3');    % path to dicoms
        xmpl_data(3).dicom_num = 39;                  % dicom series number
        xmpl_data(3).refIdx    = 1;                   % reference index for motion calculation (MATLAB indexing starting from 1)
        xmpl_data(3).initBbox  = [ [30 58 47 24];...
                                   [51 34 45 26] ];   % initial bounding box for the two slices

    % example 4
        xmpl_data(4).dicom_dir = fullfile(maindir,'data/phantom_4');    % path to dicoms
        xmpl_data(4).dicom_num = 71;                  % dicom series number
        xmpl_data(4).refIdx    = 1;                   % reference index for motion calculation (MATLAB indexing starting from 1)
        xmpl_data(4).initBbox  = [ [49 62 28 35];...
                                   [22 55 37 47] ];   % initial bounding box for the two slices


%% specify input
    use_example_number = 1; %{1,2,3,4}

    trackerNum = 2; %{2 3 7}
    video_output_type = 1; %{1}
    saveDicomAsVideos = true; %{true,false}

    
%% load dicom
    data        = xmpl_data(use_example_number);
    navData     = loadNavSeries(data.dicom_dir,data.dicom_num);


%% create video: convert navigator-series dicoms to videos (1/slice)
    tic
    [~,vidNameFull] = dicom2video(navData,video_output_type,false,'silent',true);
    if any(arrayfun(@(x) ~exist(x{:},'file'),vidNameFull))
        [~,vidNameFull] = dicom2video(navData,video_output_type,true,'silent',false);
    end                    
    vid_dir         = fileparts(vidNameFull{1});
    toc


%% for each navigator slice
    bb = [];
    AA = [];
    for slcidx = 1:navData.nSlices
    
        [~,bf,cf]=fileparts(vidNameFull{slcidx});
    
        %% run tracking
            cd(vid_dir)
            tic
            fprintf("slice %d\n",slcidx);
            bIsOk = clib.libtracking4matlab.videoTracking(vidNameFull{slcidx},trackerNum,data.refIdx-1,data.initBbox(slcidx,:),true,true);
            toc
        c
 tracking4maltab   
        %% read log files
            log_name = sprintf('%s__TRACK_%d_%d_%d_%d_%d.log',bf,trackerNum,data.initBbox(slcidx,:));
            fprintf(log_name);
            log_file = fullfile(vid_dir,log_name);
            if ~exist(log_file,'file')
                error('couldnt find logfile')
            end
        
            % read bounding box logfiles. BBOX: [left bottom width height]
            [bbox_xywh,~,~] = readTrackingLog(log_file);
            % convert [left bottom width height] to [left bottom right top]
            positionBbox = bbox2bbox(bbox_xywh);  % xywh->xyxy
            
    
        %% displacement
            motionBbox_px = positionBbox - positionBbox(:,data.refIdx);
            motionBbox_mm = motionBbox_px .* repmat(navData.dcmInf{1,slcidx}.PixelSpacing,2,1);
    
        
        %% coordinate transformation
            uvecs = reshape(navData.dcmInf{1,slcidx}.ImageOrientationPatient,3,2);
            rotMat = [uvecs, cross(uvecs(:,1),uvecs(:,2))];
    
        
        %% create features
            % "length"/position of the feature
                bb = cat(1,bb,motionBbox_mm); % add singleton dimension
    
            % compose the direction of the bounding boxes' features:
                % 1st: [1 0 0], 2nd: [0 1 0], 3rd: [1 0 0], 4th: [0 1 0]
                %   This originates from the way object tracking is working on
                %   rectangular (non-rotated) bounding boxes. 
                %   Could generally be arbitrary directions, if returned
                %   from the tracking algorithm.
                directions  = [[1 0 0]; [0 1 0];[1 0 0]; [0 1 0];];
                AA_dcm      = repmat(directions,[1 1 navData.nReps]);
                AA_pcs      = pagemtimes(AA_dcm,rotMat');
                AA_list     = reshape(permute(AA_pcs,[2 1 3]),4*3,navData.nReps);
                AA          = cat(1,AA,AA_list);
            
    
    end % end slice loop
    

%% combine features

    bb;                     % lengths
    AA;                     % basis vectors
    ww = ones(size(bb));    % weights

    motion_3D_vec = nan(3,navData.nReps);
    
    for fdx = 1:navData.nReps
        %%
        %{
            bb = [1 2 1]; %lengths
            AA = [[1 0 0],[0 1 0],[1 0 0],[0 1 0]]; % basis vectors
            ww = [1 1 1]; % weights
            res = clib.calcshiftvectorlib.MyCalcShiftVector(bb,ww,AA);
            res.double
        %}

        %%
        res = clib.calcshiftvectorlib.MyCalcShiftVector(bb(:,fdx)',ww(:,fdx)',AA(:,fdx)');
        motion_3D_vec(:,fdx) = res.double;
    end

    hFig = 101; clf(figure(hFig))
    hAx = axes(figure(hFig));
        plot(hAx,motion_3D_vec')
        legend(hAx,{'SAG','COR','TRA'})
        xlabel('repetition / -')
        ylabel('displacement / mm')
        title('motion in patient coordinate system')
