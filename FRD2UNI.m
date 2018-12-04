function [UFF] = FRD2UNI(varargin)
%% FRD2UNI - convert iddata object to universal file time series
%
% Syntax:
%       [UFF] = FRD2UNI(data)
%
% Description:
%       Convert iddata object to time series data sets for universal file
%       format.
%
% Input Arguments:
%       -data: FRD object
%
% Output Arguments:
%       -UFF: universal file datasets ready for writeuff(uff_filename,UFF)
%
% Examples:
%       [UFF] = FRD2UNI(data);
%       Info = writeuff(fileName, UFF, 'replace');
%
% See Also:
%       iddata pak2IdData UNI2IdData LMSmat2FRD
%       http://www.sdrl.uc.edu/sdrl/referenceinfo/universalfileformats/file-format-storehouse/universal-dataset-number-58
%
%
%------------------------------------------------------------------
% This file is part of the Virtual NVH Car (VC) Toolbox.
%
%------------------------------------------------------------------
% Authors:      Thomas Emmert
% Email:        <a href="mailto:Thomas.Emmert@BMW.de">Thomas.Emmert@BMW.de</a>
% Website:      <a href="https://www.BMW.de/">www.BMW.de/</a>
% Work Adress:  BMW Group
% Last Change:  11 DEC 2017
% Copyright (c) 2017 EG-400, BMW Group
%------------------------------------------------------------------

data = varargin{1};
if nargin == 2
    NodeMapping = varargin{2};
else
    NodeMapping = [];
end

%% PAK Unit to UFF Abscissa Data Characteristics Map
% Input
InputUnit2ordDataCharMap = containers.Map;
InputUnit2ordDataCharMap('Pa') = 'pressure';
InputUnit2ordDataCharMap('N') = 'excitation force';
% Output
OutputUnit2ordDataCharMap = containers.Map;
OutputUnit2ordDataCharMap('Pa') = 'pressure';
OutputUnit2ordDataCharMap('N') = 'reaction force';
%TODO: implement more Unit mappings

%% Abscissa Data Characteristics
% According to http://www.sdrl.uc.edu/sdrl/referenceinfo/universalfileformats/file-format-storehouse/universal-dataset-number-58
% Field 1    - Specific Data Type
ordDataCharMap = containers.Map;
ordDataCharMap('unknown') = 0;
ordDataCharMap('general') = 1;
ordDataCharMap('stress') = 2;
ordDataCharMap('strain') = 3;
ordDataCharMap('temperature') = 5;
ordDataCharMap('heat flux') = 6;
ordDataCharMap('displacement') = 8;
ordDataCharMap('reaction force') = 9;
ordDataCharMap('velocity') = 11;
ordDataCharMap('acceleration') = 12;
ordDataCharMap('excitation force') = 13;
ordDataCharMap('pressure') = 15;
ordDataCharMap('mass') = 16;
ordDataCharMap('time') = 17;
ordDataCharMap('frequency') = 18;
ordDataCharMap('rpm') = 19;
ordDataCharMap('order') = 20;
ordDataCharMap('sound pressure') = 21;
ordDataCharMap('sound intensity') = 22;
ordDataCharMap('sound power') = 23;

%% Execute conversion
UFF = {};
% Iterate over Inputs
for idxInput = 1:size(data,2)
    % Iterate over Outputs
    for idxOutput = 1:size(data,1)
        uf = channel2uni(data);
        uf.measData = squeeze(data(idxOutput,idxInput).ResponseData);
        
        %% Input/Reference Name and ID Mapping
        if not(isempty(NodeMapping))
            idx = strcmp(NodeMapping.ChannelID,data.InputName{idxInput});
            NodeID = NodeMapping.NodeIDFRF(idx);
        elseif isfield(data.UserData,'InputNodeID')
            NodeID = data.UserData.InputNodeID{idxInput};
        else
            NodeID = [];
        end
        [uf.refNode, uf.refDir] = Name2NodeDir(data.InputName{idxInput},NodeID);
        uf.refEntName = data.InputName{idxInput};
        uf.d1 = data.InputName{idxInput};
        % uf.ordinateNumUnitsLabel= data.InputUnit{idxInput}; % TODO:
        % implement proper mapping for input and output units and labels
        % according to
        % data.InputUnit, data.OutputUnit,
        % data.UserData.InputordinateAxisLabel,
        % data.UserData.OutputordinateAxisLabel
        
        %% Output/response Name and ID Mapping
        if not(isempty(NodeMapping))
            idx = strcmp(NodeMapping.ChannelID,data.OutputName{idxOutput});
            NodeID = NodeMapping.NodeIDFRF(idx);
        elseif isfield(data.UserData,'OutputNodeID')
            NodeID = data.UserData.OutputNodeID{idxOutput};
        else
            NodeID = [];
        end
        [uf.rspNode, uf.rspDir] = Name2NodeDir(data.OutputName{idxOutput},NodeID);
        uf.rspEntName = data.OutputName{idxOutput};
        uf.d2 = data.OutputName{idxOutput};
        uf.ordinateNumUnitsLabel= data.OutputUnit{idxOutput};
        
        AxisLabel = '';
        if isfield(data.UserData,'OutputordinateAxisLabel')
            AxisLabel = data.UserData.OutputordinateAxisLabel{idxOutput};
        end
        uf.ordinateAxisLabel = AxisLabel;
        
        AxisLabel = lower(AxisLabel);
        if isKey(InputUnit2ordDataCharMap,data.InputUnit{idxInput})
            uf.ordDataChar = ordDataCharMap(InputUnit2ordDataCharMap(data.InputUnit{idxInput}));
        elseif isKey(ordDataCharMap,AxisLabel)
            uf.ordDataChar = ordDataCharMap(AxisLabel);
        else
            uf.ordDataChar = ordDataCharMap('unknown');
        end
        
        UFF(end+1) = {uf};
    end
