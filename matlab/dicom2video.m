function [navData,video_filenames] = dicom2video(navData,output_type,saveVid,varargin)
%% DICOM2VIDEO() converts a series of dicoms to a video, opens GUI to select.
%
%  DICOM2VIDEO(NAVDATA) allows specification of input.
%
%  DICOM2VIDEO(~,OUTPUT_TYPE) allows specification of output-type:
%       '1' - Image data directly to video
%       '2' - Grab frame
%       '3' - Grab frame, all slices in one figure (default)
%
%  DICOM2VIDEO(~,~,SAVEVIDEO) whether to save the videos or not (true/false).
%
%  [DATA,VIDEO_FILENAMES] = DICOM2VIDEO(...) returns the loaded dicom-data
%           and the filenames of the videos written
%
%  'windowing': true(default)/false
%  'silent':    true/false(default)

video_filenames = [];

if nargin==0
    navData         = [];
    output_type     = 3;
    saveVid         = false;
elseif nargin==1
    output_type     = 3;
    saveVid         = false;
elseif nargin==2
    saveVid         = false;
end

if isempty(output_type)
    output_type     = 3;
end

opts = processVarargin(varargin{:});
if ~isfield(opts,'silent')
    opts.silent = false;
end
if ~isfield(opts,'windowing')
    opts.windowing = true;
end
if ~isfield(opts,'framerate')
    opts.framerate = 24.97;
end

vid_profile = 'Uncompressed AVI';

destDirVids         = 'results/videos/';


%% load navigators
if ~exist('navData','var') || isempty(navData)
    
    startDir = pwd();
    
    % from 'guiPromptSpectroPlotCsi.m'
    % Show DICOM folder tree
    ret.h = Spectro.FileOpenGui(startDir,true,['Select dicom series'],false);

    % Handle data loading...
    while isvalid(ret.h)
        singleNavSerData = ret.h.waitForItemChosen();

        if isempty(singleNavSerData)
            % Clean up if user closes GUI
            return
            break
        end

        if any(strcmp(singleNavSerData.Type,{'Folder','Study'}))
            % Selecting a folder won't work so try again!
            disp('Please select a DICOM series or instance.')
            continue
        end

        try
            navUid = cell(1,numel(ret.h.hTree.current));
            % all selected nodes
            for it=1:numel(ret.h.hTree.current)
                %allData(it) = ret.h.hTree.current(it).treenode.Data;
                treedata = ret.h.hTree.evalin('treedata');
                navSeriesData(it) = treedata(ret.h.hTree.current(it).treenodeId);
                % Load the relevant data
                if strcmp(navSeriesData(it).Type,'Series')
                    % theDicomPath = fileparts(thisData.Data.instance(1).Filename);
                    % identifyDicomFilesInDir(theDicomPath); % Run this to check which files wanted below.
                    navUid{it} = navSeriesData(it).Data.SeriesInstanceUID;
                    fprintf('\n\nLoading SERIES spectra <a href="matlab:clipboard(''copy'',''%s'')">%s</a> from <a href="matlab:clipboard(''copy'',''%s'')">%s</a>...\n\n',navUid{it},navUid{it},navSeriesData(it).dicomTree.path,navSeriesData(it).dicomTree.path);
                else
                    % theDicomPath = fileparts(thisData.Data.Filename);
                    navUid{it} = {navSeriesData(it).Data.SOPInstanceUID};
                    fprintf('\n\nLoading INSTANCE spectra <a href="matlab:clipboard(''copy'',''%s'')">%s</a> from <a href="matlab:clipboard(''copy'',''%s'')">%s</a>...\n\n',navUid{it},navUid{it},navSeriesData(it).dicomTree.path,navSeriesData(it).dicomTree.path);
                end
            end

        waitObj = autoWaitCursor(ret.h.hFig);

        clear waitObj;

        % Close figure now
        delete(ret.h)
        catch ME
            disp('Caught error loading')
            fprintf('%s',getReport(ME))
        end
    end
    

    %% load all relevant dicoms
    hWait = waitbar(0,'Loading dicoms...','Name','Loading dicoms...');
    waitbar(0,hWait,'loading dicoms...');

    % load navigators
    disp('loading image-series...')

        matchedImage = navSeriesData.Data;
        tmpInfo      = SiemensCsaParse(dicominfo(matchedImage.instance(1).Filename));
            nAcqs    = numel(matchedImage.instance);
            %nSlices  = round(numel(matchedImage.instance) / ( (getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'lRepetitions')+1) * getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'lAverages') * getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'sPhysioImaging.lPhases') ));
            nSlices  = max(1, round(numel(matchedImage.instance) / ( (getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'lRepetitions')+1) * getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'lAverages') * getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'sPhysioImaging.lPhases') )));
            nRefImas = numel(matchedImage.instance) / nSlices;
            refIma   = zeros([size(dicomread(matchedImage.instance(1).Filename)),nRefImas,nSlices]);
            refInf   = cell(nRefImas,nSlices);

        for instIdx = 1:nRefImas
            for slcIdx = 1:nSlices
                % load image&info from dicoms
                runIdx = (instIdx-1)*nSlices+slcIdx;
                %refIma{refImaIdx}{instIdx} = myDicomRead(matchedImage.instance(instIdx).Filename);      % without row/col swap
                refIma(:,:,instIdx,slcIdx) = dicomread(matchedImage.instance(runIdx).Filename);      % with row/col swap
                refInf{instIdx,slcIdx}     = SiemensCsaParse(dicominfo(matchedImage.instance(runIdx).Filename));   % get dicom-header and csa-section!

                waitbar(runIdx/nAcqs,hWait,sprintf('loading dicoms...%d%s',floor(100*runIdx/nAcqs),'\%'))
            end
        end

    close(hWait);

    % fill navData
    navData.path        = navSeriesData(1).dicomTree.path;
    navData.nAcqs       = nAcqs;
    navData.nSlices     = nSlices;
    navData.nReps       = nRefImas;
    navData.seriesinfo  = matchedImage;
    navData.dcmIma      = refIma;
    navData.dcmInf      = refInf;

    clear navSeriesData matchedImage
    
