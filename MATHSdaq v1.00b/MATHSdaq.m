function varargout = MATHSdaq(varargin)
% MATHSDAQ MATLAB code for MATHSdaq.fig
%% mathsdaq.m
% This GUI code interfaces with mathsdaq oscilloscopes (Model HS3--> onwards)
% using the LibTiePie SDI plugin. Measurements may be performed in a
% continuous mode or a triggered mode according to typical oscilloscope
% parameters e.g. falling edge, rising edge or threshold.
%
% Coded J. Bedford (U of Liverpool), D. Faulkner (U of Liverpool) & 
% C. Harbord (INGV, Roma)
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

% Last Modified by GUIDE v2.5 23-Nov-2019 23:57:17

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
cdir = pwd();
eval(['addpath ' cdir])
handles.output = hObject;
h = msgbox('Building LibTiePie');
handles.LibTiePie = LibTiePie.Library;
i = msgbox(['Status of library initialisation: ' handles.LibTiePie.LastStatusStr ', click OK to continue']);
if ishandle(h)
    close(h)
end
while ishandle(i)
    pause(0.01)
end
handles.counter = 0;
end
guidata(hObject, handles);


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
function init_Callback(hObject, eventdata, handles)
% hObject    handle to init (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
import LibTiePie.Const.*;
import LibTiePie.Enum.*;
sel = questdlg('Search for Handyscopes?','Connecting to instruments','OK','Cancel','Cancel');
if strcmp(sel,'Cancel')
    return
else
    [handles.scp,handles.SN,handles.sn_c,handles.nscp] = get_scp(handles.LibTiePie);
    if handles.scp == -1
        set(handles.msg_box,'String','No oscilloscopes found, if you are experiencing difficulties try turning it on and off again...');
    else
        handles.chans = length(handles.scp.Channels);
        for i = 1:handles.chans
     
        end
        handles.res = handles.scp.Resolutions;
        headers = [];
        dat={};
        serial = [];
        for i = 1:length(handles.SN)
            serial = [serial; ['Osc' num2str(i) ' SN: ' num2str(handles.SN(i))]];
        end
        set(handles.serials,'String',serial);
        for j = 1:handles.chans
            dat = [dat; {false  false 'set'}];
            headers = [headers; {num2str(j)}];
            handles.AR = handles.scp.Channels(j).AutoRanging;
        end
        handles.ctot = sum(handles.chans);
        i1 = 4;
        i2 = ceil(handles.ctot/4);
        for i = 1:handles.ctot
            handles.ax(i)=subplot(i1,i2,i,'Parent',handles.uipanel1);
            handles.line(i)=plot(handles.ax(i),rand(10,1));
            xlabel(handles.ax(i),'Time [s]')
            ylabel(handles.ax(i),'Volts')
            title(handles.ax(i),['Channel ' num2str(i)])
        end
        
        handles.v_range = {'0.2','0.4','0.8','2','4','8','20','40','80'};
        handles.f_range = {50e6,25e6,10e6,5e6,1e6,500e3,400e3,250e3,200e3,150e3,125e3,100e3,75e3,50e3,10e3,1e3,1e2,10};
        handles.nsamps = {128e3,64e3,32e3,16e3,8e3,4e3,2e3,1e3,1e2,10};
        handles.uitable1.ColumnEditable = [true true true];
        handles.uitable1.ColumnName = {'Use?','Trigger?','Scale'};
        handles.uitable1.RowName = cellstr(headers);
        handles.uitable1.Data = dat;
        handles.uitable1.ColumnFormat(3) = {handles.v_range};
        handles.samp_freq.String = handles.f_range;
        handles.n_samps.String = handles.nsamps;
        handles.ratio = 0:0.05:1;
        handles.trigger_r.String = cellstr(num2str(handles.ratio'));
        handles.trig_type.String = {'Rising edge','Falling edge','Threshold'};
    end
end
guidata(hObject,handles);


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
import LibTiePie.Const.*;
import LibTiePie.Enum.*;
handles.LibTiePie.DeviceList.update();
handles.dispstr = [];
if any(handles.scp.IsRunning==1)
    handles.scp(1).stop();
    set(handles.msg_box,'String','Stopping the TiePie in order to arm it')
end
table = get(handles.uitable1,'Data');
if get(handles.cont,'Value') == 0
    fss ={50e6,25e6,10e6,5e6,1e6,500e3,400e3,250e3,200e3,150e3,125e3,100e3,75e3,50e3,10e3,1e3,1e2,10,1};
    handles.settings.fs = cell2mat(fss(get(handles.samp_freq,'Value')));
    clear fss
elseif get(handles.cont,'Value') == 1
    fss ={400e3,250e3,200e3,150e3,125e3,100e3,75e3,50e3,10e3,1e3,1e2};
    handles.settings.fs = cell2mat(fss(get(handles.samp_freq,'Value')));
    clear fss
end
nsmp = {128e3,64e3,32e3,16e3,8e3,4e3,2e3,1e3,100,10,1};
handles.settings.nsamp = cell2mat(nsmp(get(handles.n_samps,'Value')));
handles.settings.chan_enabled = cell2mat(table(:,1));
handles.settings.chan_trig = cell2mat(table(:,2));
handles.settings.chan_range = string(table(:,3));

ratio = handles.ratio(get(handles.trigger_r,'Value'));
handles.settings.trig_r = ratio;

if get(handles.cont,'Value')==0
     set(handles.msg_box,'String','Trigger mode selected'); %Tell the user which channel is the trigger
    handles.scp(1).MeasureMode = MM.BLOCK;
elseif get(handles.cont,'Value')==1
    set(handles.msg_box,'String','Continuous streaming mode selected'); %Tell the user which channel is the trigger
    handles.scp(1).MeasureMode = MM.STREAM;
else
    error('Incorrect mode set')
end
handles.scp(1).SampleFrequency = handles.settings.fs; % 1 MHz
handles.scp(1).RecordLength = handles.settings.nsamp; % 10000 Samples
if get(handles.cont,'Value')==0
    handles.scp.PreSampleRatio = handles.settings.trig_r;% handles.settings.trig_r; % 0 %
    for ch = 1:length(handles.scp.Channels)
        handles.scp(1).Channels(ch).Trigger.Enabled = false;
    end
end

for ch = 1:handles.chans
    if logical(handles.settings.chan_enabled(ch))==1
        handles.scp.Channels(ch).Enabled = logical(handles.settings.chan_enabled(ch)); %Set whether the channel records
        if strcmp(handles.settings.chan_range(ch),'auto')
            handles.scp.Channels(ch).AutoRanging = 1;
        else
            handles.scp.Channels(ch).Range = double(handles.settings.chan_range(ch)); %Set the voltage range of the individual channel
        end
        handles.scp.Channels(ch).Coupling = CK.DCV; %Set the coupling of the channel
    else %For disabled channels just disable them
        handles.scp.Channels(ch).Enabled = logical(handles.settings.chan_enabled(ch)); 
    end
    if logical(handles.settings.chan_trig(ch)) == true && get(handles.cont,'Value')==0
        %handles.dispstr = [handles.dispstr; []];
        set(handles.msg_box,'String',['Trigger set on ' num2str(ch)]); %Tell the user which channel is the trigger
        handles.scp.Channels(ch).Trigger.Enabled = true; %Set the trigger on the current channel
        handles.scp.TriggerTimeOut = -1; % Set the trigger to wait forever
        %Set the trigger type according to the GUI drop-down menu
        if handles.trig_type.Value == 1
            handles.scp(1).Channels(ch).Trigger.Kind = TK.RISINGEDGE; %Set rising edge trigger
        elseif handles.trig_type.Value == 2
            handles.scp(1).Channels(ch).Trigger.Kind = TK.FALLINGEDGE; %Set falling edge trigger
        elseif handles.trig_type.Value == 3
            handles.scp(1).Channels(ch).Trigger.Kind = TK.ANYEDGE;
        end
        handles.scp(1).Channels(ch).Trigger.Levels(1) = str2double(get(handles.trig_t,'String')); %Set the trigger according to the input string
        handles.scp(1).Channels(ch).Trigger.Hystereses(1) = str2double(get(handles.hys,'String')); %Set the trigger hysteresis according to the input string
    end
end
%handles.dispstr = [handles.dispstr; ];
set(handles.msg_box,'String','Oscilloscopes successfully armed'); %Tell the user which channel is the trigger
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
% hObject    handle to acq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
import LibTiePie.Const.*;
import LibTiePie.Enum.*;
if get(handles.acq, 'Value')==0
    set(handles.acq,'String','Start acquisition');
    set(handles.init,'enable','on');
    set(handles.samp_freq,'enable','on');
    set(handles.uitable1,'enable','on');
    set(handles.n_samps,'enable','on');
    set(handles.trig_t,'enable','on');
    set(handles.hys,'enable','on');
    set(handles.autodir,'enable','on');
    set(handles.trigger_r,'enable','on');
    return
else
    set(handles.init,'enable','off');
    set(handles.samp_freq,'enable','off');
    set(handles.uitable1,'enable','off');
    set(handles.n_samps,'enable','off');
    set(handles.trig_t,'enable','off');
    set(handles.hys,'enable','off');
    set(handles.autodir,'enable','off');
    set(handles.trigger_r,'enable','off');
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
        handles.scp.start();
        set(handles.msg_box,'String','Stop Start')
    end
    set(handles.msg_box,'String','Acquisition is starting')
%% Continuous mode acqusition, plotting enabled
    if get(handles.cont,'Value') == 1 && get(handles.plot_data,'Value') == 1
        while get(handles.acq, 'Value')==1
            while ~handles.scp.IsDataReady
                pause(1e-4); % 1 ms delay, to save CPU time
                if get(handles.acq,'Value') == 0 
                    break    
                end
            end
            if get(handles.acq,'Value') == 0 
                break
            end
            handles.counter = handles.counter+1;
            % Get data:
            time = datestr(now,'HHmmss');
            arData = handles.scp(1).getData();
            freq = handles.scp(1).SampleFrequency;
            eval(['save ' num2str(handles.counter) '_' num2str(time) ' arData time freq']);
            for j = 1:handles.ctot
                plot(handles.ax(j),(1:length(arData(:,j))) / handles.scp(1).SampleFrequency,arData(:,j));
                xlabel(handles.ax(j),'Time [s]')
                ylabel(handles.ax(j),'Volts')
                title(handles.ax(j),['Channel ' num2str(j)])
            end
            set(handles.n_trigs,'String',num2str(handles.counter))
        end
%% Continuous mode acqusition, plotting disabled
    elseif get(handles.cont,'Value') == 1 && get(handles.plot_data,'Value') == 0
        while get(handles.acq, 'Value')==1
            while ~handles.scp.IsDataReady
                pause(1e-4); % 1 ms delay, to save CPU time
                if get(handles.acq,'Value') == 0 
                    break
                end
            end
            if get(handles.acq,'Value') == 0 
                break
            end
            handles.counter = handles.counter+1;
            % Get data:
            time = datestr(now,'HHmmss');
            arData = handles.scp(1).getData();
            freq = handles.scp(1).SampleFrequency;
            eval(['save ' num2str(handles.counter) '_' num2str(time) ' arData time freq']);
            set(handles.n_trigs,'String',num2str(handles.counter))
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
            time = datestr(now,'HHmmss');
            arData = handles.scp(1).getData();
            freq = handles.scp(1).SampleFrequency;
            handles.scp.start();
            eval(['save ' num2str(handles.counter) '_' num2str(time) ' arData time freq']);
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
            time = datestr(now,'HHmmss');
            arData = handles.scp(1).getData();
            freq = handles.scp(1).SampleFrequency;
            handles.scp.start();
            eval(['save ' num2str(handles.counter) '_' num2str(time) ' arData time freq']);
            set(handles.n_trigs,'String',num2str(handles.counter))
        end
    end
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
eval(['cd ' handles.parent_dir]);
guidata(hObject,handles)


% --- Executes on button press in sng_shot.
function sng_shot_Callback(hObject, eventdata, handles)
% hObject    handle to sng_shot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
import LibTiePie.Const.*;
import LibTiePie.Enum.*;
if handles.acq.Value == 1
    return
elseif handles.cont.Value == 1
    set(handles.msg_box,'String','Cannot force capture, continuous mode selected');
else
   set(handles.msg_box,'String','Acquiring single shot');
    if handles.scp(1).IsRunning==1
        handles.scp(1).stop();
    end
    handles.scp(1).start()
    pause(1e-5)
    if get(handles.cont,'Value')==0
        handles.scp.forceTrigger()
    end
    %Wait for measurement to complete:
    while ~handles.scp(1).IsDataReady
        pause(1e-4); % 1 ms delay, to save CPU time.
    end
    handles.counter = handles.counter+1;
    set(handles.msg_box,'String','Triggered')
    % Get data:
    arData = handles.scp(1).getData();
    time = datestr(now,'HHmmss');
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
    set(handles.samp_freq,'String',{400e3,250e3,200e3,150e3,125e3,100e3,75e3,50e3,10e3,1e3,1e2});
else
    set(handles.sng_shot,'enable','on')
    handles.uitable1.ColumnEditable = [true true true];
    set(handles.samp_freq,'String',{50e6,25e6,10e6,5e6,1e6,500e3,400e3,250e3,200e3,150e3,125e3,100e3,75e3,50e3,10e3,1e3,1e2});
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
set(handles.init,'enable','on');
set(handles.samp_freq,'enable','on');
set(handles.uitable1,'enable','on');
set(handles.n_samps,'enable','on');
set(handles.trig_t,'enable','on');
set(handles.hys,'enable','on');
set(handles.autodir,'enable','on');
set(handles.trigger_r,'enable','on');
