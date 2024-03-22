function [res] = getNumberFromMrProtocol(MrPhoenixProtocol,strToFind)
%GETNUMBERFROMMRPROTOCOL returns a number entry from the MrPhoenix part of
%   a dicom header.
%
% from CTR: getMrProtocol & getMrProtocolNumber

    % Search using a regular expression over the MrPhoenixProtocol header
    tmp = regexp(MrPhoenixProtocol,...
        ['^' regexptranslate('escape',strToFind) '\s*= (.*)$'], ...
        'dotexceptnewline','lineanchors', 'tokens','once');
    
    if isempty(tmp)
        res = 0;
    else
        tmp2 = regexp(strtrim(tmp{1}),'^0x([0-9A-Fa-f]+)$','tokens','once');
        if ~isempty(tmp2)
            % Hex result
            res = hex2dec(tmp2{1});
        else
            % Decimal result
            res = str2double(tmp{1});
        end
    end
end
