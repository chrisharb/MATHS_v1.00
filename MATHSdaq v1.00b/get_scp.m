function [scope,sn,sn_c,nscp,msg] = get_scp(library)

import LibTiePie.Const.* %Import LibTiePie constants library
import LibTiePie.Enum.* %Import LibTiePie enumeration library
library.DeviceList.update() %Update the Device list
library.DeviceList;
import LibTiePie.Oscilloscope; %Import the LibTiePie Oscilloscope library for creation of a blank instrument
scps = Oscilloscope.empty; %Create an empty Oscilloscope
sn = [];
if library.DeviceList.Count == 0 %Check if MATLAB detected any devices
    scope = -1;
    sn = -1;
    sn_c = -1;
    nscp = -1;
    msg = -1;
elseif ismac %If computer runs Apple IOS this code will not work :-(
    scope = -1;
    sn = -1;
    nscp = -1;
    sn_c = -1;
    msg = -1;
elseif library.DeviceList.Count == 1
    scope = scps;
    sn_c = scope.SerialNumber;
    clear scps;
    msg=['I found ' num2str(length(scope.Channels)) ' available channels which is a standalone instrument'];
else %Run the code to import the instruments
    nscp = library.DeviceList.Count;
    for k = 0:library.DeviceList.Count - 1
        item = library.DeviceList.getItemByIndex(k);
        if item.ProductId == 0
            disp('Invalid device connected')
            break
        elseif item.ProductId == 13 %HS3
            scps(end+1) = item.openOscilloscope();
            sn(end+1) = item.SerialNumber;
        elseif item.ProductId == 15 %HS4
            scps(end+1) = item.openOscilloscope();
            sn(end+1) = item.SerialNumber;
        elseif item.ProductId == 20 %HS4d
            scps(end+1) = item.openOscilloscope();
            sn(end+1) = item.SerialNumber;
        else 
            for j = 0:library.DeviceList.Count-2
                item = library.DeviceList.getItemByIndex(j);
                sn(end+1) = item.SerialNumber;
            end
            item = library.DeviceList.getItemByIndex(library.DeviceList.Count-1);
            scope = item.openOscilloscope();
            sn_c = scope.SerialNumber;
            msg=['I found ' num2str(length(scope.Channels)) ' available channels across ' num2str(nscp-1) ' oscilloscopes, which are now combined.'];
            break
        end
    end
    clear item
    if length(scps) > 1
        %disp('Attempting to combine instruments together');
        scope = library.DeviceList.createAndOpenCombinedDevice(scps);
        sn_c = scope.SerialNumber;
        % Remove HS3/HS4(D) objects, not required anymore:
        clear scps;
        msg=['I found ' num2str(length(scope.Channels)) ' available channels across ' num2str(nscp) ' oscilloscopes, which are now combined.'];
    else
    end
end
clear item
