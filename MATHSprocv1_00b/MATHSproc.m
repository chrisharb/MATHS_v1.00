%% GUI for use with Itasca Insite generated .atf files or alternatively
% the GUI MATHSdaq which utilises HandyScope HS4's manufactured by
% TiePie corporation.
% Developed for use with triggered or continuous strain gauge recordings,
% but also accepts piezos which may be used in rupture velocity models, and
% features that will be developed in the future!
%%%%%%%%%%%%%%%%%%%%>> Coded C. Harbord HPHT Rome <<%%%%%%%%%%%%%%%%%%%%%%%

function varargout = MATHSproc(varargin)
% MATHSPROC MATLAB code for MATHSproc.fig
%      MATHSPROC, by itself, creates a new MATHSPROC or raises the existing
%      singleton*.
%
%      H = MATHSPROC returns the handle to a new MATHSPROC or the handle to
%      the existing singleton*.
%
%      MATHSPROC('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MATHSPROC.M with the given input arguments.
%
%      MATHSPROC('Property','Value',...) creates a new MATHSPROC or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MATHSproc_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MATHSproc_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MATHSproc

% Last Modified by GUIDE v2.5 23-Nov-2019 23:35:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @MATHSproc_OpeningFcn, ...
    'gui_OutputFcn',  @MATHSproc_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MATHSproc is made visible.
function MATHSproc_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MATHSproc (see VARARGIN)

% Choose default command line output for MATHSproc
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MATHSproc wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MATHSproc_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function f_open_atf_Callback(hObject, eventdata, handles)
% hObject    handle to f_open_atf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Initialise some information using input dialogs

path = uigetdir('Open folder containing .atf files'); %Open dialog to import files
if path == 0 %If opening operation is cancelled stop exit the callback
    set(handles.text7,'string','Opening operation cancelled'); %Display a message to the message box
    return;
else
    flds = {'data','strain','t','dt','name','ax'};
    for i = 1:length(flds)
        chr = flds(i);
        if isfield(handles,chr)
            handles = rmfield(handles,chr);
        end
    end
    eval(['cd ' path]); %Change directory to file location
    txtfile = dir('*.atf'); %Get list of .atf files in directory using wildcard
    nfile = numel(txtfile); %Count the number of files to process
    prompt = {'Enter number of channels:','N. rosettes'}; %Prompt user for experimental set-up
    dlgtitle = 'Get channel info.'; %Title of pop-up window displayed to get experimental set-up information
    dims = [1;1]; %Dimensions of pop-up window
    definput = {'8','4'}; %Default input for number of channels and number of observation locations
    response = inputdlg(prompt,dlgtitle,dims,definput); %Get the input data using a pop-up window
    if isempty(response)
        handles.channels = str2double(definput{1}); %Default behaviour if no response
        handles.rosettes = str2double(definput{2}); %Default behaviour if no response
        set(handles.text7,'string','Using default channel and rosette settings');
    else
        handles.channels = str2double(response{1}); %Get number of channels from the dialog response
        handles.rosettes = str2double(response{2}); %Get number of rosettes from the dialog response
    end
    
    handles.at = NaN.*ones(handles.channels,1); %Assign NaN to arrival time array
    
    sel = questdlg('Does the data require converting to decimal representation? (Required when importing *.atf files saved directly from Cecchi Leech)','Data formatting','Yes','No','Cancel import','No');
    if strcmp(sel,'Yes')
        handles.bits = str2double(inputdlg({'Enter the bit representation of the raw data'},'Specify bits',1,{'12'}));
        bitflag = true;
    else
        bitflag = false;
    end
    %set(handles.msg_box,'String','Bit conversion will be applied');
    %Settings for subplots
    i1 = 4;
    if handles.channels>4 && handles.channels<9
        i2 = 2;
    elseif handles.channels>8 && handles.channels<13
        i2 = 3;
    elseif handles.channels>12 && handles.channels<16
        i2 = 4;
    else
        i2 = 1;
        i1 = handles.channels;
    end
    
    %Plot something as an initial check
    for i = 1:handles.channels
        handles.ax(i)=subplot(i1,i2,i,'Parent',handles.uipanel1);
        handles.line(i)=plot(handles.ax(i),rand(10,1));
        xlabel(handles.ax(i),'Time [ms]');
        ylabel(handles.ax(i),'Volts');
        title(handles.ax(i),['Channel ' num2str(i)])
    end
    %% Extract waveform data from .atf files created by InSite lab processing software
    h = waitbar(0,'Reading data into MATLAB');
    h.Children.Title.Interpreter = 'none';
    % The main data extraction loop, strongly not reccommended to edit
    for i = 0:handles.channels:nfile-handles.channels %Extraction loop
        clear Sxy1 Sxy2
        for j = 1:handles.channels
            waitbar(i/nfile,h,['Reading data into MATLAB, file: ',txtfile(i+j).name])
            if j == 1
                fid = txtfile(i+j).name; %Get file name for extraction
                c = j;%str2double(fid(end-5:end-3));
                ev = i/handles.channels+1;%str2double(fid(10:13));
                EV(i+j) = i/handles.channels+1;
                handles.name{ev} = fid(1:end-7);
                Str = fileread(fid); %Open file as a string
                Str(strfind(Str, '=')) = []; %Remove = from string
                Str(strfind(Str, ':')) = []; %Remove : from string
                Str(strfind(Str, ' ')) = []; %Remove empty spaces
                % Extract time information
                Key = 'Time';
                Itime = strfind(Str, Key);
                time{ev} = sscanf(Str(Itime(1) + length(Key):end), '%g', 1);
                %Extract sacling of data
                Key = 'TraceMaxVolts';
                ImaxV = strfind(Str, Key);
                maxV{ev} = sscanf(Str(ImaxV(1) + length(Key):end), '%g', 1); %Extract the signal scaling to convert data to decimal
                % Extract waveform length data
                Key = 'TracePoints';
                Ilength = strfind(Str, Key);
                nsamp{ev} = sscanf(Str(Ilength(1) + length(Key):end), '%g', 1);
                %Extract sampling interval
                Key = 'TSamp';
                Isamp = strfind(Str, Key);
                samp{ev} = sscanf(Str(Isamp(1) + length(Key):end), '%g', 1);
                %Extract Time units of data
                Key = 'TimeUnits';
                Iunits = strfind(Str, Key);
                timeunits{ev} = sscanf(Str(Iunits(1) + length(Key):end), '%g', 1);
                handles.dt{ev} = samp{ev}.*timeunits{ev};
                %Remove - from string and extract date
                Str(strfind(Str, '-')) = [];
                Key = 'Date';
                Idate = strfind(Str,Key);
                Date{ev} = sscanf(Str(Idate(1) + length(Key):end), '%g', 1);
                %Create time vector for each waveform
                handles.t{ev} = handles.dt{ev}:handles.dt{ev}:nsamp{ev}*handles.dt{ev};
                clear Str
                fil = fopen(fid,'r'); %Open the file
                cdata = textscan(fil,'%f','delimiter','\n','HeaderLines',3); %Extract waveform data ignoring first three lines of file
                if bitflag == 1
                    handles.data(ev,c).raw = cdata{1}./(2^handles.bits*maxV{ev}); %Save waveform data to cell structures
                else
                    handles.data(ev,c).raw = cdata{1};
                end
                ST = fclose(fil); %Close file
            else
                fid = txtfile(i+j).name; %Get file name for extraction
                c = j;%str2double(fid(end-5:end-3));
                ev = i/handles.channels+1;%str2double(fid(10:13));
                EV(i+j) = i/handles.channels+1;
                fil = fopen(fid,'r'); %Open the file
                cdata = textscan(fil,'%f','delimiter','\n','HeaderLines',3); %Extract waveform data ignoring first three lines of file
                if bitflag == 1
                    handles.data(ev,c).raw = cdata{1}./(2^handles.bits*maxV{ev}); %Save waveform data to cell structures
                else
                    handles.data(ev,c).raw = cdata{1};
                end
                
                ST = fclose(fil); %Close file
            end
            
        end
    end
    close(h);
    
    %% Plotting of initial data
    i1 = 4;
    if handles.channels>4 && handles.channels<9
        i2 = 2;
    elseif handles.channels>8 && handles.channels<13
        i2 = 3;
    elseif handles.channels>12 && handles.channels<16
        i2 = 4;
    else
        i2 = 1;
        i1 = handles.channels;
    end
    
    for i = 1:handles.channels
        handles.line(i)=plot(handles.ax(i),handles.t{1}.*1000,handles.data(1,i).raw);
        xlabel(handles.ax(i),'Time [ms]');
        ylabel(handles.ax(i),'Volts');
        title(handles.ax(i),['Channel ' num2str(i)])
    end
    set(handles.trig,'Value',1);
    linkaxes(handles.ax,'x');
    
    %% Define parameters for uitable and drop down menus
    evn = size(handles.data);
    handles.events = evn;
    evV = 1:1:evn(1);
    handles.trig.String = cellstr(handles.name);
    chan=1:1:handles.channels;
    ros=1:1:handles.rosettes;
    chans = cellstr(num2str(chan'));
    ros = cellstr(num2str(ros'));
    
    %% Setting of acquisition parameters uitable
    %Initialisation of uitable using matrix
    dat = {false 'set' 'set' 'set' 'set' NaN 'set' 'set' 'pick' NaN};
    datini = {};
    for i = 1:handles.channels
        datini = [datini; dat];
    end
    handles.datini=datini;
    handles.uitable.Data=datini;
    
    %Definition of uitable choices
    comp = {'exx','ed','eyy'};
    brid = {'Full','Half','Quarter'};
    vexc = {'5V','10V'};
    res = {'120 ohm','350 ohm'};
    gain = {'1x','10x','100x'};
    
    %Definition of uitable headers
    handles.uitable.ColumnName = {'Piezo?','Rosette','Component','Bridge','Vexc','Gauge factor','Resistance','Gain','Arrival time','Arrival time [ms]'};
    handles.uitable.RowName = chans;
    
    %Filling of uitable according to choices
    handles.uitable.ColumnEditable = [true true true true true true true true false true];
    handles.uitable.ColumnFormat(2)={ros'};% comp brid};
    handles.uitable.ColumnFormat(3)={comp};
    handles.uitable.ColumnFormat(4)={brid};
    handles.uitable.ColumnFormat(5)={vexc};
    handles.uitable.ColumnFormat(7)={res};
    handles.uitable.ColumnFormat(8)={gain};
    
    %Initialisation of some vectors
    handles.ros = NaN.*ones(handles.channels,1);
    handles.comp = cellstr(num2str(666.*ones(handles.channels,1)));
    handles.bridge = handles.ros;
    handles.gf = handles.ros;
    handles.res = handles.ros;
    handles.gain = handles.ros;
    handles.exc = handles.ros;
    
    %% Setting of sensor location parameters
    dat2 = {false NaN NaN NaN};
    datini2 = {};
    for i = 1:handles.rosettes
        datini2=[datini2;dat2];
    end
    handles.uitable2.ColumnEditable = [true true true false];
    handles.datini2=datini2;
    handles.uitable2.Data=datini2;
    handles.uitable2.ColumnName = {'Use?','X-position [mm]','Y-position [mm]','Arrival time [ms]'};
    handles.uitable2.RowName = ros;
end
guidata(hObject, handles);

function fopen_mat_Callback(hObject, eventdata, handles)
% hObject    handle to fopen_mat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%% Dialogs to identify parent storage directory
handles.parent_path = uigetdir('Open parent folder containing .atf files'); % Open dialog to import files
if handles.parent_path == 0 % If no folder selected exit the callback
    set(handles.text7,'string','Opening operation cancelled');
    return
else
    flds = {'data','strain','t','dt','name','ax'};
    for i = 1:length(flds)
        chr = flds(i);
        if isfield(handles,chr)
            handles = rmfield(handles,chr);
        end
    end
    eval(['cd ' handles.parent_path]); % Navigate to parent storage directory
    files = dir(); % Get a list of all files and folders in this folder.
    dirFlags = [files.isdir]; % Get a logical vector that tells which is a directory.
    SF = files(dirFlags); % Extract only those that are directories.
    ds = 1000; % Smoothing factor of raw data
    nfol = 0; % Initialise directory counter, used as mac creates hidden folders
    
    prompt = {'Enter number of channels:','N. rosettes'}; %Prompt user for experimental set-up
    dlgtitle = 'Get channel info.';
    dims = [1;1];
    definput = {'8','4'};
    response = inputdlg(prompt,dlgtitle,dims,definput);
    
    if isempty(response)
        handles.channels = str2double(definput{1});
        handles.rosettes = str2double(definput{2});
        set(handles.text7,'string','Using default channel and rosette settings');
    else
        handles.channels = str2double(response{1});
        handles.rosettes = str2double(response{2});
    end
    % Define information about plotting array
    i1 = 4;
    if handles.channels>4 && handles.channels<9
        i2 = 2;
    elseif handles.channels>8 && handles.channels<13
        i2 = 3;
    elseif handles.channels>12 && handles.channels<16
        i2 = 4;
    else
        i2 = 1;
        i1 = handles.channels;
    end
    % Plot something as a check that everything is hunky dory
    for i = 1:handles.channels
        handles.ax(i)=subplot(i1,i2,i,'Parent',handles.uipanel1);
        handles.line(i)=plot(handles.ax(i),rand(10,1));
        xlabel(handles.ax(i),'Time [ms]');
        ylabel(handles.ax(i),'Volts');
        title(handles.ax(i),['Channel ' num2str(i)]);
    end
    %% Main .mat data extraction loop
    h =waitbar(0,'Reading in .mat files, please wait');
    for i = 1:length(SF)
        waitbar(i/length(SF),h,['Working on directory: ' SF(i).name]);
        if strcmp(SF(i).name,'.') || strcmp(SF(i).name, '..')
        else
            nfol = nfol+1;
            eval(['cd ' handles.parent_path '/' SF(i).name]); % Change directory to open and stitch folders
            temp = []; % Initialise a temporary storage variable
            files = dir('*.mat'); % Get a list of all .mat files in the current directory
            for j = 1:length(files)
                fil = files(j).name; % Get filename to open
                p = open(fil); % Open file
                dat = p.arData; % Get raw data
                temp = [temp dat']; % Concatenate data arrays
                FS = p.freq; % Get sampling frequency of data
                clear dat p % Clear temporary variables
            end
            for j = 1:handles.channels
                handles.data(nfol,j).raw = smooth(temp(j,:),ds); % Store data in struct array
                handles.data(nfol,j).fs = FS; % Store sampling frequency of file
            end
            handles.t{nfol} = (1:1:length(handles.data(nfol,1).raw))/FS; % Create time vector for plotting and data processing later on :-)
            handles.dt{nfol} = 1/FS; % Samling interval of current directory
            handles.name{nfol} = SF(i).name; %Save current dirctory name to list of directory names
            if isfield(handles,'TR')
                chr = [SF(i).name(1:4) ':' SF(i).name(5:6) ':' SF(i).name(7:8) ':' SF(i).name(9:10) ':' SF(i).name(11:12) ':' SF(i).name(13:14)];
                t = datetime(chr,'InputFormat','yyyy:MM:dd:HH:mm:ss');
                tmp = t-handles.TR.start;
                handles.name{nfol} = datestr(tmp,'dd:HH:mm:ss');
            end
            clear temp
            clear files
            clear FS
        end
    end
    close(h); % Close the waitbar
    eval(['cd ' handles.parent_path]); % Change back to the parent directory
    handles.at = NaN.*ones(handles.channels,1); % Initialise arrival times
    set(handles.trig,'Value',1);
    handles.trig.String = cellstr(handles.name);
    %% Plot some data as initial check
    for i = 1:handles.channels
        handles.line(i)=plot(handles.ax(i),handles.t{1}.*1000,handles.data(1,i).raw);
        xlabel(handles.ax(i),'Time [ms]');
        ylabel(handles.ax(i),'Volts');
        title(handles.ax(i),['Channel ' num2str(i)])
    end
    linkaxes(handles.ax,'x');
    %% Define parameters for uitable and drop down menus
    evn = size(handles.data,1);
    handles.events = evn;
    evV = 1:1:evn(1);
    handles.trig.String = cellstr(handles.name);
    chan=1:1:handles.channels;
    ros=1:1:handles.rosettes;
    chans = cellstr(num2str(chan'));
    ros = cellstr(num2str(ros'));
    
    %% Setting of acquisition parameters uitable
    %Initialisation of uitable using matrix
    dat = {false 'set' 'set' 'set' 'set' NaN 'set' 'set' 'pick' NaN};
    datini = {};
    for i = 1:handles.channels
        datini = [datini; dat];
    end
    handles.datini=datini;
    handles.uitable.Data=datini;
    
    %Definition of uitable choices
    comp = {'exx','ed','eyy'};
    brid = {'Full','Half','Quarter'};
    vexc = {'5V','10V'};
    res = {'120 ohm','350 ohm'};
    gain = {'1x','10x','100x'};
    
    %Definition of uitable headers
    handles.uitable.ColumnName = {'Piezo?','Rosette','Component','Bridge','Vexc','Gauge factor','Resistance','Gain','Arrival time','Arrival time [ms]'};
    handles.uitable.RowName = chans;
    
    %Filling of uitable according to choices
    handles.uitable.ColumnEditable = [true true true true true true true true false true];
    handles.uitable.ColumnFormat(2)={ros'};% comp brid};
    handles.uitable.ColumnFormat(3)={comp};
    handles.uitable.ColumnFormat(4)={brid};
    handles.uitable.ColumnFormat(5)={vexc};
    handles.uitable.ColumnFormat(7)={res};
    handles.uitable.ColumnFormat(8)={gain};
    
    %Initialisation of some vectors
    handles.ros = NaN.*ones(handles.channels,1);
    handles.comp = cellstr(num2str(666.*ones(handles.channels,1)));
    handles.bridge = handles.ros;
    handles.gf = handles.ros;
    handles.res = handles.ros;
    handles.gain = handles.ros;
    handles.exc = handles.ros;
    
    %% Setting of sensor location parameters
    dat2 = {false NaN NaN NaN};
    datini2 = {};
    for i = 1:handles.rosettes
        datini2=[datini2;dat2];
    end
    handles.uitable2.ColumnEditable = [true true true false];
    handles.datini2=datini2;
    handles.uitable2.Data=datini2;
    handles.uitable2.ColumnName = {'Use?','X-position [mm]','Y-position [mm]','Arrival time [ms]'};
    handles.uitable2.RowName = ros;
end
guidata(hObject, handles);

function Fstop_Callback(hObject, eventdata, handles)

function Fstop_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu4_Callback(hObject, eventdata, handles)


function popupmenu4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function File_menu_Callback(hObject, eventdata, handles)

function close_prog_Callback(hObject, eventdata, handles)
delete(hObject)
clear
close all

% --- Executes on button press in zoomB.
function zoomB_Callback(hObject, eventdata, handles)
pan off
hzoom = zoom;
hzoom.Motion='horizontal';
linkaxes(handles.ax,'x');
hzoom.Enable='on';

% --- Executes on button press in panB.
function panB_Callback(hObject, eventdata, handles)
zoom off
hpan = pan;
hpan.Motion='horizontal';
linkaxes(handles.ax,'x');
hpan.Enable='on';

% --- Executes on button press in cursor.
function cursor_Callback(hObject, eventdata, handles)
zoom off
pan off
datacursormode off

% --- Executes on button press in Reset.
function Reset_Callback(hObject, eventdata, handles)

handles.uitable.Data=handles.datini;

% --- Executes on button press in rupture.
function rupture_Callback(hObject, eventdata, handles)
% hObject    handle to rupture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
n = get(handles.trig,'Value');
data = get(handles.uitable,'Data');
data2 = get(handles.uitable2,'Data');
at = cell2mat(data(:,10));
at = str2num(at).*1e-3;
temp = data(:,2);
I=strcmp(temp,'set');
temp(I) = [];
if sum(isnan(at))>7
    set(handles.text7,'string','Insufficient number of gauges to estimate the rupture velocity')
else
    at(isnan(at))=[];
    xpos = cell2mat(data2(:,2));
    xpos(isnan(xpos))=[];
    ypos = cell2mat(data2(:,3));
    ypos(isnan(ypos))=[];
    W = str2double(get(handles.S_width,'String'));
    L = str2double(get(handles.S_length,'String'));
    [handles.Rupt(n).vrct,handles.Rupt(n).trc,handles.Rupt(n).x_loc,handles.Rupt(n).y_loc,handles.Rupt(n).vr_op,handles.Rupt(n).tr_op]=ruptcalc(xpos,ypos,at,W,L);
    set(handles.text7,'string',['Rupture velocity for event ' num2str(n) ' is ' num2str(handles.Rupt(n).vr_op) ' m/s, with a ' num2str(handles.Rupt(n).tr_op.*1e6) ' mus residual'])
end
guidata(hObject,handles);

% --- Executes on selection change in trig.
function trig_Callback(hObject, eventdata, handles)
% hObject    handle to trig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns trig contents as cell array
%        contents{get(hObject,'Value')} returns selected item from trig
update_plots(hObject, eventdata, handles)

function update_plots(hObject, eventdata, handles)
% Function to plot data on the GUI axes
n = get(handles.trig,'Value');
table = get(handles.uitable,'Data');
st = get(handles.filt,'Value');
if get(handles.plot_strain,'Value')==1 && isfield(handles,'strain')
    for i = 1:handles.channels
        if table{i,1}==1
            plot(handles.ax(i),handles.t{n}.*1000,handles.data(n,i).raw);
            xlabel(handles.ax(i),'Time [ms]');
            ylabel(handles.ax(i),'Amplitude [V]');
            title(handles.ax(i),['Channel ' num2str(i)]);
        else
            chr = handles.comp{i};
            if st == 1
                eval(['plot(handles.ax(i),handles.t{n}*1000,handles.strain(n).raw.' chr '*1e6)']);
                hold(handles.ax(i),'on')
                eval(['plot(handles.ax(i),handles.t{n}*1000,handles.strain(n).filt.' chr '*1e6)']);
                hold(handles.ax(i),'off')
            else
                eval(['plot(handles.ax(i),handles.t{n}*1000,handles.strain(n).raw.' chr '*1e6)']);
            end
            xlabel(handles.ax(i),'Time [ms]')
            ylabel(handles.ax(i),['\epsilon_{' chr(2:end-1) '}^' chr(end)  ' [\mu\epsilon]'])
            title(handles.ax(i),['Channel ' num2str(i)]);
            
        end
    end
else
    for i = 1:handles.channels
        plot(handles.ax(i),handles.t{n}.*1000,handles.data(n,i).raw);
        xlabel(handles.ax(i),'Time [ms]');
        ylabel(handles.ax(i),'Amplitude [V]');
        title(handles.ax(i),['Channel ' num2str(i)]);
    end
end

% --- Executes during object creation, after setting all properties.
function trig_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','red');
end


% --- Executes when entered data in editable cell(s) in uitable.
function uitable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in c_strain.
function c_strain_Callback(hObject, eventdata, handles)

if isfield(handles,'data')
    table = get(handles.uitable,'Data');
    st = get(handles.filt,'Value');
    n = get(handles.trig,'Value');
    fstop = str2num(get(handles.Fstop,'String'));
    flo = str2num(get(handles.f_lo,'String'));
    all = get(handles.all_events,'Value');
    if st == 1
        d = designfilt('bandpassfir', 'FilterOrder', 100, 'CutoffFrequency1', ...
            flo, 'CutoffFrequency2', fstop, ...
            'SampleRate', 1/handles.dt{n}*1, 'DesignMethod', ...
            'window', 'Window', 'hamming');
    else
    end
    flag=0;
    quit=0;
    if all == 1
        loop = 1:1:handles.events(1);
        set(handles.text7,'string',['Processing all ' num2str(handles.events(1)) ' events']);
    else
        loop = n;
    end
    hh = waitbar(0,'Converting data to strain');
    for n=loop
        waitbar(n/max(loop),hh);
        for i=1:handles.channels
            flag = flag+1;
            if table{i,1} == 1
                if flag <= handles.channels
                    set(handles.text7,'string',['Channel ' num2str(i) ' is a piezo']);
                else
                end
            else
                if flag <= handles.channels
                    set(handles.text7,'string',['Channel ' num2str(i) ' is a gauge']);
                else
                end
                
                switch table{i,2}
                    case 'set'
                        set(handles.text7,'string',['Rosette of gauge ' num2str(i) ' not set']);
                        break
                    otherwise
                        handles.ros(i) = str2double(table{i,2});
                end
                
                switch table{i,3}
                    case 'set'
                        set(handles.text7,'string',['Component of gauge ' num2str(i) ' not set']);
                        break
                    case 'exx'
                        handles.comp{i} = ['exx' num2str(handles.ros(i))];
                    case 'ed'
                        handles.comp{i} = ['ed' num2str(handles.ros(i))];
                    case 'eyy'
                        handles.comp{i} = ['eyy' num2str(handles.ros(i))];
                    otherwise
                        set(handles.text7,'string',['Error in component of gauge ' num2str(i)]);
                        handles.comp{i} = NaN;
                end
                
                switch table{i,4}
                    case 'set'
                        set(handles.text7,'string',['Bridge type of gauge ' num2str(i) ' not set'])
                        break
                    case 'Full'
                        handles.bridge(i) = 1;
                    case 'Half'
                        handles.bridge(i) = 2;
                    case 'Quarter'
                        handles.bridge(i) = 3;
                    otherwise
                        set(handles.text7,'string',['Error in bridge configuration of gauge ' num2str(i)]);
                        handles.bridge(i) = NaN;
                end
                
                switch table{i,5}
                    case 'set'
                        set(handles.text7,'string',['Excitation of gauge ' num2str(i) ' not set'])
                        break
                    case '5V'
                        handles.exc(i) = 5;
                    case '10V'
                        handles.exc(i) = 10;
                    otherwise
                        set(handles.text7,'string',['Error in excitation setting of gauge ' num2str(i)]);
                        handles.exc(i) = NaN;
                end
                
                if isnan(table{i,6}) || isempty(table{i,6})
                    disp(['Gauge factor for gauge ' num2str(i) ' not set'])
                    break
                else
                    handles.gf(i) = table{i,6};
                end
                
                switch table{i,7}
                    case 'set'
                        set(handles.text7,'string',['Resistance for gauge ' num2str(i) ' not set'])
                        break
                    case '120 ohm'
                        handles.res(i) = 120;
                    case '350 ohm'
                        handles.res(i) = 350;
                    otherwise
                        set(handles.text7,'string',['Error in resistance setting of gauge ' num2str(i)]);
                        handles.res(i) = NaN;
                end
                
                switch table{i,8}
                    case 'set'
                        set(handles.text7,'string',['Gain for gauge ' num2str(i) ' not set'])
                        break
                    case '1x'
                        handles.gain(i) = 1;
                    case '10x'
                        handles.gain(i) = 10;
                    case '100x'
                        handles.gain(i) = 100;
                    otherwise
                        set(handles.text7,'string',['Error in resistance setting of gauge ' num2str(i)]);
                        handles.gain(i) = NaN;
                end
                
                nu = 0.25;
                chr = handles.comp{i};
                temp = (handles.data(n,i).raw)./(handles.exc(i)*handles.gain(i));
                if handles.bridge(i) == 1
                    eval(['handles.strain(n).raw.' chr '= (-2.*temp)./(handles.gf(i).*((nu+1)-temp.*(nu-1)));']);
                elseif handles.bridge(i) == 2
                    eval(['handles.strain(n).raw.' chr '= (-4.*temp)./(handles.gf(i).*((nu+1)-2.*temp.*(nu-1)));']);
                elseif handles.bridge(i) == 3
                    eval(['handles.strain(n).raw.' chr '= (-4.*temp)./(handles.gf(i).*(1+2.*temp));']);
                end
                if st == 1
                    eval(['handles.strain(n).filt.' chr '=filtfilt(d,double(handles.strain(n).raw.' chr '));']);
                else
                end
                clear temp
            end
            
        end
        
    end
    close(hh)
    update_plots(hObject, eventdata, handles)
else
end

guidata(hObject,handles);

% --- Executes when selected cell(s) is changed in uitable.
function uitable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

handles.currentCell=eventdata.Indices;
if isempty(eventdata.Indices) | eventdata.Indices ~= 9
    return
elseif handles.currentCell(2) == 9
    delete(findall(gcf,'Type','hggroup'));
    figHandles = findobj('Type', 'figure');
    ind = handles.currentCell(1);
    dc = datacursormode(figHandles);
    datacursormode on
    info = ginput(1);
    handles.at(ind) = info(1);
    arrt = cellstr(num2str(handles.at));
    handles.uitable.Data(:,10)=arrt';
    guidata(hObject,handles);
else
    return
end
guidata(hObject,handles);


function figure1_DeleteFcn(hObject,eventdata,handles)
%added to avoid error on closing... :-)


function S_width_Callback(hObject, eventdata, handles)
% hObject    handle to S_width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of S_width as text
%        str2double(get(hObject,'String')) returns contents of S_width as a double


% --- Executes during object creation, after setting all properties.
function S_width_CreateFcn(hObject, eventdata, handles)
% hObject    handle to S_width (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function S_length_Callback(hObject, eventdata, handles)
% hObject    handle to S_length (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of S_length as text
%        str2double(get(hObject,'String')) returns contents of S_length as a double


% --- Executes during object creation, after setting all properties.
function S_length_CreateFcn(hObject, eventdata, handles)
% hObject    handle to S_length (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in plot_strain.
function plot_strain_Callback(hObject, eventdata, handles)
% hObject    handle to plot_strain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in plot_stress.
function plot_stress_Callback(hObject, eventdata, handles)
% hObject    handle to plot_stress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of plot_stress


% --- Executes on button press in filt.
function filt_Callback(hObject, eventdata, handles)
% hObject    handle to filt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of filt


% --- Executes on button press in all_events.
function all_events_Callback(hObject, eventdata, handles)
% hObject    handle to all_events (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of all_events



function bit_Callback(hObject, eventdata, handles)
% hObject    handle to bit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bit as text
%        str2double(get(hObject,'String')) returns contents of bit as a double


% --- Executes during object creation, after setting all properties.
function bit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in bit_conv.
function bit_conv_Callback(hObject, eventdata, handles)
% hObject    handle to bit_conv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of bit_conv


% --------------------------------------------------------------------




function f_lo_Callback(hObject, eventdata, handles)
% hObject    handle to f_lo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of f_lo as text
%        str2double(get(hObject,'String')) returns contents of f_lo as a double


% --- Executes during object creation, after setting all properties.
function f_lo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to f_lo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[~,PathName] = uiputfile;
old_dir = pwd;
eval(['cd ' PathName]);
n = get(handles.trig,'Value');
nom1 = handles.name{n};
for i = 1:handles.channels
    nom2 = ['CH' num2str(i)];
    fignew = figure('Visible','off'); % Invisible figure
    newAxes = copyobj(handles.ax(i),fignew); % Copy the appropriate axes
    set(newAxes,'Position',get(groot,'DefaultAxesPosition')); % The original position is copied too, so adjust it.
    set(fignew,'CreateFcn','set(gcbf,''Visible'',''on'')'); % Make it visible upon loading
    saveas(fignew,[nom1 nom2 '.png']);
    delete(fignew);
end
eval(['cd ' old_dir]);


% --------------------------------------------------------------------
function tr2_Callback(hObject, eventdata, handles)
% hObject    handle to tr2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[Name,PathName] = uigetfile('*.*');
if Name ~= 0
handles.old_dir = pwd;
eval(['cd ' PathName])
fid = fileread(Name);
handles.TR.date = [fid(14:17) ':' fid(11:12) ':' fid(8:9)];
handles.TR.time = [fid(25:26) ':' fid(28:29) ':' fid(31:32)];
handles.TR.start = datetime([handles.TR.date ':' handles.TR.time],'InputFormat','yyyy:MM:dd:HH:mm:ss');
nhead = 37;
spec = [];

for i = 1:nhead
    spec = [spec '%f'];
end

data = textscan(fid,spec,'delimiter','\n','HeaderLines',3); %Extract waveform data ignoring first three lines of file
handles.TR.t = data{1};
handles.TR.t_base = seconds(handles.TR.t);
handles.TR.t_base.Format = 'dd:hh:mm:ss.SSS';
handles.TR.UPp = data{2};
handles.TR.DPp = data{3};
handles.TR.Pc = data{4};
handles.TR.PPvol = data{5};
handles.TR.F = data{6};
handles.TR.T = data{7};
handles.TR.U = data{8};
handles.TR.PcVol = data{9};
clear fid
plot(handles.tr_plot,handles.TR.t_base,handles.TR.F)
cd(handles.old_dir);
guidata(hObject,handles);
end


% --- Executes on button press in dat_tip.
function dat_tip_Callback(hObject, eventdata, handles)
% hObject    handle to dat_tip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.text7,'String','Hold shift for multiple datatips');
datacursormode on


% --- Executes on button press in dt_delete.
function dt_delete_Callback(hObject, eventdata, handles)
% hObject    handle to dt_delete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(findall(gcf,'Type','hggroup'));
set(handles.text7,'String','Datatips deleted!');


% --- Executes on button press in rm_event.
function rm_event_Callback(hObject, eventdata, handles)
% hObject    handle to rm_event (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
n = get(handles.trig,'Value');
handles.name(n) = [];
handles.trig.String = cellstr(handles.name);
handles.data(n,:) = [];
handles.t(n)=[];
if exist('handles.strain','var')
    handles.strain(n) = [];
end
update_plots(hObject, eventdata, handles);
handles.events = length(handles.t);
guidata(hObject,handles);


% --- Executes on button press in cut_event.
function cut_event_Callback(hObject, eventdata, handles)
% hObject    handle to cut_event (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cut_event
table = get(handles.uitable,'Data');
delete(findall(gcf,'Type','hggroup'));
figHandles = findobj('Type', 'figure');
dc = datacursormode(figHandles);
datacursormode on
info = ginput(2);
n = get(handles.trig,'Value');
ix(1) = round((info(1,1)-handles.t{n}(1)*1000)/1000/handles.dt{n});
ix(2) = round((info(2,1)-handles.t{n}(1)*1000)/1000/handles.dt{n});
sel = questdlg('Do you want to cut the data?','Confirm selection','Yes','No','Yes');
if strcmp(sel,'Yes')
    for i = 1:handles.channels
        handles.data(n,i).raw = handles.data(n,i).raw(ix(1):ix(2));
        chr = handles.comp{i};
        if isfield(handles,'strain') && table{i,1}==0
            eval(['handles.strain(n).raw.' chr '= handles.strain(n).raw.' chr '(ix(1):ix(2));']);
            if isfield(handles.strain,'filt')
                eval(['handles.strain(n).filt.' chr '= handles.strain(n).filt.' chr '(ix(1):ix(2));']);
            end
        end
        
    end
    handles.t{n}=handles.t{n}(ix(1):ix(2));
else
end
update_plots(hObject, eventdata, handles)
guidata(hObject,handles);


% --------------------------------------------------------------------
function exp_dat_Callback(hObject, eventdata, handles)
% hObject    handle to exp_dat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function png_save_Callback(hObject, eventdata, handles)
% hObject    handle to png_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function save_svg_Callback(hObject, eventdata, handles)
% hObject    handle to save_svg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mat_save_Callback(hObject, eventdata, handles)
% hObject    handle to mat_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function txt_save_Callback(hObject, eventdata, handles)
% hObject    handle to txt_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function csv_save_Callback(hObject, eventdata, handles)
% hObject    handle to csv_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
