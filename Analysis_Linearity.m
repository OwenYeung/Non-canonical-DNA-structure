%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Linearity                                                                %
% O.Yeung                                                                  %
% NOTE - Accepts optput files from NanodropSpectraProcessing.py (.txt)     %
% NOTE - Files must be in following format;                                %
% ["Lin"][Concentration(replacing"." for "-")][".tsv"]                     %
% e.g 'Linl-25.tsv'                                                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

%CURRENT DIR
currentdir = pwd;

%USERPROMPT FILE IMPORT & DIR CHANGE
[file,path] = uigetfile('*.tsv','Select One or More Files','MultiSelect', 'on');
cd(path)

%DEFINITIONS
file = cellstr(file); %Convert file list to cell array
tfileno = size(file); %size of file array
count_main = 1;
count_sub = 1;
fnm = '%sR%d.txt'; %Sprintf name container
fid = 1; %File ID
table = []; %Dataset table
table_index = cell(tfileno(:,2),1); %Index for dataset tables


%MAIN LOOP
for c = file
    %READ X VALUES
    inputname = file{count_main};
    A = dlmread(sprintf(fnm, inputname, count_sub), '\t', [3,0,0,0]); %dlmread import X values excluding file header
    table = [(array2table(A))];
    table.Properties.VariableNames = {'Wavelength'};
    
    %READ Y VALUES
    while fid > 0
        fid = fopen(sprintf(fnm, inputname, count_sub));
        if fid == -1
            break
        else
            B = dlmread(sprintf(fnm, inputname, count_sub), '\t', [3,1,0,1]); %dlmread import Y values excluding file header
            table(:,count_sub + 1) = (array2table(B));
            
            count_sub = count_sub + 1;
        end       
    end
    
    %DELETE OUT OF RANGE VALUES
    todelete = table.Wavelength < 220;
    table(todelete, :) = [];
    todelete = table.Wavelength > 700;
    table(todelete, :) = [];
    
    %CALCULATION (wavelength avgerage)
    table.tableavg = mean(table{:,2:end},2);
    table_index{count_main} = table;
    count_main = count_main + 1;
    count_sub = 1;
    fid = 1;   
end

%SUMMARY TABLE (table avg)
count_main = 1;
table_summary = table(:,1); %Populate new table with X values
for c = file
    inputname = file{count_main}; %Find & format file names for column identifiers
    inputname = inputname(1:end-4);
    inputname = strrep(inputname,'-','_');
    
    table = table_index{count_main,1}; %Find table
    table_summary(:,count_main + 1) = table(:,2); %Extract column 7 (table avg)
    table_summary.Properties.VariableNames(count_main + 1) = {inputname}; %Label new column
    
    count_main = count_main + 1;
end

%%
%TEST PLOTS
count_main = 1;
figure('Name', 'AbsMainPeak_AllTraces','NumberTitle','off');
hold on
for c = file
    x = table_summary(:,1);
    x = table2array(x);
    y = table_summary(:,count_main + 1);
    y = table2array(y);
    plot(x,y);
    xlim([220 340]);
    count_main = count_main + 1;
end
hold off;

fclose all;
