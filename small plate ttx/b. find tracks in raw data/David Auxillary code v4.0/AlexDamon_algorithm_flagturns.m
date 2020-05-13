function tracks = AlexDamon_algorithm_flagturns(tr)
% THIS IS THE ONE TO USE TO FLAG THE TURNS AND TRACKS
%the goal here is to assemble the structure tracks, which for each worm
%includes information about the angle they were going at every point, the
%indexes at which they turned, the index where they began their tracks,
%etc.
global FPS; 

tracks=tr;

AD_minlen = 10; %%% minimum length for calculating local angle (10pxl~2mm)
AD_moveby = 3;  %%% minimal distance in pixels the worm moved when
                %%% calculating angle for scoring a turn (3 pixels)
AD_N = 10/FPS;  %%% (5 frames, probably set for 2 FPS - has to be larger than AD_maxframes)
AD_maxframes = 6/FPS; %%% maximum no. of frames for calculating local angle (3 frames, probably set for 2 FPS)
AD_angforturn = pi/4; %%% minimal change of angle that cunts as turn 
                      %%% (ORIGINALLY SET TO pi/4 radians !)
AD_MinframesBetweenTurns = 1; %5/FPS; %%% (ORIGINALLY SET TO 1 !)

%%% initialize all foelds (most not used) %%%
for i = 1:length(tracks)
    t = tr(i).f/FPS;
    t = t'; 
	tracks(i).t = t;
    
    tracks(i).seg_indx = [];
    tracks(i).seg_ang = [];
	tracks(i).seg_num = 0; 
	tracks(i).seg_dx = []; 
	tracks(i).seg_dy = [];
	tracks(i).seg_dist = [];
	tracks(i).seg_dur = [];
	
	tracks(i).run_duration = [];
	tracks(i).run_time = [];
	tracks(i).run_dx = [];
	tracks(i).run_dy = [];
	tracks(i).run_dist = []; % dist end2end (straight line)
    tracks(i).run_Int_along_path = []; % dist along path
	tracks(i).curved = [];
	tracks(i).run_angle = [];
	tracks(i).run_indx = [];
    tracks(i).run_num = 0; % important to initialize
    tracks(i).turn_indx = [];
    
	tracks(i).IT_duration = [];
	tracks(i).IT_time =[];
	tracks(i).IT_dx = [];
	tracks(i).IT_dy = [];
	tracks(i).IT_dist = [];
	tracks(i).IT_end2end_dist = [];
	tracks(i).IT_angle = [];
	tracks(i).IT_indx = [];
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% Change names of fields: 
%%% .rundir --> .run_angle
%%% .runlen --> .run_duration
%%% .turn   --> .turn_indx
%%% .track  --> for scoring ITs - ignored here
c_runs = 0;
for i = 1:length(tracks) %for each worm
    x=tracks(i).x;
    y=tracks(i).y;
    f=tracks(i).f;
    dist=[0; cumsum(sqrt(diff(x).^2+diff(y).^2))];
    Ntot = length(tracks(i).x);
    
    %firsttime=1;
    
    tracks(i).run_angle = [];
    tracks(i).run_duration = [];
    tracks(i).ang = zeros(Ntot,1); % local angle
    tracks(i).turn_indx = [];
    tracks(i).track = []; %%% used for storing IT information - not used here
        
    tempturn=[];
    tempang=[];
    realturn=[];
    for j=AD_N:Ntot+1-AD_N %going through each point on the worm's path       
        %%% move away from current point (forward and backward) on track by: 
        %%% at least 2 frames, BUT
        %%% no more than AD_maxframes frames
        %%% and no more than AD_minlen pixels (AD_minlen is actually a max..)
        %%% Stay in range because AD_N>AD_maxframe
        m=1;
        %while ((x(j-m)-x(j))^2+(y(j-m)-y(j))^2<AD_minlen^2 & f(j)-f(j-m)<AD_maxframes & j-m>1)
        while (dist(j)-dist(j-m)<AD_minlen & f(j)-f(j-m)<AD_maxframes & j-m>1)
            m=m+1;
        end
        n=1;
        %while ((x(j+n)-x(j))^2+(y(j+n)-y(j))^2<AD_minlen^2 & f(j+n)-f(j)<AD_maxframes & j+n<Ntot)
        while (dist(j+n)-dist(j)<AD_minlen & f(j+n)-f(j)<AD_maxframes & j+n<Ntot)
            n=n+1;
        end
               
        x2=x(j-m)-x(j); % the point before current, from which angle is determined
        y2=y(j-m)-y(j); % the point before current, from which angle is determined
        x1=x(j+n)-x(j); % the point after current, from which angle is determined
        y1=y(j+n)-y(j); % the point after current, from which angle is determined
        
        tracks(i).xdot(j)=(x(j-m)-x(j))/(f(j-m)-f(j)); % local x-velocity [pixels/frame]
        tracks(i).ydot(j)=(y(j-m)-y(j))/(f(j-m)-f(j)); % local y-velocity [pixels/frame]
        
        tracks(i).ang(j)=angle(-x2-y2*sqrt(-1)); % angle is calculated from current point backward
                                                 % .ang is the angle the worm "came from"
        tracks(i).dang(j)=sqrt(x2^2+y2^2);  % dang = distance used to calculate angle (backwards vector)
        if tracks(i).dang(j)==0 % worm did not advance during the frames used to calculate backwards vector
            tracks(i).ang(j)=tracks(i).ang(j-1); % angle remains same as previous
        end;
        tracks(i).angdot(j)=(tracks(i).ang(j-m)-tracks(i).ang(j))/(f(j-m)-f(j)); % angular velocity also calculated from previous angle
        if tracks(i).dang(j)==0 % no turn if worms didn't advance
            turnang=0;  % one of the vectors is of zero length, but they're not at 90 degrees!
        else % calculate turn angle
            turnang=acos((x1*x2+y1*y2)/(sqrt((x1^2+y1^2)*(x2^2+y2^2))));  % dot product
        end;
        
        % damon change
        if pi-turnang>AD_angforturn & abs(x1)+abs(x2)+abs(y1)+abs(y2)>AD_moveby
            tempturn=[tempturn, j];
            tempang=[tempang, pi-turnang];
        end;
    end; % j=AD_N:Ntot+1-AD_N - going through each point on the worm's path
    %%%%%%%%%% find best turns in here... DAMON ADD
    d=diff(tempturn);  % intervals between indices of turns
    f1=find(d>AD_MinframesBetweenTurns); % these delimit the indices of turns
    for k= 1:length(f1)
        if k==1
            f2=find(tempang==max(tempang(1:f1(k))));
            f2 = f2(f2<=f1(k));
            realturn(k)=tempturn(f2(1));
        elseif k==length(f1)
            f2=find(tempang==max(tempang((f1(k)+1):length(tempturn))));
            f2 = f2(f2>=(f1(k)+1));
            realturn(k)=tempturn(f2(1));
        else
            f2=find(tempang==max(tempang((f1(k)+1):f1(k+1))));
            f2 = f2(f2>=(f1(k)+1) & f2<=f1(k+1));
            realturn(k)=tempturn(f2(1));
        end;
    end; % k= 1:length(f1)

    for k=1:length(realturn)-1
        tracks(i).turn_indx=[tracks(i).turn_indx; realturn(k)];
        if max(realturn)>length(f)
            keyboard;
        end;
        tracks(i).run_duration=[tracks(i).run_duration; f(realturn(k+1))-f(realturn(k))];  % okay
        
        %%% Added by david: update fields containing runs and turns information %%%
        tracks(i).run_indx(k,1) = realturn(k);    % index where k-th run starts
        tracks(i).run_indx(k,2) = realturn(k+1);  % index where k-th run ends
        %tracks(i).run_num = tracks(i).run_num+1;  % total number of runs 
        tracks(i).turn_indx(k,1) = realturn(k); % index of k-th turn (column vector)
        if k==(length(realturn)-1) % record last turn
            tracks(i).turn_indx(k+1,1) = realturn(k+1); % (column vector)
        end;
        %tracks(i).run_time(k,1) = tracks(i).run_duration(k)/FPS; % duration of run in seconds
        %dx = x(realturn(k+1))-x(realturn(k));
        %dy = y(realturn(k+1))-y(realturn(k));
        %tracks(i).run_dx(k,1) = dx; % (column vector)
        %tracks(i).run_dy(k,1) = dy; % (column vector)
        %tracks(i).run_dist(k,1) = sqrt(dx^2-dy^2); % (column vector)
        %tracks(i).run_Int_along_path(k,1) = dist(realturn(k+1))-dist(realturn(k)); % (column vector) 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
        %%%%%%%%%%% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! %%%%%%%%%%%
        %%% ORIGINAL: %%%
        %tracks(i).run_angle = [tracks(i).run_angle; mean(tracks(i).ang(realturn(k):realturn(k+1)))]; % damon original
        %%% REPLACED BY %%%
        %tracks(i).run_angle = [tracks(i).run_angle; angle(dx+dy*sqrt(-1))]; % David
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
    end; % k=1:length(realturn)-1
    
	%%%%%%%%%%%%%% Clean out short runs %%%%%%%%%%%%%%%
	%%% Code copied from AlexDamon_runlengthanal2.m %%%        
	if length(tracks(i).turn_indx)>=2
        t=tracks(i).turn_indx;
        dist=[0;cumsum(sqrt(diff(tracks(i).x).^2+diff(tracks(i).y).^2))];
        dx=tracks(i).x(t(2:end))-tracks(i).x(t(1:end-1));
        dy=tracks(i).y(t(2:end))-tracks(i).y(t(1:end-1));
        dt=tracks(i).f(t(2:end))-tracks(i).f(t(1:end-1))/FPS; % David: convert units to seconds
        angi=angle(dx+sqrt(-1)*dy);
        leni=sqrt(dx.^2+dy.^2); % pixels - linear
        lensi=dist(t(2:end))-dist(t(1:end-1)); % pixels along contour
        dur=dt; % time (seconds) between consecutive turns
        len=leni; % linear distance between consecutive turns
        lens=lensi; % distance on contour (pixels) between consecutive turns
        ang=angi; % verage angle (radians) between consecutive turns
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% save curved tracks %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        crv_ind = find(dur>5 & lens>2 & len>4 & pi*len/2<=lens); % curved tracks
        c_runs = c_runs+length(crv_ind);
        tracks(i).c_turn_indx = tracks(i).turn_indx(crv_ind);
        tracks(i).c_run_duration = dur(crv_ind);
        tracks(i).c_run_indx = tracks(i).run_indx(crv_ind,:); % two columns..    
        tracks(i).c_run_num = length(crv_ind); 
        tracks(i).c_run_time = dur(crv_ind) / FPS; 
        tracks(i).c_run_dx = dx(crv_ind);
        tracks(i).c_run_dy = dy(crv_ind);
        tracks(i).c_run_dist = len(crv_ind); % linear dist
        tracks(i).c_run_Int_along_path = lens(crv_ind); % Integral along path
        tracks(i).c_run_angle = ang(crv_ind); 
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%% original Alex code for 0.5 FPS:
        %%% chooseall=find(dur>2 & lens>2 & len>4 & pi*len/2>lens); % 3+frames
        chooseall=find(dur>=6*FPS & lens>2 & len>4 & pi*len/2>lens);  % frames equivalent to 6+ seconds
        
        %%% Update fields containing runs and turns information %%%
        tracks(i).turn_indx = tracks(i).turn_indx(chooseall);
        tracks(i).run_duration = dur(chooseall);
        tracks(i).run_indx = tracks(i).run_indx(chooseall,:); % two columns..    
        tracks(i).run_num = length(dur(chooseall));  
        tracks(i).run_time = dur(chooseall)/FPS; 
        tracks(i).run_dx = dx(chooseall);
        tracks(i).run_dy = dy(chooseall);
        tracks(i).run_dist = len(chooseall); % linear
        tracks(i).run_Int_along_path = lens(chooseall); % Path
        tracks(i).curved = zeros(size(chooseall));    
        tracks(i).run_angle = ang(chooseall); 
	end; % if length(tr(i).turn_indx)>=2
    tracks(i).curved = ((pi/2 * tracks(i).run_dist) <= tracks(i).run_Int_along_path); % column vector, Alex/Damon criteria for curved run
    
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
end; % i=1:length(tr) %for each worm

N = 0;
D = [];
L = [];
for i=1:length(tracks)
    N = N+tracks(i).c_run_num;
    D = [D; tracks(i).c_run_duration];
    L = [L; tracks(i).c_run_Int_along_path];
end;
str = '# of CURVED runs: ';
str = [str num2str(N)];
disp(str);
length(D)
c_runs
str = 'average durationh of CURVED runs: ';
str = [str num2str(mean(D))];
disp(str);
str = 'average length of CURVED runs: ';
str = [str num2str(mean(L))];
disp(str);

