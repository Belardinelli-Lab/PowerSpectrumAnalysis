%% Script to loop through entire folder of datafiles                                                           COMMENTS AND EXPLANATIONS
                                                                                                                                
    % Restore MATLAB default path and add necessary paths
    restoredefaultpath
    addpath 'C:\Users\melis\Documents\MATLAB\fieldtrip-20240731'
    addpath 'C:\Users\melis\Documents\MATLAB\Scripts'
    ft_defaults
    
    % Define the directory containing the BrainVision files
    data_dir            = 'C:\Users\melis\Documents\Trento\TESTMS\Data\TG111224'; 
    
    continuous_dir      = 'C:\Users\melis\Documents\Trento\TESTMS\Data\TG111224\continuous';
    
    output_dir    = fullfile(data_dir, 'Poweranalysis');                                                        % Directory to save processed files
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);                                                                                      % Create output directory if  
    end                                                                                                         % it doesn't exist
    
    file_list_data      = dir(fullfile(data_dir, '*.vhdr')); 
    file_list_contin    = dir(fullfile(continuous_dir, '*.vhdr'));
    file_list           = [file_list_contin; file_list_data];
   
%% Load, preprocess, and save filtered data

    for file_idx                = 1:length(file_list)
        
        % Try to locate the .vhdr and .eeg files in data_dir, fallback to continuous_dir
        vhdr_file = fullfile(data_dir, file_list(file_idx).name);                                               % Full path to .vhdr file
        
        % Check if the vhdr file exists in data_dir
        if ~exist(vhdr_file, 'file')
            fprintf('File not found in data_dir, looking in continuous_dir...\n');
            vhdr_file = fullfile(continuous_dir, file_list(file_idx).name);                                     % Fallback to continuous_dir
        end
        
        % Extract base name from the located vhdr file
        [~, base_name, ~] = fileparts(vhdr_file);
        
        % Build the corresponding .eeg file path
        eeg_file = fullfile(data_dir, [base_name, '.eeg']);
        
        % Check if the .eeg file exists; fallback to continuous_dir if not found
        if ~exist(eeg_file, 'file')
            fprintf('EEG file not found in data_dir, looking in continuous_dir...\n');
            eeg_file = fullfile(continuous_dir, [base_name, '.eeg']);
        end                                                                                                     % Full path to corresponding .eeg file
        
        % Extract the base name and replace underscores with spaces
        name = strrep(base_name, '_', ' ');                                                                     % Replace '_' with ' ' in base filename
        fprintf(['Processing file (loading and preprocessing):' ...
            ' %s (Name: %s)\n'], vhdr_file, name);                                                              % Debugging output

            
            % Preprocessing
            cfg = [];
            cfg.headerfile          = vhdr_file;                                                                % Use dynamically assigned vhdr_file
            cfg.datafile            = eeg_file;               
            cfg.channel             = [1 2 3 4 5];                                                              % select only EEG channels; 5 21 23 25 27
            cfg.dhelemean           = 'yes';
            cfg.detrend             = 'yes';
            cfg.reref               = 'yes';                                                                    % having only 5 channels with the signal created from all of the above (C3 - 0.25 per each of the other electrodes
            cfg.refchannel          = 'all';
            cfg.refmethod           = 'avg';                                                                    % on the single electrode on AF8
            cfg.bpfilter            = [5 15];
            data1                   = ft_preprocessing(cfg);
                       
            % Visual Artifact Detection
            cfg = [];
            cfg.layout          = 'easycapM25.mat';
            cfg.viewmode        = 'vertical';
            cfg.blocksize       = 3;                                                                            % time window to browse
            cfg.preproc.demean  = 'yes';
            cfg.artifactalpha   = 0.8;                                                                          % this make the colors less transparent and thus more vibrant
            cfg.artfctdef       = [];
            % Print the current dataset being analyzed
            fprintf('Currently analyzing: %s\n', strrep(base_name, '_', ' '));
            % Launch the FieldTrip databrowser
            artif = ft_databrowser(cfg, data1);                                                                 % Launch databrowser
                
            
            % Reject artifacts;
            cfg = [];
            cfg.artfctdef           = artif.artfctdef;
            cfg.artfctdef.reject    = 'partial';
            data_rejected           = ft_rejectartifact(cfg, data1);
            
            % Filtering
            cfg = [];
            cfg.channel             = 'all';
            cfg.demean              = 'yes';
            cfg.dftfilter           = 'yes';
            cfg.dftfreq             = [50 100 150];
            % cfg.bsfilter          = 'no'; % band-stop method
            % cfg.bsfreq            = [48 52];
            data_preproc            = ft_preprocessing(cfg,data_rejected);
            
            % Epoching
            cfg = [];
            cfg.length               = 1;
            data_segmented           = ft_redefinetrial(cfg, data_preproc);


        % Save the preprocessed data
        preproc_dir             = fullfile(output_dir, 'Preprocessed');                                         % Directory to save processed files
        if ~exist(preproc_dir, 'dir')
            mkdir(preproc_dir);                                                                                 % Create output directory if  
        end 
        save(fullfile(preproc_dir, [base_name, '_preproc.mat']), 'data_segmented');
    end

%% Powerspectrum Analysis

    file_list               = dir(fullfile(preproc_dir, '*.mat'));                                              % Get a list of all .mat files
    for file_idx            = 1:length(file_list)
    
        % Get the current file's base name
        [~, base_name, ~]   = fileparts(file_list(file_idx).name);
    
        % Load the preprocessed data
        preproc_file        = fullfile(preproc_dir, [base_name, '.mat']);
            if ~isfile(preproc_file)
                fprintf('Preproc file not found for %s. Skipping.\n', base_name);
                continue;
            end
        load(preproc_file, 'data_segmented');                                                                   % Load saved filtered_data
        fprintf('Processing file (Preprocessed): %s\n', base_name);
        
            
            % power analysis
            cfg             = [];
            cfg.output      = 'pow';
            % cfg.channel   = 'all';
            cfg.method      = 'mtmfft';
            cfg.taper       = 'dpss';
            cfg.foi         = 1:1:45;     
            cfg.tapsmofrq   = 1;
            data_pow        = ft_freqanalysis(cfg, data_segmented);    


        % Save the filtered data
        pow_dir             = fullfile(output_dir, 'Powerspectrum');                                            % Directory to save processed files
        if ~exist(pow_dir, 'dir')
            mkdir(pow_dir);                                                                                     % Create output directory if  
        end 
        name                = strrep(base_name, 'preproc', 'pow');                                              % Replace 'preproc' with 'pow' in filename  
        save(fullfile(pow_dir, name), 'data_pow');
    end

%% Plot and save figures

    file_list                   = dir(fullfile(pow_dir, '*.mat'));                                              % Get a list of all .mat files
    for file_idx            = 1:length(file_list)
    
        % Get the current file's base name
        [~, base_name, ~]           = fileparts(file_list(file_idx).name);
    
        % Load the preprocessed data
        pow_file                    = fullfile(pow_dir, [base_name, '.mat']);
            if ~isfile(pow_file)
                fprintf('Pow file not found for %s. Skipping.\n', base_name);
                continue;
            end
        load(pow_file, 'data_pow');                                                                             % Load saved filtered_data
        fprintf('Processing file (Pow): %s\n', base_name);                                                      % Debugging output       
            
            
            % First figure: Plot each channel's spectrum with mean overlaid
            figure('Name', strrep(base_name, '_', ' '), 'NumberTitle', 'off');                                  % Figure window title
            hold on;                                                                                            % Allow multiple plots on the same figure
            
            % Plot the power spectra for each channel
            plot(data_pow.freq, data_pow.powspctrm', 'LineWidth', 1.5);                                         % Transpose powspctrm for plotting
            
            % Compute and plot the mean power spectrum as a dotted black line
            mean_spectrum           = mean(data_pow.powspctrm, 1);                                                        % Compute mean across channels
            plot(data_pow.freq, mean_spectrum, 'k--', 'LineWidth', 2);                                          % Mean spectrum as dotted line
            
            % Find the peak frequency and power around 10 Hz
            freq_range              = (data_pow.freq >= 8) & (data_pow.freq <= 12);                                          % Logical index for 8–12 Hz range
            freq_subset             = data_pow.freq(freq_range);                                                                    % Subset of frequencies
            power_subset            = mean_spectrum(freq_range);                                                           % Subset of power spectrum
            
            [peak_power, peak_idx]  = max(power_subset);                                                                 % Find the maximum power in the range
            peak_freq               = freq_subset(peak_idx);                                                                  % Corresponding frequency
            
            % Mark the peak frequency on the plot
            plot(peak_freq, peak_power, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');                         % Red dot for the peak
            
            % Add a text annotation at a fixed y-position (e.g., y = 1)
            text(peak_freq, 0.01, sprintf('Peak: %.2f Hz, %.2f', peak_freq, peak_power), ...
                'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Color', 'black');

            % Add labels, title, and legend
            xlabel('Frequency (Hz)');
            ylabel('Power');
            title('Channel Spectra');                                                                           % Title inside the plot
            legend([data_pow.label; {'Mean'}], 'Location', 'Best');                                             % Add channel labels and mean
            grid on;
            ylim ([0 1])
            hold off;
            
        % Save all figures to a Figures folder
        fig_dir             = fullfile(output_dir, 'Figures');                                                  % Directory to save processed files
        if ~exist(fig_dir, 'dir')
            mkdir(fig_dir);                                                                                     % Create the folder if it doesn't exist
        end
        figure_file         = fullfile(fig_dir, [base_name, '.fig']);                                           % Define the .fig file path
        figure(file_idx);                                                                                       % Select the current figure
        savefig(figure_file);                                                                                   % Save the figure
        fprintf('Figure for %s saved to %s\n', base_name, figure_file);                                         % Log success
                                                                                                                      
    end
