function [rspNode, rspDir] = Name2NodeDir(Name, NodeID)
%% Universal file Channel Name DOF ID and Direction Mapping

[StripName,Sign] = strsplit(Name,{'-','+'});

%% response Node ID
rspNode = str2double(StripName{1});
if not(isempty(NodeID)) % "Manual" setting of Node Identifier
    rspNode = NodeID;
end
if isnan(rspNode) % Catch NaN if inputname is not a number coded string
        rspNode = 0;
        % warning('rspNode was NaN. Name: %s. This may cause an issue in further processing.',Name)
end

%% response Direction
switch StripName{end}
    case 'X'
        rspDir = 1;
    case 'Y'
        rspDir = 2;
    case 'Z'
        rspDir = 3;
        % TODO: Rotational DOF 4,5,6
    otherwise
        rspDir = 0;
end

if not(isempty(Sign))&&strcmp(Sign{end},'-')
    rspDir = -rspDir;
end

end