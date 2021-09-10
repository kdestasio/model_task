function PicRatings_Model_BRF()
% Rate all images, choose top X picsn    
global wRect window XCENTER rects mids COLORS KEYS PicRatings_Model_BRF

%% Set important variables
[mfilesdir,~,~] = fileparts(which('PicRatings_Model_BRF.m')); %find the directory that houses this script
imgdir = [mfilesdir filesep 'Pics_rate']; %UPDATE HERE TO CHANGE IMAGE DIRECTORY
savedir = [mfilesdir filesep 'Results']; %output will be saved in this directory
heightScaler = .5; % Change this to set the picture size relative to the screen. For ex., .5 will scale the image to 1/2 the screen height wile maintaining the aspect ratio.
DEBUG=0; %1 debug, 0 display normally

%% SETUP
prompt={'SUBJECT ID' 'Wave'};% 'fMRI? (1 = Y, 0 = N)'};
defAns={'4444' '1'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
SESS = str2double(answer{2});
%fmri = str2double(answer{2});

COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.rect = COLORS.GREEN;

KbName('UnifyKeyNames');

KEYS = struct;
KEYS.ONE= KbName('1!');
KEYS.TWO= KbName('2@');
KEYS.THREE= KbName('3#');
KEYS.FOUR= KbName('4$');
KEYS.FIVE= KbName('5%');
KEYS.SIX= KbName('6^');
KEYS.SEVEN= KbName('7&');
KEYS.EIGHT= KbName('8*');
KEYS.NINE= KbName('9(');
rangetest = cell2mat(struct2cell(KEYS));
KEYS.all = min(rangetest):max(rangetest);
% KEYS.trigger = 52;

%%
cd(imgdir);
PICS =struct;

    PICS.in.thin = dir('Thin*');
    PICS.in.avg = dir('Avg*');
    PICS.in.ow = dir('ow*');
    
    if isempty(PICS.in.thin) || isempty(PICS.in.avg) || isempty(PICS.in.ow);
        error('Could not find pics! Make sure a folder exists called "Pics" with all the appropriate images contained therein.')
    end
    
    picnames = {PICS.in.thin.name PICS.in.avg.name PICS.in.ow.name}';
    %2 = Overweight, 1 = Average, 0 = Thin
    pictype = num2cell([zeros(length(PICS.in.thin),1); ones(length(PICS.in.avg),1); 2.*ones(length(PICS.in.ow),1)]);
    picnames = [picnames pictype];
    picnames = picnames(randperm(size(picnames,1)),:);

PicRatings_Model_BRF = struct('filename',picnames(:,1),'PicType',picnames(:,2),'Rate_Att',0);


%% Keyboard stuff for fMRI...
% 
% %list devices
% [keyboardIndices, productNames] = GetKeyboardIndices;
% 
% isxkeys=strcmp(productNames,'Xkeys');
% 
% xkeys=keyboardIndices(isxkeys);
% macbook = keyboardIndices(strcmp(productNames,'Apple Internal Keyboard / Trackpad'));
% 
% %in case something goes wrong or the keyboard name isn?t exactly right
% if isempty(macbook)
%     macbook=-1;
% end
% 
% %in case you?re not hooked up to the scanner, then just work off the keyboard
% if isempty(xkeys)
%     xkeys=macbook;
% end

%%
commandwindow;

%%
%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
Screen('Preference', 'SkipSyncTests', 1);

screenNumber=max(Screen('Screens'));

if DEBUG==1
    %create a rect for the screen
    winRect=[0 0 640 480];
    %establish the center points
    XCENTER=320;
    YCENTER=240;
else
    [swidth, sheight] = Screen('WindowSize', screenNumber); %this gives the x and y dimensions of our screen, in pixels.
    XCENTER=fix(swidth/2);
    YCENTER=fix(sheight/2);
    winRect=[]; %when you leave winRect blank, it just fills the whole screen
end

%open a window on that monitor. 32 refers to 32 bit color depth (millions of
%colors), winRect will either be a 1024x768 box, or the whole screen. The
%function returns a window "window", and a rect that represents the whole
%screen. 
[window, wRect]=Screen('OpenWindow', screenNumber, 0,winRect,32,2);

%%
%you can set the font sizes and styles here
Screen('TextFont', window, 'Arial');
Screen('TextSize',window,35);

%% Dat Grid
[rects,mids] = DrawRectsGrid();
verbage = '.';

%% Intro

DrawFormattedText(window,'We are going to show you some pictures of people and have you rate how attractive each person is.\n\n You will use a scale from 1 to 9, where 1 is "Not at all attractive" and 9 is "Extremely attractive."\n\nPress any key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',window);
KbWait([],3);

DrawFormattedText(window,'You will use the numbers along the top of the keyboard to select your rating. \n\nPress any key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',window);
KbWait([],3);


%% fMRI synch window/trigger
% if fmri == 1;
%     DrawFormattedText(window,'Synching with fMRI: Waiting for trigger','center','center',COLORS.WHITE);
%     Screen('Flip',window);
%     
%     scan_sec = KbTriggerWait(KEYS.trigger,xkeys);
% else
%     scan_sec = GetSecs();
% end

%%
DrawFormattedText(window,'The rating task will now begin.\n\nPress any key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',window);
KbWait([],3);
WaitSecs(1);

%% Pic Location

for x = 1:20:length(PicRatings_Model_BRF)
    for y = 0:19
        xy = x+y;
        if xy > length(PicRatings_Model_BRF)
            break
        end
        
        dat_pic = getfield(PicRatings_Model_BRF,{xy},'filename');
        theImage = imread(dat_pic); % Load in the image from a file
        [imgH, imgW, ~] = size(theImage); % Get the original height and width of the image
        aspectRatio = imgW / imgH; % Get the aspect ratio to maintain when drawn in different size
        imageHeight = sheight .* heightScaler; % Calculate new image height based on scaler variable
        imageWidth = imageHeight .* aspectRatio; % Calculate new width bassed on new height to maintain aspect ratio
        theRect = [XCENTER-(imageWidth(1)/2), wRect(4)*.1, XCENTER+(imageWidth(1)/2), imageHeight(1)+525]; % Define image location on the screen
        imgTx = Screen('MakeTexture',window,theImage); % Convert the image to a texture      
        Screen('DrawTexture',window,imgTx,[],theRect); % Display the resized image on the screen

        drawRatings([],window);
        DrawFormattedText(window,verbage,'center',(wRect(4)*.75),COLORS.WHITE);

        Screen('Flip',window);
        
        FlushEvents();
            while 1
                [keyisdown, ~, keycode] = KbCheck();
                if (keyisdown==1 && any(keycode(KEYS.all)))                   
                    
                    rating = KbName(find(keycode));
                    rating = str2double(rating(1));
                    
                    Screen('DrawTexture',window,imgTx,[],theRect);
                    drawRatings(keycode,window);
                    DrawFormattedText(window,verbage,'center',(wRect(4)*.75),COLORS.WHITE);
                    Screen('Flip',window);
                    WaitSecs(.25);
                    break;
                end
            end
            
            PicRatings_Model_BRF(xy).Rate_Att = rating;
           
           Screen('Flip',window);
           FlushEvents();
           WaitSecs(.25);
    end
    
    %Take a break every 20 pics.
    Screen('Flip',window);
    DrawFormattedText(window,'Press any key when you are ready to continue','center','center',COLORS.WHITE);
    Screen('Flip',window);
    KbWait([],3);
    
end

Screen('Flip',window);
WaitSecs(.5);


%% Sort & Save list of image ratings
fields = {'name' 'pictype' 'rating'}; 
presort = struct2cell(PicRatings_Model_BRF)';
pre_avg = presort(([presort{:,2}]==1),:);
pre_thin = presort(([presort{:,2}]==0),:);
pre_ow = presort(([presort{:,2}]==2),:);
postsort_avg = sortrows(pre_avg,-3);    %Sort descending by column 3
postsort_thin = sortrows(pre_thin,-3);
postsort_ow = sortrows(pre_ow,-3);
PicRating_Mod.Avg = cell2struct(postsort_avg,fields,2);
PicRating_Mod.Thin = cell2struct(postsort_thin,fields,2);
PicRating_Mod.Ow = cell2struct(postsort_ow,fields,2);

if SESS == 1
    savefilename = sprintf('PicRate_Mod%d.mat',ID);
else
    savefilename = sprintf('PicRate_Mod%d_%d.mat',ID,SESS);
end

savefile = fullfile(savedir,savefilename);



try
save(savefile,'PicRating_Mod');
catch
    warning('Something is amiss with this save. Retrying to save in a more general location...');
    try
        save([mfilesdir filesep savefilename],'PicRating_Mod');
    catch
        warning('STILL problems saving....Try right-clicking on ''PicRating_Mod'' and Save as...');
        PicRating_Mod
    end
end

DrawFormattedText(window,'That concludes this task. The assessor will be with you soon.','center','center',COLORS.WHITE);
Screen('Flip', window);
WaitSecs(10);

sca

end

%%
function [ rects,mids ] = DrawRectsGrid(varargin)
%DrawRectGrid:  Builds a grid of squares with gaps in between.

global wRect XCENTER

%Size of image will depend on screen size. First, an area approximately 80%
%of screen is determined. Then, images are 1/4th the side of that square
%(minus the 3 x the gap between images.

num_rects = 9;                 %How many rects?
xlen = wRect(3)*.8;           %Make area covering about 90% of vertical dimension of screen.
gap = 10;                       %Gap size between each rect
square_side = fix((xlen - (num_rects-1)*gap)/num_rects); %Size of rect depends on size of screen.

squart_x = XCENTER-(xlen/2);
squart_y = wRect(4)*.8;         %Rects start @~80% down screen.

rects = zeros(4,num_rects);

% for row = 1:DIMS.grid_row;
    for col = 1:num_rects
%         currr = ((row-1)*DIMS.grid_col)+col;
        rects(1,col)= squart_x + (col-1)*(square_side+gap);
        rects(2,col)= squart_y;
        rects(3,col)= squart_x + (col-1)*(square_side+gap)+square_side;
        rects(4,col)= squart_y + square_side;
    end
% end
mids = [rects(1,:)+square_side/2; rects(2,:)+square_side/2+5];

end

%%
function drawRatings(varargin)

global window KEYS COLORS rects mids

colors=repmat(COLORS.WHITE',1,9);
% rects=horzcat(allRects.rate1rect',allRects.rate2rect',allRects.rate3rect',allRects.rate4rect');

%Needs to feed in "code" from KbCheck, to show which key was chosen.
if nargin >= 1 && ~isempty(varargin{1})
    response=varargin{1};
    
    key=find(response);
    if length(key)>1
        key=key(1);
    end
    
    switch key
        
        case {KEYS.ONE}
            choice=1;
        case {KEYS.TWO}
            choice=2;
        case {KEYS.THREE}
            choice=3;
        case {KEYS.FOUR}
            choice=4;
        case {KEYS.FIVE}
            choice=5;
        case {KEYS.SIX}
            choice=6;
        case {KEYS.SEVEN}
            choice=7;
        case {KEYS.EIGHT}
            choice=8;
        case {KEYS.NINE}
            choice=9;
    end
    
    if exist('choice','var')
        
        
        colors(:,choice)=COLORS.GREEN';
        
    end
end

if nargin>=2
    
    window=varargin{2};
    
else
    
    window=window;
    
end
   

Screen('TextFont', window, 'Arial');
Screen('TextStyle', window, 1);
oldSize = Screen('TextSize',window,35);


%draw all the squares
Screen('FrameRect',window,colors,rects,1);


% Screen('FrameRect',w2,colors,rects,1);


%draw the text (1-10)
for n = 1:9
    numnum = sprintf('%d',n);
    CenterTextOnPoint(window,numnum,mids(1,n),mids(2,n),COLORS.WHITE);
end


Screen('TextSize',window,oldSize);

end


%%
function [nx, ny, textbounds] = CenterTextOnPoint(win, tstring, sx, sy,color)


if nargin < 1 || isempty(win)
    error('CenterTextOnPoint: Windowhandle missing!');
end

if nargin < 2 || isempty(tstring)
    % Empty text string -> Nothing to do.
    return;
end

% Store data class of input string for later use in re-cast ops:
stringclass = class(tstring);

% Default x start position is left border of window:
if isempty(sx)
    sx=0;
end

xcenter=0;

% No vertical mirroring by default:
% if nargin < 9 || isempty(vSpacing)
    vSpacing = 1.5;
% end

% if nargin < 10 || isempty(righttoleft)
    righttoleft = 0;
% end

% Convert all conventional linefeeds into C-style newlines:
newlinepos = strfind(char(tstring), '\n');

% If '\n' is already encoded as a char(10) as in Octave, then
% there's no need for replacemet.
if char(10) == '\n' %#ok<STCMP>
   newlinepos = [];
end

% Need different encoding for repchar that matches class of input tstring:
if isa(tstring, 'double')
    repchar = 10;
elseif isa(tstring, 'uint8')
    repchar = uint8(10);    
else
    repchar = char(10);
end

while ~isempty(newlinepos)
    % Replace first occurence of '\n' by ASCII or double code 10 aka 'repchar':
    tstring = [ tstring(1:min(newlinepos)-1) repchar tstring(min(newlinepos)+2:end)];
    % Search next occurence of linefeed (if any) in new expanded string:
    newlinepos = strfind(char(tstring), '\n');
end

% % Text wrapping requested?
% if wrapat > 0
%     % Call WrapString to create a broken up version of the input string
%     % that is wrapped around column 'wrapat'
%     tstring = WrapString(tstring, wrapat);
% end

% Query textsize for implementation of linefeeds:
theight = Screen('TextSize', win) * vSpacing;

% Default y start position is top of window:
if isempty(sy)
    sy=0;
end

winRect = Screen('Rect', win);
winHeight = RectHeight(winRect);

% if ischar(sy) && strcmpi(sy, 'center')
    % Compute vertical centering:
    
    % Compute height of text box:
%     numlines = length(strfind(char(tstring), char(10))) + 1;
    %bbox = SetRect(0,0,1,numlines * theight);
    bbox = SetRect(0,0,1,theight);
    
    
    textRect=CenterRectOnPoint(bbox,sx,sy);
    % Center box in window:
    [rect,dh,dv] = CenterRect(bbox, textRect);

    % Initialize vertical start position sy with vertical offset of
    % centered text box:
    sy = dv;
% end

% Keep current text color if noone provided:
if nargin < 5 || isempty(color)
    color = [];
end

% Init cursor position:
xp = sx;
yp = sy;

minx = inf;
miny = inf;
maxx = 0;
maxy = 0;

% Is the OpenGL userspace context for this 'windowPtr' active, as required?
[previouswin, IsOpenGLRendering] = Screen('GetOpenGLDrawMode');

% OpenGL rendering for this window active?
if IsOpenGLRendering
    % Yes. We need to disable OpenGL mode for that other window and
    % switch to our window:
    Screen('EndOpenGL', win);
end

% Disable culling/clipping if bounding box is requested as 3rd return
% % argument, or if forcefully disabled. Unless clipping is forcefully
% % enabled.
% disableClip = (ptb_drawformattedtext_disableClipping ~= -1) && ...
%               ((ptb_drawformattedtext_disableClipping > 0) || (nargout >= 3));
% 

disableClip=1;

% Parse string, break it into substrings at line-feeds:
while ~isempty(tstring)
    % Find next substring to process:
    crpositions = strfind(char(tstring), char(10));
    if ~isempty(crpositions)
        curstring = tstring(1:min(crpositions)-1);
        tstring = tstring(min(crpositions)+1:end);
        dolinefeed = 1;
    else
        curstring = tstring;
        tstring =[];
        dolinefeed = 0;
    end

    if IsOSX
        % On OS/X, we enforce a line-break if the unwrapped/unbroken text
        % would exceed 250 characters. The ATSU text renderer of OS/X can't
        % handle more than 250 characters.
        if size(curstring, 2) > 250
            tstring = [curstring(251:end) tstring]; %#ok<AGROW>
            curstring = curstring(1:250);
            dolinefeed = 1;
        end
    end
    
    if IsWin
        % On Windows, a single ampersand & is translated into a control
        % character to enable underlined text. To avoid this and actually
        % draw & symbols in text as & symbols in text, we need to store
        % them as two && symbols. -> Replace all single & by &&.
        if isa(curstring, 'char')
            % Only works with char-acters, not doubles, so we can't do this
            % when string is represented as double-encoded Unicode:
            curstring = strrep(curstring, '&', '&&');
        end
    end
    
    % tstring contains the remainder of the input string to process in next
    % iteration, curstring is the string we need to draw now.

    % Perform crude clipping against upper and lower window borders for
    % this text snippet. If it is clearly outside the window and would get
    % clipped away by the renderer anyway, we can safe ourselves the
    % trouble of processing it:
    if disableClip || ((yp + theight >= 0) && (yp - theight <= winHeight))
        % Inside crude clipping area. Need to draw.
        noclip = 1;
    else
        % Skip this text line draw call, as it would be clipped away
        % anyway.
        noclip = 0;
        dolinefeed = 1;
    end
    
    % Any string to draw?
    if ~isempty(curstring) && noclip
        % Cast curstring back to the class of the original input string, to
        % make sure special unicode encoding (e.g., double()'s) does not
        % get lost for actual drawing:
        curstring = cast(curstring, stringclass);
        
        % Need bounding box?

            bbox=Screen('TextBounds', win, curstring, [], [], [], righttoleft);

            [rect,dh] = CenterRect(bbox, textRect);
            % Set drawing cursor to horizontal x offset:
            xp = dh;
        
            [nx ny] = Screen('DrawText', win, curstring, xp, yp, color, [], [], righttoleft);

    else
        % This is an empty substring (pure linefeed). Just update cursor
        % position:
        nx = xp;
        ny = yp;
    end

    % Update bounding box:
    minx = min([minx , xp, nx]);
    maxx = max([maxx , xp, nx]);
    miny = min([miny , yp, ny]);
    maxy = max([maxy , yp, ny]);

    % Linefeed to do?
    if dolinefeed
        % Update text drawing cursor to perform carriage return:
        if xcenter==0
            xp = sx;
        end
        yp = ny + theight;
    else
        % Keep drawing cursor where it is supposed to be:
        xp = nx;
        yp = ny;
    end
    % Done with substring, parse next substring.
end

% Add one line height:
maxy = maxy + theight;

% Create final bounding box:
textbounds = SetRect(minx, miny, maxx, maxy);

% Create new cursor position. The cursor is positioned to allow
% to continue to print text directly after the drawn text.
% Basically behaves like printf or fprintf formatting.
nx = xp;
ny = yp;

% Our work is done. If a different window than our target window was
% active, we'll switch back to that window and its state:
if previouswin > 0
    if previouswin ~= win
        % Different window was active before our invocation:

        % Was that window in 3D mode, i.e., OpenGL rendering for that window was active?
        if IsOpenGLRendering
            % Yes. We need to switch that window back into 3D OpenGL mode:
            Screen('BeginOpenGL', previouswin);
        else
            % No. We just perform a dummy call that will switch back to that
            % window:
            Screen('GetWindowInfo', previouswin);
        end
    else
        % Our window was active beforehand.
        if IsOpenGLRendering
            % Was in 3D mode. We need to switch back to 3D:
            Screen('BeginOpenGL', previouswin);
        end
    end
end

return;
end

