function ERP_data = get_ERPs(epar,all_channels, start_t, stop_t, shape_nr)

% start_t: time in ms relative to flash onset to start cutting the ERP
% stop_t: time in ms relative to flash onset to stop cutting the ERP

% shape_nr: which shapes to detect flashes from and cut ERPs from

% epar.trial_nr = total number of trials

% epar.cue_frames: 1 * epar.trial_nr = moment of cue onset as nr of frames
% after trial start

% epar.flip_times: 284 * epar.trial_nr = timing of flips in seconds from
% trial onset; max 284 frames, if less padded with nans

% epar.tar_loc: 1 * epar.trial_nr = cued location 1 (left) or 2 (right)

% returns ERP_data: - ERP data for each flash in valid trials
% at shape_nr shapes. 
% - flash location (L or R), 
% - flash attended or not, 
% - time of flash relative to cue onset,
% - nr of trial the flash was in, 
% - start_t
% - stop_t
% - eeg channel nr


EEG_hz = 5000;
display_hz = 120;
t_after_cue = 0.5; % only use flashes that occur from 't_after_cue' seconds after cue onset
lum = 1; % detect flips from black to white
channel = 17; % only store Oz for now
nr_log_vars = 7;

% convert start and stop t to number of EEG samples (ms = 1000hz to 5000hz)
start_t_eeg = start_t * 5;
stop_t_eeg = stop_t * 5;
ERP_length = 1+abs(start_t_eeg)+abs(stop_t_eeg);

% preallocate for speed
ERP_data = NaN(epar.trial_nr*15,ERP_length+nr_log_vars);

count = 0;
for trial = 1:epar.trial_nr
    disp(trial)
    if epar.sacc_count(trial) == 0
        eeg_trial_start = epar.eeg_rows(1,trial);
        for square_nr = shape_nr
            if square_nr == 3 % left
                flash_loc = 0;
            elseif square_nr == 21 % right
                flash_loc = 1;
            end
            if flash_loc + 1 == epar.tar_loc(trial)
                attention = 1;
            else
                attention = 0;
            end
            one_trial = squeeze(epar.sqColors(1,square_nr,:,trial));
            for flp = (epar.cue_frames(trial)+ceil(t_after_cue*display_hz)):sum(~isnan(epar.flip_times(:,trial)))-1
                if one_trial(flp+1) - one_trial(flp) == lum
                    count = count + 1;
                    flp_t = epar.flip_times(flp+1,trial);
                    flp_eeg_row = round(flp_t * EEG_hz);
                    ERP_data(count,1:ERP_length) = all_channels(channel,eeg_trial_start+flp_eeg_row+start_t_eeg:eeg_trial_start+flp_eeg_row+stop_t_eeg);
                    ERP_data(count,ERP_length+1:ERP_length+nr_log_vars) = [flash_loc, attention, flp+1-epar.cue_frames(trial), trial, start_t, stop_t, channel];
                end
            end
        end
    end
end
ERP_data = ERP_data(1:count,:);
end