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
    libPath     = '/usr/local/lib' ; %fullfile(productPath,'');
    % Header file name
    hppFile     = 'tracking4matlab.h';
    % Full path to folder containing all header files
    hppPath     = productPath;
    % Full path to folder containing include files
    iPath       = productPath;
    % Library file name: NEEDS TO START WITH "lib", e.g. "libFILENAME.so"!!!
    libFile     = 'libtracking4matlab.so';
    
% name the interface
    libname     = "libtrackinginmatlab";
    

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
            ...%'OverwriteExistingDefinitionFiles',true,...
            'Verbose',true,...
            'TreatConstCharPointerAsCString',true ...
            );
        

    
    % check definition and run the build process
        definelibtrackinginmatlab;
        summary(definelibtrackinginmatlab)
        
        build(definelibtrackinginmatlab)
    

%% add LIB-path to Matlab path
    addpath(fullfile(pubPath,libname))
    setenv('PATH', [char(fullfile(pubPath,libname)) ':' getenv('PATH')]);
    setenv('LD_LIBRARY_PATH',[char(fullfile(pubPath,libname)) ':' getenv('LD_LIBRARY_PATH')])
    import clib.libtrackinginmatlab.*



%% RUN

% 1) exit Matlab
% 2) add lib-path to environment PATH (temporarily), run from shell:
    %{
    export LD_LIBRARY_PATH="matlab/libtrackinginmatlab:$LD_LIBRARY_PATH"
    %}
% 3) start Matlab from this shell
% 4) add path
% get current directory
    mfilePath = mfilename('fullpath');
    if contains(mfilePath,'LiveEditorEvaluationHelper') || isempty(mfilePath)
        mfilePath = matlab.desktop.editor.getActiveFilename;
    end
    curdir = fileparts(fileparts(mfilePath));
    addpath(fullfile(curdir,'matlab/libtrackinginmatlab'))
    %import clib.libtrackinginmatlab.*
% 5) execute function
    %clib.libtrackinginmatlab.videoTracking()





