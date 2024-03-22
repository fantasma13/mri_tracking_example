%% https://de.mathworks.com/help/matlab/matlab_external/publish-interface-to-shared-c-library-on-linux.html

%% FILE LOCATIONS
% get current directory
    mfilePath = mfilename('fullpath');
    if contains(mfilePath,'LiveEditorEvaluationHelper') || isempty(mfilePath)
        mfilePath = matlab.desktop.editor.getActiveFilename;
    end
    curdir = fileparts(fileparts(mfilePath));

% source file location
    source_location = fullfile(curdir,'src');

% create publisher folder
    pubPath = fullfile(curdir,"matlab");
    if ~isfolder(pubPath)
        mkdir(pubPath)
    end
    cd(pubPath)

% identify c++ library files
    productPath = fullfile(source_location);
    libPath     = '/usr/local/lib'; %fullfile(productPath,'');
    % Header file name
    hppFile     = 'CalcShift_cppwrapper.h';
    % Full path to folder containing all header files
    hppPath     = productPath;
    % Full path to folder containing include files
    iPath       = productPath;
    % Library file name: NEEDS TO START WITH "lib", e.g. "libFILENAME.so"!!!
    libFile     = 'libCalcShift_cppwrapper.so';
    
% name the interface
    libname     = "calcshiftvectorlib";
    

%% GENERATE LIBRARY
    % verify supported c++ compiler
        mex -setup cpp

    % call clibgen.generateLibraryDefinition
        clibgen.generateLibraryDefinition(...
            fullfile(hppPath,hppFile),...
            'IncludePath',  iPath,... 
            'Libraries',    fullfile(libPath,libFile),... 
            'OutputFolder', pubPath,...
            'PackageName',  libname,...
            ...%'ReturnCArrays',false,... % treat output as MATLAB arrays
            ... %'OverwriteExistingDefinitionFiles',true,...
            'Verbose',true,...
            'TreatConstCharPointerAsCString',true...
            )
    

    
    % check definition and run the build process
        definecalcshiftvectorlib
        summary(definecalcshiftvectorlib)
    
        build(definecalcshiftvectorlib)
    

%% add LIB-path to Matlab path
    addpath(fullfile(pubPath,libname))
    setenv('PATH', [char(fullfile(pubPath,libname)) ':' getenv('PATH')]);
    setenv('LD_LIBRARY_PATH',[char(fullfile(pubPath,libname)) ':' getenv('LD_LIBRARY_PATH')])
    import clib.calcshiftvectorlib.*



%% RUN

% 1) exit Matlab
% 2) add lib-path to environment PATH (temporarily), run from shell:
    %{
    export LD_LIBRARY_PATH="matlab/calcshiftvectorlib:$LD_LIBRARY_PATH"
    %}
% 3) start Matlab from this shell
% 4) add path 
% get current directory
    mfilePath = mfilename('fullpath');
    if contains(mfilePath,'LiveEditorEvaluationHelper') || isempty(mfilePath)
        mfilePath = matlab.desktop.editor.getActiveFilename;
    end
    curdir = fileparts(fileparts(mfilePath));
    addpath(fullfile(curdir,'matlab/calcshiftvectorlib'))
    import clib.tracking4matlablib.*
% 5) execute function
    % f1: direct vector hand-over
        %res = clib.calcshiftvectorlib.MyCalcShiftVector([1 2 1],[1 1 1],[1 0 0 0 1 0 0 1 0]);
        %res.double
        


