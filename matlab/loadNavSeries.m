function [navData] = loadNavSeries(srcDir,dicomNum,varargin)
%% loadNavSeries(srcDir) opens a GUI to select a dicom-series of navigators
%       starting in srcDir.
%% loadNavSeries(srcDir,seriesNum) loads the dicoms with series number seriesNum
%% [navdata] = loadNavSeries(...) returns a struct holding most data about 
%       the selected dicom series

navData = struct();

percent_sign = '%';
if strcmpi(get(0,'defaultTextInterpreter'),'latex')
    percent_sign = '\%';
end

nArgs = nargin;
opts = processVarargin(varargin{:});
if ~isempty(fieldnames(opts))
    nArgs = 2;
end
if ~isfield(opts,'study')
    opts.study = 1;
end


if nArgs==1 || isempty(dicomNum)

    %% Select navigator series
    % from 'guiPromptSpectroPlotCsi.m'

    % Show DICOM folder tree
    ret.h = Spectro.FileOpenGui(srcDir,true,['Select dicom series'],false);

    % Handle data loading...
    while isvalid(ret.h)
        singleNavSerData = ret.h.waitForItemChosen();

        if isempty(singleNavSerData)
            % Clean up if user closes GUI
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

    dataset.seriesList=[navSeriesData.SeriesNumber];
    dataset.instanceList=ones(1,numel(dataset.seriesList));

    matched      = navSeriesData.Data;
    tmp          = dir(navSeriesData(1).dicomTree.path);
    navData.path = tmp(1).folder;

elseif nArgs==2
    
    dt          = Spectro.dicomTree('dir',srcDir);
    if isempty(dt.study)
        % guess 'dicom' subdir
        dt      = Spectro.dicomTree('dir',fullfile(srcDir,'dicom'));
        if isempty(dt.study)
            % last resort: recursive parsing
            dt  = Spectro.dicomTree('dir',srcDir,'recursive',1);
        end
    end
    tmp         = dt.searchForSeriesNumber(dicomNum);
    matched     = tmp(opts.study);
    tmp         = dir(fileparts(matched.instance(1).Filename));
    navData.path= tmp(1).folder;

end
    
%% LOAD all relevant dicoms
hWait = waitbar(0,'Loading dicoms...','Name','Loading dicoms...');
waitbar(0,hWait,'Loading dicoms...');

% load navigators
fprintf('Loading image-series...')

    tmpInfo      = SiemensCsaParse(dicominfo(matched.instance(1).Filename));
        nAcqs    = numel(matched.instance);
        nSlices  = round( numel(matched.instance) / ( (getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'lRepetitions')+1) * (getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'lAverages')+getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'sSpecPara.lPreparingScans')) * getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'lContrasts') * getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'sPhysioImaging.lPhases') ));
%        nSlices  = getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'sSliceArray.lSize');
        
        tmp_list = dicominfo(matched.instance(1).Filename).ImageOrientationPatient;
        for idx = 2:numel(matched.instance)
            tmp_ori = dicominfo(matched.instance(idx).Filename).ImageOrientationPatient;
            if ~all(tmp_list==tmp_ori)
                tmp_list = cat(2,tmp_list,tmp_ori);
            else
                nSlices = size(tmp_list,2);
                break
            end
        end

        nReps    = nAcqs / nSlices;
        nConcat  = getNumberFromMrProtocol(tmpInfo.csa.MrPhoenixProtocol,'sSliceArray.lConc');
        dcmIma   = zeros([size(dicomread(matched.instance(1).Filename)),nReps,nSlices]);
        dcmInf   = cell(nReps,nSlices);
    
    for instIdx = 1:nReps
        for slcIdx = 1:nSlices
            % load image&info from dicoms
            runIdx = (instIdx-1)*nSlices+slcIdx;
            %refIma{refImaIdx}{instIdx} = myDicomRead(matchedImage.instance(instIdx).Filename);      % without row/col swap
            dcmIma(:,:,instIdx,slcIdx) = dicomread(matched.instance(runIdx).Filename);      % with row/col swap
            dcmInf{instIdx,slcIdx}     = SiemensCsaParse(dicominfo(matched.instance(runIdx).Filename));   % get dicom-header and csa-section!

            waitbar(runIdx/nAcqs,hWait,sprintf('Loading dicoms...%d%s',floor(100*runIdx/nAcqs),percent_sign))
        end
    end

close(hWait);
fprintf('DONE.\n')


%% Fill return struct
navData.nAcqs           = nAcqs;
navData.nSlices         = nSlices;
navData.nReps           = nReps;
navData.dcmIma          = dcmIma;
navData.dcmInf          = dcmInf;
navData.seriesinfo      = matched;


end