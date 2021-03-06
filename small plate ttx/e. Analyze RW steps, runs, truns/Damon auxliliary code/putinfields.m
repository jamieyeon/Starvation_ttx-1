function out=putinfields(in, clean, plate_id, cal_data, tot_time, varargin)

% puts output of track.m into a field format for easier analysis
%
% Arguments: 
% ----------
% in: output from track - [x y frame particle-id] sorted by particle id-s
% clean: boolean - if true then clean data of large gaps, short tracks etc
% plate_id: a number plate identifier for future reference
% MOVEBY (optional): minimal number of pixels moved in either x or y
%                    direction in a "legal" track (units - pixels)  
%
% Parameters:
% -----------
% TOOSHORT: minimal number of frames in "legal" track
% MAXGAP: if a particle track has a gap larger that MAXGAP frames then 
%         split it into two independent particles (units - frames)
%
% Output:
% -------
% out = an array of structures, 
% each structure corresponding to a single particle track. 
% The array is sorted by the lengths of the tracks, 
% from long to short.  
% Fields: out(i).x = x coordinates in pixels for track of particle i
%         out(i).y = y coordinates in pixels for track of particle i
%         out(i).f = corresponding frame numbers for track of particle i 
%         out(i).num = total number of frames in track of particle i
%         out(i).plate_id = number plate identifier for the plate of origin of particle i
%         out(i).min_edge = pixel value of edge with minimal Temperature
%         out(i).max_edge = pixel value of edge with maximal Temperature
%         out(i).min_T = Temperature at edge with minimal Temperature
%         out(i).max_T = Temperature at edge with maximal Temperature
%         out(i).total_time = total imaging time in seconds
%
% TOOSHORT=5; % minimal number of frames in "legal" track
% MAXGAP=1; % max frame gap allowed in single particle track 
%           % (more than that gets split to two tracks)
% DEFAULT_MOVEBY = 5; % min movement in pixels by worm in either x- or 
%                     % y-direction in single track 
%                     % (less is considered noise / dead worm)

global TOOSHORT
global MAXGAP
global DEFAULT_MOVEBY

if nargin>5
    MOVEBY = varargin{1};
else
    MOVEBY = DEFAULT_MOVEBY;
end

[u dum locs]=unique(in(:,4)); % in(:,4) = particle id-s
                              % u = unique particle id-s
                              % dum = index such that u=in(dum,4)
                              % locs = index such that in(:,4)=u(locs)
for i=1:length(u) % transfer in array to out structure for each particle (i)
    choose=find(locs==i);
    out(i).x=in(choose,1);
    out(i).y=in(choose,2);
    out(i).f=in(choose,3);
    out(i).num=length(choose);  % number of frames for particle i
    out(i).plate_id = plate_id; % number plate identifier for the plate of origin of particle i
    out(i).min_edge = cal_data(1); % pixel value of edge with minimal Temperature
    out(i).max_edge = cal_data(2); % pixel value of edge with maximal Temperature
    out(i).min_T = cal_data(3);    % Temperature at edge with minimal Temperature
    out(i).max_T = cal_data(4);    % Temperature at edge with maximal Temperature
    out(i).total_time = tot_time;  % total imaging time in seconds
end;

if clean %%% cleans out data -- for large skips in frame number, too short tracks, etc.
    
    % split tracks where gaps>MAXGAP are found
    for i=1:length(out)
        d=[out(i).f(2:end)',999999]-out(i).f(1:end)';  % sufficiently high to get last one
        split=find(d>MAXGAP);
        if ~isempty(split)
            for j=1:length(split)-1
                new=length(out)+1;
                out(new).x=out(i).x(split(j)+1:split(j+1));
                out(new).y=out(i).y(split(j)+1:split(j+1));
                out(new).f=out(i).f(split(j)+1:split(j+1));
                out(new).num=length(out(new).x);
                out(new).plate_id = plate_id;
                out(new).min_edge = cal_data(1); % pixel value of edge with minimal Temperature
                out(new).max_edge = cal_data(2); % pixel value of edge with maximal Temperature
                out(new).min_T = cal_data(3);    % Temperature at edge with minimal Temperature
                out(new).max_T = cal_data(4);    % Temperature at edge with maximal Temperature
                out(new).total_time = tot_time;  % total imaging time in seconds
            end;
            out(i).x=out(i).x(1:split(1));
            out(i).y=out(i).y(1:split(1));
            out(i).f=out(i).f(1:split(1));
            out(i).num=length(out(i).x);            
        end;
    end;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % David, April 2008: extrapolate where gap=1 frame is found
    for i=1:length(out)
        d = [out(i).f(2:end)',999999]-out(i).f(1:end)';  % sufficiently high to get last one
        one_frm_gap = find(d==2);
        if ~isempty(one_frm_gap)
            for j=1:length(one_frm_gap)
                k = one_frm_gap(j);
                mn_x = mean([out(i).x(k) out(i).x(k+1)]); 
                mn_y = mean([out(i).y(k) out(i).y(k+1)]); 
                mn_f = mean([out(i).f(k) out(i).f(k+1)]); 
                out(i).x = [out(i).x(1:k); mn_x; out(i).x((k+1):end)];
                out(i).y = [out(i).y(1:k); mn_y; out(i).y((k+1):end)];
                out(i).f = [out(i).f(1:k); mn_f; out(i).f((k+1):end)];
                out(i).num=length(out(i).x); % larger by 1 from previous
            end;            
        end;       
    end;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Get rid of tracks shorter than TOOSHORT frames or 
    % with movement less than MOVEBY pixels in either x- or y-direction  
    j=1;
    for i=1:length(out)
        % David, April 2 2008
        % original code was strange here, changed to:
        flag = ( abs(max(out(i).x)-min(out(i).x))>MOVEBY ); % number of pixels 
        flag = flag | ( abs(max(out(i).y)-min(out(i).y))>MOVEBY ); % number of pixels
        flag = flag & (out(i).num >= TOOSHORT); % number of frames in track
        % Original code:
        %flag = out(i).num >= TOOSHORT; % number of frames in track
        %flag = flag & ~(abs(max(out(i).x)-min(out(i).x))<MOVEBY; % number of pixels 
        %flag = flag & abs(max(out(i).y)-min(out(i).y))<MOVEBY); % number of pixels
        if flag
            temp(j)=out(i);
            j=j+1;
        end
    end
    out=temp;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

% sort the indices by length of the particle tracks found in each
for i=1:length(out)
    len(i)=out(i).num; 
end
[dum ind]=sort(-1*len);
temp=out;
for i=1:length(out)
    out(i)=temp(ind(i));
end
