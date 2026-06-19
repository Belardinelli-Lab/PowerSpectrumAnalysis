%% Script to loop through entire folder of datafiles                                                           COMMENTS AND EXPLANATIONS
                                                                                                                                
%                                                                                                                                 
 % Restore MATLAB default path and add necessary paths
   % restoredefaultpath
    addpath C:\Users\melissa.null\Documents\MATLAB\fieldtrip-20260518
    ft_defaults
    %%
    cd 'C:\Users\neurone\Desktop\NOCI-PROJECT\Session2\' % adjust Session
    sub = input('Which SUB ID do you want to look at?', 'S'); %CHANGE TO SUB ID OF CURRENT SESSION (IN COMMAND WINDOW)
  
    %%
    path = 'C:\Users\neurone\Desktop\NOCI-PROJECT\Session2\'; % adjust Session 
    data_dir            = dir(fullfile(path,['S',sub, '*'])); 
    
    % data_dir            = 'C:\Users\neurone\Desktop\NOCI-PROJECT\Session1\S10-010725-Session1';
    % data_dir            = dir(fullfile('C:\Users\neurone\Desktop\NOCI-PROJECT\Session1\S10-010725-Session1')); 
    % Define the directory containing the BrainVision files
for n = 1: numel(data_dir)
    
    output_dir    = fullfile(path, 'Poweranalysis');                                                        % Directory to save processed files
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);                                                                                      % Create output directory if  
    end                                                                                                         % it doesn't exist
    
    path_current = data_dir.name; %'C:\Users\neurone\Desktop\NOCI-PROJECT\Session1\S12-020725-Session1', '*RS-PRE.vhdr';
   
    file_list_data       = dir(fullfile(path,path_current, '*RS*.vhdr')); 
    % dir(fullfile('C:\Users\neurone\Desktop\NOCI-PROJECT\Session1\S21-040725-Session1', '*RS-PRE.vhdr'));
    file_list            = file_list_data;
     
    % Load, preprocess, and save filtered data

    for file_idx                = 1:length(file_list)
        
        % Try to locate the .vhdr and .eeg files in data_dir, fallback to continuous_dir
        vhdr_file = fullfile("F:\DataT4TE\BEL_S12\BEL_S12_EEG\BEL_S12_12062026_PRE_RS.vhdr") %fullfile(path_current, file_list(file_idx).name);                                               % Full path to .vhdr file
        
        % Extract base name from the located vhdr file
        [~, base_name, ~] = fileparts(vhdr_file);
        
        % Build the corresponding .eeg file path
        eeg_file = fullfile("F:\DataT4TE\BEL_S12\BEL_S12_EEG\BEL_S12_12062026_PRE_RS.eeg") %fullfile(path_current, [base_name, '.eeg']);
        
        % Extract the base name and replace underscores with spaces
        name = strrep(base_name, '-', ' ');                                                                     % Replace '_' with ' ' in base filename
        fprintf(['Processing file (loading and preprocessing):' ...
            ' %s (Name: %s)\n'], vhdr_file, name);                                                              % Debugging output

            
            % Preprocessing
            cfg = [];
            cfg.headerfile          = vhdr_file;                                                                % Use dynamically assigned vhdr_file
            cfg.datafile            = eeg_file;
            %cfg.channel             = [29 21 48 19 46];
            cfg.channel             = [5 21 23 25 27];                                                          % select only EEG channels; 5 21 23 25 27; Hjorth montage C3
            %cfg.channel             = 'all';
            cfg.dhelemean           = 'yes';                                                                    % Removes the mean from each channel's signal — helpful to eliminate DC offset.
            cfg.detrend             = 'yes';                                                                    % Removes linear trends from the data (e.g., slow drifts), which can help with filtering and artifact rejection.
            cfg.reref               = 'yes';                                                                    % having only 5 channels with the signal created from all of the above (C3 - 0.25 per each of the other electrodes
            cfg.refchannel          = 'all';
            cfg.refmethod           = 'avg';                                                                    % on the single electrode on AF8100
            cfg.bpfilter            = [1 100];
            data1                   = ft_preprocessing(cfg);
                       
%             % Visual Artifact Detection
%             cfg = [];
%             cfg.layout          = 'easycapM25.mat';
%             cfg.viewmode        = 'vertical';
%             cfg.blocksize       = 3;                                                                            % time window to browse
%             cfg.preproc.demean  = 'yes';
%             cfg.artifactalpha   = 0.8;                                                                          % this make the colors less transparent and thus more vibrant
%             cfg.artfctdef       = [];
%             % Print the current dataset being analyzed
%             fprintf('Currently analyzing: %s\n', strrep(base_name, '_', ' '));
%             % Launch the FieldTrip databrowser
% %             artif = ft_databrowser(cfg, data1);                                                                 % Launch databrowser
%                 
%             
%             % Reject artifacts;
%             cfg = [];
%             cfg.artfctdef           = artif.artfctdef;
%             cfg.artfctdef.reject    = 'partial';
%             data_rejected           = ft_rejectartifact(cfg, data1);
            
            % Filtering
            cfg = [];
            cfg.channel             = 'all';
            cfg.demean              = 'yes';
            cfg.dftfilter           = 'yes';
            
            %cfg.dftfreq            = [50 100 150];
            cfg.bsfilter            = 'yes'; % band-stop method
            cfg.bsfiltord           = 3;
            cfg.bsfreq              = [48 52];
            data_preproc            = ft_preprocessing(cfg,data1);
%             data_preproc            = ft_preprocessing(cfg,data_rejected);

             % Epoching
             cfg = [];
             cfg.length              = 5;
            data_segmented           = ft_redefinetrial(cfg, data_preproc);         

        % Save the preprocessed data
        preproc_dir             = fullfile(output_dir, 'Preprocessed');                                         % Directory to save processed files
        if ~exist(preproc_dir, 'dir')
            mkdir(preproc_dir);                                                                                 % Create output directory if  
        end 
        save(fullfile(preproc_dir, [base_name, '_preproc_tLength5.mat']), 'data_segmented');
    end
end

%% Powerspectrum Analysis

%   path            = 'C:\Users\neurone\Desktop\NOCI-PROJECT\Session1\';
   output_dir    = fullfile(path, 'Poweranalysis'); 

    preproc_dir            = fullfile(path, 'Poweranalysis/Preprocessed');
    file_list               = dir(fullfile(preproc_dir, ['S',sub, '*']));                                     % Get a list of all .mat files
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
                
            weighted_avg = 0.25 * (data_segmented.trial{1}(find(strcmp(data_segmented.label, 'FC1')), :) + ...
                           data_segmented.trial{1}(find(strcmp(data_segmented.label, 'FC5')), :) + ...
                           data_segmented.trial{1}(find(strcmp(data_segmented.label, 'CP1')), :) + ...
                           data_segmented.trial{1}(find(strcmp(data_segmented.label, 'CP5')), :));
    
            % Subtract this weighted average from C3
            chan1_idx = find(strcmp(data_segmented.label, 'C3'));
            data_segmented.trial{1}(chan1_idx, :) = data_segmented.trial{1}(chan1_idx, :) - weighted_avg;
            
            cfg = [];
            cfg.resamplefs = 1000; % minimo il doppio della nostra frequenza massima (248 x 2)
            cfg.detrend    = 'no'; % Opzionale, per rimuovere o meno i trend lineari
            data_down = ft_resampledata(cfg, data_segmented);

            cfg               = [];
            cfg.channel       = 'C3'; %che ormai e' lo hjort
            cfg.foi           = 1:.2:45;        
            cfg.pad           = 'nextpow2';
            cfg.method        =  'irasa';
            cfg.output        =  'fractal';
            fractal = ft_freqanalysis(cfg, data_down);
            cfg.output        = 'original';
            original = ft_freqanalysis(cfg, data_down);
        
            % subtract the fractal component from the power spectrum
            cfg               = [];
            cfg.parameter     = 'powspctrm';
            cfg.operation     = 'x2-x1';
            data_irasa = ft_math(cfg, fractal, original);
            
            % get peak
            [peak_pow, peak_freq_idx] = max(data_irasa.powspctrm(36:56));
            peak_freq_idx = peak_freq_idx+35; %+35 to account for the fact that above we only look at 20 freq data points
            mu_peak_freq= round(data_irasa.freq(peak_freq_idx),1);

                % First figure: Plot each channel's spectrum with mean overlaid
                figure('Name', strrep(base_name, '_', ' '), 'NumberTitle', 'off');                                  % Figure window title
                hold on;                                                                                            % Allow multiple plots on the same figure               
                % Plot the power spectra for each channel
                plot(data_irasa.freq, data_irasa.powspctrm', 'LineWidth', 1.5);                                         % Transpose powspctrm for plotting
                
                text(data_irasa.freq(peak_freq_idx), peak_pow+0.02,...
                    sprintf('Peak Frequency: %.2f Hz', data_irasa.freq(peak_freq_idx)),'FontSize',10,'FontWeight','bold');
                % Add labels, title, and legend
                xlabel('Frequency (Hz)');
                ylabel('Power');
                title('Channel Spectra'); % Title inside the plot
                legend('C3 - Hjorth filtered');                                             
                grid on;
                ylim ([0 (max(data_irasa.powspctrm)+0.05)])
                hold off;

        % Save the filtered data
        irasa_dir             = fullfile(output_dir, 'IRASA');                                            % Directory to save processed files
        if ~exist(irasa_dir, 'dir')
            mkdir(irasa_dir);                                                                                     % Create output directory if  
        end 
        name                = strrep(base_name, 'preproc', 'irasa4');                                              % Replace 'preproc' with 'pow' in filename  
        save(fullfile(irasa_dir, name), 'data_irasa');
   
    end
