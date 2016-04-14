function runme(nruns,startRun)
% Prompts experimenter for session information and executes functional
% localizer experiment used to define regions in high-level visual cortex
% selective to written characters, body parts, faces, and places. 
% 
% INPUTS (optional)
% nruns: total number of runs to execute sequentially (default is 3 runs)
% startRun: run number to start with if interrupted (default is run 1)
% 
% STIMULUS CATEGORIES (2 subcategories for each stimulus condition)
% Written characters
%     1 = word:  English psueudowords (3-6 characters long; see Glezer et al., 2009)
%     2 = number: whole numbers (3-6 characters long)
% Body parts
%     3 = body: headless bodies in variable poses
%     4 = limb: hands, arms, feet, and legs in various poses and orientations
% Faces
%     5 = adult: adults faces
%     6 = child: child faces
% Places
%     7 = corridor: views of indoor corridors placed aperature
%     8 = house: houses and buildings isolated from background
% Objects
%     9 = car: motor vehicles with 4 wheels
%     10 = instrument: string instruments
% Baseline = 0
%
% EXPERIMENTAL DESIGN
% Run duration: 5 min + countdown (12 sec by default)
% Block duration: 4 sec (8 images shown sequentially for 500 ms each)
% Task: 1 or 2-back image repetition detection or odddball detection
% 6 conditions counterbalanced (5 stimulus conditions + baseline condition)
% 12 blocks per condition (alternating between subcategories)
%
% Version 2.0 8/2015
% Anthony Stigliani (astiglia@stanford.edu)
% Department of Psychology, Stanford University
%
% Update KJ 12/2015: 
%   Add timestamps for filenames
%   fix file moving issues
%   Remove prompt for triggering scanner
%
% Update KJ 2/2016: Fix timing bug, Handle subsets of categories
% Update KJ 4/13/2016: ACTUALLY handle subsets of categories

%% SET DEFUALTS
if ~exist('nruns','var')
    nruns = 4;
end
if ~exist('startRun','var')
    startRun = 1;
end
if startRun > nruns
    error('startRun cannot be greater than nruns')
end

timestamp=datestr(now,'yyyymmdd-HHMMSS');

%% SET PATHS
path.baseDir = pwd; addpath(path.baseDir);
path.fxnsDir = fullfile(path.baseDir,'functions'); addpath(path.fxnsDir);
path.scriptDir = fullfile(path.baseDir,'scripts'); addpath(path.scriptDir);
path.dataDir = fullfile(path.baseDir,'data'); addpath(path.dataDir);
path.stimDir = fullfile(path.baseDir,'stimuli'); addpath(path.stimDir);

%% COLLECT SESSION INFORMATION
% initialize subject data structure
subject.name = {};
subject.date = {};
subject.experiment = 'fLoc';
subject.task = -1;
subject.scanner = -1;
subject.script = {};
subject.categories = {}; %all categories
%subject.categories = {'adult','instrument','adult','instrument','adult','instrument','adult','instrument','adult','instrument'};

% collect subject info and experimental parameters
subject.name = input('Subject initials : ','s');
subject.name = deblank(subject.name);
subject.date = date;
subject.timestamp = timestamp;
while ~ismember(subject.task,[1 2 3])
    subject.task = input('Task (1 = 1-back, 2 = 2-back, 3 = oddball) : ');
end
subject.scanner=1;
%while ~ismember(subject.scanner,[0 1])
%    subject.scanner = input('Wait for scanner trigger? (0 = no, 1 = yes) : ');
%end

%% GENERATE STIMULUS SEQUENCES
if startRun == 1
    % create subject script directory
    cd(path.scriptDir);
    makeorder_fLoc(nruns,subject.categories,subject.task,subject.timestamp);
    subScriptDir = [subject.name '_' subject.timestamp '_' subject.experiment];
    [~,~]=mkdir(subScriptDir);
    % create subject data directory
    cd(path.dataDir);
    subDataDir = [subject.name '_' subject.timestamp '_' subject.experiment];
    [~,~]=mkdir(subDataDir);
    % prepare to exectue experiment
    cd(path.baseDir);
    sprintf(['\n' num2str(nruns) ' runs will be exectued.\n']);
end
tasks = {'1back' '2back' 'oddball'};

%% EXECUTE EXPERIMENTS AND SAVE DATA FOR EACH RUN
for r = startRun:nruns
    % execute this run of experiment
    subject.script = ['script_' subject.experiment '_' tasks{subject.task} '_run' num2str(r) '_' subject.timestamp];
    sprintf(['\nRun ' num2str(r) '\n']);
    WaitSecs(1);
    [theSubject theData] = et_run_fLoc(path,subject);
    % save data for this run
    cd(path.dataDir); cd(subDataDir);
    saveName = [theSubject.name '_' theSubject.timestamp '_' theSubject.experiment '_' tasks{subject.task} '_run' num2str(r)];
    save(saveName,'theData','theSubject')
    cd(path.baseDir);
    
    cd(path.scriptDir);
    movefile(subject.script,subScriptDir);
    movefile([subject.script '.par'],subScriptDir);
    cd(path.baseDir);
end

end