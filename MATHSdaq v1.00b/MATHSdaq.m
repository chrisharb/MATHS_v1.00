function varargout = MATHSdaq(varargin)
% MATHSDAQ MATLAB code for MATHSdaq.fig
%% mathsdaq.m
% This GUI code interfaces with TiePie oscilloscopes (Model HS3--> onwards)
% using the LibTiePie SDI plugin. Measurements may be performed in a
% continuous mode or a triggered mode according to typical oscilloscope
% parameters e.g. falling edge, rising edge or threshold.
%
% Coded by C. Harbord (UCL Seismolab)
%% Matlab waffle
%      MATHSDAQ, by itself, creates a new MATHSDAQ or raises the existing
%      singleton*.
%
%      H = MATHSDAQ returns the handle to a new MATHSDAQ or the handle to
%      the existing singleton*.
%
%      MATHSDAQ('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MATHSDAQ.M with the given input arguments.
%
%      MATHSDAQ('Property','Value',...) creates a new MATHSDAQ or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MATHSdaq_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MATHSdaq_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MATHSdaq

% Last Modified by GUIDE v2.5 15-May-2021 14:14:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MATHSdaq_OpeningFcn, ...
                   'gui_OutputFcn',  @MATHSdaq_OutputFcn, ...
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

% --- Executes just before MATHSdaq is made visible.
function MATHSdaq_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MATHSdaq (see VARARGIN)
% Choose default command line output for MATHSdaq
if ismac
    disp('LibTiePie is not compatible with MacOS, aborting program. Bye.')
    clear; close all
    return
else
cdir = pwd(); %Get working directory to import subpaths
eval(['addpath ' cdir])  % add library paths
handles.output = hObject; % Update handles
disp('Launching MATHSdaq and building LibTiePie');
handles.LibTiePie = LibTiePie.Library; % Compile LibTiePie c library
 % Return library compilation status in pop up window
i = msgbox(['Status of library initialisation: ' handles.LibTiePie.LastStatusStr ', click OK to continue']);
while ishandle(i) % Wait for user acknowledgement of status
    pause(0.01)
end
handles.counter = 0; % Initialise the counter
end
guidata(hObject, handles); % Update handles


% --- Outputs from this function are returned to the command line.
function varargout = MATHSdaq_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function uipanel1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in init.
% Calls function get_scp() to open connection to handyscope(s)
function init_Callback(hObject, eventdata, handles)
% hObject    handle to init (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
import LibTiePie.Const.*;
import LibTiePie.Enum.*;
% Confirm user intends to search for handyscopes, accidental click after initial connection will throw an error exception
sel = questdlg('Search for Handyscopes?','Connecting to instruments','OK','Cancel','Cancel');
if strcmp(sel,'Cancel') % Cancel search
    return
else
    % Open connection to handyscope(s)
    [handles.scp,handles.SN,handles.sn_c,handles.PID,handles.nscp] = get_scp(handles.LibTiePie);
    % Case -1, no handyscopes found or .dll error
    if handles.scp == -1
        set(handles.msg_box,'String','No oscilloscopes found, if you are experiencing difficulties try turning it on and off again.');
    % Other case, handyscopes found, set up display graphics
    else
        handles.chans = length(handles.scp.Channels); % Get total number of channels
        handles.res = handles.scp.Resolutions; % Read supported bitness
        headers = []; % Initialise settings table headers
        dat={}; % Initialise settings table data
        serial = []; % Initialise serial number array
        % Loop to create string of serial numbers of each instrument
        for i = 1:length(handles.SN)
            serial = [serial; ['Osc' num2str(i) ' SN: ' num2str(handles.SN(i))]];
        end
        % Print serial number dialog to message box
        set(handles.serials,'String',serial);

        for j = 1:handles.chans
            dat = [dat; {true  true '8'}]; % Initialise channel settings
            headers = [headers; {['Chan' num2str(j)]}]; % Assign each channel name
            handles.AR = handles.scp.Channels(j).AutoRanging; % Establish if autorange available
        end
        rows = ceil(handles.chans/4); % get number of rows for plot window
        for i = 1:handles.chans % Create graphs for live plotting
            handles.ax(i)=subplot(4,rows,i,'Parent',handles.uipanel1);
            handles.line(i)=plot(handles.ax(i),rand(10,1)); % Check plot refs are working
            xlabel(handles.ax(i),'Time [s]'); % Label x-axis
            ylabel(handles.ax(i),'Volts');  % Label y-axis
            title(handles.ax(i),['Channel ' num2str(i)]) % Title each plot window
        end
%         for i = 1:length(handles.res) % To be added at a later date
%         automatically assign bitness according to supported resolutions
        if handles.PID(1) == 13 % Set bitness options according to handyscope model
            handles.resolution = {'8 bit','12 bit','14 bit','16 bit'};
            handdles.res_opts = [8 12 14 16];
        elseif handles.PID(1) == 15
            handles.resolution = {'12 bit','14 bit','16 bit'};
            handles.res_opts = [12 14 16];
        elseif handles.PID(1) == 20
            handles.resolution = {'12 bit','14 bit','16 bit'};
            handles.res_opts = [12 14 16];
        else
            handles.resolution = {'8 bit','12 bit','14 bit','16 bit'};
            handles.res_opts = [8 12 14 16];
        end
        handles.res_pop.String = handles.resolution; % Update resoultion listbox
        % Set voltage range settings according to available ranges across all models, again should be defined according to models in future update
        handles.v_range = {'0.2','0.4','0.8','2','4','8','20','40','80'}; 
        handles.f_range.String = '1e6'; % Set a default sampling resolution , value is often modified by dll to match handyscope clock
        handles.nsamps.String = '128e3'; % Number of samples per chunk
        handles.uitable1.ColumnEditable = [true true true]; % Allow editing of all channel settings
        handles.uitable1.ColumnName = {'Use?','Trigger?','Scale'}; % Title settings columns
        handles.uitable1.RowName = cellstr(headers); % Title channels
        handles.uitable1.Data = dat; % Initialise settings table with initial settings
        handles.uitable1.ColumnFormat(3) = {handles.v_range}; % Set voltage ranges in listbox
        handles.samp_freq.String = '1e6'; % Initialise frequency settings
        handles.n_samps.String = '1e5'; % sample points settings
        handles.ratio = 0:0.05:1; % Itrigger ratio settings
        handles.trigger_r.String = cellstr(num2str(handles.ratio')); % Generate trigger ratio options
        handles.trig_type.String = {'Rising edge','Falling edge','Threshold'}; % Trigger type settings
    end
end
guidata(hObject,handles); % Update GUI options


% Hint: get(hObject,'Value') returns toggle state of init


% --- Executes on selection change in samp_freq.
function samp_freq_Callback(hObject, eventdata, handles)
% hObject    handle to samp_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns samp_freq contents as cell array
%        contents{get(hObject,'Value')} returns selected item from samp_freq


% --- Executes during object creation, after setting all properties.
function samp_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to samp_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in n_samps.
function n_samps_Callback(hObject, eventdata, handles)
% hObject    handle to n_samps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns n_samps contents as cell array
%        contents{get(hObject,'Value')} returns selected item from n_samps


% --- Executes during object creation, after setting all properties.
function n_samps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to n_samps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in arm.
function arm_Callback(hObject, eventdata, handles)
% This function arms the Handyscopes according to parameters set in the GUI
% window. A triggered or continuous acquisition mode may be selected, of
% which the maximum acqusition frequency depends on the model of the
% Handyscope and acquisition mode selected.
% hObject    handle to arm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
import LibTiePie.Const.*;   % Import constants
import LibTiePie.Enum.*;    % Import enumeration constants
handles.LibTiePie.DeviceList.update(); % Update device list and check status
handles.dispstr = []; % Clear display
if any(handles.scp.IsRunning==1) 
% Check if scopes are running, trying to arm whilst running will cause a crash
    handles.scp(1).stop();
    set(handles.msg_box,'String','Stopping the TiePie in order to arm it')
end
table = get(handles.uitable1,'Data'); % Getting settings from table
handles.settings.fs = str2double(get(handles.samp_freq,'String')); % Update sampling frequency
handles.settings.nsamp = str2double(get(handles.n_samps,'String')); % Update number of samples per channel
handles.settings.chan_enabled = cell2mat(table(:,1)); % Get channel usage imformation
handles.settings.chan_trig = cell2mat(table(:,2));  % Get trigger settings
handles.settings.chan_range = string(table(:,3));   % Get channel range settings

handles.scp(1).Resolution = handles.res_opts(handles.res_pop.Value); % Set bitness
ratio = handles.ratio(get(handles.trigger_r,'Value')); % Get trigger ratio value
handles.settings.trig_r = ratio; % Store trigger ratio value

if get(handles.cont,'Value')==0 % Is trigger mode selected?
    set(handles.msg_box,'String','Trigger mode selected'); %Tell the user which channel is the trigger
    handles.scp(1).MeasureMode = MM.BLOCK; % Set handyscopes into "Block measurement mode"
elseif get(handles.cont,'Value')==1 % Continuous streaming selected
    set(handles.msg_box,'String','Continuous streaming mode selected'); %Tell the user which channel is the trigger
    handles.scp(1).MeasureMode = MM.STREAM; % Set handyscopes into "Stream" continuous measurement
else
    error('Incorrect mode set')
end
handles.scp(1).SampleFrequency = handles.settings.fs; % Set sample frequency
handles.scp(1).RecordLength = handles.settings.nsamp; % Set number of samples per chunk
if get(handles.cont,'Value')==0 % Check if in triggered mode
    handles.scp.PreSampleRatio = handles.settings.trig_r;% Set trigger ratio
    for ch = 1:length(handles.scp.Channels)
        handles.scp(1).Channels(ch).Trigger.Enabled = false; % Turn all triggers off to clear previous settings
    end
end

for ch = 1:handles.chans
    if logical(handles.settings.chan_enabled(ch))==1 % Check if channel enabled
        handles.scp.Channels(ch).Enabled = logical(handles.settings.chan_enabled(ch)); %Set whether the channel records
        if strcmp(handles.settings.chan_range(ch),'auto')
            handles.scp.Channels(ch).AutoRanging = 1; % Set to autorange
        else
            handles.scp.Channels(ch).Range = double(handles.settings.chan_range(ch)); %Set the voltage range of the individual channel
        end
        handles.scp.Channels(ch).Coupling = CK.DCV; %Set the coupling of the channel, currently no other option specified since nearly all measurments are DC
    else %For disabled channels just disable them
        handles.scp.Channels(ch).Enabled = logical(handles.settings.chan_enabled(ch));
    end
    % Check if channel is selected as a trigger, and that triggered mode is selected
    if logical(handles.settings.chan_trig(ch)) == true && get(handles.cont,'Value')==0 
        set(handles.msg_box,'String',['Trigger set on ' num2str(ch)]); %Tell the user which channel is the trigger
        handles.scp.Channels(ch).Trigger.Enabled = true; %Set the trigger on the current channel
        handles.scp.TriggerTimeOut = -1; % Set the trigger to wait forever
        %Set the trigger type according to the GUI drop-down menu
        if handles.trig_type.Value == 1
            handles.scp(1).Channels(ch).Trigger.Kind = TK.RISINGEDGE; %Set rising edge trigger
        elseif handles.trig_type.Value == 2
            handles.scp(1).Channels(ch).Trigger.Kind = TK.FALLINGEDGE; %Set falling edge trigger
        elseif handles.trig_type.Value == 3
            handles.scp(1).Channels(ch).Trigger.Kind = TK.ANYEDGE; % Set any edge trigger
        end
        handles.scp(1).Channels(ch).Trigger.Levels(1) = str2double(get(handles.trig_t,'String')); %Set the trigger according to the input string
        handles.scp(1).Channels(ch).Trigger.Hystereses(1) = str2double(get(handles.hys,'String')); %Set the trigger hysteresis according to the input string
    end
end
set(handles.msg_box,'String','Oscilloscopes successfully armed'); %Tell the user that the oscilloscopes have been armed
guidata(hObject,handles)


% --- Executes on selection change in trig_type.
function trig_type_Callback(hObject, eventdata, handles)
% hObject    handle to trig_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns trig_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from trig_type


% --- Executes during object creation, after setting all properties.
function trig_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trig_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in trigger_r.
function trigger_r_Callback(hObject, eventdata, handles)
% hObject    handle to trigger_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns trigger_r contents as cell array
%        contents{get(hObject,'Value')} returns selected item from trigger_r


% --- Executes during object creation, after setting all properties.
function trigger_r_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trigger_r (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in acq.
function acq_Callback(hObject, eventdata, handles)
% Contains the acquisition code, of which there are 4 modes, triggered with
% plotting enabled, triggered with plotting disabled, continunous with
% plotting enabled and continuous with plotting disabled. Each case is
% coded independtly to avoid checking each loop individual settings.
% hObject    handle to acq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
import LibTiePie.Const.*;
import LibTiePie.Enum.*;
arm_Callback(hObject, eventdata, handles); % Run the arm callback to apply any changed settings

if get(handles.acq, 'Value')==0 % If acquisition stopped re-enable disabled controls
    set(handles.acq,'String','Start acquisition');
    set(handles.init,'enable','on');
    set(handles.samp_freq,'enable','on');
    set(handles.uitable1,'enable','on');
    set(handles.n_samps,'enable','on');
    set(handles.trig_t,'enable','on');
    set(handles.hys,'enable','on');
    set(handles.autodir,'enable','on');
    set(handles.trigger_r,'enable','on');
     set(hnadles.plot_data,'enable','on');
    return
else % Disable controls during acquisition
    set(handles.init,'enable','off');
    set(handles.samp_freq,'enable','off');
    set(handles.uitable1,'enable','off');
    set(handles.n_samps,'enable','off');
    set(handles.trig_t,'enable','off');
    set(handles.hys,'enable','off');
    set(handles.autodir,'enable','off');
    set(handles.trigger_r,'enable','off');
    set(hnadles.plot_data,'enable','off');
    set(handles.acq,'String','Stop acquisition');
    handles.counter = 0;
    set(handles.sng_shot,'Value',0);
    if get(handles.autodir,'Value')==1
        set(handles.msg_box,'String',['Changing directory, counter at ' num2str(handles.counter)])
        date = datestr(now, 'yyyymmddHHMMss');
        eval(['cd ' handles.parent_dir]);
        mkdir(date);
        handles.dir = [handles.parent_dir '\' date];
        eval(['cd ' handles.dir]);
        set(handles.dir_curr,'String',['dir: ',handles.dir]);
    end
    if handles.scp.IsRunning==0
        handles.scp.start();
        disp('Start')
    elseif any(handles.scp(1).IsRunning==1)
        handles.scp.stop();
        wait(0.1)
        handles.scp.start();
        set(handles.msg_box,'String','Stop Start')
    end
    set(handles.msg_box,'String','Acquisition is starting')
%% Continuous mode acqusition, plotting enabled
    if get(handles.cont,'Value') == 1 && get(handles.plot_data,'Value') == 1
        set(handles.msg_box,'String','Acquisition running')
        while 1
            while ~handles.scp.IsDataReady %Check if data is avaible
                pause(1e-4); % 1 ms delay, to save CPU time, otherwise wait on scopes
            end
            arData = handles.scp(1).getData(); % Get data from the scope
            freq = handles.scp(1).SampleFrequency; % Get actual sampling frequency of data
            handles.counter = handles.counter+1; % Data is available update counter to let the user know
            time1 = datestr(now,'HHMMSS'); % Get time to name individual file
            time2 = datestr(now,'mmmm dd, yyyy HH:MM:SS.FFF'); % Get time accurate to ms from PC
            filename = strcat(num2str(handles.counter),'_',num2str(time1),'.mat'); % Create filename string
            save(filename,'arData','time2','freq'); % Save data to .mat format
            for j = 1:handles.ctot % Plot streamed data
                plot(handles.ax(j),(1:length(arData(:,j))) / handles.scp(1).SampleFrequency,arData(:,j));
                xlabel(handles.ax(j),'Time [s]')
                ylabel(handles.ax(j),'Volts')
                title(handles.ax(j),['Channel ' num2str(j)])
            end
            set(handles.n_trigs,'String',num2str(handles.counter)) % Update counter value
            if get(handles.acq,'Value') == 0 % If acquistion has been stopped break the loop
                break
            end
        end
%% Continuous mode acqusition, plotting disabled
    elseif get(handles.cont,'Value') == 1 && get(handles.plot_data,'Value') == 0
        while 1
            set(handles.msg_box,'String','Acquisition running')
            while ~handles.scp.IsDataReady
                pause(1e-4); % 1 ms delay, to save CPU time
                if get(handles.acq,'Value') == 0
                    set(handles.acq,'enable','off')
                    set(handles.msg_box,'String','Acquisition is stopping')
                end
            end
            handles.counter = handles.counter+1;
            % Get data:
            time1 = datestr(now,'HHMMSS');
            time2 = datestr(now,'mmmm dd, yyyy HH:MM:SS.FFF');
            arData = handles.scp(1).getData();
            freq = handles.scp(1).SampleFrequency;
            filename = strcat(num2str(handles.counter),'_',num2str(time1),'.mat');
            save(filename,'arData','time2','freq');
            set(handles.n_trigs,'String',num2str(handles.counter))
            if get(handles.acq,'Value') == 0
                break
            end
        end
%% Triggered mode acqusition, plotting enabled
    elseif get(handles.cont,'Value') == 0 && get(handles.plot_data,'Value') == 1
        while get(handles.acq, 'Value')==1
            set(handles.sng_shot,'enable','on')
            set(handles.msg_box,'String','Waiting for trigger')
            while ~handles.scp(1).IsDataReady
                pause(1e-4); % 1 ms delay, to save CPU time.
                if get(handles.sng_shot,'Value') == 1
                    set(handles.msg_box,'String','Force triggering')
                    handles.scp(1).forceTrigger();
                    set(handles.sng_shot,'Value',0);
                    set(handles.sng_shot,'enable','off')
                elseif get(handles.acq,'Value') == 0
                    break
                end
            end
            if get(handles.acq,'Value') == 0
                break
            end
            set(handles.msg_box,'String','Triggered')
            handles.counter = handles.counter+1;
            % Get data:
            time1 = datestr(now,'HHMMSS');
            time2 = datestr(now,'mmmm dd, yyyy HH:MM:SS.FFF');
            arData = handles.scp(1).getData();
            freq = handles.scp(1).SampleFrequency;
            handles.scp.start();
            eval(['save ' num2str(handles.counter) '_' num2str(time1) ' arData time2 freq']);
            for j = 1:handles.ctot
                plot(handles.ax(j),(1:length(arData(:,j))) / handles.scp(1).SampleFrequency,arData(:,j));
                xlabel(handles.ax(j),'Time [s]')
                ylabel(handles.ax(j),'Volts')
                title(handles.ax(j),['Channel ' num2str(j)])
            end
            set(handles.n_trigs,'String',num2str(handles.counter))
        end
%% Triggered mode acqusition, no plotting
    elseif get(handles.cont,'Value') == 0 && get(handles.plot_data,'Value') == 0
        while get(handles.acq, 'Value')==1
            set(handles.sng_shot,'enable','on')
            set(handles.msg_box,'String','Waiting for trigger')
            while ~handles.scp(1).IsDataReady
                pause(1e-4); % 1 ms delay, to save CPU time.
                if get(handles.sng_shot,'Value') == 1
                    set(handles.msg_box,'String','Force triggering')
                    handles.scp(1).forceTrigger();
                    set(handles.sng_shot,'Value',0);
                    set(handles.sng_shot,'enable','off')
                elseif get(handles.acq,'Value') == 0
                    break
                end
            end
            if get(handles.acq,'Value') == 0
                break
            end
            set(handles.msg_box,'String','Triggered')
            handles.counter = handles.counter+1;
            % Get data:
            time1 = datestr(now,'HHMMSS');
            time2 = datestr(now,'mmmm dd, yyyy HH:MM:SS.FFF');
            arData = handles.scp(1).getData();
            freq = handles.scp(1).SampleFrequency;
            handles.scp.start();
            eval(['save ' num2str(handles.counter) '_' num2str(time1) ' arData time2 freq']);
            set(handles.n_trigs,'String',num2str(handles.counter))
        end
    end
    set(handles.acq,'enable','on')
end
handles.scp.stop();
set(handles.msg_box,'String','Acquisition stopped');
set(handles.acq,'String','Start acquisition');
set(handles.init,'enable','on');
set(handles.samp_freq,'enable','on');
set(handles.uitable1,'enable','on');
set(handles.n_samps,'enable','on');
set(handles.trig_t,'enable','on');
set(handles.hys,'enable','on');
set(handles.autodir,'enable','on');
set(handles.trigger_r,'enable','on');
guidata(hObject,handles)


function n_trigs_Callback(hObject, eventdata, handles)
% hObject    handle to n_trigs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of n_trigs as text
%        str2double(get(hObject,'String')) returns contents of n_trigs as a double


% --- Executes during object creation, after setting all properties.
function n_trigs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to n_trigs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in rst_ct.
function rst_ct_Callback(hObject, eventdata, handles)
% hObject    handle to rst_ct (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.counter=0;
set(handles.n_trigs,'String',num2str(handles.counter));
guidata(hObject,handles)


% --- Executes on button press in dir_set.
function dir_set_Callback(hObject, eventdata, handles)
% hObject    handle to dir_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.parent_dir = uigetdir();
cd(handles.parent_dir);
guidata(hObject,handles)


% --- Executes on button press in sng_shot.
function sng_shot_Callback(hObject, eventdata, handles)
% Runs a force trigger when scopes are in triggered mode to check
% acqusition runs as expected
% hObject    handle to sng_shot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
import LibTiePie.Const.*;
import LibTiePie.Enum.*;
if handles.acq.Value == 1
    return
elseif handles.cont.Value == 1 % check if in continuous mode and throw error if so
    set(handles.msg_box,'String','Cannot force capture, continuous mode selected');
else
   set(handles.msg_box,'String','Acquiring single shot'); % Start trigger
%     if handles.scp(1).IsRunning==1
%         handles.scp(1).stop();
%     end
%     handles.scp(1).start()
%     pause(1e-5)
%     if get(handles.cont,'Value')==0
%         handles.scp.forceTrigger()
%     end
    %Wait for measurement to complete:
    while ~handles.scp(1).IsDataReady
        pause(1e-4); % 1 ms delay, to save CPU time.
    end
    handles.counter = handles.counter+1;
    set(handles.msg_box,'String','Triggered')
    % Get data:
    arData = handles.scp(1).getData();
    time = datestr(now,'mmmm dd, yyyy HH:MM:SS.FFF');
    freq = handles.scp(1).SampleFrequency;
    eval(['save ' num2str(handles.counter) '_' num2str(time) ' arData time freq']);
    % Get all channel data value ranges (which are compensated for probe gain/offset):
    %     % Plot results:
    for j = 1:handles.ctot
        plot(handles.ax(j),(1:length(arData(:,j))) / handles.scp(1).SampleFrequency,arData(:,j));
        xlabel(handles.ax(j),'Time [s]')
        ylabel(handles.ax(j),'Volts')
        title(handles.ax(j),['Channel ' num2str(j)])
    end
end
set(handles.n_trigs,'String',num2str(handles.counter))
guidata(hObject,handles)



function hys_Callback(hObject, eventdata, handles)
% hObject    handle to hys (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hys as text
%        str2double(get(hObject,'String')) returns contents of hys as a double


% --- Executes during object creation, after setting all properties.
function hys_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hys (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function trig_t_Callback(hObject, eventdata, handles)
% hObject    handle to trig_t (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trig_t as text
%        str2double(get(hObject,'String')) returns contents of trig_t as a double


% --- Executes during object creation, after setting all properties.
function trig_t_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trig_t (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function file_Callback(hObject, eventdata, handles)
% hObject    handle to file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function close_Callback(hObject, eventdata, handles)
% hObject    handle to close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
import LibTiePie.Oscilloscope;
import LibTiePie.Const.*;
import LibTiePie.Enum.*;
import LibTiePie.DeviceList.*;
sn = handles.scp.SerialNumber;
handles.LibTiePie.LastStatus;
%handles.LibTiePie.DeviceList.removeDevice(sn); %Throws an error, not sure
%why
clear handles.scp;

% --- Executes on button press in cont.
function cont_Callback(hObject, eventdata, handles)
% Contiunuous mode check box
% hObject    handle to cont (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.old_uitable = get(handles.uitable1,'Data');
% Hint: get(hObject,'Value') returns toggle state of cont
if get(handles.cont,'Value') == 1
    set(handles.sng_shot,'enable','off')
    handles.uitable1.ColumnEditable = [true false true];
    temp = handles.old_uitable;
    temp(:,2) = {false};
    handles.uitable1.Data = temp;
else
    set(handles.sng_shot,'enable','on')
    handles.uitable1.ColumnEditable = [true true true];
%     set(handles.samp_freq,'String',{50e6,25e6,10e6,5e6,1e6,500e3,400e3,250e3,200e3,150e3,125e3,100e3,75e3,50e3,10e3,1e3,1e2});
end
guidata(hObject,handles);
function autodir_Callback(hObject, eventdata, handles)
% hObject    handle to autodir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autodir


% --- Executes on button press in plot_data.
function plot_data_Callback(hObject, eventdata, handles)
% hObject    handle to plot_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of plot_data


% --- Executes on button press in enab.
function enab_Callback(hObject, eventdata, handles)
% hObject    handle to enab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% set(handles.init,'enable','on');
% set(handles.samp_freq,'enable','on');
% set(handles.uitable1,'enable','on');
% set(handles.n_samps,'enable','on');
% set(handles.trig_t,'enable','on');
% set(handles.hys,'enable','on');
% set(handles.autodir,'enable','on');
% set(handles.trigger_r,'enable','on');
set(handles.acq,'enable','on')
handles.old_uitable = get(handles.uitable1,'Data');
temp = handles.old_uitable;
temp(:,1) = {true};
handles.uitable1.Data = temp;


% --- Executes on selection change in res_pop.
function res_pop_Callback(hObject, eventdata, handles)
% hObject    handle to res_pop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns res_pop contents as cell array
%        contents{get(hObject,'Value')} returns selected item from res_pop


% --- Executes during object creation, after setting all properties.
function res_pop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to res_pop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
