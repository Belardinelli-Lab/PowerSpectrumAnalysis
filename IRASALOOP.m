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
    preproc_dir             = fullfile(output_dir, 'Preprocessed');   
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
                
            weighted_avg = 0.25 * (data_segmented.trial{1}(find(strcmp(data_segmented.label, '2')), :) + ...
                           data_segmented.trial{1}(find(strcmp(data_segmented.label, '3')), :) + ...
                           data_segmented.trial{1}(find(strcmp(data_segmented.label, '4')), :) + ...
                           data_segmented.trial{1}(find(strcmp(data_segmented.label, '5')), :));
    
            % Subtract this weighted average from C3
            chan1_idx = find(strcmp(data_segmented.label, '1'));
            data_segmented.trial{1}(chan1_idx, :) = data_segmented.trial{1}(chan1_idx, :) - weighted_avg;
            
            cfg = [];
            cfg.resamplefs = 300; % minimo il doppio della nostra frequenza massima (248 x 2)
            cfg.detrend    = 'no'; % Opzionale, per rimuovere o meno i trend lineari
            data_down = ft_resampledata(cfg, data_segmented);

            cfg               = [];
            cfg.channel       = 'C3'; %che ormai e' lo hjort
            cfg.foi           = 1:1:45;     
            cfg.pad           = 'nextpow2';
            cfg.method        = 'irasa';
            cfg.output        = 'fractal';
            fractal = ft_freqanalysis(cfg, data_down);
            cfg.output        = 'original';
            original = ft_freqanalysis(cfg, data_down);
        
            % subtract the fractal component from the power spectrum
            cfg               = [];
            cfg.parameter     = 'powspctrm';
            cfg.operation     = 'x2-x1';
            data_irasa = ft_math(cfg, fractal, original);

            % First figure: Plot each channel's spectrum with mean overlaid
            figure('Name', strrep(base_name, '_', ' '), 'NumberTitle', 'off');                                  % Figure window title
            hold on;                                                                                            % Allow multiple plots on the same figure
            
            % Plot the power spectra for each channel
            plot(data_irasa.freq, data_irasa.powspctrm', 'LineWidth', 1.5);                                         % Transpose powspctrm for plotting
            
            % Add labels, title, and legend
            xlabel('Frequency (Hz)');
            ylabel('Power');
            title('Channel Spectra');                                                                           % Title inside the plot
            %legend([data_irasa.label; {'Mean'}], 'Location', 'Best');                                             % Add channel labels and mean
            grid on;
            ylim ([0 0.04])
            hold off;


        % Save the filtered data
        irasa_dir             = fullfile(output_dir, 'IRASA');                                            % Directory to save processed files
        if ~exist(irasa_dir, 'dir')
            mkdir(irasa_dir);                                                                                     % Create output directory if  
        end 
        name                = strrep(base_name, 'preproc', 'irasa');                                              % Replace 'preproc' with 'pow' in filename  
        save(fullfile(irasa_dir, name), 'data_irasa');
   
    end

%% Plot and save figures

    file_list                   = dir(fullfile(irasa_dir, '*.mat'));                                              % Get a list of all .mat files
    for file_idx            = 1:length(file_list)

        % Get the current file's base name
        [~, base_name, ~]           = fileparts(file_list(file_idx).name);

        % Load the preprocessed data
        irasa_file                    = fullfile(irasa_dir, [base_name, '.mat']);
            if ~isfile(irasa_file)
                fprintf('Pow file not found for %s. Skipping.\n', base_name);
                continue;
            end
        load(irasa_file, 'data_irasa');                                                                             % Load saved filtered_data
        fprintf('Processing file (IRASA): %s\n', base_name);                                                      % Debugging output       
            
            % First figure: Plot each channel's spectrum with mean overlaid
            figure('Name', strrep(base_name, '_', ' '), 'NumberTitle', 'off');                                  % Figure window title
            hold on;                                                                                            % Allow multiple plots on the same figure
            
            % Plot the power spectra for each channel
            plot(data_irasa.freq, data_irasa.powspctrm', 'LineWidth', 1.5);                                         % Transpose powspctrm for plotting
            
            % % Compute and plot the mean power spectrum as a dotted black line
            % mean_spectrum           = mean(data_irasa.powspctrm, 1);                                                        % Compute mean across channels
            % plot(data_irasa.freq, mean_spectrum, 'k--', 'LineWidth', 2);                                          % Mean spectrum as dotted line
            % 
            % % % Find the peak frequency and power around 10 Hz
            % freq_range              = (data_irasa.freq >= 8) & (data_irasa.freq <= 12);                                          % Logical index for 8–12 Hz range
            % freq_subset             = data_irasa.freq(freq_range);                                                                    % Subset of frequencies
            % power_subset            = mean_spectrum(freq_range);                                                           % Subset of power spectrum
            % 
            % [peak_power, peak_idx]  = max(power_subset);                                                                 % Find the maximum power in the range
            % peak_freq               = freq_subset(peak_idx);                                                                  % Corresponding frequency
            % 
            % % Mark the peak frequency on the plot
            % plot(peak_freq, peak_power, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');                         % Red dot for the peak
            % 
            % % Add a text annotation at a fixed y-position (e.g., y = 1)
            % text(peak_freq, 1, sprintf('Peak: %.2f Hz, %.2f', peak_freq, peak_power), ...
            %     'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Color', 'black');

            % Add labels, title, and legend
            xlabel('Frequency (Hz)');
            ylabel('Power');
            title('Channel Spectra');                                                                           % Title inside the plot
            %legend([data_irasa.label; {'Mean'}], 'Location', 'Best');                                             % Add channel labels and mean
            grid on;
            ylim ([0 0.04])
            hold off;
            
        % Save all figures to a Figures folder
        figirasa_dir             = fullfile(output_dir, 'IRASA Figures');                                                  % Directory to save processed files
        if ~exist(figirasa_dir, 'dir')
            mkdir(figirasa_dir);                                                                                     % Create the folder if it doesn't exist
        end
        figure_file         = fullfile(figirasa_dir, [name, '.fig']);                                           % Define the .fig file path
        figure(file_idx);                                                                                       % Select the current figure
        savefig(figure_file);                                                                                   % Save the figure
        fprintf('Figure for %s saved to %s\n', name, figure_file);                                         % Log success
       
        % figure_file         = fullfile(figfrac_dir, [name, '.fig']);                                           % Define the .fig file path
        % figure(file_idx);                                                                                       % Select the current figure
        % savefig(figure_file);                                                                                   % Save the figure
        % fprintf('Figure for %s saved to %s\n', name, figure_file);                                         % Log success
  end
