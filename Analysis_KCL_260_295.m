%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% KCl                                                                     %
% O.Yeung                                                                  %
% NOTE - Accepts optput files from NanodropSpectraProcessing.py (.txt)     %
% NOTE - Files must be in following format;                                %
% ['GQ(n)']['KCl'/'NaCl'][Concentration(replacing'.' for '-')]['.tsv']     %
% e.g 'GQ2KCl0-2.tsv'                                                      %
% Baseline dataset [Concentration('.' as '-')] is replaced w/ ['Baseline'] %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
close all;
fclose all;

%DIRECTORY
currentdir = pwd;

%USERPROMPT FILE SELECT % DIR CHANGE
[file,path] = uigetfile('*.tsv','Select all files to process inclusing baseline','MultiSelect', 'on');
cd (path)

%DEFINITIONS
file = cellstr(file); %ensure file is cell array
tfileno = size(file); %size of file array
fnm = '%sR%d.txt'; %Sprintf format string container
fid = 1; %FileID metric

%BLANK TABLES
table = [];
table_normalised = [];
table_baseline_normalised = [];
table_index = cell(tfileno(:,2),1);

%MAIN LOOP (Sqeuqntially building tables for each selected file)
count_main = 1;
count_sub = 1;
for c = file
    
    %READ X VALUES
    inputname = file{count_main};
    if contains(c, 'Baseline') == 0
        A = dlmread(sprintf(fnm, inputname, count_sub), '\t', [3,0,0,0]); %Dlmread X values excluding file headers
        table = [(array2table(A))]; %Populate table along y axis
        table.Properties.VariableNames = {'Wavelength'};
        todelete = table.Wavelength < 220; %Delete values below 220 nm
        table(todelete, :) = [];
        todelete = table.Wavelength > 700; %Delete values above 700 nm
        table(todelete, :) = [];
        
        %GET SALT CONC - Reads salt concentration in filename & replaces '-' w/ '.'
%        if strfind(inputname, 'NaCl') > 1
%            underscore_indices = strfind(inputname,'NaCl'); %If 'NaCl' (non-capitalised)
%        else
%            underscore_indices = strfind(inputname,'NACL'); %If 'NACL' (capitalised)
%        end
        if strfind(inputname, 'KCl') > 1
            underscore_indices = strfind(inputname,'KCl'); %If 'KCl' (non-capitalised)
        else
            underscore_indices = strfind(inputname,'KCL'); %If 'KCL' (capitalised)
        end
        fs_indices = strfind(inputname,'.');
        %saltconc = (inputname(underscore_indices(end)+4:fs_indices(end)-1)); %Find salt concentraion from filename | NaCl = +4
        saltconc = (inputname(underscore_indices(end)+3:fs_indices(end)-1)); %Find salt concentraion from filename | KCl = +3
        saltconc = strrep(saltconc,'-','.'); %Reformats imported filename '-' with '.'
        tablelookup(count_main,:) = [count_main, str2num(saltconc)];
        
        %READ Y VALUES
        while fid > 0
            fid = fopen(sprintf(fnm, inputname, count_sub));
            if fid == -1
                break
            else
                B = dlmread(sprintf(fnm, inputname, count_sub), '\t', [3,1,0,1]); %Dlmread Y values stripping file headers
                B1 = dlmread(sprintf(fnm, inputname, count_sub), '\t', [3,0,0,1]); %Dlmread X&Y values stripping file headers
                BTable = B1;
                BTable = array2table(BTable);
                BTable.Properties.VariableNames = {'Var1','Var2'};
                todelete = BTable.Var1 < 220; %Mark all values below 220 nm to delete
                BTable(todelete, :) = [];
                todelete = BTable.Var1 > 700; %Mark all values above 700 nm to delete
                BTable(todelete, :) = [];
                
                table(:,count_sub + 1) = (BTable(:,2)); %Progressively populate table columns
                count_sub = count_sub + 1;
            end
        end
    else break
    end
    
    %DELETE OUT OF RANGE VALUES (table)
    todelete = table.Wavelength < 220; %Mark all values below 220 nm to delete
    table(todelete, :) = [];
    todelete = table.Wavelength > 700; %Mark all values above 700 nm to delete
    table(todelete, :) = [];
    
    %DEFINITIONS
    fid2 = 1;
    count_sub2 = 1;
    
    %NORMALISE DATA
    table_normalised = [(array2table(table.Wavelength))]; %Import formatted X vals from non normalised table
    table_normalised.Properties.VariableNames = {'Wavelength'};
    
    while fid2 > 0
        fid2 = fopen(sprintf(fnm, inputname, count_sub2));
        if fid2 == -1
            break
        else
            B2 = table(: , (count_sub2 + 1));
            B2 = table2array(B2);
            table_normalised(:,count_sub2 + 1) = (array2table(B2/max(B2))); %Abs(Norm) = Abs / Abs(max)(Mccarte, B. Using Biomolecules to Build Nanoscale Actuators. (University of Edinburgh, 2018))
            count_sub2 = count_sub2 + 1;
        end
    end
    
    
    
    %DEL OOR VALUES (table_normalised)
    todelete = table_normalised.Wavelength < 220;
    table_normalised(todelete, :) = [];
    todelete = table_normalised.Wavelength > 700;
    table_normalised(todelete, :) = [];
    
    %CALCULATION - TABLE AVG
    table.tableavg = mean(table{:,2:end},2);
    table_normalised.tableavg = mean(table_normalised{:,2:end},2);
    
    %INDEX TABLES
    table_index{count_main,1} = table;
    table_index{count_main,2} = table_normalised;
    
    count_main = count_main + 1;
    count_sub = 1;
    fid = 1;
    
