function nirx_defaults()
% PURPOSE: set directory paths and default settings for single session use so that only main
% toolbox directory needs to be on matlab path
% AUTHOR: D. Rojas
% INPUTS: none
% OUTPUTS: none
% HISTORY: 08/29/2022 - first version

% set paths if needed
p = path;
if ~contains(p,'nirx_tools')
    addpath(p,'nirx_tools');
end
[pth,~,~] = fileparts(which('nirx_defaults'));
if ~contains(p,'stats')
    addpath(p,fullfile(pth,'stats'));
end
if ~contains(p,'templates')
    addpath(p,fullfile(pth,'templates'));
end

% end of main
end