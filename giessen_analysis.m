clear;
clear all;
clc;

% Note: Github repository does not include eeglab toolbox or original EEG data files
% To run this script download eeglab and data files
%              - eeglab (preferably version 14.1.1b) at https://sccn.ucsd.edu/eeglab/download.php
%              - EEG and experimental data (5.6Gb) at https://osf.io/96xsh/


trial_nr = 900;
data_path = './data/';
% eeglab version 14.1.1b
EEGlabpath = 'yourpath\eeglab14_1_1b';

addpath(data_path)
addpath(EEGlabpath)

eeglab

for session = 1:2
    % load epar
    load(join(['aliki0',num2str(session), '_parsed.mat']))
    % load .vhdr file
    % [filename,pathname] = uigetfile;
    filename = join(['aliki0',num2str(session),'.vhdr']);
    eeg_signal = pop_loadbv(data_path,filename);

    events = [];
    count = 1;
    for i = 1:length(eeg_signal.event)
        if strcmp(eeg_signal.event(1,i).type,'S  1')
            events(:,count) = [eeg_signal.event(1,i).latency; eeg_signal.event(1,i+1).latency];

            count = count +1;
        end
    end
    
    all_channels_pre = eeg_signal.data(:,1:events(2,trial_nr)+10*5000); % remove eeg data after 10 seconds after last trial end
    eeg_times = eeg_signal.times(1:events(2,trial_nr)+10*5000);
    
    for ch = 1:32
        if ch == 10
            channel_names{ch} = 'PO3';
        elseif ch == 23
            channel_names{ch} = 'PO4';
        else
            channel_names{ch} = eeg_signal.chanlocs(1,ch).labels;
        end
    end
    epar.channel_names = channel_names;

    % clearvars -except epar all_channels
    
    % low pass; cut high
    all_channels_pre = eegfilt(all_channels_pre,5000,0,65,0,21,0,'fir1');
    % all_channels = eegfilt(all_channels,eeg_data.SamplingRate(1),0,80,0,255,0,'fir1');

    % high pass; cut low
    all_channels_pre = eegfilt(all_channels_pre,5000,3,0,0,280,0,'fir1');
    % all_channels = eegfilt(all_channels,eeg_data.SamplingRate(1),10,0,0,153,0,'fir1');

    % cut line frequency 50 hz
    all_channels_pre = eegfiltfft(all_channels_pre,5000,47,53,0,[],1);
    
    % merge session etc
    fields = fieldnames(epar);
    for nr = 1:length(fields)
        if length(epar.(fields{nr})) == trial_nr && ~strcmp(fields{nr},'sqColors') && size(epar.(fields{nr}),2) ~= trial_nr
            epar.(fields{nr}) = epar.(fields{nr})';
        end
    end
    
    if session == 1
        epar_all = epar;
        all_channels = all_channels_pre;
        
        epar_all.eeg_rows = events;

        epar_all.eeg_time = eeg_times;
        epar_all.trial_nr = length(epar.trial_length);
    else
        % concatenate over relevant variables
        for nr = 1:length(fields)
            if strcmp(fields{nr},'sqColors')
                epar_all.(fields{nr}) = cat(4,epar_all.(fields{nr}),epar.(fields{nr}));
            elseif size(epar.(fields{nr}),2) == trial_nr
                epar_all.(fields{nr}) = cat(2,epar_all.(fields{nr}),epar.(fields{nr}));
            end
        end
        rows_length = length(epar_all.eeg_rows);
        time_length = length(epar_all.eeg_time);
        epar_all.eeg_rows(:,rows_length+1:rows_length+length(events)) = events + time_length;
        
        extra_time = epar_all.eeg_time(time_length) + 0.2;
        epar_all.eeg_time(time_length+1:time_length+length(eeg_times)) = eeg_times + extra_time;
        
        all_channels(:,time_length+1:time_length+length(eeg_times)) = all_channels_pre;
        
        epar_all.trial_nr = epar_all.trial_nr + length(epar.trial_length);
          
    end
end
%%

% get ERPs to flashes
ERP_data = get_ERPs(epar_all,all_channels, 0, 300, [3 21]);

save([data_path '\' ERP_data],'ERP_data');