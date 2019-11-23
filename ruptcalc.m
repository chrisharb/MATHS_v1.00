%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ruptcalc.m %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate best fit rupture velocities from arrival times at strain gauges
%or piezos during stick-slip experiments after Passelegue et al. 2016 JGR
% CODED BY C.HARBORD @HPHT, Roma/RML Durham cwaharbord@gmail.com
function [Vrct,trc,x_loc,y_loc,Vr_op,tr_op]=ruptcalc(xpos,ypos,at,W,L)
%% Initialise model
Xdist = W/2;
Ydist = L/2;
dx = W/25;            %Grid spacing
X = -Xdist:dx:Xdist;    %Generate X coordinates
Y = -Ydist:dx:Ydist;    %Generate Y coordinates
minvr = 100;           %Minimum rupture velocity to start search
maxvr = 6000;           %Maximum theoretical Mode II rupture velocity 
                        %(normally P-wave velocity)
Cs = 3500;              %Shear wave speed
dvr = 10;               %Spacing of velocity search
vr = (minvr:dvr:maxvr); %Generate array of rupture velocities
nx = numel(X);          
ny = numel(Y);
nr = numel(vr);
Xg = xpos;
Yg = ypos;
ng = numel(Xg);
atcomp=at;
ttmax = sqrt((2*Xdist)^2+(2*Ydist)^2)/minvr;
t0max = min(atcomp);
t0min = ttmax - t0max;
nc = 100;
t0 = t0min:(t0max-t0min)/nc:t0max;

tr = zeros(nr*nx*ny,1);         %Initialise storage variables
Xnr = tr;
Ynr = tr;
Vrc = tr;
trc = zeros(nr,1);              %Initialise residual variables
Vrct = trc;
Xnrc = trc;
Ynrc = trc;

%% Start searching algorithm
hh = waitbar(0,'Inverting for rupture velocity');
for j = 1:nr
    waitbar(j/nr,hh);
    Xnrtemp = zeros(nx*ny,1);   %Re-initialise these variables every loop
    Ynrtemp = Xnrtemp;
    trtemp = Xnrtemp;
    Vr = vr(j);
    
    if Vr < Cs
        VIII = vr(j);   %Circular rupture if velocity is not supershear
    else
        VIII = Cs;    %Elliptical rupture if velocity supershear (VIII is limited to Cs)
    end
    
    for i = 1:nx
        Xn =  X(i);
        for k = 1:ny
            Yn =  Y(k);
            d = sqrt((Xn-Xg).^2+(Yn-Yg).^2); %Calculate array of distances
            theta = sinh((Yg-Yn)./d); % Angle calcs
            Vr_a = sqrt(VIII^2*cos(theta).^2+Vr^2*sin(theta).^2); %Apparent rupture velocities
            dt = d./Vr_a;%Theoretical travel times
            t_temp=zeros(numel(t0),1);
            for ooo = 1:numel(t0) %Time residual for current location
                t_te=0;
                for l = 1:ng
                    t_te = abs(at(l)-dt(l)-t0(ooo))+t_te;
                end
                t_temp(ooo)=sqrt(t_te^(2/ng));
            end
            [~,itemp] = min(t_temp);
            t0i(j*i*k) = t0(itemp);
            tr(j*i*k) = t_temp(itemp);
            %Store information about location and velocity
            Xnr(j*i*k) = Xn;
            Ynr(j*i*k) = Yn;
            Vrc(j*i*k) = Vr;
            
            %Create temporary variables to store results of current
            % trial velocity
            Xnrtemp(i*k) = Xnr(j*i*k);
            Ynrtemp(i*k) = Ynr(j*i*k);
            trtemp(i*k) = tr(j*i*k);     
        end
    end
    
    %Find minimum time residual and corresponding position and store this
    %information
    [kk] = find(trtemp==0);
    trtemp(kk) = [];
    Xnrtemp(kk) = [];
    Ynrtemp(kk) = [];
    [~,jj] = min(trtemp);
    trc(j) = trtemp(jj);
    Vrct(j) = vr(j);
    Xnrc(j) = Xnrtemp(jj);
    Ynrc(j) = Ynrtemp(jj);
    
end
close(hh)
% [trmin_t,minn] = min(trc);
% trmin(ooo) = trmin_t;
% end

%% Plot some results and output some information

[~,minn] = min(trc);
disp(['Mininum residual time: ', num2str(trc(minn).*1e6), ' microseconds'])
disp(['Optimum rupture velocity:', num2str(Vrct(minn)), ' m/s'])
disp(['Location x = ', num2str(Xnrc(minn)), ' m, y = ', num2str(Ynrc(minn)), ' m'])
Vr_op = Vrct(minn);
tr_op = trc(minn);
x_loc = Xnrc(minn);
y_loc = Ynrc(minn);
figure(2)
plot(Vrct,trc*1e6)
hold on
x=[Vrct(minn),Vrct(minn)];
y=[trc(minn),max(trc)];
plot(x,y)
xlabel('Rupture velocity [m s^{-1}]')
ylabel('Time residual [\mus]')
hold off
% plot(trmin)               
        
        
        
