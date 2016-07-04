function stimseq = makeorder_fLoc(nruns,categories,task,timestamp)
% Generates stimulus sequences, scripts, and parfiles for specified number
% of functional localizer runs.
% 
% INPUTS
% nruns: number of counterbalanced stimulus sequences to generate
% categories: subset of available categories to display.  If [], use all
%               Note: must provide complete pairs 
%               eg: {'word','number'}
%               eg: {'word','number','adult','child'}
% task: 1 (1-back), 2 (2-back), or 3 (oddball detection)
% 
% OUTPUTS
% stimseq: data structure containing trial information
% Sperarate script files for each run of the experiment
% 
% AS 8/2015
% KJ 2/2016 Updated to allow subsets of categories and more robust
%           handling of different parameter choices
% KJ 4/13/2016 ACTUALLY allow subsets of categories, and allow specifying
%           repeating categories 
%           (ie: input categories={'adult','adult','adult','instrument'};
% KJ 7/4/2016
%   - Add new categories and allow for categories with <144 images ( by
%   concatenating scrambled copies until we reach 144)

%% EXPERIMENTAL PARAMETERS
% scanner and task parameters (modifiable)
TR = 2; % fMRI TR (must be a factor of block duration in secs)
repfreq = 1/3; % proportion of blocks with task probe
% stimulus categories (2 per condition)
cats = {'word' 'number'; ...
    'body' 'limb'; ...
    'adult' 'child'; ...
    'corridor' 'house'; ...
    'car' 'instrument'}';

cats_new = [cats'; {'adult_male','adult_female'}]';

if(isempty(categories))
    categories=cats;
    usecats=1:numel(cats);
else
    if(mod(numel(categories),2))
        error('Must provide categories in condition pairs (eg: {''word'',''number''} )');
    end
    %usecats=find(ismember(cats,categories));
    usecats=[];
    for i = 1:numel(categories)
        usecats(i)=find(ismember(cats_new,categories{i}));
    end
end
usecats=reshape(usecats,2,[]);

ncats = numel(usecats); % number of stimulus categories
nconds = size(usecats,2)+1; % number of conditions including baseline
tasks = {'1back' '2back' 'oddball'}; % task names
% presentation and design parameters (do not change)
norders = 2; % number of counterbalanced condition orders per run
stimperblock = 8; % number of stimuli per block
stimdur = .5; % stimulus presentation duration (secs)
nblocks = 3+norders*nconds^2; % number of blocks per run including padding
ntrials = nblocks*stimperblock; % number of trials
nstim = 144; % number of stimuli per subcategory
% force TR to be a factor of block duration
if rem(stimperblock*stimdur,TR)
    TR = stimperblock*stimdur;
end
% balance frequency of stimulus repetition or oddballs across image sets
repfreq = max(1,round(repfreq*norders*nconds/2))/(norders*nconds/2);

%% GENERATE STIMULUS SEQUENCES
% initialzie stimulus sequence data structure
stimseq.block = [];
stimseq.onset = [];
stimseq.cond = [];
stimseq.task = [];
stimseq.img = {};

%We need to scan the stimulus directories to count images
baseDir=fileparts(fileparts(mfilename('fullpath')));
stimDir=fullfile(baseDir,'stimuli');

% randomize order of stimulus numbers for each category
for c = 1:numel(categories)
    
    %count the number of jpg files in this category
    nstim_cat=numel(dir(fullfile(stimDir,categories{c},'*.jpg')));
    
    for r = 1:ceil(nruns/3)
        %stimnums(nstim*(r-1)+1:nstim*(r-1)+nstim,c) = shuffle(1:nstim);
        
        %build full list by adding shuffled lists until we reach the
        %desired count (144), then trim to 144.  Make sure there are no
        %sequential duplicates
        imgorder=shuffle(1:nstim_cat);
        while numel(imgorder) < nstim
            tmporder=shuffle(1:nstim_cat);
            if(imgorder(end)==tmporder(1))
                tmporder=tmporder([2:end 1]);
            end
            imgorder=[imgorder tmporder];
        end

        stimnums(nstim*(r-1)+1:nstim*(r-1)+nstim,c) = imgorder(1:nstim);
    end
end

catcnt = zeros(numel(categories),1);
% create stimulus sequence data structure
for r = 1:nruns
    % order of conditions with baseline padding blocks
    condorder = [0; 2*(makeorder(nconds,norders*nconds)-1); 0; 0];

    % alternate between subcategories in each condition
    for c = 2:2:ncats
        ind = find(condorder==c);
        condorder(ind(2:2:end)) = condorder(ind(2:2:end))-1;
    end
    blockorder=condorder;
    condorder(condorder>0)=usecats(condorder(condorder>0));
    
    % pseudorandomly select blocks for task
    repblocks = zeros(length(blockorder),1);
    for c = 1:ncats
        ind = shuffle(find(blockorder==c));
        repblocks(ind(1:round(1/repfreq):end)) = 1;
    end
    % generate image sequence without repetitions or oddballs
    for b = 1:nblocks
        if blockorder(b) == 0
            imgmat(1:stimperblock,b) = {'blank'};
        else
            for i = 1:stimperblock
                catcnt(blockorder(b)) = catcnt(blockorder(b))+1;
                catname=cats_new{condorder(b)};
                imgnum=stimnums(catcnt(blockorder(b)),blockorder(b));
                
                imgmat{i,b} = strcat(catname,'-',num2str(imgnum),'.jpg');
            end
        end
    end
    % insert repetitions or oddballs
    taskmatch = zeros(stimperblock,nblocks);
    for b = 1:nblocks
        if repblocks(b) == 1
            if task == 2
                repimg = randi(stimperblock-4)+3;
                taskmatch(repimg,b) = 1;
                imgmat(repimg,b) = imgmat(repimg-2,b);
            elseif task == 3
                repimg = randi(stimperblock-2)+1;
                taskmatch(repimg,b) = 1;
                imgmat(repimg,b) = {strcat('scrambled-',num2str(randi(144)),'.jpg')};
            else
                repimg = randi(stimperblock-3)+2;
                taskmatch(repimg,b) = 1;
                imgmat(repimg,b) = imgmat(repimg-1,b);
            end
        else
        end
    end
    
    % fill in data structure
    stimseq(r).block = reshape(repmat(1:nblocks,stimperblock,1),[],1);
    stimseq(r).onset = 0:stimdur:ntrials*stimdur-stimdur;
    stimseq(r).cond = reshape(repmat(condorder',stimperblock,1),[],1);
    stimseq(r).task = reshape(taskmatch,[],1);
    stimseq(r).img = reshape(imgmat,[],1);
end

%% WRITE SCRIPT AND PARAMETER FILES
% header lines
if(all(usecats<=numel(cats)))
    printcats=cats;
else
    printcats=cats_new;
end

cnames = strcat(printcats(1:end-1),{', '});
cnames = [cnames{:}];
header1 = ['fLoc: ' cnames 'and ' printcats{end} ' '];

header2 = ['Number of temporal frames per run (given TR = ' num2str(TR) ' secs): ',num2str(nblocks*stimperblock*stimdur/TR),' '];
header3 = ['Total # of runs: ',num2str(nruns),' '];
header5 = 'Block      Onset     Category      TaskMatch     Image';
footer = '*** END SCRIPT ***';
% write separate script file for each run
for r = 1:nruns
    fid = fopen(strcat('script_fLoc_',tasks{task},'_run',num2str(r),'_',timestamp),'w');
    fprintf(fid,'%s\n',header1);
    fprintf(fid,'%s\n',header2);
    fprintf(fid,'%s\n\n',header3);
    fprintf(fid,'%s\n',['*** RUN ',num2str(r),' ***']);
    fprintf(fid,'%s\n',header5);
    for t = 1:ntrials
        fprintf(fid,'%i \t %f \t %i \t %i \t %s \n',...
            stimseq(r).block(t),... % write trial block
            stimseq(r).onset(t),... % write trial onset time
            stimseq(r).cond(t),... % write trial condition
            stimseq(r).task(t),... % write trial task
            stimseq(r).img{t}); % write trial image name
    end
    fprintf(fid,'%s',footer);
    fclose(fid);
end
% write separate parfile for each run
for r = 1:nruns
    writeParfile_fLoc(strcat('script_fLoc_',tasks{task},'_run',num2str(r),'_',timestamp),TR,stimperblock,stimdur);
end

end