end
%
% for idxInput = 1:size(data,2)
%     uf = channel2uni(data);
%     uf.measData = data(:,idxInput,[]).y; % TODO: fix
%     uf.rspNode = str2double(data.OutputName(idxInput));
%     if isfield(data.UserData,'OutputNodeID')
%         uf.rspNode = data.UserData.OutputNodeID{idxInput};
%     elseif isnan(uf.rspNode) % Catch NaN if inputname is not a number coded string
%         uf.rspNode = 0;
%         warning('rspNode was NaN. This may cause an issue in further processing.')
%     end
%     uf.rspEntName = data.OutputName{idxInput};
%     uf.ordinateNumUnitsLabel= data.OutputUnit{idxInput};
%
%     AxisLabel = '';
%     if isfield(data.UserData,'OutputordinateAxisLabel')
%         AxisLabel = data.UserData.OutputordinateAxisLabel{idxInput};
%     end
%     uf.ordinateAxisLabel = AxisLabel;
%
%     AxisLabel = lower(AxisLabel);
%     if isKey(OutputUnit2ordDataCharMap,data.OutputUnit{idxInput})
%         uf.ordDataChar = ordDataCharMap(OutputUnit2ordDataCharMap(data.OutputUnit{idxInput}));
%     elseif isKey(ordDataCharMap,AxisLabel)
%         uf.ordDataChar = ordDataCharMap(AxisLabel);
%     else
%         uf.ordDataChar = ordDataCharMap('unknown');
%     end
%     UFF(end+1) = {uf};
% end
end

function uf = channel2uni(data)
%% Create all generic uf data (i/o independent)
uf = [];
% Creat Universal file structure for writing
% #58 - for measurement data - function at dof (58).
%     .x (time or frequency)  .measData               .d1 (descrip. 1)
%     .d2 (descrip. 2)        .date                   .functionType (see notes)
%     .rspNode                .rspDir                 .refNode
%     .refDir
%     (Optional fields):
%     .precision {'single' or 'double'}, defaults to double
%     .ID_4                   .ID_5                   .loadCaseId
%     .rspEntName             .refEntName
%     .abscDataChar           .abscUnitsLabel
%     .abscLengthUnitsExponent.abscForceUnitsExponent
%     .abscTempUnitsExponent  .abscAxisLabel
%     .ordinateLengthUnitsExponent
%     .ordDataChar            .ordDenomDataChar
%     .ordinateNumUnitsLabel  .ordinateDenomUnitsLabel
%     .zUnitsLabel            .zAxisValue
%     .ordinateForceUnitsExponent .ordinateTempUnitsExponent
%     .ordinateAxisLabel
uf.dsType = 58;
uf.binary = 1;
uf.x = data.Frequency;
uf.d1 = [];
uf.d2 = data.Name;
if isfield(data.UserData,'Date')
    uf.date = data.UserData.Date;
else
    uf.date = '';
end
uf.rspDir = 0;
uf.refNode = -1;
uf.refDir = 0;
% Optional
if ischar(data.Notes)
    uf.ID_4 = data.Notes;
else
    uf.ID_4 = 'Zeitrohdaten';
end
uf.ID_5 = 'Converted by FRD2UNI';
uf.precision = 'single';
uf.ordLenExp = 0;
uf.ordinateDenomUnitsLabel= 'NONE';
uf.abscAxisLabel = 'Frequency';
uf.abscUnitsLabel = data.FrequencyUnit;
%% Function Type
%  0 - General or Unknown
%  1 - Time Response
%  2 - Auto Spectrum
%  3 - Cross Spectrum
%  4 - Frequency Response Function
%  5 - Transmissibility
%  6 - Coherence
%  7 - Auto Correlation
%  8 - Cross Correlation
%  9 - Power Spectral Density (PSD)
%  10 - Energy Spectral Density (ESD)
%  11 - Probability Density Function
%  12 - Spectrum
%  13 - Cumulative Frequency Distribution
%  14 - Peaks Valley
%  15 - Stress/Cycles
%  16 - Strain/Cycles
%  17 - Orbit
%  18 - Mode Indicator Function
%  19 - Force Pattern
%  20 - Partial Power
%  21 - Partial Coherence
%  22 - Eigenvalue
%  23 - Eigenvector
%  24 - Shock Response Spectrum
%  25 - Finite Impulse Response Filter
%  26 - Multiple Coherence
%  27 - Order Function
uf.functionType = 4;
end