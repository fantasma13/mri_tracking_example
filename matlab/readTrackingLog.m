function [bboxPos,trackerId,info] = readTrackingLog(filelist,varargin)
%% READTRACKINGLOG(filelist) reads the logfile(s) provided by opencv_trackVideo,
%       returns the boundingbox in the ROW/COL coordinate system of the image, 
%       expects the most recent version of the log-file.
%
% READTRACKINGLOG(filename,version) uses the specified version to parse the file.
%
% boxPos ==> (nFiles,nReps,[bbox_left, bbox_right, bbox_top, bbox_bottom])
% e.g.
%   filelist=dir(['./c-resp_13_3T_30_triggered__TRACK_0_' '*.log']);
%   readTrackingLog({filelist.name})

if ischar(filelist)
    filelist = {filelist};
end

opts = processVarargin(varargin{:});
if ~isfield(opts,'quiet')
    opts.quiet = false;
end

%% init variables
nFeatFound = [];


nFiles = numel(filelist);
bboxlog= cell(1,nFiles);

trackerId   = -1*ones(nFiles,1);
initbbox    = zeros(4,nFiles);
initcenter  = zeros(2,nFiles);
initsize    = zeros(2,nFiles);

%% Parse filename
for iFile=1:nFiles
    filename=filelist{iFile};
    try
        tmp=substr(filename,strfind(filename,'TRACK')+length('TRACK'),length(filename));
        tmp=substr(tmp,0,strfind(tmp,'.log')-1);
    catch
        tmp=filename(1+strfind(filename,'TRACK')+length('TRACK'):length(filename));
        tmp=tmp(1:strfind(tmp,'.log')-1);
    end
    tmp=str2double(strsplit(tmp,'_'));
    trackerId(iFile)=tmp(1)+1; % ATTENTION!
%    initbbox(:,iFile)=tmp(2:5);
%    initcenter(:,iFile) = [initbbox(1,iFile)+initbbox(3,iFile)/2 initbbox(2,iFile)+initbbox(4,iFile)/2];
%    initsize(:,iFile)   = [initbbox(3,iFile) initbbox(4,iFile)];
end


%bboxPos = nan(4,1,max(trackerId),nFiles);
bboxPos = nan(4,1,nFiles);
info = struct('nFailures',nan(1,nFiles),'fps_mean',nan(1,nFiles),'fps_std',nan(1,nFiles),'spf_mean',nan(1,nFiles),'spf_std',nan(1,nFiles));

    
    %% VOXlog logfile
    if ~opts.quiet
        disp('reading TRACKING logfiles ...')
    end
    iRepIdx = 0;
    for iFile=1:nFiles
        if ~opts.quiet
            disp(['                          ' num2str(iFile) '/' num2str(nFiles)])
        end
        filename=filelist{iFile};
        bboxlog{iFile}=readtext(char(filename));
        
        for iLineIdx=1:numel(bboxlog{iFile})
            % -- SEQ -------------------------------------------------------- %
            buffer=[strsplit(char(bboxlog{iFile}{iLineIdx,:}))];
            
            % check whether is comment ('#...') or text
            if isempty(regexp(buffer{1},'(^#)|(^\s+#)')) && ~isempty(buffer{1})
                
                iRepIdx = iRepIdx + 1;
                % retrieve data
                tmp = reshape(str2double(buffer(:)),4,[]);
                if iRepIdx == 1 && size(tmp,2) > 1  % multitracking
                    %bboxPos = nan(4,1,max(trackerId),nFiles,size(tmp,2));
                    bboxPos = nan(4,1,nFiles,size(tmp,2));
                end
                %bboxPos(:,iRepIdx,trackerId(iFile),iFile,:)    = tmp;
                bboxPos(:,iRepIdx,iFile,:)    = tmp;
                
            elseif ~isempty(regexp(buffer{1},'(^#)|(^\s+#)'))
                
                if any(contains({buffer{1},buffer{2}},'failures'))
                    info.nFailures(iFile) = str2double(buffer(find(contains(buffer,':='))+1));
                end
                if any(contains({buffer{1},buffer{2}},'fps'))
                    info.fps_mean(iFile)  = str2double(buffer(find(contains(buffer,':='))+1));
                    info.fps_std(iFile)   = str2double(buffer(find(contains(buffer,':='))+2));
                end
                if any(contains({buffer{1},buffer{2}},'spf'))
                    info.spf_mean(iFile)  = str2double(buffer(find(contains(buffer,':='))+1));
                    info.spf_std(iFile)   = str2double(buffer(find(contains(buffer,':='))+2));
                end

            end
            
        end 
        % bookkeeping
        iRepIdx = 0;
    end
    
end


