end
tablelookup(count_main,:) = [count_main, 0];

%ZERO SALT BASELINE

%DEFINITIONS
fid = 1;
count_main = 1;

file_baselinelookup = contains(file, 'Baseline'); %Search filelist for baseline file & import data
[row col] = find(file_baselinelookup == 1);
fnm_baseline = file{:,col};
fnm_baseline = strcat(fnm_baseline , 'R%d.txt'); %Sprintf format string container for baseline

A = dlmread(sprintf(fnm_baseline, count_main), '\t', [3,0,0,0]); %Import wavelength data from baseline file
table_baseline = [(array2table(A))];
table_baseline.Properties.VariableNames = {'Wavelength'};
table_baseline_normalised = [(array2table(A))];
table_baseline_normalised.Properties.VariableNames = {'Wavelength'};

%TABLE BUILDING LOOP
while fid > 0
    fid = fopen(sprintf(fnm_baseline, count_main));
    if fid == -1
        break
    else
        B = dlmread(sprintf(fnm_baseline, count_main), '\t', [3,1,0,1]); %Import spectra data from baseline file
        table_baseline(:,count_main + 1) = (array2table(B));
        count_main = count_main + 1;
    end
end


%DEL OOR VALUES (table_baseline)
todelete = table_baseline.Wavelength < 220;
table_baseline(todelete, :) = [];
todelete = table_baseline.Wavelength > 700;
table_baseline(todelete, :) = [];

%DEL OOR VALUES (table_baseline_normalised)
todelete = table_baseline_normalised.Wavelength < 220;
table_baseline_normalised(todelete, :) = [];
todelete = table_baseline_normalised.Wavelength > 700;
table_baseline_normalised(todelete, :) = [];


baselinesize = size(table_baseline);
count_main = 1;

%NORMALISE BASELINE
for c2 = 1:(baselinesize(1,2) - 1); 
    D = table2array(table_baseline(:,count_main + 1));
    table_baseline_normalised(:,count_main + 1) = (array2table(D/max(D)));
    count_main = count_main + 1;
end

table_baseline.tableavg = mean(table_baseline{:,2:end},2);
table_baseline_normalised.tableavg = mean(table_baseline_normalised{:,2:end},2);

%APPEND LOOKUP INDEX WITH BASELINE
E = size(table_index);
table_index{E(1),1} = table_baseline;
table_index{E(1),2} = table_baseline_normalised;

%DEFINITIONS
count_main = 1;

%BUILD SUMMARY TABLE (table_260295)
for c = file
    if contains(c, 'Baseline') == 0
        table = table_index{count_main,1};
        table_normalised = table_index{count_main,2};
        
        %DELTA ABS FULL SPECTRA
        table_normalised.DeltaAbs = (table_normalised.tableavg - table_baseline_normalised.tableavg);
        table_index{count_main,2} = table_normalised;
        
        [row260 col] = find(table.Wavelength == 260);
        [row295 col] = find(table.Wavelength == 295);
        DeltaAbs260 = (table_normalised.tableavg(row260)-table_baseline_normalised.tableavg(row260));
        DeltaAbs295 = (table_normalised.tableavg(row295)-table_baseline_normalised.tableavg(row295));
        table_260295(count_main,:) = [count_main, ...               %(1)
            tablelookup(count_main,2), ...                          %(2)
            row260, ...                                             %(3)
            table.tableavg(row260), ...                             %(4)
            table_normalised.tableavg(row260), ...                  %(5)
            DeltaAbs260, ...                                        %(6)
            row295, ...                                             %(7)
            table.tableavg(row295), ...                             %(8)
            table_normalised.tableavg(row295), ...                  %(9)
            DeltaAbs295];                                           %(10)
        count_main = count_main + 1;
    end
end

%APPEND SUMMARY TABLE WITH ZERO SALT DATA
[row260 col] = find(table_baseline_normalised.Wavelength == 260);
[row295 col] = find(table_baseline_normalised.Wavelength == 295);
table_260295(count_main,:) = [count_main, ...                       %(1)
    tablelookup(count_main,2), ...                                  %(2)
    row260, ...                                                     %(3)
    table_baseline.tableavg(row260), ...                            %(4)
    table_baseline_normalised.tableavg(row260), ...                 %(5)
    DeltaAbs260, ...                                                %(6)
    row295, ...                                                     %(7)
    table_baseline.tableavg(row295), ...                            %(8)
    table_baseline_normalised.tableavg(row295), ...                 %(9)
    DeltaAbs295];                                                   %(10)
table_260295 = array2table(table_260295);
table_260295.Properties.VariableNames = {'tableNo', ...             %(1)
    'SaltConc', ...                                                 %(2)
    'RowNoA', ...                                                   %(3)
    'AvgAbsA', ...                                                  %(4)
    'AvgAbsA_Norm', ...                                             %(5)
    'DeltaAbsA', ...                                                %(6)
    'RowNoB', ...                                                   %(7)
    'AvgAbsB', ...                                                  %(8)
    'AvgAbsB_Norm', ...                                             %(9)
    'DeltaAbsB'};                                                   %(10)
count_main = 1;

fclose all;
