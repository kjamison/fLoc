function writeParfile_fLoc(script,TR,stimperblock,stimdur)
% Reads information from a script file and writes a parameter file.
% AS 8/2014
% KJ 2/2016: make text parsing more robust

% get category names
fid = fopen(script);
ignore = fscanf(fid,'%s',1);
cat0 = 'baseline';
s=fgetl(fid);
s=regexp(s,'([\s,]+)|and','split');
catnames=s(~cellfun(@isempty,s));

% get number of frames and duration
s=fgetl(fid);
s=regexp(s,':','split');
par.numTR=str2num(s{end});
duration = par.numTR*TR;
nblocks = duration/(stimperblock*stimdur);
ntrials = nblocks*stimperblock;

for i = 1:4
    ignore=fgetl(fid); 
end

% read in trial information
temp=[];
cnt = 1;
blocknum = fscanf(fid,'%s',1);
while ~isempty(blocknum) && strncmp('*',blocknum,1) == 0
    temp.block(cnt) = str2num(blocknum);
    temp.onset(cnt) = fscanf(fid,'%f',1);
    temp.cond(cnt) = fscanf(fid,'%d',1);
    temp.task(cnt) = fscanf(fid,'%i',1);
    temp.img{cnt} = fscanf(fid,'%s',1);
    skipLine = fgetl(fid);
    cnt = cnt+1;
    blocknum = fscanf(fid,'%s',1);
end

% generate category code matrix
cnt = 1;
for b = 1:stimperblock:ntrials
    list(cnt) = temp.cond(b);
    cnt = cnt+1;
end
nframes = stimperblock*stimdur/TR;
condition = [];
for b = 1:length(list)
    matrix = repmat(list(b),1,nframes);
    condition = [condition matrix];
end
onsetnum = 0;
c = 1;
par.cat = char('');
for i = 1:nblocks
    par.onset(i) = onsetnum*(stimperblock*stimdur);
    onsetnum = onsetnum+1;
    switch condition(c)
        case 0 % fixation
            par.cat{i} = cat0;
            par.color{i} = [1 1 1];
        case 1 % word
            par.cat{i} = catnames{1};
            par.color{i} = [.2 .2 .2];
        case 2 % number
            par.cat{i} = catnames{2};
            par.color{i} = [0 0 0];
        case 3 % body
            par.cat{i} = catnames{3};
            par.color{i} = [0 .8 .8];
        case 4 % limb
            par.cat{i} = catnames{4};
            par.color{i} = [0 1 1];
        case 5 % child
            par.cat{i} = catnames{5};
            par.color{i} = [.8 0 0];
        case 6 % adult
            par.cat{i} = catnames{6};
            par.color{i} = [1 0 0];
        case 7 % place
            par.cat{i} = catnames{7};
            par.color{i} = [0 .8 0];
        case 8 % house
            par.cat{i} = catnames{8};
            par.color{i} = [0 1 0];
        case 9 % car
            par.cat{i} = catnames{9};
            par.color{i} = [.8 .8 0];
        case 10 % instrument
            par.cat{i} = catnames{10};
            par.color{i} = [1 1 0];
    end
    par.cond(i) = condition(c);
    c = c+(stimperblock*stimdur/TR);
end
fclose(fid);

% write parfile
outFile = [script '.par'];
fidout = fopen(outFile,'w');
for n=1:nblocks
    fprintf(fidout,'%d \t %d \t', par.onset(n), par.cond(n));
    fprintf(fidout,'%s \t', par.cat{n});
    fprintf(fidout,'%g %g %g \n', par.color{n});
end
fclose(fidout);
fclose('all');

end
