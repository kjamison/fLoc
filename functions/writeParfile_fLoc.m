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

par_colors=[.2 .2 .2; 
    0 0 0; 
    0 .8 .8; 
    0 1 1;
    .8 0 0;
    1 0 0;
    0 .8 0;
    0 1 0;
    .8 .8 0;
    1 1 0];

onsetnum = 0;
c = 1;
par.cat = char('');
for i = 1:nblocks
    par.onset(i) = onsetnum*(stimperblock*stimdur);
    onsetnum = onsetnum+1;
    if condition(c) == 0
        par.cat{i} = cat0;
        par.color{i} = [1 1 1];
    elseif condition(c) <= size(par_colors,1)
        par.cat{i} = catnames{condition(c)};
        par.color{i} = par_colors(condition(c),:);
    else
        par.cat{i} = catnames{condition(c)};
        par.color{i} = [0 0 0];
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
