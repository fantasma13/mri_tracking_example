function [] = mri_example_tracking(example_number)
%% MRI_EXAMPLE_TRACKING()  loads magnetic resonance imaging navigator data 
%   from dicoms, converts them into a video, runs OpenCV object tracking on
%   the target, writes the in-plane displacements into log-file(s), rotates
%   the in-plane vectors into a common 3D coordinate system (patient
%   coordinate system), combines these displacements using SVD and plots
%   the resulting displacements for each acquisition.
% 
% MRI_EXAMPLE_TRACKING(EXAMPLE_NUMBER) allows to select a different example dataset.
% %TODO [RET] = MRI_EXAMPLE_TRACKING(...) returns the results in RET.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PREPARATION:
% This example uses C++ code from within Matlab. Some preparation steps
%   need to be carried out in advance:
        % 1) Clone the OXSA toolbox into './matlab/OXSA' or add manually add the 'OXSA' folder to the matlab path
            % e.g. from the shell:
            %{
                cd ./matlab
                git clone https://github.com/OXSAtoolbox/OXSA
            %}
        % 2) Build interface libraries for matlab:
            % from Matlab:
            %{
                mexgen_tracking
                mexgen_calcshiftvector
            %}
        % 3) (optional. older Matlab versions) After building the libraries, close Matlab.
        % 4) (optional. older Matlab versions) Temporarily add absolute path to environment LD_LIBRARY_PATH
            % run from shell that you start Matlab from:
            % e.g. in Linux (replace '~/github_example_tracking/' by the
            % absolute path to the example:
            %{
                export LD_LIBRARY_PATH="~/github_example_tracking/libtrackinginmatlab:$LD_LIBRARY_PATH"
                export LD_LIBRARY_PATH="~/github_example_tracking/libcalcshiftvector:$LD_LIBRARY_PATH"
            %}
        % 5) Start Matlab from this shell
        % 6) Test functionionality, or run this script.
            %{
                trackerNum = 2;
                initBbox = [51 37 26 31];
                refIdx = 1;
                clib.libtrackinginmatlab.videoTracking('results/videos/157_flash_nav_set-210526_2slc_SETTER_START_slc-1.avi',trackerNum,refIdx-1,initBbox,true,true)
            %}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% check inputs
    if nargin==0 || isempty(example_number)
        example_number = 1; %{1,2,3,4}
    end

    
%% get path to current file
    mfilePath = mfilename('fullpath');
    if contains(mfilePath,'LiveEditorEvaluationHelper') || isempty(mfilePath)
        mfilePath = matlab.desktop.editor.getActiveFilename;
    end
    maindir = fileparts(fileparts(mfilePath));

cd(maindir);
addpath(genpath(fullfile(maindir,'matlab')))
    addpath(fullfile(maindir,'matlab/libtrackinginmatlab'))
    addpath(fullfile(maindir,'matlab/libcalcshiftvector'))


%% specify input
    iTrackerNum = 2; %{2 3 7}
    video_output_type = 1; %{1}
    bOverwriteExistingVideos = false; %{true,false}

    
%% load dicom
    data        = mri_example_datasets(fullfile(maindir,'data'),example_number);
    navData     = loadNavSeries(data.dicom_dir,data.dicom_num);


%% create video: convert navigator-series dicoms to videos (1/slice)
    tic
    [~,vidNameFull] = dicom2video(navData,video_output_type,bOverwriteExistingVideos,'silent',true);
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
            bIsOk = clib.libtrackinginmatlab.videoTracking(vidNameFull{slcidx},iTrackerNum,data.refIdx-1,data.initBbox(slcidx,:),true,true);
            toc
        
    
        %% read log files
            log_name = sprintf('%s__TRACK_%d_%d_%d_%d_%d.log',bf,iTrackerNum,data.initBbox(slcidx,:));
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
            % simple test:
            bb = [1 2 1]; %lengths
            AA = [[1 0 0],[0 1 0],[1 0 0],[0 1 0]]; % basis vectors
            ww = [1 1 1]; % weights
            res = clib.libcalcshiftvector.MyCalcShiftVector(bb,ww,AA);
            res.double
        %}

        %%
        res = clib.libcalcshiftvector.MyCalcShiftVector(bb(:,fdx)',ww(:,fdx)',AA(:,fdx)');
        motion_3D_vec(:,fdx) = res.double;
    end


%% display result

    hFig = 100+example_number; clf(figure(hFig))
    hAx = axes(figure(hFig));
        plot(hAx,motion_3D_vec')
        legend(hAx,{'SAG','COR','TRA'})
        xlabel('navigator number / -')
        ylabel('displacement / mm')
        title('motion in patient coordinate system [SAG,COR,TRA]')


%% output
    %ret; %TODO
end
