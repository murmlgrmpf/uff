function Info = writeuff(fileName, UffDataSets, action)
%WRITEUFF Writes UFF (Universal File Format) files of 10 types:
%   151, 15, 18, 55, 1858, 58, 82, 164, 2420, and also the hybrid one, 58b
%   Info = writeuff(fileName, UffDataSets, action)
%
%   Works in Matlab/Octave.
%
%
%   - fileName:     name of the uff file to write data to (add or replace - see action parameter)
%   - UffDataSets:  an array of structures; each structure holds one data set
%                   (the data set between -1 and -1; Each structure,
%                   UffDataSets{i}, has the field
%                       .dsType
%                       .binary
%                   and some additional, data-set dependent fields (some of
%                   them are optional) and are as follows:
%                   #1858 - optional for additional information not contained in
%                           UFF58.  Must be placed just before UFF58.
%                       (Optional fields):
%                       .windowType             .AmpUnits
%                       .NorMethod              .ordNumDataTypeQual
%                       .ordDenomDataTypeQual   .zDataTypeQual
%                       .samplingType           .zRPM
%                       .zTime                  .zOrder
%                       .NumSamples             .expWindowDamping
%                   #58 - for measurement data - function at dof (58). 
%                       .x (time or frequency)  .measData               .d1 (descrip. 1)
%                       .d2 (descrip. 2)        .date                   .functionType (see notes)
%                       .rspNode                .rspDir                 .refNode
%                       .refDir
%                       (Optional fields):
%                       .precision {'single' or 'double'}, defaults to double
%                       .ID_4                   .ID_5                   .loadCaseId
%                       .rspEntName             .refEntName
%                       .abscDataChar           .abscUnitsLabel
%                       .abscLengthUnitsExponent.abscForceUnitsExponent
%                       .abscTempUnitsExponent  .abscAxisLabel
%                       .ordinateLengthUnitsExponent
%                       .ordDataChar            .ordDenomDataChar       
%                       .ordinateNumUnitsLabel  .ordinateDenomUnitsLabel
%                       .zUnitsLabel            .zAxisValue
%                       .ordinateForceUnitsExponent .ordinateTempUnitsExponent
%                       .ordinateAxisLabel
%
%                   #15 - coordinate data (15)  (Grid pts):
%                       .nodeN                  .x                      .y
%                       .z
%                       (Optional fields):
%                       .defCS                  .dispCS                 .color
%
%                   #18 - coordinate system data (18):
%                       .csNum                  .csType                 .refCsNum  
%						.color                  .method    (=1)         .csName    
%					    .csX                    .csY                    .csZ
%                       .ref1X                  .ref1Y                  .ref1Z 
%			            .ref2X                  .ref2Y                  .ref2Z
%                       Method 1 defines the CS with three points: origin,
%                       point on +x axis, point on +xz plane
%
%                   #82 - display Sequence data (82):
%                       .traceNum               .lines
%                       (Optional fields):
%                       .color                  .ID
%
%                   #55 - data at nodes (55):
%                       Common fields:
%                       .analysisType           .dataCharacter = 1      .r1
%                       .r2                     .r3                     .responseType
%                       .dataType (2=real data, 5=complex data)
%                       (Optional fields; needed if there are 6DOFs per node. For complex
%                        data there additional fields are ignored):
%                       .r4                     .r5                     .r6
%                       Normal modes specific fields (analysisType = 2)
%                       .modeNum                .modeFreq               .modeMass
%                       .mode_v_damping_ratio   .mode_h_damping_ratio
%                       ...or, for complex modes specific fields (analysisType = 3 or 7)
%                       .modeNum                .eigVal                 .modalA
%                       .modalB
%                       ...or, for frequency response specific fields (analysisType = 5)
%                       .freqNum                .freq
%
%                   #151 - header data (151):
%                       .modelName              .description            .dbApp
%                       .dateCreated            .timeCreated            .dbVersion
%                       .dbLastSaveDate         .dbLastSaveTime         .uffApp
%
%                   #164 - units (164):
%                       .unitsCode              .tempMode
%                       Unit factors for converting universal file units to SI. To convert from
%                       universal file units to SI divide by the appropriate factor listed below:
%                       .facLength              .facForce               .facTemp
%                       .facTempOffset
%                       (Optional fields):
%                       .unitsDescription
%
%                   #1860 - transducer calibration data
%                       .serNum
%                       .sensitivity (mV/EU)  (EU set by file type 164)
%                       .dataType (from UFF 58 record 8)
%                       .operatingMode  (1 - voltage, 2 - ICP, 3 - ?)
%                       (Optional fields):
%                       .manufacturer           .model
%                       .calibrationBy          .calibrationDate
%                       .calibrationDueDate     .transducerDescrip
%                       .typeQualifier          .lengthUnitsExp
%                       .forceUnitsExp          .temperatureUnitsExp
%                       .unitsLabel
%
%                   #2420 - coordinate systems (2420):
%                       .partUID                .partName
%                       .csLabels (array)       .csTypes (0=cart. 1=sph. 2=cyl.)
%                       .csColors (array)
%                       .csTrMatrices (cell array of 4x3 transformation matrices for each cs)
%                       (optional)
%                       .csNames (cell array)
%
%   - action:       (optional) 'add' (default) or 'replace'
%
%   - Info:         (optional) structure with the following fields:
%                   .errcode    -   an array of error codes for each data
%                                   ment to be written; 0 = no error otherwise an error occured in data
%                                   set being written - see errmsg
%                   .errmsg     -   error messages (cell array of strings) for each
%                                   data set - empty if no error occured at specific data set
%                   .nErrors    -   number of errors found (unsupported
%                                   datasets, error writing data set,...)
%                   .errorMsgs  -   error messages (empty if no error is found)
%
%   NOTES: r1..r6 are response vectors with node numbers in ROWS and
%   direction in COLUMN (r1=x, r2=y,...,r6=rz).
%
%   functionType can be one of the following:
%               0 - General or Unknown
%               1 - (supported) Time Response
%               2 - (supported) Auto Spectrum
%               3 - (supported) Cross Spectrum
%               4 - (supported) Frequency Response Function
%               5 - Transmissibility
%               6 - (supported) Coherence
%               7 - Auto Correlation
%               8 - Cross Correlation
%               9 - Power Spectral Density (PSD)
%               10 - Energy Spectral Density (ESD)
%               11 - Probability Density Function
%               12 - Spectrum
%               13 - Cumulative Frequency Distribution
%               14 - Peaks Valley
%               15 - Stress/Cycles
%               16 - Strain/Cycles
%               17 - Orbit
%               18 - Mode Indicator Function
%               19 - Force Pattern
%               20 - Partial Power
%               21 - Partial Coherence
%               22 - Eigenvalue
%               23 - Eigenvector
%               24 - Shock Response Spectrum
%               25 - Finite Impulse Response Filter
%               26 - Multiple Coherence
%               27 - Order Function
%
%   analysisType can be one of the following:
%               0: Unknown
%               1: Static
%               2: (supported) Normal Mode
%               3: (supported) Complex eigenvalue first order
%               4: Transient
%               5: (supported) Frequency Response
%               6: Buckling
%               7: (supported) Complex eigenvalue second order
%
%   dataCharacter can be one of the following:
%               0: Unknown
%               1: Scalar
%               2: 3 DOF Global Translation Vector
%               3: 6 DOF Global Translation & Rotation Vector
%               4: Symmetric Global Tensor
%
%   unitsCode can be one of the following:
%               1 - SI: Meter (newton)
%               2 - BG: Foot (pound f)
%               3 - MG: Meter (kilogram f)
%               4 - BA: Foot (poundal)
%               5 - MM: mm (milli newton)
%               6 - CM: cm (centi newton)
%               7 - IN: Inch (pound f)
%               8 - GM: mm (kilogram f)
%
%   functionType as well as other parameters are described in
%   Test_Universal_File_Formats.pdf
%
%   See also: READUFF
%
%   SOURCES:    [1] Bryce Gardner's read_uff obtained from the internet
%               [2] http://www.sdrl.uc.edu/uff/SDRChelp/LANG/English/unv_ug/book.htm
%
%
%   First release on 02.02.2004
%   Primoz Cermelj, Slovenia
%   Contact: primoz.cermelj@gmail.com
%   Download location: http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=6395&objectType=file
%
%   Version:  1.1.2
%   Last revision: 2.12.2015
%
%   Contributors:
%   - Ben Cazzolato
%   - Ulrich Bittner
%   - Edward Hage 
%
%   Bug reports, questions, contributions, etc. can be sent to the e-mail given above.
%   
%   Known bug - double precision binary abscissa write is in double precision
%               but must be in single precision
%              (only affects uneven data and readuff has the corresponding issue)
%--------------------------------------------------------------------------

%----------------
% WRITEUFF history
%----------------
% [v.1.1.2] 2.12.2015
% - FIX: Matlab-related bug removed in dataset 58 writing iscomplex Octave function replaced by ~isreal
% [v.1.1.1] 20.11.2015
% - FIX: bug removed: dataset 58 writing had 2 issues with even abscissa and complex meas data
% [v.1.1.0] 14.11.2015
% - NEW: support for data set #18 added (Ulrich Bittner, Bosch Rexroth).
% [v.1.0.1] 24.11.2014
% - FIX: proper dataType field handling addded to data-set 55. Thanks to Edward Hage
% [v.1.0.0] 27.02.2013
% - FIX: data-set 151 fields unified (readuff and writeuff)
% [v.0.9.8b7] 17.07.2012
% - FIX: ordinateDenumUnitsLabel changed to ordinateDenomUnitsLabel
% [v.0.9.8b7-v.0.9.8b10] 16.Apr.2012
% - MOD: increased the precision for dx in UFF58 line 7 for PC
% - NEW: added filetype 1860 transducer calibration
% [v.0.9.8b7-v.0.9.8b9] 04.Apr.2012
% - BUG: bug in filetype 82 fixed
% [v.0.9.8b7-v.0.9.8b8] 03.02.2011
% - NEW added single precision writing in binary and ascii
% - FIX limit length of .unitsDescription in UFF164 to 20 characters
% - FIX number of nodes in tracelines
% - NEW added .dbCreateDate .dbCreateDate to UFF151
% - FIX ordDenomLenExp, ordinateDenomUnitsLabel names corrected
% - NEW ordLenExp & ordDenomLenExp (58)
% [v.0.9.8b4-v.0.9.8b7] 30.08.2010
% - FIX: a bug removed when writing data sets 58 (bug appeared along with
%        the last new feature added
% - NEW: function type 12 Spectrum (58)
% - NEW: support for Dataset 1858 added.
% - NEW: ordLenExp & ordDenomLenExp (58)
% - FIX: correct number of bytes written for 58b when uneven data
% - FIX: corrected detection whether the abscissa is even or not
% - FIX: minor changes
% [v.0.9.8b2] 31.01.2006
% - NEW: uneven abscissa data-writing is now supported
% - NEW: 2420 data-set added (coordinate systems)
% [v.0.9.5b1] 06.06.2005
% - NEW: hybrid binary-58 format (58b) is now supported
% - NEW: binary field was added to UffDataSets structures
% [v.0.9.4] 24.05.2005
% - NEW: dsType field is added to UffDataSets structures; dsTypes parameter
%        is no longer needed
%
%----------------

% Notes
% Ideas only reads single precision in binary
% Ideas writes out the Ordinate length units exponent as 2 for auto
% spectrum, 1 for spectrum and 1 for FRF 
% Ideas writes out 1 for the Denominator for the length units exponent
% Ideas units for autopower spectrum requires file 1858 

%--------------
% Check input arguments
%--------------
error(nargchk(2,3,nargin));
if nargin < 3 || isempty(action)
    action = 'add';
end
if ~iscell(UffDataSets)
    error('UffDataSets must be given as a cell array of structures');
end

%--------------
% Open the file for writing
%--------------
machineFormat='n';      % native sets to default for the OS
if strcmpi(action,'replace')
    [fid,ermesage] = fopen(fileName,'w',machineFormat);
else
    [fid,ermesage] = fopen(fileName,'a',machineFormat);
end
if fid == -1,
    error(['could not open file: ' fileName]);
end

%--------------
% Go through all the data sets and write each data set according to its type
%--------------
nDataSets = length(UffDataSets);

Info.errcode = zeros(nDataSets,1);
Info.errmsg = cell(nDataSets,1);
Info.nErrors = 0;

for ii=1:nDataSets
    try
        %
        switch UffDataSets{ii}.dsType
            case {15,18,82,55,1858,58,151,164,1860,2420}
                fprintf(fid,'%6i%74s\n',-1,' ');
                switch UffDataSets{ii}.dsType
                    case 15
                        Info.errmsg{ii} = write15(fid,UffDataSets{ii});
                    case 18
                        Info.errmsg{ii} = write18(fid,UffDataSets{ii});
                    case 82
                        Info.errmsg{ii} = write82(fid,UffDataSets{ii});
                    case 55
                        Info.errmsg{ii} = write55(fid,UffDataSets{ii});
                    case 1858
                        Info.errmsg{ii} = write1858(fid,UffDataSets{ii});
                    case 58
                        Info.errmsg{ii} = write58(fid,UffDataSets{ii});
                    case 151
                        Info.errmsg{ii} = write151(fid,UffDataSets{ii});
                    case 164
                        Info.errmsg{ii} = write164(fid,UffDataSets{ii});
                    case 1860
                        Info.errmsg{ii} = write1860(fid,UffDataSets{ii});
                    case 2420
                        Info.errmsg{ii} = write2420(fid,UffDataSets{ii});
                end
                fprintf(fid,'%6i%74s\n',-1,' ');
            otherwise
                Info.errmsg{ii} = ['Unsupported data set: ' num2str(UffDataSets{ii}.dsType)];
        end
        %
    catch
        fclose(fid);
        error(['Error writing uff file: ' fileName ': ' lasterr]);
    end
end
fclose(fid);

for ii=1:nDataSets
    if ~isempty(Info.errmsg{ii})
        Info.errcode(ii) = 1;
    end
end
Info.nErrors = length(find(Info.errcode));
Info.errorMsgs = Info.errmsg(find(Info.errcode));








%==========================================================================
%                       SUBFUNCTIONS SECTION
%==========================================================================

%--------------------------------------------------------------------------
function errMessage = write15(fid,UFF)
% #15 - Write data-set type 15 data
errMessage = [];
if ispc
    F_13 = '%13.4e';
else
    F_13 = '%13.5e';
end
try
    n = length(UFF.nodeN);
    if ~isfield(UFF,'defCS');   UFF.defCS = zeros(n,1);  end;
    if ~isfield(UFF,'dispCS');  UFF.dispCS = zeros(n,1); end;
    if ~isfield(UFF,'color');   UFF.color = zeros(n,1);  end;
    fprintf(fid,'%6i%74s\n',15,' ');
    for ii=1:n
        fprintf(fid,['%10i%10i%10i%10i' F_13 F_13 F_13 '\n'],UFF.nodeN(ii),UFF.defCS(ii),UFF.dispCS(ii),UFF.color(ii), ...
            UFF.x(ii),UFF.y(ii),UFF.z(ii));
    end
catch
    errMessage = ['error writing coordinate data: ' lasterr];
end
%-----------------------------------------------------------------

%-----------------------------------------------------------------
function errMessage = write18(fid, UFF)
% #18 - Write data-set type 18 data
errMessage = [];
if ispc
    F_13 = '%13.4e';
else
    F_13 = '%13.5e';
end
try
    n = length(UFF.csNum);
    if ~isfield(UFF,'csType');   UFF.csType = zeros(n,1);  end;
    if ~isfield(UFF,'refCsNum');  UFF.refCsNum = zeros(n,1); end;
    if ~isfield(UFF,'color');   UFF.color = zeros(n,1);  end;
    if ~isfield(UFF,'method');   UFF.method = ones(n,1);  end;
    if ~isfield(UFF,'csName');   UFF.csName = cellstr(strcat('CS',num2str(linspace(1,n,n).'))).';  end;
    fprintf(fid,'%6i%74s\n',18,' ');
    for ii=1:n
        fprintf(fid,['%10i%10i%10i%10i%10i\n'],UFF.csNum(ii),UFF.csType(ii),UFF.refCsNum(ii),UFF.color(ii), ...
            UFF.method(ii));
        fprintf(fid,'%-20s\n',UFF.csName{ii});
        fprintf(fid,[ F_13 F_13 F_13 F_13 F_13 F_13 '\n'],UFF.csX(ii),UFF.csY(ii),UFF.csZ(ii),UFF.ref1X(ii), ...
            UFF.ref1Y(ii),UFF.ref1Z(ii));
        fprintf(fid,[ F_13 F_13 F_13 '\n'],UFF.ref2X(ii),UFF.ref2Y(ii),UFF.ref2Z(ii));
    end
catch
    errMessage = ['error writing coordinate data: ' lasterr];
end
%-----------------------------------------------------------------

%--------------------------------------------------------------------------
function errMessage = write82(fid,UFF)
% #82 - Write data-set type 82 data
errMessage = [];
try
    if ~isfield(UFF,'ID');      UFF.ID = 'NONE'; end;
    if ~isfield(UFF,'color');   UFF.color = 0;  end;
    fprintf(fid,'%6i%74s\n',82,' ');
    fprintf(fid,'%10i%10i%10i\n',UFF.traceNum,length(UFF.lines),UFF.color);  % line 1
    fprintf(fid,'%-80s\n',UFF.ID); % line 2
    fprintf(fid,'%10i%10i%10i%10i%10i%10i%10i%10i\n',UFF.lines); % line 3
    if rem(length(UFF.lines),8)~=0,
        fprintf(fid,'\n');
    end
catch
    errMessage = ['error writing display-sequence data: ' lasterr];
end
%-----------------------------------------------------------------


%--------------------------------------------------------------------------
function errMessage = write55(fid,UFF)
% #55 - Write data-set type 55 data
if ispc
    F_13 = '%13.4e';
else
    F_13 = '%13.5e';
end
errMessage = [];
try
    if isfield(UFF,'r4') & isfield(UFF,'r5') & isfield(UFF,'r6')
        num_data_per_pt = 6;
    else
        num_data_per_pt = 3;
    end

    fprintf(fid,'%6i%74s\n',55,' ');
    fprintf(fid,'%-80s\n','NONE'); %line 1
    fprintf(fid,'%-80s\n','NONE'); %line 2
    fprintf(fid,'%-80s\n','NONE'); %line 3
    fprintf(fid,'%-80s\n','NONE'); %line 4
    fprintf(fid,'%-80s\n','NONE'); %line 5
    fprintf(fid,'%10i%10i%10i%10i%10i%10i\n',1,UFF.analysisType,UFF.dataCharacter, ...
        UFF.responseType,UFF.dataType,num_data_per_pt); %line 6
    if UFF.analysisType == 2,                               % Normal modes
        fprintf(fid,'%10i%10i%10i%10i\n',2,4,0,UFF.modeNum); %line 7
        fprintf(fid,[F_13 F_13 F_13 F_13 '\n'], ...
            UFF.modeFreq,UFF.modeMass,UFF.mode_v_damping,UFF.mode_h_damping); %line 8
    elseif UFF.analysisType == 5,                           % Frequency Response
        fprintf(fid,'%10i%10i%10i%10i\n',2,1,0,UFF.freqNum); %line 7
        fprintf(fid,'%13.4e\n', UFF.freq); %line 8
    elseif UFF.analysisType == 3 | UFF.analysisType == 7,   % Complex modes
        fprintf(fid,'%10i%10i%10i%10i\n',2,6,0,UFF.modeNum); %line 7
        fprintf(fid,[F_13 F_13 F_13 F_13 F_13 F_13 '\n'], ...
            real(UFF.eigVal),imag(UFF.eigVal),real(UFF.modalA),imag(UFF.modalA), ...
            real(UFF.modalB),imag(UFF.modalB)); %line 8
    else
        errMessage = ['Unsupported analysis type: ' num2str(UFF.analysisType)];
        return
    end
    if UFF.dataType == 2,  % real data
        if num_data_per_pt == 3,
            for k = 1:length(UFF.nodeNum);
                fprintf(fid,'%10i\n',UFF.nodeNum(k));
                fprintf(fid,[F_13 F_13 F_13 '\n'],...
                    real(UFF.r1(k)), real(UFF.r2(k)), real(UFF.r3(k)));
            end
        else    % num_data_per_pt = 6
            for k = 1:length(UFF.nodeNum);
                fprintf(fid,'%10i\n',UFF.nodeNum(k));
                fprintf(fid,[F_13 F_13 F_13 F_13 F_13 F_13 '\n'], ...
                    real(UFF.r1(k)), real(UFF.r2(k)), real(UFF.r3(k)),...
                    real(UFF.r4(k)), real(UFF.r5(k)), real(UFF.r6(k)));
            end
        end
    elseif UFF.dataType == 5  %complex data
        for k = 1:length(UFF.nodeNum);
            fprintf(fid,'%10i\n',UFF.nodeNum(k));
            fprintf(fid,[F_13 F_13 F_13 F_13 F_13 F_13 '\n'], ...
                real(UFF.r1(k)),imag(UFF.r1(k)), real(UFF.r2(k)),imag(UFF.r2(k)), ...
                real(UFF.r3(k)),imag(UFF.r3(k)));
        end
    else
        errMessage = sprintf('Unsupported dataType: %d', UFF.dataType);
        return
    end
    
catch
    errMessage = ['error writing modal data: ' lasterr];
end
%-----------------------------------------------------------------


%--------------------------------------------------------------------------
function errMessage = write1858(fid,UFF)
% #1858 - Write data-set type 1858 data
% Ideas writes this out just before the UFF58 file
% Fortran 1PE15.7 puts one significant digit to the left of the decimal place,
% Matlab's default
if ispc
    F_15 = '%15.6e';
else
    F_15 = '%15.7e';
end
errMessage = [];
try
    if ~isfield(UFF,'windowType');  UFF.windowType = 0; end;
    if ~isfield(UFF,'AmpUnits');  UFF.AmpUnits = 0; end;
    if ~isfield(UFF,'NorMethod');  UFF.NorMethod = 0; end;
    if ~isfield(UFF,'ordNumDataTypeQual');  UFF.ordNumDataTypeQual = 0; end;
    if ~isfield(UFF,'ordDenomDataTypeQual');  UFF.ordDenomDataTypeQual = 0; end;
    if ~isfield(UFF,'zDataTypeQual');  UFF.zDataTypeQual = 0; end;
    if ~isfield(UFF,'samplingType');  UFF.samplingType = 0; end;
    if ~isfield(UFF,'zRPM');  UFF.zRPM = 0; end;
    if ~isfield(UFF,'zTime');  UFF.zTime = 0; end;
    if ~isfield(UFF,'zOrder');  UFF.zOrder = 0; end;
    if ~isfield(UFF,'NumSamples');  UFF.NumSamples = 0; end;
    if ~isfield(UFF,'expWindowDamping');  UFF.expWindowDamping = 0; end;
    fprintf(fid,'%6i%74s\n',1858,' ');
    % Line 1
    fprintf(fid,'%12i%12i%12i%12i%12i%12i        \n',0,0,0,0,0,0);
    % Line 2
    fprintf(fid,'%6i%6i%6i%6i%6i%6i%6i%6i%6i%6i%6i%6i        \n',0,UFF.windowType,UFF.AmpUnits,UFF.NorMethod,0,UFF.ordNumDataTypeQual,UFF.ordDenomDataTypeQual,UFF.zDataTypeQual,UFF.samplingType,0,0,0);
    % Line 3
    fprintf(fid,[ F_15 F_15 F_15 F_15 F_15 '     \n'],0,0,0,0,UFF.expWindowDamping);
    % Line 4
    fprintf(fid,[ F_15 F_15 F_15 F_15 F_15 '     \n'],0,0,0,0,0);
    % Line 5
    fprintf(fid,[ F_15 F_15 F_15 F_15 F_15 '     \n'],0,0,0,0,0);
    % Line 6 (IDeas seems not to follow the 80 character convention)
    fprintf(fid,'%-6s%-74s\n','NONE','NONE');
    % Line 7
    fprintf(fid,'%-80s\n','NONE');
catch
    errMessage = ['error writing modal data: ' lasterr];
end
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
function errMessage = write58(fid,UFF)
% #58 - Write data-set type 58 data
%
%       Ordinate             Abscissa
% Case  Type    Precision   Spacing    Format
% 1     real    single      even        6E13.5
% 2     real    single      uneven      6E13.5
% 3     complex single      even        6E13.5
% 4     complex single      uneven      6E13.5
% 5     real    double      even        4E20.12
% 6     real    double      uneven      2(E13.5,E20.12)
% 7     complex double      even        4E20.12
% 8     complex double      uneven      E13.5,2E20.12

% For binary unevenly spaced double precision data, the documentation is unclear as to
% whether the abscissa should be single or double precision.  There is some
% indication that perhaps it should be single, but double has been
% implemented here

if ispc
    F_13 = '%13.4e';
    F_20 = '%20.11e';
else
    F_13 = '%13.5e';
    F_20 = '%20.12e';
end
errMessage = [];
try
    if isempty(find(UFF.functionType == [1 2 3 4 6 12], 1))
        errMessage = ['Unsupported function type: ' num2str(UFF.functionType)];
        return
    end
    if ~isfield(UFF,'precision'); UFF.precision='double'; end;
    if ~isfield(UFF,'ID_4');  UFF.ID_4 = 'NONE'; end;
    if ~isfield(UFF,'ID_5');  UFF.ID_5 = 'NONE'; end;
    if ~isfield(UFF,'loadCaseId');  UFF.loadCaseId = 0; end;
    if ~isfield(UFF,'abscLengthUnitsExponent');  UFF.abscLengthUnitsExponent = 0; end;
    if ~isfield(UFF,'abscForceUnitsExponent');  UFF.abscForceUnitsExponent = 0; end;
    if ~isfield(UFF,'abscTempUnitsExponent');  UFF.abscTempUnitsExponent = 0; end;
    if ~isfield(UFF,'abscAxisLabel');  UFF.abscAxisLabel = 'NONE'; end;
    if ~isfield(UFF,'abscUnitsLabel');  UFF.abscUnitsLabel= 'NONE'; end;
    if ~isfield(UFF,'ordinateLengthUnitsExponent');  UFF.ordinateLengthUnitsExponent = 0; end;
    if ~isfield(UFF,'ordinateForceUnitsExponent');  UFF.ordinateForceUnitsExponent = 0; end;
    if ~isfield(UFF,'ordinateTempUnitsExponent');  UFF.ordinateTempUnitsExponent = 0; end;
    if ~isfield(UFF,'ordinateAxisLabel');  UFF.ordinateAxisLabel = 'NONE'; end;
    if ~isfield(UFF,'rspEntName');  UFF.rspEntName = 'NONE'; end;
    if ~isfield(UFF,'refEntName');  UFF.refEntName = 'NONE'; end;
    if ~isfield(UFF,'ordinateNumUnitsLabel');  UFF.ordinateNumUnitsLabel= 'NONE'; end;
    if ~isfield(UFF,'ordLenExp');  UFF.ordLenExp = 0; end;
    if ~isfield(UFF,'ordinateDenomUnitsLabel');  UFF.ordinateDenomUnitsLabel= 'NONE'; end;
    if ~isfield(UFF,'ordDenomLenExp');  UFF.ordDenomLenExp = 0; end;
    if ~isfield(UFF,'zUnitsLabel');  UFF.zUnitsLabel= 'NONE'; end;
    if ~isfield(UFF,'zAxisValue');  UFF.zAxisValue= 0; end;
    if UFF.functionType == 1    % time response
        if ~isfield(UFF,'abscDataChar');  UFF.abscDataChar = 17; end;
        if ~isfield(UFF,'ordDataChar');  UFF.ordDataChar = 8; end;
        if ~isfield(UFF,'ordDenomDataChar');  UFF.ordDenomDataChar = 0; end;
    else                        % frequency response
        if ~isfield(UFF,'abscDataChar');  UFF.abscDataChar = 18; end;
        if ~isfield(UFF,'ordDataChar');  UFF.ordDataChar = 12; end;
        if ~isfield(UFF,'ordDenomDataChar');  UFF.ordDenomDataChar = 13; end;
    end
    
    isXEven = (length( unique( diff(UFF.x) ) ) < 2);
    isDatacomplex = ~isreal(UFF.measData);
    
    if     ~isDatacomplex && strcmpi(UFF.precision,'single') &&  isXEven; caseID=1;
    elseif ~isDatacomplex && strcmpi(UFF.precision,'single') && ~isXEven; caseID=2;
    elseif  isDatacomplex && strcmpi(UFF.precision,'single') &&  isXEven; caseID=3;
    elseif  isDatacomplex && strcmpi(UFF.precision,'single') && ~isXEven; caseID=4;
    elseif ~isDatacomplex && strcmpi(UFF.precision,'double') &&  isXEven; caseID=5;
    elseif ~isDatacomplex && strcmpi(UFF.precision,'double') && ~isXEven; caseID=6;
    elseif  isDatacomplex && strcmpi(UFF.precision,'double') &&  isXEven; caseID=7;
    elseif  isDatacomplex && strcmpi(UFF.precision,'double') && ~isXEven; caseID=8;
    else errMessage = 'Cannot determine data writing case for data set 58'; return
    end
    
    if UFF.binary
        [filename, mode, machineformat] = fopen(fid);
        if strcmpi(machineformat(1:7),'ieee-le')
            byteOrdering = 1;
        else
            byteOrdering = 2;
        end
        % number of bytes
        switch caseID,
            case 1, % real, single precision, even data
                nBytes=(4+0+0)*length(UFF.measData);
            case 2, % real, single precision, uneven data
                nBytes=(4+0+4)*length(UFF.measData);
            case 3, % complex, single precision, even data
                nBytes=(4+4+0)*length(UFF.measData);
            case 4, % complex, single precision, uneven data
                nBytes=(4+4+4)*length(UFF.measData);
            case 5, % real, double precision, even data
                nBytes=(8+0+0)*length(UFF.measData);
            case 6, % real, double precision, uneven data
                nBytes=(8+0+8)*length(UFF.measData);
            case 7, % complex, double precision, even data
                nBytes=(8+8+0)*length(UFF.measData);
            case 8, % complex, double precision, uneven data
                nBytes=(8+8+8)*length(UFF.measData);
        end
        fprintf(fid,'%6i%1s%6i%6i%12i%12i%6i%6i%12i%12i\n',58,'b',byteOrdering,2,11,nBytes,0,0,0,0);
    else
        fprintf(fid,'%6i%74s\n',58,' ');
    end
    if length(UFF.d1)<=80,
        fprintf(fid,'%-80s\n',UFF.d1);   %  line 1
    else
        fprintf(fid,'%-80s\n',UFF.d1(1:80));   %  line 1
    end
    if length(UFF.d2)<=80,
        fprintf(fid,'%-80s\n',UFF.d2);   %  line 2
    else
        fprintf(fid,'%-80s\n',UFF.d2(1:80));   %  line 2
    end
    if length(UFF.date)<=80,
        fprintf(fid,'%-80s\n',UFF.date);   %  line 3
    else
        fprintf(fid,'%-80s\n',UFF.date(1:80));   %  line 3
    end
    if length(UFF.ID_4)<=80,
        fprintf(fid,'%-80s\n',UFF.ID_4);   %  line 4
    else
        fprintf(fid,'%-80s\n',UFF.ID_4(1:80));   %  line 4
    end
    if length(UFF.ID_5)<=80,
        fprintf(fid,'%-80s\n',UFF.ID_5);   %  line 5
    else
        fprintf(fid,'%-80s\n',UFF.ID_5(1:80));   %  line 5
    end
    %
    fprintf(fid,'%5i%10i%5i%10i %-10s%10i%4i %-10s%10i%4i\n',UFF.functionType,0,0,UFF.loadCaseId,UFF.rspEntName,...
        UFF.rspNode,UFF.rspDir,UFF.refEntName,UFF.refNode,UFF.refDir);    % line 6
    numpt = length(UFF.measData);
    % line 7
    dx = UFF.x(2) - UFF.x(1);
    switch caseID,
        case {1, 2},    % real single precision
            ordDataType=2;
        case {5, 6},    % real, double precision
            ordDataType=4;
        case {3, 4},    % complex, single precision
            ordDataType=5;
        case {7, 8},    % complex, double precision
            ordDataType=6;
    end
%     fprintf(fid,['%10i%10i%10i' F_13 F_13 F_13 '           \n'],ordDataType,numpt,isXEven,isXEven*UFF.x(1),isXEven*dx,UFF.zAxisValue);
    fprintf(fid,'%10i%10i%10i%13.5e%13.5e%13.5e           \n',ordDataType,numpt,isXEven,isXEven*UFF.x(1),isXEven*dx,UFF.zAxisValue);
    % line 8
    fprintf(fid,'%10i%5i%5i%5i %-20s %-20s             \n',UFF.abscDataChar,0,0,0,'NONE',UFF.abscUnitsLabel);
    % line 9
    fprintf(fid,'%10i%5i%5i%5i %-20s %-20s             \n',UFF.ordDataChar,UFF.ordLenExp,0,0,'NONE',UFF.ordinateNumUnitsLabel);
    %                                                      ^--acceleration data
    % line 10
    % others: 0=unknown,8=displacement,11=velocity,13=excitation force,15=pressure
    fprintf(fid,'%10i%5i%5i%5i %-20s %-20s             \n',UFF.ordDenomDataChar,UFF.ordDenomLenExp,0,0,'NONE',UFF.ordinateDenomUnitsLabel);
    %                                                      ^--excitation force data
    % line 11
    % others: 0=unknown,8=displacement,11=velocity,12=acceleration,15=pressure
    fprintf(fid,'%10i%5i%5i%5i %-20s %-20s             \n',0,0,0,0,'NONE',UFF.zUnitsLabel);
    %
    % line 12: % data values
    nOrdValues = length(UFF.measData);
    switch caseID,
        case {1, 5}     % real even data
            newdata = UFF.measData;
        case {2, 6}     % real uneven data
            newdata = zeros(2*nOrdValues,1);
            newdata(1:2:end-1) = UFF.x;
            newdata(2:2:end) = UFF.measData;
        case {3, 7}     % complex even data
            newdata = zeros(2*nOrdValues,1);
            newdata(1:2:end-1) = real(UFF.measData);
            newdata(2:2:end)   = imag(UFF.measData);
        case {4, 8}     % complex uneven data
            newdata = zeros(3*nOrdValues,1);
            newdata(1:3:end-2) = UFF.x;
            newdata(2:3:end-1) = real(UFF.measData);
            newdata(3:3:end)   = imag(UFF.measData);
    end
    
    if UFF.binary
        if strcmp(UFF.precision,'single')
            fwrite(fid,newdata, 'single');
        else
            fwrite(fid,newdata, 'double');
        end
    else    % ascii
        switch caseID,
            case 1, % real, single precision, even data
                fprintf(fid,[F_13 F_13 F_13 F_13 F_13 F_13 '\n'],newdata);
                if rem(length(newdata),6)~=0,
                    fprintf(fid,'\n');
                end
            case 2, % real, single precision, uneven data
                fprintf(fid,[F_13 F_13 F_13 F_13 F_13 F_13 '\n'],newdata);
                if rem(length(newdata),6)~=0,
                    fprintf(fid,'\n');
                end
            case 3, % complex, single precision, even data
                fprintf(fid,[F_13 F_13 F_13 F_13 F_13 F_13 '\n'],newdata);
                if rem(length(newdata),6)~=0,
                    fprintf(fid,'\n');
                end
            case 4, % complex, single precision, uneven data
                fprintf(fid,[F_13 F_13 F_13 F_13 F_13 F_13 '\n'],newdata);
                if rem(length(newdata),6)~=0,
                    fprintf(fid,'\n');
                end
            case 5, % real, double precision, even data
                fprintf(fid,[F_20 F_20 F_20 F_20 '\n'],newdata);
                if rem(length(newdata),4)~=0,
                    fprintf(fid,'\n');
                end
            case 6, % real, double precision, uneven data
                fprintf(fid,[F_13 F_20 F_13 F_20 '\n'],newdata);
                if rem(length(newdata),4)~=0,
                    fprintf(fid,'\n');
                end
            case 7, % complex, double precision, even data
                fprintf(fid,[F_20 F_20 F_20 F_20 '\n'],newdata);
                if rem(length(newdata),4)~=0,
                    fprintf(fid,'\n');
                end
            case 8, % complex, double precision, uneven data
                fprintf(fid,[F_13 F_20 F_20 '\n'],newdata);
                if rem(length(newdata),3)~=0,
                    fprintf(fid,'\n');
                end
        end
    end
    
catch
    errMessage = ['error writing measurement data: ' lasterr];
end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function errMessage = write151(fid,UFF)
% #151 - Write data-set type 151 data
errMessage =[];
try
    d = datestr(now,1);
    d(end-3:end-2) = [];
    if ~isfield(UFF,'dateCreated'); UFF.dateCreated=d; end
    if ~isfield(UFF,'timeCreated'); UFF.timeCreated=datestr(now,13); end
    if ~isfield(UFF,'dbVersion'); UFF.dbVersion = 0; end;
    if ischar(UFF.dbVersion); UFF.dbVersion = str2num(UFF.dbVersion); end;
    if ~isfield(UFF,'dbLastSaveDate'); UFF.dbLastSaveDate=d; end;
    if ~isfield(UFF,'dbLastSaveTime'); UFF.dbLastSaveTime=datestr(now,13); end;
    
    fprintf(fid,'%6i%74s\n',151,' ');
    fprintf(fid,'%-80s\n',UFF.modelName); % line 1
    fprintf(fid,'%-80s\n',UFF.description); % line 2
    fprintf(fid,'%-80s\n',UFF.dbApp); % line 3
    fprintf(fid,'%-10s%-10s%10i%10i%10i%30s\n',...
        UFF.dateCreated,UFF.timeCreated,UFF.dbVersion,UFF.dbVersion,0,' '); % line 4
    fprintf(fid,'%-10s%-10s%60s\n',UFF.dbLastSaveDate,UFF.dbLastSaveTime,' '); % line 5
    fprintf(fid,'%-80s\n',UFF.uffApp); % line 6
    fprintf(fid,'%-10s%-10s%60s\n',d,datestr(now,13),' '); % line 7
catch
    errMessage = ['error writing header data: ' lasterr];
end
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
function errMessage = write164(fid,UFF)
% #164 - Write data-set type 164 data
errMessage = [];
try
    if ~isfield(UFF,'unitsDescription'); UFF.unitsDescription = ' '; end;
    fprintf(fid,'%6i%74s\n',164,' ');
    if ischar(UFF.tempMode); UFF.tempMode = str2num(UFF.tempMode); end;
    if isempty(UFF.tempMode); UFF.tempMode = 1; end;
    if length(UFF.unitsDescription)>20; UFF.unitsDescription=UFF.unitsDescription(1:20); end;
    fprintf(fid,'%10i%-20s%10i\n',UFF.unitsCode,UFF.unitsDescription,UFF.tempMode); % line 1
    %
    str = lower(sprintf('%25.17e%25.17e%25.17e',UFF.facLength,UFF.facForce,UFF.facTemp)); % line 2
    str = strrep(str,'e+','D+');
    str = strrep(str,'e-','D-');
    fprintf(fid,'%s\n',str);
    str = lower(sprintf('%25.17e',UFF.facTempOffset)); % line 3
    str = strrep(str,'e+','D+');
    str = strrep(str,'e-','D-');
    fprintf(fid,'%s\n',str);
catch
    errMessage = ['error writing units data: ' lasterr];
end
%--------------------------------------------------------------------------


function errMessage = write1860(fid,UFF)
% #1860 - Write data-set type 1860 transducer calibration data
errMessage = [];
if ispc
    F_15 = '%15.6e';
else
    F_15 = '%15.7e';
end
try
    if ~ischar(UFF.serNum); UFF.serNum = num2str(UFF.serNum); end;
    if ~isfield(UFF,'manufacturer'); UFF.manufacturer = 'NONE'; end;
    if ~isfield(UFF,'model'); UFF.model = 'NONE'; end;
    if ~isfield(UFF,'calibrationBy'); UFF.calibrationBy = 'NONE'; end;
    if ~isfield(UFF,'calibrationDate'); UFF.calibrationDate = 'NONE'; end;
    if ~isfield(UFF,'calibrationDueDate'); UFF.calibrationDueDate = 'NONE'; end;
    if ~isfield(UFF,'transducerDescrip'); UFF.transducerDescrip = 'NONE'; end;
    if ~isfield(UFF,'typeQualifier'); UFF.typeQualifier = 0; end;
    if ~isfield(UFF,'lengthUnitsExp'); UFF.lengthUnitsExp = 0; end;
    if ~isfield(UFF,'forceUnitsExp'); UFF.forceUnitsExp = 0; end;
    if ~isfield(UFF,'temperatureUnitsExp'); UFF.temperatureUnitsExp = 0; end;
    if ~isfield(UFF,'unitsLabel'); UFF.unitsLabel = 'NONE'; end;
    fprintf(fid,'%6i%74s\n',1860,' ');
    fprintf(fid,'%-20s\n',UFF.serNum); % line 1
    fprintf(fid,'%-20s  %-20s\n',UFF.manufacturer,UFF.model); % line 2
    fprintf(fid,'%-20s  %-20s  %-20s\n',...
        UFF.calibrationBy,UFF.calibrationDate,UFF.calibrationDueDate); % line 3
    fprintf(fid,'%-80s\n',UFF.transducerDescrip); % line 4
    % Note the two spaces before the unitsLabel are missing in the 
    % documentation file but are present in the file written by Ideas
    fprintf(fid,'%12i%12i%12i%6i%6i%6i  %-20s\n',...
        UFF.operatingMode,UFF.dataType,UFF.typeQualifier,...
        UFF.lengthUnitsExp,UFF.forceUnitsExp,UFF.temperatureUnitsExp,...
        UFF.unitsLabel);                                             % line 5
    fprintf(fid,[F_15 '\n'],UFF.sensitivity); % line 6
catch
errMessage = ['error writing trasducer data: ' lasterr];
end


%--------------------------------------------------------------------------
function errMessage = write2420(fid,UFF)
% #2420 - Write data-set type 2420 data
errMessage = [];
if ispc
    F_25 = '%25.15e';
else
    F_25 = '%25.16e';
end
try
    n = length(UFF.csLabels);
    if ~isfield(UFF,'csNames'); UFF.csNames = cell(n,1); UFF.csNames(1:n) = {' '}; end;
    fprintf(fid,'%6i%74s\n',2420,' ');
    fprintf(fid,'%10i%10i\n',UFF.partUID,0);       % line 1
    fprintf(fid,'%-40s\n',UFF.partName);            % line 2
    for ii=1:n
        fprintf(fid,'%10i%10i%10i%10i\n',...
            UFF.csLabels(ii),UFF.csTypes(ii),UFF.csColors(ii),0);     % line 3
        fprintf(fid,'%-40s\n',UFF.csNames{ii});     % line 4
        fprintf(fid,[F_25 F_25 F_25 '\n'],UFF.csTrMatrices{ii}(1,1:3)); % line 5
        fprintf(fid,[F_25 F_25 F_25 '\n'],UFF.csTrMatrices{ii}(2,1:3)); % line 6
        fprintf(fid,[F_25 F_25 F_25 '\n'],UFF.csTrMatrices{ii}(3,1:3)); % line 7
        fprintf(fid,[F_25 F_25 F_25 '\n'],UFF.csTrMatrices{ii}(4,1:3)); % line 8
    end
    
catch
    errMessage = ['error writing coordinate system data: ' lasterr];
end
%--------------------------------------------------------------------------