end



%% checks
baseDir = fileparts(navData.path);
vidDirPath  = fullfile(baseDir,destDirVids);
if ~exist(vidDirPath,'dir')
    disp('destination directory for figures does not yet exist, creating it...')
    mkdir(vidDirPath);
end




%% 
switch output_type

    case 1
        %% Image data directly to video
        tic
        for slcIdx = 1:navData.nSlices

            if ~opts.silent
                hFig = 332+slcIdx;
                figure(hFig);
                hIm = imshow(navData.dcmIma(:,:,1,slcIdx),[]);
            end

            vid_fullname = [vidDirPath num2str(navData.seriesinfo.SeriesNumber) '_' char(strrep(navData.seriesinfo.SeriesDescription,' ','_')) '_slc-' num2str(slcIdx) '.avi'];
            if saveVid
                %vid_profile = 'Motion JPEG AVI';
                vid = VideoWriter(vid_fullname,vid_profile);
                vid.FrameRate = opts.framerate;
                %vid.Quality = 100;
                open(vid);
                disp(['writing video ' vid.Filename])
            end

            for instIdx = 1:navData.nReps

                if ~opts.silent
                    if saveVid
                        fprintf('writing ')
                    else
                        fprintf('displaying ')
                    end
                    fprintf('video frame #%d/%d', instIdx,navData.nReps)
                end

                %writeVideo(vid,uint8(navData.dcmIma(:,:,instIdx,slcIdx)));
                
                maxV = max(navData.dcmIma(:,:,:,slcIdx),[],'all');
                tmpImaDat = navData.dcmIma(:,:,instIdx,slcIdx)/maxV;
                % use DICOM windowing
                if opts.windowing
                    tmpImaDat = tmpImaDat * maxV;
                    imaCDataLimits = [navData.dcmInf{instIdx,slcIdx}.WindowCenter - navData.dcmInf{instIdx,slcIdx}.WindowWidth/2 navData.dcmInf{instIdx,slcIdx}.WindowCenter + navData.dcmInf{instIdx,slcIdx}.WindowWidth/2];
                    tmpImaDat = 0.5 + (tmpImaDat - mean(imaCDataLimits)) / range(imaCDataLimits);
                    tmpImaDat(tmpImaDat<0) = 0;
                    tmpImaDat(tmpImaDat>1) = 1;
                end
                % apply gamma correction
                if false
                    tmpImaDat = gamma_correction_image(tmpImaDat);
                end

                if saveVid
                    writeVideo(vid,tmpImaDat);
                end

                if ~opts.silent
            %        hIm.CData = navData.dcmIma(:,:,instIdx,slcIdx);
            %        caxis( imaCDataLimits );
                    hIm.CData = tmpImaDat;
                    caxis('auto');
                    drawnow
                end

                if ~opts.silent
                    fprintf(' (%f s)\n',toc)
                end
            end

            video_filenames{slcIdx} = fullfile(vid_fullname);
            if saveVid
                close(vid);
                disp(['finished writing video ' vid.Filename])
            end
        end
        toc

        
        
    case 2
        %% grab frame
        tic
        for slcIdx = 1:navData.nSlices

            hFig = 332+slcIdx;
            figure(hFig);
            set(hFig,'Visible',~opts.silent)
            hIm = imshow(navData.dcmIma(:,:,1,slcIdx),[]);
            
            vid_fullname = [vidDirPath num2str(navData.seriesinfo.SeriesNumber) '_' char(strrep(navData.seriesinfo.SeriesDescription,' ','_')) '_slc-' num2str(slcIdx) '.avi'];
            if saveVid
                vid = VideoWriter(vid_fullname,vid_profile);
                vid.FrameRate = opts.framerate;
                vid.Quality = 100;
                open(vid);
                disp(['writing video ' vid.Filename])
            end

            for instIdx = 1:navData.nReps

                if ~opts.silent
                    if saveVid
                        fprintf('writing ')
                    else
                        fprintf('displaying ')
                    end
                    fprintf('video frame #%d/%d', instIdx,navData.nReps)
                end

                %writeVideo(vid,uint8(navData.dcmIma(:,:,instIdx,slcIdx)));
                tmpImaDat = navData.dcmIma(:,:,instIdx,slcIdx);
                if opts.windowing
                    imaCDataLimits = [navData.dcmInf{instIdx,slcIdx}.WindowCenter - navData.dcmInf{instIdx,slcIdx}.WindowWidth/2 navData.dcmInf{instIdx,slcIdx}.WindowCenter + navData.dcmInf{instIdx,slcIdx}.WindowWidth/2];
                    tmpImaDat = 0.5 + (navData.dcmIma(:,:,instIdx,slcIdx) - mean(imaCDataLimits)) / range(imaCDataLimits);
                    tmpImaDat(tmpImaDat<0) = 0;
                    tmpImaDat(tmpImaDat>1) = 1;
                end

                hIm.CData = tmpImaDat;
                caxis('auto');
                drawnow

                if saveVid
                    thisFrame = getframe(hIm.Parent);
                    writeVideo(vid,thisFrame);
                end

                if ~opts.silent
                    fprintf(' (%f s)\n',toc)
                end
            end

            video_filenames{slcIdx} = fullfile(vid_fullname);
            if saveVid
                close(vid);
                disp(['finished writing video ' vid.Filename])
            end
        end
        toc

        
        

    case 3
        %% grab frame, all slices in one figure
        tic
        
        hFig = 332;
        figure(hFig);
        set(hFig,'Visible',~opts.silent)
        
        for slcIdx = 1:navData.nSlices
            hSub(slcIdx) = subplot(1,navData.nSlices,slcIdx);
            hIm(slcIdx) = imshow(navData.dcmIma(:,:,1,slcIdx),[],'Parent', hSub(slcIdx));
        end
        
        vid_fullname = [vidDirPath num2str(navData.seriesinfo.SeriesNumber) '_' char(strrep(navData.seriesinfo.SeriesDescription,' ','_')) '_slc' sprintf('-%d',1:navData.nSlices) '.avi'];
        if saveVid
            vid = VideoWriter(vid_fullname,vid_profile);
            vid.FrameRate = opts.framerate;
            vid.Quality = 100;
            open(vid);
            disp(['writing video ' vid.Filename])
        end

        for instIdx = 1:navData.nReps
            
            if ~opts.silent
                if saveVid
                    fprintf('writing ')
                else
                    fprintf('displaying ')
                end
                fprintf('video frame #%d/%d', instIdx,navData.nReps)
            end

            for slcIdx = 1:navData.nSlices
                tmpImaDat = navData.dcmIma(:,:,instIdx,slcIdx);
                if opts.windowing
                    imaCDataLimits = [navData.dcmInf{instIdx,slcIdx}.WindowCenter - navData.dcmInf{instIdx,slcIdx}.WindowWidth/2 navData.dcmInf{instIdx,slcIdx}.WindowCenter + navData.dcmInf{instIdx,slcIdx}.WindowWidth/2];
                    tmpImaDat = 0.5 + (navData.dcmIma(:,:,instIdx,slcIdx) - mean(imaCDataLimits)) / range(imaCDataLimits);
                    tmpImaDat(tmpImaDat<0) = 0;
                    tmpImaDat(tmpImaDat>1) = 1;
                end

                hIm(slcIdx).CData = tmpImaDat;
                colormap(hFig,'gray')
                caxis(hSub(slcIdx),'auto');
            end
            drawnow
            
            if saveVid
                thisFrame = getframe(hFig);
                writeVideo(vid,thisFrame);
            end

            if ~opts.silent
                fprintf(' (%f s)\n',toc)
            end

        end
        
        video_filenames{slcIdx} = fullfile(vid_fullname);
        if saveVid
            close(vid);
            disp(['finished writing video ' vid.Filename])
        end
        toc

        
    
    
end

end