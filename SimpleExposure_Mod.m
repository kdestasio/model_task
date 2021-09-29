function SimpleExposure_Mod(varargin)

    global KEYS COLORS w wRect XCENTER YCENTER PICS STIM SimpExpMod trial
    
    %% IMPORTANT VARIABLES
    [mdir,~,~] = fileparts(which('SimpleExposure_Mod.m')); % find the directory that houses this script
    imgdir = fullfile(mdir,'Pics_scan'); % UPDATE HERE TO CHANGE IMAGE DIRECTORY
    savedir = [mdir filesep 'Results' filesep]; % output will be saved in this directory
    trials_perblock = 20; % Should equal number of images per category
    trials_total = 40; % Should equal total number of images
    DEBUG=0; % 1 debug, 0 display normally
    
    %% SETUP
    prompt={'SUBJECT ID' 'fMRI: 1 = Yes; 0 = No' 'Session: 1 = Pre; 2 = Post'};
    defAns={'4444' '1' '1'};
    
    answer=inputdlg(prompt,'Please input subject info',1,defAns);
    
    ID = str2double(answer{1});
    fmri = str2double(answer{2});
    % COND = str2double(answer{2});
    SESS = str2double(answer{3});
    % prac = str2double(answer{4});
    
    rng(ID); %Seed random number generator with subject ID
    d = clock;
    
    
    KEYS = struct;
    if fmri == 1
        KEYS.ONE= KbName('0)');
        KEYS.TWO= KbName('1!');
        KEYS.THREE= KbName('2@');
        KEYS.FOUR= KbName('3#');
        KEYS.FIVE= KbName('4$');
        KEYS.SIX= KbName('5%');
        KEYS.SEVEN= KbName('6^');
        KEYS.EIGHT= KbName('7&');
        KEYS.NINE= KbName('8*');
    %     KEYS.TEN= KbName('9(');
    else
        KEYS.ONE= KbName('1!');
        KEYS.TWO= KbName('2@');
        KEYS.THREE= KbName('3#');
        KEYS.FOUR= KbName('4$');
        KEYS.FIVE= KbName('5%');
        KEYS.SIX= KbName('6^');
        KEYS.SEVEN= KbName('7&');
        KEYS.EIGHT= KbName('8*');
        KEYS.NINE= KbName('9(');
    %     KEYS.TEN= KbName('0)');
    end
    
    rangetest = cell2mat(struct2cell(KEYS));
    % KEYS.all = min(rangetest):max(rangetest);
    KEYS.all = rangetest;
    %Top trigger is for Macs, bottom trigger is for PCs. Comment out whichever
    %is not being used...
    % KEYS.trigger = KbName('''"');
    % KEYS.trigger = KbName('''');
    
    
    COLORS = struct;
    COLORS.BLACK = [0 0 0];
    COLORS.WHITE = [255 255 255];
    COLORS.RED = [255 0 0];
    COLORS.BLUE = [0 0 255];
    COLORS.GREEN = [0 255 0];
    COLORS.YELLOW = [255 255 0];
    COLORS.rect = COLORS.GREEN;
    
    STIM = struct;
    STIM.blocks = 1;
    STIM.trials = trials_total;
    STIM.totes = STIM.blocks*STIM.trials;
    STIM.trialsper = trials_perblock;
    STIM.trialdur = 5;
    % STIM.rate_dur = 1;
    STIM.jitter = [4 5 6 7 8];
    
    %% Keyboard stuff for fMRI...
    
    %list devices
    [keyboardIndices, productNames] = GetKeyboardIndices;
    
    isxkeys=strcmp(productNames,'Xkeys');
    
    xkeys=keyboardIndices(isxkeys);
    macbook = keyboardIndices(strcmp(productNames,'Apple Internal Keyboard / Trackpad'));
    
    %in case something goes wrong or the keyboard name isn't exactly right
    if isempty(macbook)
        macbook=-1;
    end
    
    %in case you're not hooked up to the scanner, then just work off the keyboard
    if isempty(xkeys)
        xkeys=macbook;
    end
    
    %% Get & load in pics
    cd(imgdir);
     
    PICS =struct;
    PICS.in.hi = dir('Avg*');
    PICS.in.lo = dir('Thin*');
    PICS.in.ow = dir('ow*');
    
    %Check if pictures are present. If not, throw error.
    if isempty(PICS.in.hi) || isempty(PICS.in.lo) || isempty(PICS.in.ow)
        error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
    end
    
    %% Fill in rest of pertinent info
    SimpExpMod = struct;
    
    %0 = Thin, 1 = Avg, 2 = Overweight
    pictype = [zeros(STIM.trialsper,1); ones(STIM.trialsper,1); 2.*ones(length(PICS.in.ow),1)];
    
    %Make long list of randomized #s to represent each pic
    if length(pictype) ~= (length(PICS.in.hi) + length(PICS.in.lo) + length(PICS.in.ow))
        error('Incorrect number of images in /PICS. Expected %d and found %d.', length(pictype), (length(PICS.in.hi) + length(PICS.in.lo) + length(PICS.in.ow)))
    else
        piclist = [randperm(length(PICS.in.hi))'; randperm(length(PICS.in.lo))'; randperm(length(PICS.in.ow))'];
    end
    
    %Concatenate these into a long list of trial types.
    trial_types = [pictype piclist];
    shuffled = trial_types(randperm(size(trial_types,1)),:);
    
    jitter = BalanceTrials(STIM.totes,1,STIM.jitter);
    
    for x = 1:STIM.blocks
        for y = 1:STIM.trials
             tc = (x-1)*STIM.trials + y;
             SimpExpMod.data(tc).pictype = shuffled(tc,1);
             
             if shuffled(tc,1) == 1
                SimpExpMod.data(tc).picname = PICS.in.hi(shuffled(tc,2)).name;
             elseif shuffled(tc,1) == 0
                 SimpExpMod.data(tc).picname = PICS.in.lo(shuffled(tc,2)).name;
             elseif shuffled(tc,1) == 2
                 SimpExpMod.data(tc).picname = PICS.in.ow(shuffled(tc,2)).name;
             end
             
             SimpExpMod.data(tc).jitter = jitter(tc);
             SimpExpMod.data(tc).fix_onset = NaN;
             SimpExpMod.data(tc).pic_onset = NaN;
             SimpExpMod.data(tc).rate_onset = NaN;
         end
     end
    
        SimpExpMod.info.ID = ID;
        SimpExpMod.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
        
    
    
    commandwindow;
    
    
    %% Screen
    %set up the screen and dimensions
    %list all the screens, then just pick the last one in the list (if you have
    %only 1 monitor, then it just chooses that one)
    Screen('Preference', 'SkipSyncTests', 0);
    
    screenNumber=max(Screen('Screens'));
    
    if DEBUG==1
        winRect=[0 0 640 480]; %create a rect for the screen
        XCENTER=320; % establish the center points X
        YCENTER=240; % and Y
    else
        %this gives the x and y dimensions of our screen, in pixels.
        [swidth, sheight] = Screen('WindowSize', screenNumber);
        XCENTER=fix(swidth/2);
        YCENTER=fix(sheight/2);
        winRect=[]; %when you leave winRect blank, it just fills the whole screen
    end
    
    %open a window on that monitor. 32 refers to 32 bit color depth (millions of
    %colors), winRect will either be a 1024x768 box, or the whole screen. The
    %function returns a window "w", and a rect that represents the whole
    %screen. 
    [w, wRect]=Screen('OpenWindow', screenNumber, 0,winRect,32,2);
    
    %%
    %you can set the font sizes and styles here
    Screen('TextFont', w, 'Arial');
    Screen('TextSize',w,30);
    KbName('UnifyKeyNames');
    
    %% Where should pics go
    STIM.framerect = [XCENTER-275; YCENTER-400; XCENTER+275; YCENTER+400];
    
    %% fMRI Synch
    
    if fmri == 1
        DrawFormattedText(w,'Synching with fMRI: Waiting for trigger','center','center',COLORS.WHITE);
        Screen('Flip',w);
        
        scan_sec = ScanTrig('/dev/cu.usbserial');
    else
        scan_sec = GetSecs();
    end
    
    %% Trials
    
    for block = 1:STIM.blocks
        for trial = 1:STIM.trials
            tcounter = (block-1)*STIM.trials + trial;
            tpx = imread(getfield(SimpExpMod,'data',{tcounter},'picname'));
            texture = Screen('MakeTexture',w,tpx);
            
            DrawFormattedText(w,'+','center','center',COLORS.WHITE);
            fixon = Screen('Flip',w);
            SimpExpMod.data(tcounter).fix_onset = fixon - scan_sec;
            WaitSecs(SimpExpMod.data(tcounter).jitter);
            
            Screen('DrawTexture',w,texture,[],STIM.framerect);
            picon = Screen('Flip',w);
            SimpExpMod.data(tcounter).pic_onset = picon - scan_sec;
            WaitSecs(STIM.trialdur);
        end
    end
    
    %% Save all the data
    cd(savedir)
    savename = ['SimpExp_Mod_' num2str(ID) '-' num2str(SESS) '.mat'];
    
    if exist(savename,'file')==2
        savename = ['SimpExp_Mod_' num2str(ID) '_' sprintf('%s_%2.0f%02.0f',date,d(4),d(5)) '.mat'];
    end
    
    
    try
    save([savedir savename],'SimpExpMod');
    catch
        warning('Something is amiss with this save. Retrying to save in a more general location...');
        try
            save([mdir filesep savename],'SimpExpMod');
        catch
            warning('STILL problems saving....Try right-clicking on ''SimpExp'' and Save as...');
            SimpExpMod
        end
    end
    
    DrawFormattedText(w,'That concludes this task.','center','center',COLORS.WHITE);
    Screen('Flip', w);
    WaitSecs(10);
    
end
     
function ScanTrig(port)
%  this routine will generate a trigger using a serial port device
%  on a mac, use '/dev/cu.usbserial' or whatever it is, for port
%  >>ScanTrif('/dev/cu.usbserial');

    sport = serial(port, 'BaudRate', 300);
    fopen(sport);
    fprintf(sport, '\7');
    fclose(sport);
    return
end
