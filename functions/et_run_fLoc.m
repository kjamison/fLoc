function [theSubject theData] = et_run_fLoc(path,subject)
% Displays images for functional localizer experiment and collects
% behavioral data for 2-back image repetition detection task.
% AS 8/2014
%
% KJ 12/2015:
%   - Wait for scanner to send trigger, instead of code triggering scanner
%   - Add ignorekeys so scanner triggers aren't counted as responses
%   - Other changes to keyboard handling for CMRR setup
%
% KJ 2/2016:
%   - Fix cumulative timing bug   
% KJ 4/2016:
%   - Allow 5 or T for scanner trigger input
% KJ 7/2016:
%   - Add stimulus position offset param
%   - Un-hardcode category names; read them from script file instead

%% CHANGEABLE PARAMETERS

countDown = 12; % pre-experiment countdown (secs)

%stimSize = 700; % size to display images in pixels
stimSize = 912; %10 deg side length on 7TPS BOLDscreen

fixColor = [255 0 0]; % fixation marker color
textColor = 255; % instruction text color (grayscale)
blankColor = 128; % baseline screen color (grayscale)
waitDur = 1; % secs to wait for response (must be < 2 and a multiple of .5)

centerOffset=[0 0]; %shift center of stimulus on screen (in pixels)
%centerOffset=[0 -50]; 

startKey = {'5%','t'};
startKeyName= '''5'' or ''t'''; %for display only

ignorekeys=KbName({startKey}); % dont record TR triggers as subject responses
%% FIND RESPONSE DEVICE

%KJ: Just listen to all keyboards/boxes
laptopKey=-3;
k=-3;

%% SET UP SCREEN AND PRELOAD STIMULI
% read trial information stimulus sequence script
cd(path.scriptDir);
Trials = readScript_fLoc(subject.script);
subject.trials = Trials;
numTrials = length(Trials.block);
viewTime = Trials.onset(2);
cd(path.baseDir);
% initalize screen
[windowPtr,center,blankColor] = doScreen;

center=center+centerOffset;

centerX = center(1);
centerY = center(2);

s = stimSize/2;
stimRect = [centerX-s centerY-s centerX+s centerY+s];
% store image textures in array of pointers
picPtrs = [];

for t = 1:numTrials
    cd(path.stimDir);
    if strcmp(Trials.img{t},'blank')
        picPtrs(t) = 0;
    elseif subject.task == 3 && Trials.task(t) == 1
        cd('scrambled');
        pic = imread(Trials.img{t});
        picPtrs(t) = Screen('MakeTexture',windowPtr,pic);
    else
        cd(Trials.condname{t});
        pic = imread(Trials.img{t});
        picPtrs(t) = Screen('MakeTexture',windowPtr,pic);
    end
end
cd(path.baseDir);
% inititalize data structures
subject.timePerTrial = [];
subject.totalTime = [];
subject.countDown = countDown;
data = [];
data.keys = {};
data.rt = [];

%% DISPLAY INSTRUCTIONS AND START EXPERIMENT
% instructions for 1-back task
str{1} = sprintf('Fixate. Press a button when an image repeats on sequential trials.\nWaiting for %s from scanner to continue.', startKeyName);
% instructions for 2-back task
str{2} = sprintf('Fixate. Press a button when an image repeats within a block.\nWaiting for %s from scanner to continue.', startKeyName);
% instructions for oddball task
str{3} = sprintf('Fixate. Press a button when a scrambled image appears.\nWaiting for %s from scanner to continue.', startKeyName);
% display instruction screen
WaitSecs(1);
Screen('FillRect',windowPtr,blankColor);
Screen('Flip',windowPtr);
DrawFormattedText(windowPtr,str{subject.task},'center','center',textColor);
Screen('Flip',windowPtr);



fprintf('\nWaiting for %s from scanner to continue.\n', startKeyName);

% wait for TR trigger to start experiment
getKey(startKey,k);

%% PRE-EXPERIMENT COUNTDOWN
% display countdown numbers
countDown = round(countDown);
countTime = countDown+GetSecs;
counter = countDown;
timeRemaining = countDown+GetSecs;
while timeRemaining > 0
    if floor(timeRemaining) <= counter
        number = num2str(counter);
        DrawFormattedText(windowPtr,number,'center','center',textColor);
        Screen('Flip',windowPtr);
        counter = counter-1;
    end
    timeRemaining = countTime-GetSecs;
end

%% MAIN DISPLAY LOOP
% get timestamp for start of experiment
startTime = GetSecs;
% display preloaded stimulus sequence
for t = 1:numTrials
    trialStart = GetSecs;
    % display blank screen if baseline trial and image if stimulus trial
    if Trials.cond(t) == 0
        Screen('FillRect',windowPtr,blankColor);
        drawFixation(windowPtr,center,fixColor);
    else
        Screen('DrawTexture',windowPtr,picPtrs(t),[],[stimRect]);
        drawFixation(windowPtr,center,fixColor);
    end
    Screen('Flip',windowPtr);
    % collect response and measure timing
    trialEnd = GetSecs-startTime;
    subject.timePerTrial(t) = trialEnd;
    %[keys RT] = recordKeys(trialStart,viewTime,k,ignorekeys);
    [keys RT] = recordKeys(startTime+(t-1)*viewTime,viewTime,k,ignorekeys); %KJ lag fix
    data.keys{t} = keys;
    data.rt(t) = min(RT);
end

%% ANANLYZE DATA AND CLEAR WINDOWS
% record total time of experiment
subject.totalTime = GetSecs-startTime;
theSubject = subject;
% analyze behavioral performance
theData = [];
theData = doAnalysis_fLoc(theSubject,data,waitDur,viewTime);
% display behavioral performance
hitStr = ['Hits: ' num2str(theData.hits) '/' num2str(theData.nreps) ' (' num2str(theData.propHit*100) '%)'];
faStr = ['False alarms: ' num2str(theData.falseAlarms)];
Screen('FillRect',windowPtr,blankColor);
Screen('Flip',windowPtr);
DrawFormattedText(windowPtr,[hitStr '\n' faStr '\n\nPress g to continue'],'center','center',textColor);
Screen('Flip',windowPtr);
% wait until g is pressed
%getKey('g',laptopKey);
% show cursor and clear screen
ShowCursor;
Screen('CloseAll');

end
